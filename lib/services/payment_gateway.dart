import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'payment_config.dart';

/// Result of a payment attempt.
class PaymentResult {
  const PaymentResult({required this.success, this.paymentId, this.error});

  final bool success;
  final String? paymentId;
  final String? error;
}

/// Abstraction over the payment provider so a real gateway (Razorpay) can be
/// swapped in without touching the checkout UI or booking logic.
abstract class PaymentGateway {
  /// Launches the payment flow for [amount] (in rupees) and returns the
  /// outcome. Only the gateway layer knows how the money moves.
  Future<PaymentResult> pay({
    required int amount,
    String? reference,
    String? customerName,
    String? customerMobile,
    String? customerEmail,
  });
}

/// No-op gateway used until Razorpay is enabled.
class DummyPaymentGateway implements PaymentGateway {
  const DummyPaymentGateway();

  @override
  Future<PaymentResult> pay({
    required int amount,
    String? reference,
    String? customerName,
    String? customerMobile,
    String? customerEmail,
  }) async {
    debugPrint('[Payment] Dummy gateway — Rs $amount ($reference)');
    return const PaymentResult(success: true, paymentId: 'dummy_payment');
  }
}

/// Razorpay-backed gateway.
///
/// Flow: 1) create an order server-side (`createPaymentOrder` — the Key Secret
/// never leaves Cloud Functions), 2) open the Razorpay checkout with the order
/// id, 3) verify the returned signature AND the actual payment status
/// server-side (`verifyPayment`) before reporting success. The app never
/// trusts the checkout callback on its own.
class RazorpayPaymentGateway implements PaymentGateway {
  const RazorpayPaymentGateway();

  @override
  Future<PaymentResult> pay({
    required int amount,
    String? reference,
    String? customerName,
    String? customerMobile,
    String? customerEmail,
  }) async {
    if (!PaymentConfig.razorpayEnabled || PaymentConfig.razorpayKeyId.isEmpty) {
      return const PaymentResult(success: false, error: 'Online payments are not enabled yet.');
    }
    debugPrint('[Payment] Razorpay gateway — Rs $amount ($reference)');

    final String orderId;
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('createPaymentOrder')
          .call({'amount': amount, 'reference': reference ?? ''});
      orderId = (result.data as Map<String, dynamic>)['orderId'] as String;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[Payment] createPaymentOrder failed: ${e.code} ${e.message}');
      return PaymentResult(success: false, error: e.message ?? 'Failed to start payment.');
    } catch (e) {
      debugPrint('[Payment] createPaymentOrder threw: $e');
      return const PaymentResult(success: false, error: 'Failed to start payment.');
    }

    final razorpay = Razorpay();
    final completer = Completer<PaymentResult>();

    void finish(PaymentResult result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    void onSuccess(PaymentSuccessResponse response) {
      final paymentId = response.paymentId;
      final signature = response.signature;
      if (paymentId == null || signature == null) {
        finish(const PaymentResult(success: false, error: 'Payment confirmation was incomplete.'));
        return;
      }
      _verify(paymentId, orderId, signature, amount).then(finish, onError: (Object e) {
        debugPrint('[Payment] verifyPayment threw: $e');
        finish(const PaymentResult(success: false, error: 'Could not confirm the payment.'));
      });
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      final msg = response.message;
      finish(PaymentResult(
        success: false,
        error: (msg == null || msg.isEmpty) ? 'Payment was not completed.' : msg,
      ));
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      // Razorpay continues the flow after an external wallet is chosen.
    });

    try {
      razorpay.open({
        'key': PaymentConfig.razorpayKeyId,
        'order_id': orderId,
        'name': PaymentConfig.razorpayBrandName,
        'description': reference ?? '',
        'currency': 'INR',
        'amount': (amount * 100).toString(),
        'prefill': {
          'name': customerName ?? '',
          'contact': customerMobile ?? '',
          'email': customerEmail ?? '',
        },
      });
    } catch (e) {
      debugPrint('[Payment] razorpay.open threw: $e');
      finish(const PaymentResult(success: false, error: 'Could not open the payment screen.'));
    }

    final result = await completer.future;
    razorpay.clear();
    return result;
  }

  Future<PaymentResult> _verify(String paymentId, String orderId, String signature, int amount) async {
    try {
      await FirebaseFunctions.instance.httpsCallable('verifyPayment').call({
        'paymentId': paymentId,
        'orderId': orderId,
        'signature': signature,
        'amount': amount,
      });
      debugPrint('[Payment] Payment verified: $paymentId');
      return PaymentResult(success: true, paymentId: paymentId);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[Payment] verifyPayment failed: ${e.code} ${e.message}');
      return PaymentResult(success: false, error: e.message ?? 'Payment verification failed.');
    }
  }
}

/// Global gateway instance. Returns the Razorpay gateway once it is enabled
/// in [PaymentConfig], otherwise the no-op dummy.
PaymentGateway get paymentGateway {
  if (PaymentConfig.razorpayEnabled) return const RazorpayPaymentGateway();
  return const DummyPaymentGateway();
}

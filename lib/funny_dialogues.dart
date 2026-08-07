import 'package:flutter/material.dart';
import 'design_system.dart';

const List<String> _dialogues = [
  "You look like a hero! Be careful — girls will be attracted to your style!",
  "Booking confirmed! Now go get that glow — you deserve it!",
  "Success! You're officially the most stylish person in town!",
  "Boom! Booking done. Your swag level just went up 100x!",
  "You're not just a customer, you're a VIP! Check your token below.",
  "Booking locked! Time to relax — you've earned it, superstar!",
  "Done and dusted! Get ready to walk out looking like a million bucks!",
  "Success! The salon is lucky to have you. Own that confidence!",
  "You're booked! Warning: extreme levels of handsomeness/beauty incoming!",
  "Paid and ready! They're not ready for your glow-up!",
];

String _randomDialogue(String name) {
  final msg = _dialogues[DateTime.now().millisecondsSinceEpoch % _dialogues.length];
  return msg.replaceAll('you', name).replaceAll('You', name);
}

class PaymentSuccessDialog extends StatelessWidget {
  final String customerName;
  final String shopName;
  final String serviceName;
  final int token;
  final int amount;
  final String type; // 'booking' or 'remaining'

  const PaymentSuccessDialog({
    super.key,
    required this.customerName,
    required this.shopName,
    required this.serviceName,
    required this.token,
    required this.amount,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogue = _randomDialogue(customerName);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: DS.successLight, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.celebration, color: DS.success, size: 28)),
        const SizedBox(width: 12),
        Expanded(child: Text('Payment Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink))),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: DS.primaryLight, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shopName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? DS.darkInk : DS.ink)),
              const SizedBox(height: 2),
              Text(serviceName, style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 13)),
            ])),
            Column(children: [
              Text('Token', style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 11)),
              Text('#$token', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: DS.primary)),
            ]),
          ])),
        const SizedBox(height: 14),
        _row('Amount Paid', 'Rs $amount', isDark),
        _row('Type', type == 'premium_booking' ? 'Premium Booking' : type == 'booking' ? 'Booking Charge' : 'Service Payment', isDark),
        const SizedBox(height: 14),
        Icon(Icons.format_quote, size: 20, color: DS.accent.withValues(alpha: 0.5)),
        Text(dialogue, style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? DS.darkInk : DS.ink, fontSize: 14, height: 1.4)),
      ]),
      actions: [
        Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      ],
    );
  }

  Widget _row(String label, String value, bool isDark) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
    Flexible(child: Text('$label: ', overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontWeight: FontWeight.w500))),
    Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink))),
  ]));
}

void showPaymentSuccess(BuildContext context, {required String customerName, required String shopName, required String serviceName, required int token, required int amount, required String type}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PaymentSuccessDialog(
      customerName: customerName, shopName: shopName, serviceName: serviceName,
      token: token, amount: amount, type: type,
    ),
  );
}

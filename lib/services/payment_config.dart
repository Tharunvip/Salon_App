/// Central payment configuration.
///
/// To go live with Razorpay:
/// 1. Create a Razorpay account and generate API keys (Settings > API keys).
/// 2. Store the Key Secret + webhook secret server-side:
///      firebase functions:secrets:set RAZORPAY_KEY_ID
///      firebase functions:secrets:set RAZORPAY_KEY_SECRET
///      firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
///    and deploy the functions (`firebase deploy --only functions`).
/// 3. Flip [razorpayEnabled] to `true` and set [razorpayKeyId] to the SAME
///    key id you stored in RAZORPAY_KEY_ID. The key id is public; the key
///    secret must never live in the app.
/// 4. Deploy a new app build and test with Razorpay test keys.
class PaymentConfig {
  PaymentConfig._();

  static const bool razorpayEnabled = false;
  static const String razorpayKeyId = '';
  static const String razorpayBrandName = 'VIP Salon Hub';
}

const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');
const cloudinary = require('cloudinary').v2;
const crypto = require('crypto');
const Razorpay = require('razorpay');
const { defineSecret } = require('firebase-functions/params');

const CLOUDINARY_CLOUD_NAME = defineSecret('CLOUDINARY_CLOUD_NAME');
const CLOUDINARY_API_KEY = defineSecret('CLOUDINARY_API_KEY');
const CLOUDINARY_API_SECRET = defineSecret('CLOUDINARY_API_SECRET');
const CLOUDINARY_SECRETS = [CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET];

// Razorpay secrets live only in Secret Manager. Set them with:
//   firebase functions:secrets:set RAZORPAY_KEY_ID
//   firebase functions:secrets:set RAZORPAY_KEY_SECRET
//   firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
// Keep the value "UNSET" (or empty) until real keys are available; the payment
// functions then fail safely instead of attempting API calls.
const RAZORPAY_KEY_ID = defineSecret('RAZORPAY_KEY_ID');
const RAZORPAY_KEY_SECRET = defineSecret('RAZORPAY_KEY_SECRET');
const RAZORPAY_WEBHOOK_SECRET = defineSecret('RAZORPAY_WEBHOOK_SECRET');
const RAZORPAY_SECRETS = [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET];

admin.initializeApp();

let razorpayClient = null;

function getRazorpay() {
  const keyId = process.env.RAZORPAY_KEY_ID || '';
  const keySecret = process.env.RAZORPAY_KEY_SECRET || '';
  if (keyId === '' || keyId === 'UNSET' || keySecret === '' || keySecret === 'UNSET') return null;
  if (!razorpayClient || razorpayClient.key_id !== keyId) {
    razorpayClient = new Razorpay({ key_id: keyId, key_secret: keySecret });
  }
  return razorpayClient;
}

function getCloudinaryConfig() {
  const env = process.env;
  return {
    cloud_name: env.CLOUDINARY_CLOUD_NAME || 'udujbkbo',
    api_key: env.CLOUDINARY_API_KEY || '',
    api_secret: env.CLOUDINARY_API_SECRET || '',
  };
}

function isCloudinaryConfigured() {
  const c = getCloudinaryConfig();
  return c.cloud_name !== '' && c.api_key !== '' && c.api_secret !== '';
}

// Allowed image upload base folders. Owner-scoped sub-folders are enforced as
// "<base>/<uid>".
const ALLOWED_UPLOAD_FOLDERS = ['shop_photos', 'service_photos', 'salon_covers', 'salon_gallery'];

async function isAdminCaller(caller) {
  if (!caller) return false;
  const doc = await admin.firestore().collection('users').doc(caller.uid).get();
  return doc.exists && doc.data()?.role === 'admin';
}

exports.changePartnerPassword = functions.https.onCall(async (request) => {
  const caller = request.auth;
  if (!caller) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');

  const callerUser = await admin.firestore().collection('users').doc(caller.uid).get();
  if (!callerUser.exists || callerUser.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only an admin can change passwords');
  }

  const { partnerUid, newPassword } = request.data || {};
  if (!partnerUid || typeof newPassword !== 'string' || newPassword.length < 8) {
    throw new functions.https.HttpsError('invalid-argument', 'partnerUid and newPassword (min 8 characters) are required');
  }

  await admin.auth().updateUser(partnerUid, { password: newPassword });
  return { ok: true };
});

exports.createPartner = functions.https.onCall(async (request) => {
  const caller = request.auth;
  if (!caller) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');

  const callerUser = await admin.firestore().collection('users').doc(caller.uid).get();
  if (!callerUser.exists || callerUser.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only an admin can create partners');
  }

  const { name, email, mobile, password, partnerCode } = request.data || {};
  if (!name || !email || !mobile || !password || !partnerCode) {
    throw new functions.https.HttpsError('invalid-argument', 'name, email, mobile, password and partnerCode are required');
  }
  if (typeof name !== 'string' || typeof email !== 'string' || typeof mobile !== 'string' ||
      typeof password !== 'string' || typeof partnerCode !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'All fields must be strings');
  }
  if (password.length < 8) {
    throw new functions.https.HttpsError('invalid-argument', 'Password must be at least 8 characters');
  }
  const code = partnerCode.trim().toUpperCase();
  if (!/^[A-Z0-9_-]{3,32}$/.test(code)) {
    throw new functions.https.HttpsError('invalid-argument', 'Partner code must be 3-32 letters/numbers/_/-');
  }

  const existingCode = await admin.firestore().collection('partner_codes').doc(code).get();
  if (existingCode.exists) {
    throw new functions.https.HttpsError('already-exists', 'This partner code is already in use');
  }

  const userRecord = await admin.auth().createUser({ email, password, displayName: name });
  const uid = userRecord.uid;

  const db = admin.firestore();
  await db.collection('users').doc(uid).set({
    name, email, mobile, role: 'partner', partnerCode: code,
    language: 'en', partnerStatus: 'active',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection('partner_codes').doc(code).set({
    partnerUid: uid, partnerCode: code, partnerName: name,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { uid };
});

// Returns the parameters needed to perform a SIGNED Cloudinary upload from the
// client. Signed uploads remove the public unsigned-preset endpoint and let us
// scope every image to the caller's own folder.
exports.getUploadSignature = functions.https.onCall({ secrets: CLOUDINARY_SECRETS }, async (request) => {
  const caller = request.auth;
  if (!caller) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  if (!isCloudinaryConfigured()) {
    throw new functions.https.HttpsError('failed-precondition', 'Cloudinary is not configured');
  }

  const { folder, publicId } = request.data || {};
  if (typeof folder !== 'string' || typeof publicId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'folder and publicId are required');
  }

  const base = folder.split('/')[0];
  if (!ALLOWED_UPLOAD_FOLDERS.includes(base)) {
    throw new functions.https.HttpsError('invalid-argument', 'Folder not allowed');
  }
  const uidPart = folder.split('/')[1] || '';
  if (uidPart !== caller.uid) {
    throw new functions.https.HttpsError('permission-denied', 'Folder must be scoped to your own account');
  }
  if (!/^[A-Za-z0-9_-]{1,120}$/.test(publicId)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid publicId');
  }

  const c = getCloudinaryConfig();
  const timestamp = Math.round(Date.now() / 1000);
  const paramsToSign = { folder, public_id: publicId, timestamp, resource_type: 'image' };
  const signature = cloudinary.utils.api_sign_request(paramsToSign, c.api_secret);

  return {
    cloud_name: c.cloud_name,
    api_key: c.api_key,
    timestamp,
    signature,
    folder,
    public_id: publicId,
    resource_type: 'image',
  };
});

// Deletes an image from Cloudinary. Only the owner of the folder (or an admin)
// may delete it.
exports.deleteUpload = functions.https.onCall({ secrets: CLOUDINARY_SECRETS }, async (request) => {
  const caller = request.auth;
  if (!caller) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  if (!isCloudinaryConfigured()) {
    throw new functions.https.HttpsError('failed-precondition', 'Cloudinary is not configured');
  }

  const { publicId } = request.data || {};
  if (typeof publicId !== 'string' || publicId.length < 3 || publicId.length > 300) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid publicId');
  }

  const parts = publicId.split('/');
  if (parts.length < 3) {
    throw new functions.https.HttpsError('invalid-argument', 'publicId must be scoped to a user folder');
  }
  const ownerUid = parts[1];
  if (!ALLOWED_UPLOAD_FOLDERS.includes(parts[0])) {
    throw new functions.https.HttpsError('invalid-argument', 'Folder not allowed');
  }
  const isAdmin = await isAdminCaller(caller);
  if (ownerUid !== caller.uid && !isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'You can only delete your own uploads');
  }

  try {
    const result = await cloudinary.uploader.destroy(publicId, { resource_type: 'image' });
    return { result };
  } catch (e) {
    throw new functions.https.HttpsError('internal', 'Cloudinary delete failed');
  }
});

exports.sendPushOnNotification = functions.firestore.onDocumentCreated(
  { document: 'notifications/{notificationId}' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { ownerId, customerId, title, body } = data;
    const uid = ownerId || customerId;
    if (!uid || !title || !body) return;

    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return;

    const message = {
      notification: { title, body },
      token: fcmToken,
    };

    try {
      await admin.messaging().send(message);
    } catch (e) {
      if (e.code === 'messaging/invalid-registration-token' ||
          e.code === 'messaging/registration-token-not-registered') {
        await userDoc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
      }
    }
  }
);

// ======================= RAZORPAY PAYMENTS =======================

// Creates a Razorpay order server-side. The Key Secret never leaves here.
// Returns the order id the client uses to open the checkout.
exports.createPaymentOrder = functions.https.onCall(
  { secrets: RAZORPAY_SECRETS },
  async (request) => {
    const caller = request.auth;
    if (!caller) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');

    const data = request.data || {};
    const amount = data.amount;
    const reference = typeof data.reference === 'string' ? data.reference.slice(0, 40) : '';

    if (!Number.isInteger(amount) || amount <= 0 || amount > 100000) {
      throw new functions.https.HttpsError('invalid-argument', 'amount must be a positive integer (rupees)');
    }

    const rzp = getRazorpay();
    if (!rzp) throw new functions.https.HttpsError('failed-precondition', 'Razorpay is not configured yet');

    try {
      const order = await rzp.orders.create({
        amount: amount * 100,
        currency: 'INR',
        receipt: `bk_${Date.now()}_${caller.uid.slice(0, 6)}`,
        notes: { customerUid: caller.uid, reference },
      });
      return { orderId: order.id, amount, currency: order.currency };
    } catch (e) {
      functions.logger.error('createPaymentOrder failed', e);
      throw new functions.https.HttpsError('internal', 'Failed to create payment order');
    }
  }
);

// Verifies a payment after the client-side checkout returns. Both the HMAC
// signature AND the actual Razorpay payment record are checked; a booking is
// only created when this returns ok.
exports.verifyPayment = functions.https.onCall(
  { secrets: RAZORPAY_SECRETS },
  async (request) => {
    const caller = request.auth;
    if (!caller) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');

    const { paymentId, orderId, signature, amount } = request.data || {};
    if (!paymentId || !orderId || !signature || !Number.isInteger(amount) || amount <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'paymentId, orderId, signature and amount are required');
    }

    const secret = process.env.RAZORPAY_KEY_SECRET;
    if (!secret || secret === 'UNSET') {
      throw new functions.https.HttpsError('failed-precondition', 'Razorpay is not configured yet');
    }

    // 1. HMAC signature over `${orderId}|${paymentId}` with the Key Secret.
    const expected = crypto.createHmac('sha256', secret).update(`${orderId}|${paymentId}`).digest('hex');
    if (expected !== signature) {
      throw new functions.https.HttpsError('unauthenticated', 'Payment signature verification failed');
    }

    // 2. Cross-check the real payment record on Razorpay.
    const rzp = getRazorpay();
    if (!rzp) throw new functions.https.HttpsError('failed-precondition', 'Razorpay is not configured yet');

    let payment;
    try {
      payment = await rzp.payments.fetch(paymentId);
    } catch (e) {
      functions.logger.error('verifyPayment fetch failed', e);
      throw new functions.https.HttpsError('internal', 'Failed to verify payment with Razorpay');
    }

    const captured = payment.status === 'captured';
    const amountOk = Number(payment.amount) === amount * 100;
    if (!captured || !amountOk) {
      throw new functions.https.HttpsError('failed-precondition', `Payment not verified (status=${payment.status})`);
    }

    return { ok: true, paymentId };
  }
);

// Webhook endpoint for Razorpay events (payment.captured). Used for
// reconciliation and to keep a payments ledger. Configure the URL as
//   https://<region>-salonapp-cf6f2.cloudfunctions.net/razorpayWebhook
// in the Razorpay dashboard and set the matching webhook secret.
exports.razorpayWebhook = functions.https.onRequest(
  { secrets: RAZORPAY_SECRETS },
  async (req, res) => {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    const signature = req.get('x-razorpay-signature') || '';
    if (!secret || secret === 'UNSET' || !signature) {
      res.status(400).json({ error: 'Webhook not configured' });
      return;
    }

    const expected = crypto.createHmac('sha256', secret).update(req.rawBody).digest('hex');
    if (expected !== signature) {
      res.status(400).json({ error: 'Invalid signature' });
      return;
    }

    try {
      const event = req.body;
      if (event.event === 'payment.captured') {
        const payment = event.payload.payment.entity;
        await admin.firestore().collection('payments').doc(payment.id).set({
          paymentId: payment.id,
          orderId: payment.order_id,
          amount: Number(payment.amount) / 100,
          currency: payment.currency,
          status: payment.status,
          method: payment.method,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      res.status(200).json({ ok: true });
    } catch (e) {
      functions.logger.error('razorpayWebhook failed', e);
      res.status(500).json({ error: 'Webhook processing failed' });
    }
  }
);

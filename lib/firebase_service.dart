import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';
import 'models.dart';

class FirebaseService {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  User? get currentUser => auth.currentUser;

  Future<AppUser?> getCurrentAppUser() async {
    final u = currentUser;
    if (u == null) {
      debugPrint('[Auth] No current user');
      return null;
    }
    debugPrint('[Firestore] Reading users/${u.uid} (auto-login)');
    try {
      final d = await db.collection('users').doc(u.uid).get();
      if (!d.exists) {
        debugPrint('[Firestore] users/${u.uid} does not exist');
        return null;
      }
      debugPrint('[Firestore] users/${u.uid} read success');
      await _repairUserDoc(u.uid, d.data()!);
      return AppUser.fromMap(u.uid, d.data()!);
    } on FirebaseException catch (e) {
      debugPrint('[Firestore] ERROR reading users/${u.uid}: code=${e.code} message=${e.message}');
      return null;
    }
  }

  Future<AppUser> register({required String name, required String email, required String mobile, required String password, required String role, String? shopName, String? partnerCode}) async {
    if (role != 'customer' && role != 'owner') {
      throw Exception('Invalid account role.');
    }
    debugPrint('[Register] Creating account for $email');
    final c = await auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = c.user!.uid;
    debugPrint('[Register] Auth success. UID: $uid');
    await c.user!.sendEmailVerification();
    debugPrint('[Firestore] Creating users/$uid');
    try {
      await db.collection('users').doc(uid).set({'name': name, 'email': email, 'mobile': mobile, 'role': role, 'language': 'en', 'createdAt': FieldValue.serverTimestamp()});
      debugPrint('[Firestore] users/$uid created');
    } on FirebaseException catch (e) {
      debugPrint('[Firestore] ERROR creating users/$uid: code=${e.code} message=${e.message}');
      rethrow;
    }
    if (role == 'owner') {
      debugPrint('[Firestore] Creating shops/$uid');
      try {
        await db.collection('shops').doc(uid).set({
          'ownerId': uid, 'ownerName': name, 'shopName': shopName ?? '', 'mobile': mobile, 'location': '', 'latitude': 0, 'longitude': 0,
          'isOpen': true, 'bookingsAvailable': true, 'address': '', 'openTime': '09:00 AM', 'closeTime': '09:00 PM', 'shopPhotoUrl': '', 'services': [],
          'totalSeats': 10, 'occupiedSeats': 0, 'bookingPrice': 50, 'nextToken': 1, 'workingDays': [1, 2, 3, 4, 5, 6, 7], 'description': '',
          'accessStatus': 'pending', 'chairCount': 1, 'notificationThreshold': 5, 'tokenDate': '',
          'partnerCode': partnerCode ?? '',
          'chairAvailabilityDate': '', 'availableChairs': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[Firestore] shops/$uid created');
      } on FirebaseException catch (e) {
        debugPrint('[Firestore] ERROR creating shops/$uid: code=${e.code} message=${e.message}');
        rethrow;
      }
    }
    return AppUser.fromMap(uid, {'name': name, 'email': email, 'mobile': mobile, 'role': role});
  }

  Future<AppUser> login({required String email, required String password}) async {
    debugPrint('[Auth] Starting login for email: $email');
    final c = await auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = c.user!.uid;
    debugPrint('[Auth] Firebase Auth success. UID: $uid');
    debugPrint('[Firestore] Reading users/$uid');
    try {
      final d = await db.collection('users').doc(uid).get();
      if (!d.exists) {
        debugPrint('[Firestore] ERROR: users/$uid does not exist');
        throw Exception('Account not found. Please register first.');
      }
      debugPrint('[Firestore] users/$uid read success');
      await _repairUserDoc(uid, d.data()!);
      return AppUser.fromMap(uid, d.data()!);
    } on FirebaseException catch (e) {
      debugPrint('[Firestore] ERROR reading users/$uid: code=${e.code}, message=${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Access denied by database rules. Contact support or try again later.');
      }
      rethrow;
    }
  }

  Future<void> logout() => auth.signOut();

  /// Permanently deletes the signed-in user's account. Requires the account
  /// password to re-authenticate. Also removes the user's shop if they own one.
  Future<void> deleteAccount({required String email, required String password}) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('No signed-in user.');
    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
    final doc = await db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final role = (doc.data()?['role'] as String?) ?? '';
      if (role == 'owner' || role == 'partner') {
        await db.collection('shops').doc(user.uid).delete();
      }
      await db.collection('users').doc(user.uid).delete();
    }
    await user.delete();
  }

  Future<void> sendPasswordReset(String email) => auth.sendPasswordResetEmail(email: email);

  /// Stores the current device's FCM token on the signed-in user's own doc.
  ///
  /// Only ever touches an existing, fully-created user doc. This deliberately
  /// avoids `set` with merge so a lost/missing doc can never be resurrected
  /// into a bare `{fcmToken}` record that wipes name/email/mobile/role.
  Future<void> updateFcmToken(String token) async {
    final uid = auth.currentUser?.uid;
    if (uid == null || token.isEmpty) return;
    try {
      final d = await db.collection('users').doc(uid).get();
      if (!d.exists || d.data()?['role'] == null) {
        debugPrint('[FCM] Skipping updateFcmToken for $uid: no full user doc');
        return;
      }
      await db.collection('users').doc(uid).update({'fcmToken': token});
    } on FirebaseException catch (e) {
      debugPrint('[FCM] updateFcmToken failed: ${e.code} ${e.message}');
    }
  }

  /// Heals a partially-written or stripped user doc after a failed/partial
  /// registration. Only restores fields that are provably safe to restore:
  /// the account email (must equal the signed-in auth email) and, when the doc
  /// is otherwise empty, a default 'customer' role. Name/mobile cannot be
  /// recovered client-side, so those are left for the user to re-enter.
  Future<void> _repairUserDoc(String uid, Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    final authEmail = auth.currentUser?.email;
    final bare = (data['email'] == null || data['email'] == '')
        && (data['name'] == null || data['name'] == '')
        && (data['mobile'] == null || data['mobile'] == '')
        && (data['role'] == null || data['role'] == '');
    try {
      if (bare) {
        final fix = <String, dynamic>{'role': 'customer'};
        if (authEmail != null && authEmail.isNotEmpty) fix['email'] = authEmail;
        await db.collection('users').doc(uid).update(fix);
        data['role'] = 'customer';
        if (authEmail != null) data['email'] = authEmail;
        debugPrint('[Firestore] Repaired bare users/$uid (email + role)');
      } else if ((data['email'] == null || data['email'] == '')
          && authEmail != null && authEmail.isNotEmpty) {
        await db.collection('users').doc(uid).update({'email': authEmail});
        data['email'] = authEmail;
        debugPrint('[Firestore] Repaired missing email on users/$uid');
      }
    } on FirebaseException catch (e) {
      debugPrint('[Firestore] users/$uid repair skipped: ${e.code} ${e.message}');
    }
  }

  /// Fetches the current FCM token and persists it for push delivery.
  Future<String?> refreshFcmToken() async {
    if (kIsWeb) return null;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await updateFcmToken(token);
      return token;
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return null;
    }
  }

  Future<void> sendEmailVerification() async {
    final u = auth.currentUser;
    if (u != null && !u.emailVerified) await u.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    await auth.currentUser?.reload();
    return auth.currentUser?.emailVerified ?? false;
  }

  Future<void> updateShop(Shop shop) async {
    final map = shop.toMap();
    map.remove('accessStatus');
    map.remove('nextToken');
    map.remove('tokenDate');
    await db.collection('shops').doc(shop.ownerId).set(map, SetOptions(merge: true));
  }

  Future<String> uploadImageBytes({required Uint8List bytes, required String folder, String? uid}) async {
    final user = currentUser;
    if (user == null) throw Exception('Please sign in to upload images.');
    final type = _detectImageType(bytes);
    if (type == null) throw Exception('Only JPG, PNG or WEBP images are allowed.');
    if (bytes.length > 5 * 1024 * 1024) throw Exception('Image is too large. Maximum allowed size is 5 MB.');
    final ownerUid = uid ?? user.uid;
    final scopedFolder = '$folder/$ownerUid';
    final publicId = _sha1Hex(bytes);
    final sig = await _callFunction('getUploadSignature', {
      'folder': scopedFolder,
      'publicId': publicId,
    });
    if (sig == null || sig['signature'] == null || sig['cloud_name'] == null) {
      throw Exception('Upload signing failed. Please try again.');
    }
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/${sig['cloud_name']}/image/upload');
    final client = http.Client();
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['folder'] = scopedFolder
        ..fields['public_id'] = publicId
        ..fields['timestamp'] = '${sig['timestamp']}'
        ..fields['api_key'] = '${sig['api_key']}'
        ..fields['signature'] = sig['signature'] as String
        ..fields['resource_type'] = 'image'
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: '$publicId.$type'));
      final streamed = await client.send(request).timeout(const Duration(seconds: 60));
      if (streamed.statusCode != 200) throw Exception('Upload failed (${streamed.statusCode}). Please try again.');
      final body = await streamed.stream.bytesToString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['error'] != null) throw Exception('Upload rejected. Please try a different image.');
      return (data['secure_url'] ?? data['url']) as String;
    } finally {
      client.close();
    }
  }

  Future<void> deleteCloudinaryUpload(String publicId) async {
    await _callFunction('deleteUpload', {'publicId': publicId});
  }

  /// Extracts a Cloudinary public_id from a secure_url so uploads can be deleted.
  String? cloudinaryPublicIdFromUrl(String url) {
    const marker = '/image/upload/';
    final idx = url.indexOf(marker);
    if (idx < 0) return null;
    final rest = url.substring(idx + marker.length);
    final segments = rest.split('/');
    final start = (segments.isNotEmpty && segments.first.startsWith('v') && int.tryParse(segments.first.substring(1)) != null) ? 1 : 0;
    final clean = segments.sublist(start).join('/');
    final dot = clean.lastIndexOf('.');
    return dot > 0 ? clean.substring(0, dot) : clean;
  }

  // --- Server function calls (Cloud Functions) ---
  Future<Map<String, dynamic>?> _callFunction(String name, Map<String, dynamic> data) async {
    final u = auth.currentUser;
    if (u == null) throw Exception('Please sign in.');
    final idToken = await u.getIdToken();
    final url = 'https://us-central1-${DefaultFirebaseOptions.currentPlatform.projectId}.cloudfunctions.net/$name';
    final res = await http.post(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    }, body: jsonEncode({'data': data})).timeout(const Duration(seconds: 30));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 300) {
      final message = (body['error']?['message'] as String?) ?? 'Request failed (${res.statusCode}). Please try again.';
      throw Exception(message);
    }
    return body['result'] as Map<String, dynamic>?;
  }

  // --- Push Notifications (disabled) ---
  Future<void> sendPushNotification({required String recipientUid, required String title, required String body}) async {
  }

  // --- SEARCH ---
  Future<List<Shop>> searchShops(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final snap = await db.collection('shops').limit(500).get();
    return snap.docs.map((d) => Shop.fromMap(d.id, d.data())).where((s) =>
        s.shopName.toLowerCase().contains(q) || s.location.toLowerCase().contains(q) || s.address.toLowerCase().contains(q)).toList();
  }

  // --- ACCESS REQUESTS ---
  Future<void> createAccessRequest(String ownerId, String ownerName, String shopName, String mobile, {String note = ''}) async {
    await db.collection('admin_requests').doc(ownerId).set({
      'ownerId': ownerId, 'ownerName': ownerName, 'shopName': shopName, 'mobile': mobile,
      'status': 'pending', 'note': note, 'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateAccessStatus(String ownerId, String status) async {
    final user = currentUser;
    if (user == null) throw Exception('Please sign in.');
    if (status != 'granted' && status != 'blocked') throw Exception('Invalid status.');
    final userDoc = await db.collection('users').doc(user.uid).get();
    final role = (userDoc.data()?['role'] as String?) ?? 'customer';
    if (role != 'admin' && role != 'partner' && user.uid != ownerId) {
      throw Exception('You are not allowed to change this shop\'s status.');
    }
    if (role == 'partner') {
      final shopDoc = await db.collection('shops').doc(ownerId).get();
      if (!shopDoc.exists) throw Exception('Shop not found.');
      final code = (shopDoc.data()?['partnerCode'] as String?) ?? '';
      final codeDoc = await db.collection('partner_codes').doc(code).get();
      final linkedUid = (codeDoc.data()?['partnerUid'] as String?) ?? '';
      if (linkedUid != user.uid) {
        throw Exception('You can only manage shops linked to your own partner code.');
      }
    }
    await db.collection('shops').doc(ownerId).update({'accessStatus': status});
    final reqRef = db.collection('admin_requests').doc(ownerId);
    final reqDoc = await reqRef.get();
    if (reqDoc.exists) {
      await reqRef.update({'status': status});
    } else if (role == 'admin') {
      final shopDoc = await db.collection('shops').doc(ownerId).get();
      final data = shopDoc.data() ?? {};
      await reqRef.set({
        'ownerId': ownerId,
        'ownerName': data['ownerName'] ?? '',
        'shopName': data['shopName'] ?? '',
        'mobile': data['mobile'] ?? '',
        'status': status,
        'note': '',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Stream<List<AccessRequest>> watchAccessRequests() =>
      db.collection('admin_requests').orderBy('createdAt', descending: true).limit(200).snapshots().map((s) =>
          s.docs.map((d) => AccessRequest.fromMap(d.id, d.data())).toList());

  // --- APP STATS & EARNINGS (for admin page) ---
  Future<Map<String, dynamic>> getAppStats() async {
    final usersSnap = await db.collection('users').get();
    final shopsSnap = await db.collection('shops').get();
    final bookingsSnap = await db.collection('bookings').get();
    final owners = usersSnap.docs.where((d) => (d.data()['role'] as String?) == 'owner').length;
    final customers = usersSnap.docs.where((d) => (d.data()['role'] as String?) == 'customer').length;
    final partners = usersSnap.docs.where((d) => (d.data()['role'] as String?) == 'partner').length;
    return {
      'totalUsers': usersSnap.docs.length,
      'owners': owners,
      'customers': customers,
      'partners': partners,
      'totalShops': shopsSnap.docs.length,
      'totalBookings': bookingsSnap.docs.length,
    };
  }

  Future<Map<String, dynamic>> getShopEarnings({EarningsPeriod period = EarningsPeriod.all}) async {
    final shopsSnap = await db.collection('shops').get();
    final bookingsSnap = await db.collection('bookings').get();
    final partnerCodesSnap = await db.collection('partner_codes').get();
    final Map<String, String> partnerNameMap = {};
    for (final d in partnerCodesSnap.docs) {
      partnerNameMap[d.id] = (d.data()['partnerName'] as String?) ?? '';
    }
    final shops = shopsSnap.docs.map((d) => Shop.fromMap(d.id, d.data())).toList();
    final bookings = bookingsSnap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
    final periodStart = earningsPeriodStart(period, DateTime.now());
    final completed = bookings
        .where((b) => b.status == 'completed' || b.status == 'paid' || b.status == 'confirmed')
        .where((b) => !b.createdAt.isBefore(periodStart))
        .toList();
    final totalRevenue = completed.fold<int>(0, (s, b) => s + b.price);
    final totalBookingCharges = completed.fold<int>(0, (s, b) => s + b.bookingPrice);
    final Map<String, int> revByShop = {}, chargesByShop = {}, countByShop = {};
    final Map<String, String> shopNameMap = {};
    for (final b in completed) {
      revByShop[b.ownerId] = (revByShop[b.ownerId] ?? 0) + b.price;
      chargesByShop[b.ownerId] = (chargesByShop[b.ownerId] ?? 0) + b.bookingPrice;
      countByShop[b.ownerId] = (countByShop[b.ownerId] ?? 0) + 1;
      shopNameMap[b.ownerId] = b.shopName;
    }
    final perShop = shops.map((s) => ShopEarnings(
      ownerId: s.ownerId, shopName: s.shopName,
      partnerCode: s.partnerCode,
      partnerName: partnerNameMap[s.partnerCode] ?? '',
      totalRevenue: revByShop[s.ownerId] ?? 0,
      totalBookingCharges: chargesByShop[s.ownerId] ?? 0,
      bookingCount: countByShop[s.ownerId] ?? 0,
    )).toList();
    perShop.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    final Map<String, int> revByPartner = {}, chargesByPartner = {}, countByPartner = {}, shopCountByPartner = {};
    for (final s in shops) {
      if (s.partnerCode.isEmpty) continue;
      revByPartner[s.partnerCode] = (revByPartner[s.partnerCode] ?? 0) + (revByShop[s.ownerId] ?? 0);
      chargesByPartner[s.partnerCode] = (chargesByPartner[s.partnerCode] ?? 0) + (chargesByShop[s.ownerId] ?? 0);
      countByPartner[s.partnerCode] = (countByPartner[s.partnerCode] ?? 0) + (countByShop[s.ownerId] ?? 0);
      shopCountByPartner[s.partnerCode] = (shopCountByPartner[s.partnerCode] ?? 0) + 1;
    }
    final perPartner = revByPartner.keys.map((code) => PartnerEarnings(
      partnerCode: code,
      partnerName: partnerNameMap[code] ?? '',
      totalRevenue: revByPartner[code] ?? 0,
      totalBookingCharges: chargesByPartner[code] ?? 0,
      bookingCount: countByPartner[code] ?? 0,
      shopCount: shopCountByPartner[code] ?? 0,
    )).toList();
    perPartner.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return {
      'totalRevenue': totalRevenue,
      'totalBookingCharges': totalBookingCharges,
      'totalBookingsCompleted': completed.length,
      'perShop': perShop,
      'perPartner': perPartner,
    };
  }

  Future<List<Booking>> getShopPaymentDetails(String ownerId, {EarningsPeriod period = EarningsPeriod.all}) async {
    final snap = await db.collection('bookings').where('ownerId', isEqualTo: ownerId).get();
    final all = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
    final periodStart = earningsPeriodStart(period, DateTime.now());
    final paid = all
        .where((b) => b.status == 'completed' || b.status == 'paid' || b.status == 'confirmed')
        .where((b) => !b.createdAt.isBefore(periodStart))
        .toList();
    paid.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return paid;
  }

  // --- TIME SLOT AVAILABILITY ---
  List<String> generateTimeSlots(String openTime, String closeTime) {
    int openMinutes = _parseTimeToMinutes(openTime);
    int closeMinutes = _parseTimeToMinutes(closeTime);
    if (openMinutes == 0) openMinutes = 540; // default 09:00 AM
    if (closeMinutes == 0) closeMinutes = 1260; // default 09:00 PM
    if (closeMinutes <= openMinutes) closeMinutes += 720; // 24h "8:00" close means 8:00 PM
    if (closeMinutes > 1439) closeMinutes = 1439;
    final slots = <String>[];
    int current = openMinutes;
    while (current < closeMinutes) {
      slots.add(_formatMinutesToTime(current));
      current += 30;
    }
    if (slots.isEmpty) {
      // Final fallback so a shop never shows zero slots: 09:00 AM - 09:00 PM
      current = 540;
      while (current < 1260) {
        slots.add(_formatMinutesToTime(current));
        current += 30;
      }
    }
    return slots;
  }

  int _parseTimeToMinutes(String t) {
    final s = t.trim().toUpperCase();
    final m = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$').firstMatch(s);
    if (m == null) return 0;
    int h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2) ?? '0');
    if (h > 23 || min > 59) return 0;
    final ampm = m.group(3);
    if (ampm == 'PM' && h < 12) h += 12;
    if (ampm == 'AM' && h == 12) h = 0;
    return h * 60 + min;
  }

  String _formatMinutesToTime(int m) {
    int h = m ~/ 60;
    int min = m % 60;
    final ampm = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $ampm';
  }

  Future<Map<String, int>> getAvailableSlots({
    required String ownerId, required String date, required int chairCount, required int availableChairsOverride,
    required String openTime, required String closeTime,
  }) async {
    final chairs = availableChairsOverride > 0 ? availableChairsOverride : chairCount;
    final bookingsSnap = await db.collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .where('scheduledDate', isEqualTo: date)
        .get();
    final booked = _countSlotUsage(bookingsSnap.docs);
    final Map<String, int> result = {};
    final isToday = date == DateTime.now().toIso8601String().substring(0, 10);
    final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
    for (final slot in generateTimeSlots(openTime, closeTime)) {
      if (isToday && _parseTimeToMinutes(slot) <= nowMinutes) continue;
      final remaining = chairs - (booked[slot] ?? 0);
      if (remaining > 0) result[slot] = remaining;
    }
    return result;
  }

  /// Returns occupancy info per slot (for owner smart assistant)
  Future<Map<String, int>> getSlotOccupancy({
    required String ownerId, required String date, required int chairCount, required int availableChairsOverride,
    required String openTime, required String closeTime,
  }) async {
    final chairs = availableChairsOverride > 0 ? availableChairsOverride : chairCount;
    final bookingsSnap = await db.collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .where('scheduledDate', isEqualTo: date)
        .get();
    final booked = _countSlotUsage(bookingsSnap.docs);
    final Map<String, int> result = {};
    for (final slot in generateTimeSlots(openTime, closeTime)) {
      final count = booked[slot] ?? 0;
      result[slot] = chairs - count; // remaining chairs (0 = full, 1 = almost full, >1 = available)
    }
    return result;
  }

  /// Counts chair usage per slot. Pending bookings reserve a chair in each of their
  /// 3 preferred times; confirmed+ bookings occupy one chair in their scheduledTime.
  Map<String, int> _countSlotUsage(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final booked = <String, int>{};
    void addTime(String t) {
      if (t.isNotEmpty) {
        final normalized = _formatMinutesToTime(_parseTimeToMinutes(t));
        booked[normalized] = (booked[normalized] ?? 0) + 1;
      }
    }
    for (final d in docs) {
      final status = d.data()['status'] as String? ?? '';
      if (status == 'pending_owner_confirmation' || status == 'cancelled' || status == 'declined') {
        if (status == 'cancelled' || status == 'declined') continue;
        addTime(d.data()['preferredTime1'] as String? ?? '');
        addTime(d.data()['preferredTime2'] as String? ?? '');
        addTime(d.data()['preferredTime3'] as String? ?? '');
      } else if (status == 'confirmed' || status == 'paid' || status == 'arrived' || status == 'in_progress' || status == 'completed') {
        addTime(d.data()['scheduledTime'] as String? ?? '');
      }
    }
    return booked;
  }

  // --- BOOKING ---
  Future<Booking> createBooking({required Shop shop, required ShopService service, required String paymentMethod, required String customerName, required String customerMobile, bool isPremium = false, int premiumDaysAhead = 0, int premiumExtraPrice = 0, required String scheduledDate, required String preferredTime1, required String preferredTime2, required String preferredTime3}) async {
    if (!shop.isOpen) throw Exception('Shop is closed. Bookings are not available.');
    if (!shop.bookingsAvailable) throw Exception('Bookings are currently disabled by the shop.');
    if (scheduledDate.isNotEmpty) {
      final chairs = shop.availableChairs > 0 ? shop.availableChairs : shop.chairCount;
      final slots = await getAvailableSlots(
        ownerId: shop.ownerId, date: scheduledDate, chairCount: shop.chairCount,
        availableChairsOverride: chairs, openTime: shop.openTime, closeTime: shop.closeTime,
      );
      final unavailable = [preferredTime1, preferredTime2, preferredTime3]
          .where((t) => t.isNotEmpty && !slots.containsKey(t)).toList();
      if (unavailable.isNotEmpty) {
        throw Exception('Time slot ${unavailable.join(', ')} is no longer available. Please choose different times.');
      }
    }
    final user = currentUser;
    if (user == null) throw Exception('Please sign in to book an appointment.');
    final uid = user.uid;
    final existing = await db.collection('bookings')
        .where('customerId', isEqualTo: uid)
        .limit(20)
        .get();
    final hasActive = existing.docs.any((d) {
      final data = d.data();
      final s = data['status'] as String? ?? '';
      return (data['ownerId'] == shop.ownerId) &&
          ['pending_owner_confirmation', 'confirmed', 'in_progress'].contains(s);
    });
    if (hasActive) {
      throw Exception('You already have an active booking at this shop. Please wait for it to complete before booking again.');
    }
    final recent = await db.collection('bookings')
        .where('customerId', isEqualTo: uid)
        .limit(6)
        .get();
    final recentCount = recent.docs.where((d) {
      final t = DateTime.tryParse((d.data()['createdAt'] as String?) ?? '');
      return t != null && t.isAfter(DateTime.now().subtract(const Duration(minutes: 15)));
    }).length;
    if (recentCount >= 5) {
      throw Exception('You have created too many bookings recently. Please try again in a few minutes.');
    }
    final shopRef = db.collection('shops').doc(shop.ownerId);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final nextToken = await db.runTransaction<int>((tx) async {
      final snap = await tx.get(shopRef);
      final lastTokenDate = (snap.data()?['tokenDate'] as String?) ?? '';
      if (lastTokenDate != today) {
        tx.update(shopRef, {'nextToken': 2, 'tokenDate': today});
        return 1;
      }
      final current = (snap.data()?['nextToken'] as int?) ?? 1;
      tx.update(shopRef, {'nextToken': current + 1});
      return current;
    });
    final bookingPrice = isPremium ? premiumExtraPrice : shop.bookingPrice;
    final remaining = 0;
    final b = Booking(
      id: '', ownerId: shop.ownerId, customerId: uid, customerName: customerName, customerMobile: customerMobile,
      shopName: shop.shopName, serviceName: service.name, price: 0, bookingPrice: bookingPrice,
      remainingAmount: remaining, paymentMethod: paymentMethod, token: nextToken, status: 'pending_owner_confirmation', isPaid: false, createdAt: DateTime.now(),
      isPremium: isPremium, premiumDaysAhead: premiumDaysAhead, premiumExtraPrice: premiumExtraPrice,
      durationMinutes: service.durationMinutes, scheduledDate: scheduledDate,
      preferredTime1: preferredTime1, preferredTime2: preferredTime2, preferredTime3: preferredTime3,
      chairNumber: null,
    );
    final ref = await db.collection('bookings').add(b.toMap());
    await ref.update({'id': ref.id});
    await db.collection('notifications').add({
      'ownerId': shop.ownerId,
      'title': isPremium ? 'Premium Booking Request' : 'New Booking Request',
      'body': isPremium
          ? '$customerName has booked ${service.name} (Premium). Token #$nextToken — exact time: $preferredTime1 on $scheduledDate.'
          : '$customerName has booked ${service.name}. Token #$nextToken — preferred times: $preferredTime1, $preferredTime2, $preferredTime3.',
      'read': false, 'createdAt': DateTime.now().toIso8601String(),
    });
    await db.collection('notifications').add({
      'customerId': uid,
      'title': 'Booking Submitted',
      'body': 'Your booking for ${service.name} at ${shop.shopName} (Token #$nextToken) has been sent. Waiting for owner confirmation.',
      'read': false, 'createdAt': DateTime.now().toIso8601String(),
    });
    if (shop.ownerId != uid) {
      await sendPushNotification(
        recipientUid: shop.ownerId,
        title: 'New Booking Request',
        body: '$customerName has booked ${service.name}. Please confirm the appointment time.',
      );
    }
    return Booking(id: ref.id, ownerId: b.ownerId, customerId: b.customerId, customerName: b.customerName,
        customerMobile: b.customerMobile, shopName: b.shopName, serviceName: b.serviceName, price: b.price,
        bookingPrice: b.bookingPrice, remainingAmount: b.remainingAmount, paymentMethod: b.paymentMethod,
        token: b.token, status: b.status, createdAt: b.createdAt, isPremium: b.isPremium,
        premiumDaysAhead: b.premiumDaysAhead, premiumExtraPrice: b.premiumExtraPrice,
        durationMinutes: b.durationMinutes, scheduledDate: b.scheduledDate,
        preferredTime1: b.preferredTime1, preferredTime2: b.preferredTime2, preferredTime3: b.preferredTime3);
  }

  Future<void> updateBooking(Booking booking) => db.collection('bookings').doc(booking.id).update(booking.toMap());

  Future<void> confirmAppointment({required String bookingId, required String ownerId, required String customerId, required String customerName, required String shopName, required String serviceName, required int token, required String appointmentDate, required String appointmentTime}) async {
    final batch = db.batch();
    batch.update(db.collection('bookings').doc(bookingId), {
      'status': 'confirmed',
      'scheduledDate': appointmentDate,
      'scheduledTime': appointmentTime,
    });
    batch.set(db.collection('notifications').doc(), {
      'customerId': customerId,
      'title': 'Appointment Confirmed',
      'body': 'Your appointment at $shopName ($serviceName) has been confirmed for $appointmentDate at $appointmentTime. Token #$token.',
      'read': false, 'createdAt': DateTime.now().toIso8601String(),
    });
    await batch.commit();
    await sendPushNotification(
      recipientUid: customerId,
      title: 'Appointment Confirmed',
      body: 'Your appointment at $shopName ($serviceName) has been confirmed for $appointmentDate at $appointmentTime.',
    );
  }

  Future<void> cancelBookingByOwner({required String bookingId, required String ownerId, required String customerId, required String customerName, required String shopName, required int token}) async {
    final batch = db.batch();
    batch.update(db.collection('bookings').doc(bookingId), {
      'status': 'cancelled',
      'cancelledAt': DateTime.now().toIso8601String(),
    });
    batch.set(db.collection('notifications').doc(), {
      'customerId': customerId,
      'title': 'Booking Declined',
      'body': 'Your booking at $shopName (Token #$token) has been declined by the shop owner.',
      'read': false, 'createdAt': DateTime.now().toIso8601String(),
    });
    await batch.commit();
    await sendPushNotification(
      recipientUid: customerId,
      title: 'Booking Cancelled',
      body: 'Your booking at $shopName (Token #$token) has been cancelled by the shop owner.',
    );
  }

  Future<void> completeService(String bookingId) => db.collection('bookings').doc(bookingId).update({'status': 'completed'});

  Future<void> completeServiceByToken(String ownerId, int token) async {
    final snap = await db.collection('bookings').where('ownerId', isEqualTo: ownerId).where('token', isEqualTo: token).get();
    for (final d in snap.docs) {
      final b = Booking.fromMap(d.id, d.data());
      if (b.status == 'confirmed' || b.status == 'in_progress') {
        await d.reference.update({'status': 'completed'});
      }
    }
  }

  Future<void> startServiceByToken(String ownerId, int token) async {
    final snap = await db.collection('bookings').where('ownerId', isEqualTo: ownerId).where('token', isEqualTo: token).get();
    for (final d in snap.docs) {
      final b = Booking.fromMap(d.id, d.data());
      if (b.status == 'confirmed') {
        await d.reference.update({'status': 'in_progress'});
      }
    }
  }

  Future<void> markReachedShop(String bookingId) => db.collection('bookings').doc(bookingId).update({'reachedShop': true});

  Future<void> markReachedAndNotifyOwner({required String bookingId, required String customerId, required String ownerId, required String customerName, required int token, required String shopName}) async {
    final batch = db.batch();
    batch.update(db.collection('bookings').doc(bookingId), {'reachedShop': true});
    batch.set(db.collection('notifications').doc(), {
      'ownerId': ownerId,
      'title': 'Customer Arrived',
      'body': '$customerName (Token #$token) has arrived at $shopName.',
      'read': false, 'createdAt': DateTime.now().toIso8601String(),
    });
    batch.set(db.collection('notifications').doc(), {
      'customerId': customerId,
      'title': 'Arrival Confirmed',
      'body': 'You reached $shopName. Token #$token — the owner has been notified.',
      'read': false, 'createdAt': DateTime.now().toIso8601String(),
    });
    await batch.commit();
  }

  Future<void> payRemaining(String bookingId, {String? paymentMethod}) async {
    final ref = db.collection('bookings').doc(bookingId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found.');
    final b = Booking.fromMap(snap.id, snap.data()!);
    if (b.isPaid) return; // idempotent: already settled
    if (b.status == 'cancelled') throw Exception('This booking was cancelled.');
    await ref.update({
      'isPaid': true,
      'status': 'paid',
      'paymentMethod': paymentMethod ?? b.paymentMethod,
      'paidAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> requestOfflinePayment({required String bookingId, required String ownerId, required String customerId, required String customerName, required String serviceName, required int remainingAmount}) async {
    final batch = db.batch();
    batch.update(db.collection('bookings').doc(bookingId), {
      'paymentMethod': 'Cash',
      'offlinePaymentRequested': true,
    });
    batch.set(db.collection('notifications').doc(), {
      'ownerId': ownerId,
      'title': 'Offline Cash Payment Requested',
      'body': '$customerName wants to pay the remaining Rs $remainingAmount in cash for $serviceName. Collect the cash and confirm.',
      'read': false, 'createdAt': DateTime.now().toIso8601String(),
    });
    await batch.commit();
  }

  Future<void> markOfflinePaid({required String bookingId, required String customerId, required String customerName, required String shopName, required int remainingAmount}) async {
    final ref = db.collection('bookings').doc(bookingId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found.');
    final b = Booking.fromMap(snap.id, snap.data()!);
    if (b.isPaid) return; // idempotent: already settled
    if (b.status == 'cancelled') throw Exception('This booking was cancelled.');
    final batch = db.batch();
    batch.update(ref, {
      'isPaid': true,
      'status': 'paid',
      'paymentMethod': 'Cash',
      'paidAt': DateTime.now().toIso8601String(),
    });
    batch.set(db.collection('notifications').doc(), {
      'customerId': customerId,
      'title': 'Payment Received',
      'body': 'The owner received your cash payment of Rs $remainingAmount at $shopName. Booking marked as paid.',
      'read': false, 'createdAt': DateTime.now().toIso8601String(),
    });
    await batch.commit();
  }

  Future<void> cancelBooking(String bookingId) => db.collection('bookings').doc(bookingId).update({'status': 'cancelled', 'cancelledAt': DateTime.now().toIso8601String()});

  // --- CHAIRS (Multi-Chair Queue) ---
  Future<void> initializeChairs(String ownerId, int count) async {
    final existing = await db.collection('chairs').where('ownerId', isEqualTo: ownerId).get();
    final existingNums = existing.docs.map((d) => (d.data()['chairNumber'] as num?)?.toInt() ?? 0).toSet();
    final batch = db.batch();
    for (int i = 1; i <= count; i++) {
      if (!existingNums.contains(i)) {
        final ref = db.collection('chairs').doc('${ownerId}_chair_$i');
        batch.set(ref, {
          'ownerId': ownerId, 'chairNumber': i, 'status': 'available',
          'currentToken': null, 'customerName': null, 'customerNameDisplay': null,
          'serviceName': null, 'startTime': null, 'durationMinutes': 30,
          'remainingSeconds': 0, 'nextAssignedToken': null, 'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    }
    for (final d in existing.docs) {
      final cn = (d.data()['chairNumber'] as num?)?.toInt() ?? 0;
      if (cn > count) {
        if (d.data()['status'] == 'available') {
          batch.delete(d.reference);
        }
      }
    }
    await batch.commit();
  }

  Stream<List<Chair>> watchChairs(String ownerId) =>
      db.collection('chairs').where('ownerId', isEqualTo: ownerId).orderBy('chairNumber').snapshots()
          .map((s) => s.docs.map((d) => Chair.fromMap(d.id, d.data())).toList());

  Future<void> updateChair(Chair chair) =>
      db.collection('chairs').doc(chair.docId).set(chair.toMap(), SetOptions(merge: true));

  Future<Booking?> getNextWaitingBooking(String ownerId) async {
    final snap = await db.collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'confirmed')
        .where('chairNumber', isNull: true)
        .orderBy('token', descending: false)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Booking.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  Future<Booking?> assignNextToChair(String ownerId, int chairNumber) async {
    final next = await getNextWaitingBooking(ownerId);
    if (next == null) return null;
    final chairRef = db.collection('chairs').doc('${ownerId}_chair_$chairNumber');
    final bookingRef = db.collection('bookings').doc(next.id);
    final batch = db.batch();
    batch.update(chairRef, {
      'nextAssignedToken': next.token,
      'customerName': next.customerName,
      'customerNameDisplay': next.customerName,
      'customerId': next.customerId,
      'serviceName': next.serviceName,
      'durationMinutes': next.durationMinutes,
      'status': 'waiting_to_start',
    });
    batch.update(bookingRef, {'chairNumber': chairNumber});
    await batch.commit();
    return next;
  }

  Future<void> startChairService(String ownerId, int chairNumber, int durationMinutes) async {
    final chairRef = db.collection('chairs').doc('${ownerId}_chair_$chairNumber');
    final chairSnap = await chairRef.get();
    if (!chairSnap.exists) return;
    final chair = Chair.fromMap(chairSnap.id, chairSnap.data()!);
    final token = chair.nextAssignedToken ?? chair.currentToken;
    if (token == null) return;
    final now = DateTime.now();
    final predictedEnd = now.add(Duration(minutes: durationMinutes));
    final batch = db.batch();
    batch.update(chairRef, {
      'currentToken': token,
      'startTime': now.toIso8601String(),
      'predictedEndTime': predictedEnd.toIso8601String(),
      'durationMinutes': durationMinutes,
      'remainingSeconds': durationMinutes * 60,
      'status': 'in_service',
      'nextAssignedToken': null,
      'notificationSent': false,
    });
    final bookingSnap = await db.collection('bookings')
        .where('ownerId', isEqualTo: ownerId).where('token', isEqualTo: token).get();
    for (final d in bookingSnap.docs) {
      final data = d.data();
      batch.update(d.reference, {
        'status': 'in_progress',
        'chairNumber': chairNumber,
        'customerName': data['customerName'] ?? '',
      });
    }
    await batch.commit();
  }

  Future<void> pauseChairService(String ownerId, int chairNumber) async {
    final chairRef = db.collection('chairs').doc('${ownerId}_chair_$chairNumber');
    await chairRef.update({'status': 'paused'});
  }

  Future<void> resumeChairService(String ownerId, int chairNumber) async {
    final chairRef = db.collection('chairs').doc('${ownerId}_chair_$chairNumber');
    await chairRef.update({'status': 'in_service'});
  }

  Future<void> updateChairRemainingTime(String ownerId, int chairNumber, int remainingSeconds) async {
    final chairRef = db.collection('chairs').doc('${ownerId}_chair_$chairNumber');
    await chairRef.update({'remainingSeconds': remainingSeconds});
  }

  Future<void> markChairNotificationSent(String ownerId, int chairNumber) async {
    final chairRef = db.collection('chairs').doc('${ownerId}_chair_$chairNumber');
    await chairRef.update({'notificationSent': true});
  }

  Future<void> completeChairService(String ownerId, int chairNumber, {int? amount}) async {
    final chairRef = db.collection('chairs').doc('${ownerId}_chair_$chairNumber');
    final chairSnap = await chairRef.get();
    if (!chairSnap.exists) return;
    final chair = Chair.fromMap(chairSnap.id, chairSnap.data()!);
    final token = chair.currentToken;
    if (token == null) return;
    final now = DateTime.now();
    final batch = db.batch();
    batch.update(chairRef, {
      'status': 'completed',
      'remainingSeconds': 0,
      'updatedAt': now.toIso8601String(),
    });
    final bookingSnap = await db.collection('bookings')
        .where('ownerId', isEqualTo: ownerId).where('token', isEqualTo: token).get();
    for (final d in bookingSnap.docs) {
      batch.update(d.reference, {
        'status': 'completed',
        if (amount != null) ...{
          'price': amount,
          'remainingAmount': amount,
          'isPaid': false,
          'offlinePaymentRequested': false,
        },
      });
    }
    await batch.commit();
    await assignNextToChair(ownerId, chairNumber);
  }

  Future<void> releaseChair(String ownerId, int chairNumber) async {
    final chairRef = db.collection('chairs').doc('${ownerId}_chair_$chairNumber');
    await chairRef.update({
      'status': 'available',
      'currentToken': null, 'customerName': null, 'customerNameDisplay': null,
      'serviceName': null, 'startTime': null, 'durationMinutes': 30,
      'remainingSeconds': 0, 'nextAssignedToken': null,
    });
    await assignNextToChair(ownerId, chairNumber);
  }

  Future<Map<String, dynamic>> getCustomerQueueInfo(String ownerId, int myToken) async {
    final chairsSnap = await db.collection('chairs').where('ownerId', isEqualTo: ownerId).get();
    final chairs = chairsSnap.docs.map((d) => Chair.fromMap(d.id, d.data())).toList();
    final activeChairs = chairs.where((c) => c.status == 'in_service' || c.status == 'paused').toList();
    final waitingChairs = chairs.where((c) => c.status == 'waiting_to_start').toList();
    final availableChairs = chairs.where((c) => c.status == 'available').toList();
    final aheadCount = waitingChairs.length;
    final totalRemaining = activeChairs.fold<int>(0, (s, c) => s + c.effectiveRemainingSeconds);
    final avgPerChair = activeChairs.isNotEmpty ? (totalRemaining / activeChairs.length).round() : 0;
    final chairsBeforeMe = waitingChairs.where((c) => (c.nextAssignedToken ?? 0) < myToken).length;
    final totalWaitSeconds = totalRemaining + (chairsBeforeMe * avgPerChair);
    final estimatedMinutes = (totalWaitSeconds / 60).round();
    return {
      'ahead': aheadCount + chairsBeforeMe,
      'estimatedMinutes': estimatedMinutes,
      'activeChairs': activeChairs.length,
      'totalChairs': chairs.length,
      'availableChairs': availableChairs.length,
      'currentToken': activeChairs.isNotEmpty ? activeChairs.first.currentToken : 0,
    };
  }

  Stream<List<Booking>> watchOwnerBookings(String ownerId) =>
      db.collection('bookings').where('ownerId', isEqualTo: ownerId).limit(300).snapshots()
          .map((s) => s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Stream<Booking?> watchCustomerCurrentBooking(String customerId) =>
      db.collection('bookings').where('customerId', isEqualTo: customerId).limit(100).snapshots()
          .map((s) {
            final list = s.docs.map((d) => Booking.fromMap(d.id, d.data()))
                .where((b) => ['pending_owner_confirmation', 'confirmed', 'in_progress', 'paid'].contains(b.status))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list.isNotEmpty ? list.first : null;
          });

  Stream<List<Booking>> watchCustomerBookings(String customerId) =>
      db.collection('bookings').where('customerId', isEqualTo: customerId).limit(300).snapshots()
          .map((s) => s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  // --- QUEUE ---
  Stream<Queue> watchQueue(String ownerId) =>
      db.collection('queue').doc(ownerId).snapshots().map((d) => d.exists ? Queue.fromMap(d.data()!) : const Queue());

  Future<void> updateQueue(String ownerId, Queue q) => db.collection('queue').doc(ownerId).set(q.toMap());

  // --- SEATS ---
  Future<void> updateSeats(String ownerId, int total, int occupied) =>
      db.collection('shops').doc(ownerId).update({'totalSeats': total, 'occupiedSeats': occupied});

  // --- SERVICE TIMER ---
  Stream<ServiceTimer> watchTimer(String ownerId) =>
      db.collection('service_timers').doc(ownerId).snapshots()
          .map((d) => d.exists ? ServiceTimer.fromMap(ownerId, d.data()!) : ServiceTimer(ownerId: ownerId, token: 0));

  Future<void> updateTimer(String ownerId, ServiceTimer t) => db.collection('service_timers').doc(ownerId).set(t.toMap());

  // --- PREMIUM SLOTS ---
  Future<List<PremiumSlot>> getPremiumSlots(String ownerId) async {
    final snap = await db.collection('premium_slots').where('ownerId', isEqualTo: ownerId).get();
    return snap.docs.map((d) => PremiumSlot.fromMap(d.data())).toList();
  }

  Stream<List<PremiumSlot>> watchPremiumSlots(String ownerId) =>
      db.collection('premium_slots').where('ownerId', isEqualTo: ownerId).snapshots()
          .map((s) => s.docs.map((d) => PremiumSlot.fromMap(d.data())).toList());

  Future<void> setPremiumSlot(PremiumSlot slot) async {
    final existing = await db.collection('premium_slots')
        .where('ownerId', isEqualTo: slot.ownerId).where('daysAhead', isEqualTo: slot.daysAhead).get();
    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update(slot.toMap());
    } else {
      await db.collection('premium_slots').add(slot.toMap());
    }
  }

  // --- BOOKINGS FETCH ---
  Future<List<Booking>> getOwnerBookings(String ownerId) async {
    final snap = await db.collection('bookings').where('ownerId', isEqualTo: ownerId).get();
    final list = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // --- INVOICE / REVENUE ---
  Future<Map<String, int>> getRevenue(String ownerId, {DateTime? from, DateTime? to}) async {
    final snap = await db.collection('bookings').where('ownerId', isEqualTo: ownerId).get();
    int total = 0, fees = 0, serviceRev = 0, count = 0;
    for (final d in snap.docs) {
      final b = Booking.fromMap(d.id, d.data());
      if (b.status != 'completed' && b.status != 'paid') continue;
      if (from != null && b.createdAt.isBefore(from)) continue;
      if (to != null && b.createdAt.isAfter(to)) continue;
      fees += b.bookingPrice;
      serviceRev += b.remainingAmount;
      total += b.price;
      count++;
    }
    return {'total': total, 'bookingFees': fees, 'serviceRevenue': serviceRev, 'count': count};
  }

  // --- NOTIFICATIONS ---
  Stream<List<AppNotification>> watchNotifications(String ownerId) =>
      db.collection('notifications').where('ownerId', isEqualTo: ownerId).limit(100).snapshots()
          .map((s) => s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<void> sendCustomerNotification({required String customerId, required String ownerId, required String title, required String body}) =>
      db.collection('notifications').add({
        'customerId': customerId, 'title': title, 'body': body, 'read': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

  Stream<List<AppNotification>> watchCustomerNotifications(String customerId) =>
      db.collection('notifications').where('customerId', isEqualTo: customerId).limit(100).snapshots()
          .map((s) => s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<void> markNotificationRead(String id) => db.collection('notifications').doc(id).update({'read': true});

  Future<int> getUnreadCount(String ownerId) async {
    final snap = await db.collection('notifications').where('ownerId', isEqualTo: ownerId).where('read', isEqualTo: false).get();
    return snap.docs.length;
  }

  // --- SHOP STREAMS ---
  Stream<Shop?> watchOwnerShop(String ownerId) =>
      db.collection('shops').doc(ownerId).snapshots().map((d) => d.exists ? Shop.fromMap(d.id, d.data()!) : null);

  Stream<List<Shop>> watchShops({String location = ''}) {
    Query<Map<String, dynamic>> q = db.collection('shops');
    if (location.trim().isNotEmpty) q = q.where('location', isEqualTo: location.trim());
    return q.limit(300).snapshots().map((s) => s.docs.map((d) => Shop.fromMap(d.id, d.data())).toList());
  }

  // --- FAVOURITE SHOPS ---
  Stream<List<String>> watchFavouriteShopIds(String uid) =>
      db.collection('users').doc(uid).snapshots().map((d) {
        if (!d.exists) return <String>[];
        final list = (d.data()?['favouriteShopIds'] as List<dynamic>?) ?? const [];
        return list.map((e) => e.toString()).toList();
      });

  Future<void> addFavouriteShop(String uid, String shopId) =>
      db.collection('users').doc(uid).update({'favouriteShopIds': FieldValue.arrayUnion([shopId])});

  Future<void> removeFavouriteShop(String uid, String shopId) =>
      db.collection('users').doc(uid).update({'favouriteShopIds': FieldValue.arrayRemove([shopId])});

  // --- WAITING PREDICTION ---
  Future<Map<String, dynamic>> getWaitingPrediction(String ownerId, int myToken) async {
    final queueDoc = await db.collection('queue').doc(ownerId).get();
    if (!queueDoc.exists) return {'ahead': 0, 'estimatedMinutes': 0, 'currentToken': 0};
    final queue = Queue.fromMap(queueDoc.data()!);
    if (!queue.isActive || myToken <= queue.currentToken) {
      return {'ahead': 0, 'estimatedMinutes': 0, 'currentToken': queue.currentToken};
    }
    final ahead = myToken - queue.currentToken;
    final estimatedMinutes = ahead * queue.estimatedMinutes;
    return {'ahead': ahead, 'estimatedMinutes': estimatedMinutes, 'currentToken': queue.currentToken};
  }

  // --- PARTNER METHODS ---
  Future<void> createPartner({required String name, required String email, required String mobile, required String password, required String partnerCode}) async {
    await _callFunction('createPartner', {
      'name': name,
      'email': email,
      'mobile': mobile,
      'password': password,
      'partnerCode': partnerCode,
    });
  }

  Future<Map<String, dynamic>?> getPartnerByCode(String code) async {
    if (code.trim().isEmpty) return null;
    final d = await db.collection('partner_codes').doc(code.trim()).get();
    if (!d.exists) return null;
    return d.data();
  }

  Future<AppUser?> getAppUserByPartnerCode(String partnerCode) async {
    final snap = await db.collection('users').where('partnerCode', isEqualTo: partnerCode).where('role', isEqualTo: 'partner').limit(1).get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return AppUser.fromMap(d.id, d.data());
  }

  Future<Map<String, dynamic>> getPartnerStats(String partnerCode) async {
    final shopsSnap = await db.collection('shops').where('partnerCode', isEqualTo: partnerCode).get();
    final shopIds = shopsSnap.docs.map((d) => d.id).toList();
    int totalBookings = 0;
    for (final sid in shopIds) {
      final bSnap = await db.collection('bookings').where('ownerId', isEqualTo: sid).get();
      totalBookings += bSnap.docs.length;
    }
    return {
      'totalShops': shopsSnap.docs.length,
      'totalBookings': totalBookings,
      'partnerCode': partnerCode,
    };
  }

  Future<Map<String, dynamic>> getPartnerShopEarnings(String partnerCode, {EarningsPeriod period = EarningsPeriod.all}) async {
    final shopsSnap = await db.collection('shops').where('partnerCode', isEqualTo: partnerCode).get();
    final shops = shopsSnap.docs.map((d) => Shop.fromMap(d.id, d.data())).toList();
    final periodStart = earningsPeriodStart(period, DateTime.now());
    int totalRevenue = 0, totalBookingCharges = 0, completedCount = 0;
    final List<ShopEarnings> perShop = [];
    for (final shop in shops) {
      final bookingsSnap = await db.collection('bookings').where('ownerId', isEqualTo: shop.ownerId).get();
      final bookings = bookingsSnap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      final completed = bookings
          .where((b) => b.status == 'completed' || b.status == 'paid' || b.status == 'confirmed')
          .where((b) => !b.createdAt.isBefore(periodStart))
          .toList();
      final shopRevenue = completed.fold<int>(0, (s, b) => s + b.price);
      final shopCharges = completed.fold<int>(0, (s, b) => s + b.bookingPrice);
      totalRevenue += shopRevenue;
      totalBookingCharges += shopCharges;
      completedCount += completed.length;
      perShop.add(ShopEarnings(
        ownerId: shop.ownerId, shopName: shop.shopName,
        totalRevenue: shopRevenue, totalBookingCharges: shopCharges, bookingCount: completed.length,
      ));
    }
    perShop.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    return {
      'totalRevenue': totalRevenue,
      'totalBookingCharges': totalBookingCharges,
      'totalBookingsCompleted': completedCount,
      'perShop': perShop,
    };
  }

  Stream<List<AccessRequest>> watchPartnerAccessRequests(String partnerCode) =>
      db.collection('admin_requests').orderBy('createdAt', descending: true).limit(200).snapshots().asyncMap((s) async {
        final partnerShopDocs = await db.collection('shops').where('partnerCode', isEqualTo: partnerCode).get();
        final partnerOwnerIds = partnerShopDocs.docs.map((d) => d.id).toSet();
        return s.docs
            .where((d) => partnerOwnerIds.contains(d.data()['ownerId']))
            .map((d) => AccessRequest.fromMap(d.id, d.data()))
            .toList();
      });

  Stream<List<Shop>> watchPartnerShops(String partnerCode) =>
      db.collection('shops').where('partnerCode', isEqualTo: partnerCode).limit(200).snapshots()
          .map((s) => s.docs.map((d) => Shop.fromMap(d.id, d.data())).toList());

  // --- PARTNER MANAGEMENT (Admin) ---
  Future<void> updatePartnerStatus(String partnerUid, String status) async {
    await db.collection('users').doc(partnerUid).update({'partnerStatus': status});
  }

  Future<void> deletePartner(String partnerUid) async {
    final userDoc = await db.collection('users').doc(partnerUid).get();
    if (userDoc.exists) {
      final partnerCode = (userDoc.data()?['partnerCode'] as String?) ?? '';
      if (partnerCode.isNotEmpty) {
        await db.collection('partner_codes').doc(partnerCode).delete();
      }
      await db.collection('users').doc(partnerUid).delete();
    }
  }

  Future<void> createPartnerUnblockRequest({required String partnerUid, required String partnerName, required String partnerCode, required String mobile}) async {
    await db.collection('partner_requests').doc(partnerUid).set({
      'partnerUid': partnerUid, 'partnerName': partnerName, 'partnerCode': partnerCode,
      'mobile': mobile, 'status': 'pending', 'note': 'unblock_request',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchPartnerUnblockRequests() =>
      db.collection('partner_requests').orderBy('createdAt', descending: true).limit(200).snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> updatePartnerRequestStatus(String partnerUid, String status) async {
    await db.collection('partner_requests').doc(partnerUid).update({'status': status});
  }

  Future<void> approvePartnerUnblock(String partnerUid) async {
    await db.collection('users').doc(partnerUid).update({'partnerStatus': 'active'});
    await db.collection('partner_requests').doc(partnerUid).update({'status': 'granted'});
  }

  // --- PARTNER PROFILE CHANGE REQUESTS (Partner -> Admin) ---
  Future<void> createPartnerEditRequest({
    required String partnerUid,
    required String partnerName,
    required String partnerCode,
    required String mobile,
    required String field,
    required String currentValue,
    required String requestedValue,
    String? note,
  }) async {
    await db.collection('partner_edit_requests').add({
      'partnerUid': partnerUid,
      'partnerName': partnerName,
      'partnerCode': partnerCode,
      'mobile': mobile,
      'field': field,
      'currentValue': currentValue,
      'requestedValue': requestedValue,
      'note': note ?? '',
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchPartnerEditRequests() =>
      db.collection('partner_edit_requests').orderBy('createdAt', descending: true).limit(200).snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> watchMyPartnerEditRequests(String partnerUid) =>
      db.collection('partner_edit_requests').orderBy('createdAt', descending: true).limit(200).snapshots()
          .map((s) => s.docs.where((d) => (d.data()['partnerUid'] ?? '') == partnerUid)
              .map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> applyPartnerEditRequest({
    required String requestId,
    required String partnerUid,
    required String field,
    required String newValue,
  }) async {
    final userDoc = await db.collection('users').doc(partnerUid).get();
    final userData = userDoc.exists ? (userDoc.data() ?? {}) : {};
    final userField = {
      'name': 'name',
      'mobile': 'mobile',
      'email': 'email',
      'partnerCode': 'partnerCode',
    }[field];
    if (userField != null) {
      await db.collection('users').doc(partnerUid).update({userField: newValue});
    }
    if (field == 'partnerCode') {
      final oldCode = (userData['partnerCode'] as String?) ?? '';
      if (oldCode.isNotEmpty && oldCode != newValue) {
        await db.collection('partner_codes').doc(newValue).set({
          'partnerUid': partnerUid, 'partnerCode': newValue, 'partnerName': userData['name'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await db.collection('partner_codes').doc(oldCode).delete();
        final shopsSnap = await db.collection('shops').where('partnerCode', isEqualTo: oldCode).get();
        for (final s in shopsSnap.docs) {
          await db.collection('shops').doc(s.id).update({'partnerCode': newValue});
        }
      }
    }
    if (field == 'email') {
      try {
        final u = auth.currentUser;
        if (u != null && u.uid == partnerUid) await u.verifyBeforeUpdateEmail(newValue);
      } catch (_) {}
    }
    if (field == 'password') {
      final partnerEmail = (userData['email'] as String?) ?? '';
      try {
        await _callFunction('changePartnerPassword', {
          'partnerUid': partnerUid,
          'newPassword': newValue,
        });
        debugPrint('[PasswordChange] applied via callable');
        await db.collection('partner_edit_requests').doc(requestId).update({
          'status': 'applied',
          'appliedValue': newValue,
          'appliedAt': DateTime.now().toIso8601String(),
        });
        return;
      } catch (e) {
        debugPrint('[PasswordChange] callable error: $e');
      }
      if (partnerEmail.isNotEmpty) await auth.sendPasswordResetEmail(email: partnerEmail);
    }
    await db.collection('partner_edit_requests').doc(requestId).update({
      'status': 'applied',
      'appliedValue': newValue,
      'appliedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> rejectPartnerEditRequest(String requestId) async {
    await db.collection('partner_edit_requests').doc(requestId).update({
      'status': 'rejected',
      'appliedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getPartnerShopsWithEarnings(String partnerCode, {EarningsPeriod period = EarningsPeriod.all}) async {
    final shopsSnap = await db.collection('shops').where('partnerCode', isEqualTo: partnerCode).get();
    final shops = shopsSnap.docs.map((d) => Shop.fromMap(d.id, d.data())).toList();
    final periodStart = earningsPeriodStart(period, DateTime.now());
    final List<Map<String, dynamic>> result = [];
    int totalRevenue = 0, totalBookings = 0;
    for (final shop in shops) {
      final bSnap = await db.collection('bookings').where('ownerId', isEqualTo: shop.ownerId).get();
      final bookings = bSnap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      final completed = bookings
          .where((b) => b.status == 'completed' || b.status == 'paid' || b.status == 'confirmed')
          .where((b) => !b.createdAt.isBefore(periodStart))
          .toList();
      final shopRevenue = completed.fold<int>(0, (s, b) => s + b.price);
      final shopCharges = completed.fold<int>(0, (s, b) => s + b.bookingPrice);
      totalRevenue += shopRevenue;
      totalBookings += completed.length;
      result.add({
        'shop': shop,
        'revenue': shopRevenue,
        'bookingCharges': shopCharges,
        'bookingCount': completed.length,
      });
    }
    return {
      'shops': result,
      'totalRevenue': totalRevenue,
      'totalBookings': totalBookings,
      'totalShops': shops.length,
    };
  }

  Stream<List<Map<String, dynamic>>> watchAllShopsWithPartnerInfo() =>
      db.collection('shops').limit(300).snapshots().asyncMap((s) async {
        final results = <Map<String, dynamic>>[];
        for (final d in s.docs) {
          final shop = Shop.fromMap(d.id, d.data());
          String partnerName = '';
          String partnerCode = shop.partnerCode;
          if (partnerCode.isNotEmpty) {
            final partnerDoc = await db.collection('partner_codes').doc(partnerCode).get();
            partnerName = (partnerDoc.data()?['partnerName'] as String?) ?? '';
          }
          results.add({'shop': shop, 'partnerName': partnerName, 'partnerCode': partnerCode});
        }
        return results;
      });

  Future<String> getPartnerStatus(String partnerUid) async {
    final doc = await db.collection('users').doc(partnerUid).get();
    return (doc.data()?['partnerStatus'] as String?) ?? 'active';
  }

  // --- FEEDBACK & SUPPORT ---
  Future<void> submitFeedback({
    required String userId, required String name, required String role,
    required int rating, required String message,
  }) async {
    await db.collection('feedback').add({
      'userId': userId, 'name': name, 'role': role,
      'rating': rating, 'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitSupportTicket({
    required String userId, required String name, required String role,
    required String subject, required String message,
  }) async {
    await db.collection('support_tickets').add({
      'userId': userId, 'name': name, 'role': role,
      'subject': subject, 'message': message,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- ADMIN / DEVELOPER MANAGEMENT ---
  Stream<List<Map<String, dynamic>>> watchFeedback() {
    return db.collection('feedback')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> markFeedbackReviewed(String id) async {
    await db.collection('feedback').doc(id).update({
      'reviewed': true,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFeedback(String id) async {
    await db.collection('feedback').doc(id).delete();
  }

  Stream<List<Map<String, dynamic>>> watchSupportTickets() {
    return db.collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> replyToTicket(String id, {required String adminReply, required String repliedBy}) async {
    await db.collection('support_tickets').doc(id).update({
      'adminReply': adminReply,
      'repliedBy': repliedBy,
      'repliedAt': FieldValue.serverTimestamp(),
      'status': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTicketStatus(String id, String status) async {
    await db.collection('support_tickets').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> closeTicket(String id) async {
    await db.collection('support_tickets').doc(id).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _sha1Hex(List<int> bytes) => sha1.convert(bytes).toString();

  String? _detectImageType(Uint8List bytes) {
    if (bytes.length < 12) return null;
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return 'jpg';
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return 'png';
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'webp';
    }
    return null;
  }
}

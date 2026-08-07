import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salon_app/l10n/app_localizations.dart';
import 'package:salon_app/widgets/language_bottom_sheet.dart';

import 'design_system.dart';
import 'firebase_service.dart';
import 'login_registration.dart';
import 'models.dart';
import 'services/notification_service.dart';
import 'widgets/premium_card.dart';
import 'widgets/premium_button.dart';
import 'widgets/premium_nav.dart';
import 'widgets/shimmer.dart';
import 'widgets/empty_state.dart';
import 'widgets/dashboard_widgets.dart';
import 'widgets/delete_account_tile.dart';
import 'widgets/feedback_support_section.dart';
import 'widgets/my_tickets_section.dart';
import 'image_system/presentation/screens/owner_gallery_screen.dart';
import 'pages/shop_payment_detail_page.dart';

class OwnerDashboard extends StatefulWidget {
  final AppUser user;
  const OwnerDashboard({super.key, required this.user});
  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> with TickerProviderStateMixin {
  final svc = FirebaseService();
  final picker = ImagePicker();
  final scrollCtrl = ScrollController();

  final shopNameCnt = TextEditingController();
  final mobileCnt = TextEditingController();
  final locationCnt = TextEditingController();
  final addressCnt = TextEditingController();
  final openTimeCnt = TextEditingController();
  final closeTimeCnt = TextEditingController();
  final shopPhotoUrlCnt = TextEditingController();
  final serviceNameCnt = TextEditingController();
  final serviceDurationCnt = TextEditingController();
  final servicePhotoUrlCnt = TextEditingController();
  final bookingPriceCnt = TextEditingController();
  final premiumBookingPriceCnt = TextEditingController();
  final descriptionCnt = TextEditingController();

  List<ShopService> services = [];
  List<Booking> _bookings = [];
  bool _loadingBookings = true;
  String? _bookingsError;
  bool isOpen = true;
  bool bookingsAvailable = true;
  int chairCount = 1;
  int _availableChairs = 0;
  String _chairAvailabilityDate = '';
  int notificationThreshold = 5;
  bool loadingLoc = false;
  bool uploadingShop = false;
  bool uploadingService = false;
  double lat = 0, lng = 0;
  List<int> workingDays = [1, 2, 3, 4, 5, 6, 7];
  List<dynamic> _gallery = [];
  bool expShop = true, expServices = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int _bottomIndex = 0;
  int _serviceFilter = 0;
  EarningsPeriod _earningsPeriod = EarningsPeriod.all;
  List<Booking>? _earnings;
  bool _loadingEarnings = true;
  final Map<String, String> _selectedConfirmTime = {};
  bool _isSubmitting = false;
  String _currentAccessStatus = 'pending';
  StreamSubscription<List<Booking>>? _bookingSub;
  StreamSubscription<Shop?>? _shopSub;
  Shop? _shop;
  bool _shopLoading = true;
  String? _shopError;

  void _requestAccess(Shop shop, BuildContext context, {String note = ''}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await svc.createAccessRequest(widget.user.uid, shop.ownerName, shop.shopName, shop.mobile, note: note);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(note == 'unblock_request' ? 'Unblock request sent!' : 'Request sent successfully!'),
          backgroundColor: DS.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: DS.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _bookingSub = svc.watchOwnerBookings(widget.user.uid).listen((bk) {
      if (mounted) {
        setState(() {
          _bookings = bk;
          _loadingBookings = false;
          _bookingsError = null;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _loadingBookings = false;
          _bookingsError = '$e';
        });
      }
    });
    _shopSub = svc.watchOwnerShop(widget.user.uid).listen((shop) {
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _shopLoading = false;
        _shopError = null;
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() {
        _shopLoading = false;
        _shopError = '$e';
      });
    });
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    if (mounted) setState(() => _loadingEarnings = true);
    try {
      final bookings = await svc.getShopPaymentDetails(widget.user.uid, period: _earningsPeriod);
      if (mounted) setState(() { _earnings = bookings; _loadingEarnings = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingEarnings = false);
    }
  }

  void fillForm(Shop s) {
    shopNameCnt.text = s.shopName;
    mobileCnt.text = s.mobile;
    locationCnt.text = s.location;
    addressCnt.text = s.address;
    openTimeCnt.text = s.openTime;
    closeTimeCnt.text = s.closeTime;
    shopPhotoUrlCnt.text = s.shopPhotoUrl;
    bookingPriceCnt.text = s.bookingPrice.toString();
    premiumBookingPriceCnt.text = s.premiumBookingPrice > 0 ? s.premiumBookingPrice.toString() : '';
    descriptionCnt.text = s.description;
    lat = s.latitude;
    lng = s.longitude;
    isOpen = s.isOpen;
    bookingsAvailable = s.bookingsAvailable;
    chairCount = s.chairCount;
    _availableChairs = s.availableChairs;
    _chairAvailabilityDate = s.chairAvailabilityDate;
    notificationThreshold = s.notificationThreshold;
    services = List.from(s.services);
    workingDays = List.from(s.workingDays);
    _gallery = List.from(s.gallery);
  }

  Future<void> getLocation() async {
    setState(() => loadingLoc = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Turn on location');
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) throw Exception('Permission denied');
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() { lat = pos.latitude; lng = pos.longitude; locationCnt.text = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}'; });
    } catch (e) { msg(e.toString()); }
    if (mounted) setState(() => loadingLoc = false);
  }

  Future<void> pickUpload({required bool shop}) async {
    try {
      setState(() => shop ? uploadingShop = true : uploadingService = true);
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1920);
      if (picked == null) { if (mounted) setState(() => shop ? uploadingShop = false : uploadingService = false); return; }
      final url = await svc.uploadImageBytes(bytes: await picked.readAsBytes(), folder: shop ? 'shop_photos' : 'service_photos');
      if (!mounted) return;
      setState(() { if (shop) { shopPhotoUrlCnt.text = url; uploadingShop = false; } else { servicePhotoUrlCnt.text = url; uploadingService = false; } });
      if (shop) { await save(showMsg: false); msg('Photo saved'); } else { msg('Photo ready. Tap Add Service.'); }
    } catch (e) { if (mounted) { setState(() => shop ? uploadingShop = false : uploadingService = false); msg('Error: $e'); } }
  }

  Future<void> addService() async {
    final d = int.tryParse(serviceDurationCnt.text.trim()) ?? 30;
    if (serviceNameCnt.text.trim().isEmpty) { msg('Enter service name'); return; }
    setState(() {
      services.add(ShopService(name: serviceNameCnt.text.trim(), price: 0, durationMinutes: d, photoUrl: servicePhotoUrlCnt.text.trim()));
      serviceNameCnt.clear(); serviceDurationCnt.clear(); servicePhotoUrlCnt.clear();
    });
    await save(showMsg: false);
    msg('Service added');
  }

  Future<void> save({bool showMsg = true}) async {
    await svc.updateShop(Shop(
      ownerId: widget.user.uid, ownerName: widget.user.name,
      shopName: shopNameCnt.text.trim(), mobile: mobileCnt.text.trim(),
      location: locationCnt.text.trim(), latitude: lat, longitude: lng,
      isOpen: isOpen, bookingsAvailable: bookingsAvailable, address: addressCnt.text.trim(),
      openTime: isOpen ? openTimeCnt.text.trim() : '', closeTime: isOpen ? closeTimeCnt.text.trim() : '',
      shopPhotoUrl: shopPhotoUrlCnt.text.trim(), services: services,
      bookingPrice: int.tryParse(bookingPriceCnt.text.trim()) ?? 50,
      premiumBookingPrice: int.tryParse(premiumBookingPriceCnt.text.trim()) ?? 0,
      workingDays: workingDays, description: descriptionCnt.text.trim(),
      chairCount: chairCount, notificationThreshold: notificationThreshold,
      chairAvailabilityDate: _chairAvailabilityDate, availableChairs: _availableChairs,
      accessStatus: _currentAccessStatus, gallery: _gallery,
    ));
    if (mounted && showMsg) msg('Saved');
  }

  Future<void> openMap() async {
    if (lat == 0 && lng == 0) { msg('Set location first'); return; }
    if (!await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'), mode: LaunchMode.externalApplication)) msg('Could not open Maps');
  }

  Future<void> editService(ShopService s) async {
    final nameC = TextEditingController(text: s.name);
    final durC = TextEditingController(text: s.durationMinutes.toString());
    final urlC = TextEditingController(text: s.photoUrl);
    bool uploading = false;
    final result = await showDialog<ShopService>(
      context: context,
      builder: (c) {
        final dialogDark = Theme.of(c).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (c, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(DS.rLg)), child: const Icon(Icons.edit_outlined, color: DS.primary, size: 32)),
                    const SizedBox(height: 18),
                    Text('Edit Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: dialogDark ? DS.darkInk : DS.ink)),
                    const SizedBox(height: 20),
                    TextField(controller: nameC, style: TextStyle(color: DS.inkC(c)), decoration: DS.inputDecoration(c).copyWith(labelText: 'Service Name', prefixIcon: const Icon(Icons.content_cut, size: 18))),
                    const SizedBox(height: 14),
                    TextField(controller: durC, keyboardType: TextInputType.number, style: TextStyle(color: DS.inkC(c)), decoration: DS.inputDecoration(c).copyWith(labelText: 'Duration (min)', prefixIcon: const Icon(Icons.timer, size: 18))),
                    const SizedBox(height: 14),
                    if (urlC.text.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DS.rMd),
                        child: Image.network(urlC.text, height: 100, width: double.infinity, fit: BoxFit.cover,
                          loadingBuilder: (c2, ch, p) => p == null ? ch : Container(height: 100, color: DS.primaryVeryLight, child: const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
                          errorBuilder: (c2, e, _) => Container(height: 100, color: DS.primaryVeryLight, child: const Icon(Icons.broken_image, color: DS.muted)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    uploading
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                        : PButton(
                            text: urlC.text.isEmpty ? 'Upload Photo' : 'Change Photo',
                            icon: Icons.add_photo_alternate_outlined,
                            isOutlined: true,
                            expanded: false,
                            height: 36,
                            onPressed: () async {
                              setDialogState(() => uploading = true);
                              try {
                                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1920);
                                if (picked != null) {
                                  final bytes = await picked.readAsBytes();
                                  final url = await svc.uploadImageBytes(bytes: bytes, folder: 'service_photos');
                                  setDialogState(() { urlC.text = url; });
                                }
                              } catch (e) {
                                if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Upload failed: $e'), behavior: SnackBarBehavior.floating));
                              } finally {
                                if (c.mounted) setDialogState(() => uploading = false);
                              }
                            },
                          ),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: PButton(text: 'Cancel', icon: Icons.close, onPressed: () => Navigator.pop(c), isOutlined: true)),
                      const SizedBox(width: 12),
                      Expanded(child: PButton(text: 'Save', icon: Icons.check, onPressed: () {
                        final nd = int.tryParse(durC.text.trim()) ?? s.durationMinutes;
                        if (nameC.text.trim().isEmpty) return;
                        Navigator.pop(c, s.copyWith(name: nameC.text.trim(), durationMinutes: nd, photoUrl: urlC.text.trim()));
                      })),
                    ]),
                  ]),
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null) {
      final idx = services.indexWhere((x) => x.name == s.name);
      if (idx >= 0) {
        setState(() => services[idx] = result);
        await save(showMsg: false);
        msg('Service updated');
      }
    }
  }

  Future<void> toggleService(ShopService s) async {
    final idx = services.indexWhere((x) => x.name == s.name);
    if (idx >= 0) {
      setState(() => services[idx] = s.copyWith(enabled: !s.enabled));
      await save(showMsg: false);
    }
  }

  Future<void> logout() async { await svc.logout(); if (!mounted) return; Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())); }

  void msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  void dispose() {
    _shopSub?.cancel();
    _bookingSub?.cancel();
    _fadeCtrl.dispose();
    scrollCtrl.dispose();
    shopNameCnt.dispose(); mobileCnt.dispose(); locationCnt.dispose(); addressCnt.dispose();
    openTimeCnt.dispose(); closeTimeCnt.dispose(); shopPhotoUrlCnt.dispose();
    serviceNameCnt.dispose(); serviceDurationCnt.dispose(); servicePhotoUrlCnt.dispose();
    bookingPriceCnt.dispose(); descriptionCnt.dispose();
    super.dispose();
  }

  List<Booking> get _filteredBookings {
    if (_serviceFilter == 0) return _bookings;
    const statusMap = {1: 'pending_owner_confirmation', 2: 'confirmed', 3: 'in_progress', 4: 'completed', 5: 'cancelled', 6: 'paid'};
    final target = statusMap[_serviceFilter];
    return _bookings.where((b) => b.status == target).toList();
  }

  // ── Status badge helper ──
  ({Color color, Color dark, IconData icon, String label}) _bookingStatusMeta(String status) => switch (status) {
    'available' => (color: DS.success, dark: const Color(0xFF059669), icon: Icons.check_circle, label: 'Available'),
    'waiting_to_start' => (color: DS.purple, dark: const Color(0xFF6D28D9), icon: Icons.hourglass_top, label: 'Waiting'),
    'in_service' => (color: DS.info, dark: const Color(0xFF2563EB), icon: Icons.build, label: 'In Service'),
    'paused' => (color: DS.warning, dark: const Color(0xFFB45309), icon: Icons.pause_circle, label: 'Paused'),
    'completed' => (color: DS.success, dark: const Color(0xFF059669), icon: Icons.task_alt, label: 'Completed'),
    'pending_owner_confirmation' => (color: DS.warning, dark: const Color(0xFFB45309), icon: Icons.hourglass_top, label: 'Pending'),
    'confirmed' => (color: DS.primary, dark: const Color(0xFF00695C), icon: Icons.check_circle_outline, label: 'Confirmed'),
    'in_progress' => (color: DS.accent, dark: const Color(0xFFB8962E), icon: Icons.bolt, label: 'In Progress'),
    'paid' => (color: DS.teal, dark: const Color(0xFF0D9488), icon: Icons.payments_outlined, label: 'Paid'),
    'cancelled' => (color: DS.error, dark: const Color(0xFFDC2626), icon: Icons.cancel_outlined, label: 'Cancelled'),
    _ => (color: DS.muted, dark: DS.muted, icon: Icons.schedule, label: status),
  };

  Widget _statusBadge(String status) {
    final m = _bookingStatusMeta(status);
    return _statusChipPill(m.label, m.color, icon: m.icon);
  }

  Widget _statusChipPill(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DS.rFull), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 5)],
        Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.6)),
      ]),
    );
  }

  Widget _ownerInfoTile(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(DS.rMd),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(DS.rSm)),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: DS.mutedC(context))),
          const SizedBox(height: 1),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: DS.inkC(context))),
        ])),
      ]),
    );
  }

  Widget _badgeIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 24),
        if (count > 0)
          Positioned(
            right: -6, top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: DS.error, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(gradient: DS.isDark(context) ? DS.gradientDarkBg : DS.gradientBg),
        child: _buildShopBody(),
      ),
      bottomNavigationBar: _shop == null
          ? const SizedBox.shrink()
          : (_shop!.accessStatus == 'blocked' || _shop!.accessStatus == 'pending')
              ? const SizedBox.shrink()
              : _buildBottomNav(),
    );
  }

  Widget _buildShopBody() {
    if (_shopError != null) return _errorView('$_shopError');
    if (_shopLoading) return const Padding(padding: EdgeInsets.all(16), child: ShimmerList());
    final shop = _shop;
    if (shop == null) return _emptyShopView();
    if (_currentAccessStatus != shop.accessStatus) {
      _currentAccessStatus = shop.accessStatus;
    }
    if (shop.accessStatus == 'pending') return _buildPendingView(shop);
    if (shop.accessStatus == 'blocked') return _accessRestrictedView(shop);
    if (shopNameCnt.text.isEmpty) fillForm(shop);
    if (shopPhotoUrlCnt.text != shop.shopPhotoUrl) {
      shopPhotoUrlCnt.text = shop.shopPhotoUrl;
    }
    if (_gallery.length != shop.gallery.length) {
      _gallery = List.from(shop.gallery);
    }
    return _buildMainContent(shop);
  }

  Widget _buildMainContent(Shop shop) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ClipRect(
        child: IndexedStack(
          index: _bottomIndex,
          children: [
            _buildDashboardTab(shop),
            _buildBookingsTab(),
            _buildServicesTab(),
            _buildSettingsTab(shop),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingView(Shop shop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: DS.accentLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(DS.rXxl)),
              child: const Icon(Icons.hourglass_empty, size: 64, color: DS.accent),
            ),
            const SizedBox(height: 24),
            Text('Registration Pending', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: DS.inkC(context), letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text('Your shop registration is pending approval.\nRequest access from the admin to start using the platform.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: DS.mutedC(context), height: 1.6)),
            const SizedBox(height: 32),
            PButton(text: _isSubmitting ? 'Sending...' : 'Request Access', icon: Icons.send_rounded, onPressed: () => _requestAccess(shop, context, note: 'new_request')),
          ],
        ),
      ),
    );
  }

  Widget _accessRestrictedView(Shop shop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DS.rXxl)),
              child: const Icon(Icons.block, size: 64, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            Text('Shop Blocked', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: DS.inkC(context), letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text('Your shop has been blocked by the admin.\nTap below to request unblock.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: DS.mutedC(context), height: 1.6)),
            const SizedBox(height: 32),
            PButton(text: _isSubmitting ? 'Sending...' : 'Request Unblock', icon: Icons.lock_open_rounded, onPressed: () => _requestAccess(shop, context, note: 'unblock_request')),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(_bottomIndex == 0 ? l.dashboard : _bottomIndex == 1 ? l.bookings : _bottomIndex == 2 ? l.services : l.settings, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3)),
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        StreamBuilder<List<AppNotification>>(
          stream: svc.watchNotifications(widget.user.uid),
          builder: (c, snap) {
            final unread = snap.data?.where((n) => !n.read).length ?? 0;
            return IconButton(icon: _badgeIcon(Icons.notifications_outlined, unread), onPressed: () => _showNotifications(context));
          },
        ),
        IconButton(icon: Icon(Icons.logout, color: DS.inkC(context)), onPressed: logout),
      ],
    );
  }

  Widget _errorView(String error) {
    final isDark = DS.isDark(context);
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, size: 48, color: DS.error),
        const SizedBox(height: 16),
        Text('Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DS.error)),
        const SizedBox(height: 8),
        Text(error, maxLines: 5, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 13), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _emptyShopView() {
    final isDark = DS.isDark(context);
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.store_mall_directory_outlined, size: 48, color: isDark ? DS.darkMuted : DS.muted),
        const SizedBox(height: 16),
        Text('No Shop Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? DS.darkMuted : DS.muted)),
        const SizedBox(height: 8),
        Text('Your shop data will appear here', style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 13)),
      ]),
    ));
  }

  Widget _buildBottomNav() {
    final pendingCount = _bookings.where((b) => b.status == 'pending_owner_confirmation').length;
    return PremiumBottomNav(
      currentIndex: _bottomIndex,
      onTap: (i) => setState(() => _bottomIndex = i),
      items: [
        const NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
        NavItem(icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt, label: 'Bookings', badge: pendingCount),
        const NavItem(icon: Icons.content_cut_outlined, activeIcon: Icons.content_cut, label: 'Services'),
        const NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
      ],
    );
  }

  // ── DASHBOARD TAB ──
  Widget _buildDashboardTab(Shop shop) {
    return _buildOverview(shop);
  }

  Widget _buildOverview(Shop shop) {
    final now = DateTime.now();
    final today = _bookings.where((b) =>
        b.createdAt.year == now.year &&
        b.createdAt.month == now.month &&
        b.createdAt.day == now.day).toList();
    final todayCount = today.length;
    final todayEarnings = today.where((b) => b.isPaid || b.status == 'paid').fold<int>(0, (sum, b) => sum + b.price);
    final activeCustomers = _bookings.where((b) => b.status == 'pending_owner_confirmation' || b.status == 'confirmed' || b.status == 'in_progress').length;
    final pendingStrip = _buildPendingStrip();
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(children: [
        _buildHeader(shop, todayCount: todayCount, todayEarnings: todayEarnings, activeCustomers: activeCustomers, loading: _loadingBookings),
        const SizedBox(height: 24),
        _buildEarningsSection(shop),
        if (pendingStrip != null) ...[
          const SizedBox(height: 24),
          pendingStrip,
        ],
      ]),
    );
  }

  Widget _buildHeader(Shop shop, {required int todayCount, required int todayEarnings, required int activeCustomers, required bool loading}) {
    String statV(int v) => loading ? '...' : '$v';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [DS.primaryDark, DS.primary, DS.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(DS.rXl),
        boxShadow: [DS.shadowPrimary],
      ),
      child: Stack(children: [
        Positioned(right: -26, top: -26, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(right: 26, bottom: -34, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: DS.accent.withValues(alpha: 0.4), width: 12)))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              height: 54, width: 54,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))]),
              child: ClipOval(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.2),
                  child: shop.shopPhotoUrl.isNotEmpty
                      ? Image.network(shop.shopPhotoUrl, fit: BoxFit.cover, errorBuilder: (c, e, _) => const Icon(Icons.store, color: Colors.white, size: 26))
                      : const Icon(Icons.store, color: Colors.white, size: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(shop.shopName.isNotEmpty ? shop.shopName : 'Your Shop', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Expanded(child: Text(shop.location.isNotEmpty ? shop.location : 'No location set', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _heroStat(label: 'Today', value: statV(todayCount), color: DS.accent)),
            const SizedBox(width: 10),
            Expanded(child: _heroStat(label: 'Earnings', value: loading ? '...' : 'Rs $todayEarnings', color: DS.successLight)),
            const SizedBox(width: 10),
            Expanded(child: _heroStat(label: 'Active', value: statV(activeCustomers), color: Colors.white)),
          ]),
        ]),
      ]),
    );
  }

  Widget _statusPill({required bool active, required String activeLabel, required String inactiveLabel, required IconData activeIcon, required IconData inactiveIcon, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DS.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (active ? DS.success : DS.error).withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(DS.rFull),
            border: Border.all(color: (active ? DS.success : DS.error).withValues(alpha: 0.45)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(active ? activeIcon : inactiveIcon, size: 14, color: active ? DS.success : DS.error),
            const SizedBox(width: 5),
            Text(active ? activeLabel : inactiveLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? DS.success : DS.error)),
          ]),
        ),
      ),
    );
  }

  Widget _heroStat({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: Colors.white.withValues(alpha: 0.14))),
      child: Column(children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, height: 1.1)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: Colors.white70)),
      ]),
    );
  }

  Widget? _buildPendingStrip() {
    final confirm = _bookings.where((b) => b.status == 'pending_owner_confirmation').length;
    final collect = _bookings.where((b) => b.status == 'completed' && !b.isPaid).length;
    final live = _bookings.where((b) => b.status == 'in_progress').length;
    if (confirm + collect + live == 0) return null;
    return SectionCard(
      icon: Icons.notifications_active_outlined,
      title: 'Needs Your Attention',
      accentColor: DS.warning,
      child: Row(children: [
        _pendingActionTile(
          icon: Icons.hourglass_top,
          label: 'Confirm Requests',
          count: confirm,
          color: DS.warning,
          onTap: () => setState(() { _serviceFilter = 1; _bottomIndex = 1; }),
        ),
        const SizedBox(width: 10),
        _pendingActionTile(
          icon: Icons.money_off,
          label: 'Collect Payments',
          count: collect,
          color: DS.accent,
          onTap: () => setState(() { _serviceFilter = 4; _bottomIndex = 1; }),
        ),
        const SizedBox(width: 10),
        _pendingActionTile(
          icon: Icons.bolt,
          label: 'In Service',
          count: live,
          color: DS.info,
          onTap: () => setState(() { _serviceFilter = 3; _bottomIndex = 1; }),
        ),
      ]),
    );
  }

  Widget _pendingActionTile({required IconData icon, required String label, required int count, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(DS.rLg),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1.1)),
            ]),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: DS.mutedC(context))),
          ]),
        ),
      ),
    );
  }

  Widget _buildEarningsSection(Shop shop) {
    return SectionCard(
      icon: Icons.account_balance,
      title: 'Earnings & Revenue',
      accentColor: DS.success,
      child: Column(children: [
        _earningsPeriodChips(),
        const SizedBox(height: 14),
        if (_loadingEarnings)
          const DashboardLoading()
        else if (_earnings == null || _earnings!.isEmpty)
          const DashboardEmptyState(message: 'No earnings data yet')
        else ...[
          EarningsHeroBanner(
            totalFees: _earnings!.fold<int>(0, (s, b) => s + b.bookingPrice),
            totalRevenue: _earnings!.fold<int>(0, (s, b) => s + b.price),
            totalBookings: _earnings!.length,
          ),
          const SizedBox(height: 16),
          ShopEarningsMiniTile(
            shopName: shop.shopName,
            fees: _earnings!.fold<int>(0, (s, b) => s + b.bookingPrice),
            revenue: _earnings!.fold<int>(0, (s, b) => s + b.price),
            bookings: _earnings!.length,
            onTap: () => _openShopPayments(shop),
          ),
        ],
      ]),
    );
  }

  Widget _earningsPeriodChips() {
    final isDark = DS.isDark(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final p in const [EarningsPeriod.all, EarningsPeriod.day, EarningsPeriod.week, EarningsPeriod.month, EarningsPeriod.year]) ...[
          if (p != EarningsPeriod.all) const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              if (_earningsPeriod == p) return;
              setState(() => _earningsPeriod = p);
              _loadEarnings();
            },
            child: AnimatedContainer(
              duration: DS.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _earningsPeriod == p ? DS.success : (isDark ? const Color(0xCC16213E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _earningsPeriod == p ? DS.success : (isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF))),
              ),
              child: Text(_earningsPeriodLabel(p), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _earningsPeriod == p ? Colors.white : (isDark ? DS.darkMuted : DS.muted))),
            ),
          ),
        ],
      ]),
    );
  }

  String _earningsPeriodLabel(EarningsPeriod p) {
    switch (p) {
      case EarningsPeriod.all:
        return 'All';
      case EarningsPeriod.day:
        return 'Day';
      case EarningsPeriod.week:
        return 'Week';
      case EarningsPeriod.month:
        return 'Month';
      case EarningsPeriod.year:
        return 'Year';
    }
  }

  void _openShopPayments(Shop shop) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPaymentDetailPage(
      ownerId: shop.ownerId,
      shopName: shop.shopName,
      initialPeriod: _earningsPeriod,
    )));
  }

  // ── BOOKINGS TAB ──
  Widget _buildBookingsTab() {
    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _filterChip('All', 0),
            const SizedBox(width: 8),
            _filterChip('Pending', 1),
            const SizedBox(width: 8),
            _filterChip('Confirmed', 2),
            const SizedBox(width: 8),
            _filterChip('In Progress', 3),
            const SizedBox(width: 8),
            _filterChip('Completed', 4),
            const SizedBox(width: 8),
            _filterChip('Cancelled', 5),
            const SizedBox(width: 8),
            _filterChip('Paid', 6),
          ]),
        ),
      ),
      Expanded(child: _buildBookingsList()),
    ]);
  }

  Widget _filterChip(String label, int index) {
    final selected = _serviceFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _serviceFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? DS.gradientPrimary : null,
          color: selected ? null : DS.surfaceC(context),
          borderRadius: BorderRadius.circular(DS.rXl),
          border: Border.all(color: selected ? Colors.transparent : DS.borderC(context).withValues(alpha: 0.5)),
          boxShadow: selected ? [DS.shadowPrimary] : [],
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : DS.inkC(context))),
      ),
    );
  }

  Widget _buildBookingsList() {
    final filtered = _filteredBookings;
    if (_bookingsError != null && _bookings.isEmpty) {
      return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Text('Error: $_bookingsError', style: const TextStyle(color: DS.error))));
    }
    if (_loadingBookings) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (filtered.isEmpty) {
      return const Center(child: EmptyState(icon: Icons.event_busy, title: 'No Bookings', subtitle: 'No bookings match this filter'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: filtered.length,
      itemBuilder: (c, i) => _buildBookingItem(filtered[i]),
    );
  }

  Widget _buildBookingItem(Booking b) {
    final isDark = DS.isDark(context);
    final m = _bookingStatusMeta(b.status);

    final tiles = <Widget>[
      if (b.price > 0) _ownerInfoTile(context, icon: Icons.payments_outlined, label: 'Service Amount', value: 'Rs ${b.price}', color: DS.primary),
      if (b.customerMobile.isNotEmpty) _ownerInfoTile(context, icon: Icons.phone_outlined, label: 'Mobile', value: b.customerMobile, color: DS.info),
      if (b.chairNumber != null) _ownerInfoTile(context, icon: Icons.weekend_outlined, label: 'Chair', value: '#${b.chairNumber}', color: DS.purple),
      if (b.scheduledDate.isNotEmpty) _ownerInfoTile(context, icon: Icons.event_outlined, label: 'Date', value: b.scheduledDate, color: DS.teal),
      if (b.scheduledTime.isNotEmpty) _ownerInfoTile(context, icon: Icons.schedule, label: 'Time', value: b.scheduledTime, color: DS.success),
      if (b.paymentMethod.isNotEmpty) _ownerInfoTile(context, icon: Icons.account_balance_wallet_outlined, label: 'Payment', value: b.paymentMethod == 'Cash' ? 'Cash (Offline)' : b.paymentMethod, color: DS.purple),
      if (b.isPremium) _ownerInfoTile(context, icon: Icons.workspace_premium, label: 'Premium', value: b.premiumDaysAhead > 0 ? '${b.premiumDaysAhead} days ahead' : 'Premium Booking', color: DS.accent),
    ];

    final infoRows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      infoRows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: tiles[i]),
        if (i + 1 < tiles.length) ...[const SizedBox(width: 8), Expanded(child: tiles[i + 1])],
      ]));
      infoRows.add(const SizedBox(height: 8));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DS.rXl),
          gradient: LinearGradient(
            colors: isDark ? [DS.darkCard, m.color.withValues(alpha: 0.10)] : [Colors.white, m.color.withValues(alpha: 0.035)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: m.color.withValues(alpha: 0.22)),
          boxShadow: isDark ? null : [BoxShadow(color: m.color.withValues(alpha: 0.09), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [m.color, m.dark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(DS.rLg),
                  boxShadow: [BoxShadow(color: m.color.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('#', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 1),
                  FittedBox(fit: BoxFit.scaleDown, child: Text('${b.token}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900))),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 26, height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(gradient: b.isPremium ? DS.gradientGold : DS.gradientPrimary, borderRadius: BorderRadius.circular(DS.rSm)),
                      child: Text(b.customerName.isNotEmpty ? b.customerName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: DS.inkC(context), letterSpacing: -0.3))),
                    if (b.isPremium) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(gradient: DS.gradientGold, borderRadius: BorderRadius.circular(DS.rSm), boxShadow: [DS.shadowGold]),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.star, size: 10, color: Colors.white),
                          SizedBox(width: 4),
                          Text('PREMIUM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                        ]),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(b.serviceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: DS.mutedC(context))),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              _statusBadge(b.status),
              if (b.reachedShop) ...[
                const SizedBox(width: 8),
                _statusChipPill('Arrived', DS.success, icon: Icons.check_circle),
              ],
              if (b.offlinePaymentRequested && !b.isPaid) ...[
                const SizedBox(width: 8),
                _statusChipPill('Cash Awaiting', DS.warning, icon: Icons.money),
              ],
              const Spacer(),
              if (b.status == 'in_progress')
                _statusChipPill('LIVE', DS.error, icon: Icons.fiber_manual_record),
            ]),
          ),
          const SizedBox(height: 14),
          if (tiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: infoRows),
            ),
          if (b.status == 'pending_owner_confirmation') ...[
            const SizedBox(height: 14),
            if (b.isPremium) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [DS.accent.withValues(alpha: 0.15), DS.accent.withValues(alpha: 0.03)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(DS.rMd),
                    border: Border.all(color: DS.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.workspace_premium, size: 18, color: DS.accent),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Premium Booking', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: DS.accent)),
                      const SizedBox(height: 2),
                      Text(b.preferredTime1.isNotEmpty ? '${b.scheduledDate} at ${b.preferredTime1}' : 'Customer chose this slot', style: TextStyle(fontSize: 12, color: DS.mutedC(context))),
                    ])),
                  ]),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PreferredTimesCard(
                  b: b,
                  selectedTime: _selectedConfirmTime[b.id],
                  onSelect: (t) => setState(() => _selectedConfirmTime[b.id] = t),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: PButton(text: 'Confirm Appointment', icon: Icons.calendar_today, onPressed: () => _confirmAppointment(b, premiumTime: b.isPremium ? b.preferredTime1 : null), isGold: true)),
                const SizedBox(width: 10),
                Expanded(child: PButton(text: b.isPremium ? 'Not Available' : 'Decline', icon: Icons.close, onPressed: () => _declineBooking(b), isOutlined: true)),
              ]),
            ),
          ],
          if (b.status == 'confirmed' && !b.reachedShop) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: PButton(text: 'Reached', icon: Icons.pin_drop, onPressed: () => svc.markReachedShop(b.id), isOutlined: true)),
                const SizedBox(width: 10),
                Expanded(child: PButton(text: 'Cancel', icon: Icons.close, onPressed: () => _confirmCancel(b), isOutlined: true)),
              ]),
            ),
          ],
          if (b.status == 'confirmed' || b.status == 'in_progress') ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PButton(text: 'Complete Service', icon: Icons.check, onPressed: () => _handleCompleteService(b), isGold: true),
            ),
          ],
          if (b.status == 'completed' && !b.isPaid && b.remainingAmount == 0) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PButton(text: 'Enter Service Amount', icon: Icons.currency_rupee, onPressed: () => _handleCompleteService(b), isGold: true),
            ),
          ],
          if (b.status == 'completed' && !b.isPaid && b.offlinePaymentRequested) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DS.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DS.rMd),
                  border: Border.all(color: DS.warning.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.money, size: 18, color: DS.warning),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${b.customerName} opted to pay the remaining Rs ${b.remainingAmount} in cash. Mark as paid after collecting.', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: DS.warning, height: 1.4))),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PButton(text: 'Mark Paid (Cash Received)', icon: Icons.check_circle, onPressed: () => _markOfflinePaid(b), isGold: true),
            ),
          ],
          const SizedBox(height: 4),
        ]),
      ),
    );
  }

  Future<void> _handleCompleteService(Booking b) async {
    final amtCnt = TextEditingController(text: b.price.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (c) {
        final dialogDark = Theme.of(c).brightness == Brightness.dark;
        return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(DS.rLg)), child: const Icon(Icons.currency_rupee, color: DS.primary, size: 32)),
            const SizedBox(height: 16),
            Text('Service Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dialogDark ? DS.darkInk : DS.ink)),
            const SizedBox(height: 4),
            Text('Enter total service charge', style: TextStyle(color: dialogDark ? DS.darkMuted : DS.muted, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(controller: amtCnt, keyboardType: TextInputType.number, style: TextStyle(color: DS.inkC(c)), decoration: DS.inputDecoration(c).copyWith(labelText: 'Total Amount (Rs)', prefixIcon: const Icon(Icons.currency_rupee, size: 18))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: DS.accentLight, borderRadius: BorderRadius.circular(DS.rMd)),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 16, color: DS.accent),
                const SizedBox(width: 8),
                Flexible(child: Text('Customer will pay this full amount after service', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: DS.accent.withValues(alpha: 0.8)))),
              ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: PButton(text: 'Cancel', icon: Icons.close, onPressed: () => Navigator.pop(c), isOutlined: true)),
              const SizedBox(width: 12),
              Expanded(child: PButton(text: 'Confirm', icon: Icons.check, onPressed: () {
                final amt = int.tryParse(amtCnt.text.trim());
                if (amt == null || amt < 50) return;
                Navigator.pop(c, amt);
              }, isGold: true)),
            ]),
          ]),
        ),
        );
      },
    );
    if (result == null) return;
    await svc.updateBooking(b.copyWith(
      price: result,
      remainingAmount: result,
      status: 'completed',
      isPaid: false,
      offlinePaymentRequested: false,
    ));
    msg('Service completed. Customer owes Rs $result.');
  }

  Future<void> _markOfflinePaid(Booking b) async {
    try {
      await svc.markOfflinePaid(
        bookingId: b.id,
        customerId: b.customerId,
        customerName: b.customerName,
        shopName: b.shopName,
        remainingAmount: b.remainingAmount,
      );
      if (mounted) msg('Payment of Rs ${b.remainingAmount} marked as received.');
    } catch (e) {
      if (mounted) msg('Failed to mark paid: $e');
    }
  }

  Future<void> _confirmCancel(Booking b) async {
    showDialog(
      context: context,
      builder: (c) {
        final dialogDark = Theme.of(c).brightness == Brightness.dark;
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
        title: Text('Cancel Booking?', style: TextStyle(fontWeight: FontWeight.w800, color: dialogDark ? DS.darkInk : DS.ink)),
        content: Text('Cancel #${b.token} - ${b.customerName}\'s ${b.serviceName} booking?', style: TextStyle(color: dialogDark ? DS.darkMuted : DS.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Keep', style: TextStyle(fontWeight: FontWeight.w600))),
          TextButton(onPressed: () async {
            Navigator.pop(c);
            try {
              await svc.cancelBooking(b.id);
              await NotificationService().cancelReminder(b.id);
            } catch (_) {}
          }, child: const Text('Cancel Booking', style: TextStyle(color: DS.error, fontWeight: FontWeight.w700))),
        ],
      );
      },
    );
  }

  Future<void> _confirmAppointment(Booking b, {String? premiumTime}) async {
    final confirmedTime = (premiumTime != null && premiumTime.isNotEmpty) ? premiumTime : _selectedConfirmTime[b.id];
    if (confirmedTime == null || confirmedTime.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tap a preferred time to select it, then confirm'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    try {
      await svc.confirmAppointment(
        bookingId: b.id,
        ownerId: widget.user.uid,
        customerId: b.customerId,
        customerName: b.customerName,
        shopName: b.shopName,
        serviceName: b.serviceName,
        token: b.token,
        appointmentDate: b.scheduledDate,
        appointmentTime: confirmedTime,
      );

      final timeParts = confirmedTime.split(' ');
      final tp = timeParts[0].split(':');
      final ampm = timeParts.length > 1 ? timeParts[1] : 'AM';
      int h = int.tryParse(tp[0]) ?? 9;
      if (ampm == 'PM' && h < 12) h += 12;
      if (ampm == 'AM' && h == 12) h = 0;
      final m = int.tryParse(tp[1]) ?? 0;
      final dateParts = b.scheduledDate.split('-');
      final appointmentDateTime = DateTime(
        int.tryParse(dateParts[0]) ?? DateTime.now().year,
        int.tryParse(dateParts[1]) ?? DateTime.now().month,
        int.tryParse(dateParts[2]) ?? DateTime.now().day,
        h,
        m,
      );

      await NotificationService().scheduleAppointmentReminder(
        bookingId: b.id,
        shopName: b.shopName,
        serviceName: b.serviceName,
        appointmentDateTime: appointmentDateTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Appointment confirmed for ${b.scheduledDate} at $confirmedTime'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: DS.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _declineBooking(Booking b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) {
        final dialogDark = Theme.of(c).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
          title: Text('Decline Booking?', style: TextStyle(fontWeight: FontWeight.w800, color: dialogDark ? DS.darkInk : DS.ink)),
          content: Text('Decline ${b.customerName}\'s booking request (Token #${b.token})? They will be notified.', style: TextStyle(color: dialogDark ? DS.darkMuted : DS.muted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep', style: TextStyle(fontWeight: FontWeight.w600))),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Decline', style: TextStyle(color: DS.error, fontWeight: FontWeight.w700))),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await svc.cancelBookingByOwner(
        bookingId: b.id,
        ownerId: widget.user.uid,
        customerId: b.customerId,
        customerName: b.customerName,
        shopName: b.shopName,
        token: b.token,
      );
      await NotificationService().cancelReminder(b.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Booking request declined'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── SERVICES TAB ──
  Widget _buildServicesTab() {
    final isDark = DS.isDark(context);
    final active = services.where((s) => s.enabled).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [DS.primaryDark, DS.primary, DS.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(DS.rXl),
            boxShadow: [DS.shadowPrimary],
          ),
          child: Stack(children: [
            Positioned(right: -26, top: -26, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
            Positioned(right: 26, bottom: -34, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: DS.accent.withValues(alpha: 0.4), width: 12)))),
            Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: Colors.white.withValues(alpha: 0.18))), child: const Icon(Icons.content_cut, color: DS.accent, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Services', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text('Add, edit & manage your services', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              ])),
              if (services.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(DS.rFull), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                  child: Text('$active active', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        PremiumCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: DS.gradientPrimary, borderRadius: BorderRadius.circular(DS.rMd), boxShadow: [DS.shadowPrimary]), child: const Icon(Icons.add, size: 18, color: Colors.white)),
              const SizedBox(width: 14),
              Text('Add New Service', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: DS.inkC(context), letterSpacing: -0.3)),
            ]),
            const SizedBox(height: 16),
            TextField(controller: serviceNameCnt, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Service Name', prefixIcon: const Icon(Icons.content_cut, size: 18))),
            const SizedBox(height: 12),
            TextField(controller: serviceDurationCnt, keyboardType: TextInputType.number, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Duration (minutes)', prefixIcon: const Icon(Icons.timer, size: 18))),
            if (servicePhotoUrlCnt.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(DS.rLg), child: Image.network(servicePhotoUrlCnt.text, height: 140, width: double.infinity, fit: BoxFit.cover,
                loadingBuilder: (c, ch, p) => p == null ? ch : const ShimmerBox(height: 140, radius: DS.rLg))),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: PButton(text: 'Upload Photo', icon: Icons.photo_library_outlined, onPressed: () => pickUpload(shop: false), isOutlined: true)),
              const SizedBox(width: 10),
              Expanded(child: PButton(text: 'Add Service', icon: Icons.add, onPressed: addService, isGold: true)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        if (services.isNotEmpty)
          ...services.map((s) => _buildServiceItem(s, isDark))
        else
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: EmptyState(icon: Icons.content_cut, title: 'No Services', subtitle: 'Add your first service above'),
          ),
      ]),
    );
  }

  Widget _buildServiceItem(ShopService s, bool isDark) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DS.rMd),
          child: Container(
            height: 44, width: 44,
            decoration: BoxDecoration(gradient: s.enabled
                ? const LinearGradient(colors: [DS.primaryLight, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : const LinearGradient(colors: [DS.disabled, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: s.photoUrl.isEmpty
                ? Icon(Icons.content_cut, color: s.enabled ? DS.primary : DS.disabled, size: 20)
                : Image.network(s.photoUrl, fit: BoxFit.cover, errorBuilder: (c, e, _) => Icon(Icons.broken_image_outlined, color: isDark ? DS.darkMuted : DS.muted)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: s.enabled ? DS.inkC(context) : DS.disabled, letterSpacing: -0.2)),
            if (s.durationMinutes > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: DS.accentLight, borderRadius: BorderRadius.circular(DS.rSm), border: Border.all(color: DS.accent.withValues(alpha: 0.2))),
                child: Text('${s.durationMinutes} min', style: const TextStyle(color: DS.accent, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ],
          ]),
        ),
        const SizedBox(width: 6),
        _serviceActionBtn(
          child: Icon(s.enabled ? Icons.visibility : Icons.visibility_off, size: 16, color: s.enabled ? DS.success : DS.error),
          color: s.enabled ? DS.successLight : DS.errorLight,
          borderColor: (s.enabled ? DS.success : DS.error).withValues(alpha: 0.2),
          onPressed: () => toggleService(s),
        ),
        const SizedBox(width: 4),
        _serviceActionBtn(
          child: const Icon(Icons.edit_outlined, size: 16, color: DS.primary),
          color: DS.primaryVeryLight,
          borderColor: DS.primary.withValues(alpha: 0.15),
          onPressed: () => editService(s),
        ),
        const SizedBox(width: 4),
        _serviceActionBtn(
          child: const Icon(Icons.delete_outline, size: 16, color: DS.error),
          color: DS.errorLight,
          borderColor: DS.error.withValues(alpha: 0.15),
          onPressed: () {
            setState(() => services.remove(s));
            save(showMsg: false);
          },
        ),
      ]),
    );
  }

  Widget _serviceActionBtn({required Widget child, required Color color, required Color borderColor, required VoidCallback onPressed}) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(DS.rSm), border: Border.all(color: borderColor)),
      child: IconButton(icon: child, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 34, minHeight: 34), onPressed: onPressed),
    );
  }

  // ── SETTINGS TAB ──
  Widget _buildSettingsTab(Shop shop) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [DS.primaryDark, DS.primary, DS.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(DS.rXl),
            boxShadow: [DS.shadowPrimary],
          ),
          child: Stack(children: [
            Positioned(right: -26, top: -26, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
            Positioned(right: 26, bottom: -34, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: DS.accent.withValues(alpha: 0.4), width: 12)))),
            Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: Colors.white.withValues(alpha: 0.18))), child: const Icon(Icons.tune, color: DS.accent, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Shop Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text('Manage your salon availability & details', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              ])),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        _settingsSection(
          icon: Icons.storefront,
          title: 'Shop Status',
          subtitle: 'Control availability for customers',
          child: Row(children: [
            _statusPill(active: isOpen, activeLabel: 'Open', inactiveLabel: 'Closed', activeIcon: Icons.check_circle, inactiveIcon: Icons.cancel, onTap: () => setState(() => isOpen = !isOpen)),
            const SizedBox(width: 10),
            _statusPill(active: bookingsAvailable, activeLabel: 'Bookings On', inactiveLabel: 'Bookings Off', activeIcon: Icons.event_available, inactiveIcon: Icons.event_busy, onTap: () => setState(() => bookingsAvailable = !bookingsAvailable)),
          ]),
        ),
        const SizedBox(height: 16),
        _settingsSection(
          icon: Icons.badge_outlined,
          title: 'Basic Info',
          subtitle: 'Name, contact, address & GPS',
          child: Column(children: [
            TextField(controller: shopNameCnt, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Shop Name', prefixIcon: const Icon(Icons.store_outlined, size: 18))),
            const SizedBox(height: 12),
            TextField(controller: mobileCnt, keyboardType: TextInputType.phone, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Mobile', prefixIcon: const Icon(Icons.phone_outlined, size: 18))),
            const SizedBox(height: 12),
            TextField(controller: descriptionCnt, maxLines: 2, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Description', prefixIcon: const Icon(Icons.info_outline, size: 18))),
            const SizedBox(height: 12),
            TextField(controller: addressCnt, maxLines: 2, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Address', prefixIcon: const Icon(Icons.location_on_outlined, size: 18))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: locationCnt, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'GPS Coordinates', prefixIcon: const Icon(Icons.my_location, size: 18)))),
              const SizedBox(width: 10),
              loadingLoc
                  ? const SizedBox(height: 56, width: 56, child: Center(child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))))
                  : SizedBox(width: 110, height: 56, child: PButton(text: 'GPS', icon: Icons.gps_fixed, onPressed: getLocation, expanded: true, isOutlined: true, horizontalPadding: 12)),
            ]),
            if (lat != 0 || lng != 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: DS.successLight, borderRadius: BorderRadius.circular(DS.rLg), border: Border.all(color: DS.success.withValues(alpha: 0.3))),
                child: Row(children: [
                  const Icon(Icons.location_on, size: 18, color: DS.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}', style: const TextStyle(fontSize: 12, color: DS.success, fontWeight: FontWeight.w600))),
                  SizedBox(width: 100, height: 36, child: PButton(text: 'Map', icon: Icons.map_outlined, onPressed: openMap, expanded: true, isOutlined: true, horizontalPadding: 12)),
                ]),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        _settingsSection(
          icon: Icons.schedule,
          title: 'Working Hours',
          subtitle: 'Open & close time slots',
          child: Row(children: [
            Expanded(child: TextField(controller: openTimeCnt, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Open Time', prefixIcon: const Icon(Icons.wb_sunny_outlined, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: closeTimeCnt, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Close Time', prefixIcon: const Icon(Icons.nights_stay_outlined, size: 18)))),
          ]),
        ),
        const SizedBox(height: 16),
        _settingsSection(
          icon: Icons.event_available,
          title: 'Working Days',
          subtitle: 'Pick the days you accept bookings',
          child: Wrap(spacing: 8, runSpacing: 8, children: List.generate(7, (i) {
            final day = i + 1;
            final names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final selected = workingDays.contains(day);
            return ChoiceChip(
              label: Text(names[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : DS.inkC(context))),
              selected: selected,
              selectedColor: DS.primary,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: selected ? DS.primary : DS.borderC(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rMd)),
              onSelected: (v) { setState(() { if (v) { workingDays.add(day); } else { workingDays.remove(day); } }); },
            );
          })),
        ),
        const SizedBox(height: 16),
        _settingsSection(
          icon: Icons.event_seat_outlined,
          title: 'Chair Management',
          subtitle: 'Customers book based on available chairs per time slot',
          child: Column(children: [
            Row(children: [
              Expanded(child: Text('Total Chairs', style: TextStyle(fontSize: 13, color: DS.mutedC(context)))),
              _stepper(value: chairCount, min: 1, onChanged: (v) => setState(() => chairCount = v)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Text('Available Today', style: TextStyle(fontSize: 13, color: DS.mutedC(context)))),
              _stepper(value: _availableChairs > 0 ? _availableChairs : chairCount, min: 0, onChanged: (v) {
                setState(() {
                  _availableChairs = v;
                  _chairAvailabilityDate = DateTime.now().toIso8601String().substring(0, 10);
                });
              }),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        _settingsSection(
          icon: Icons.payments_outlined,
          title: 'Pricing',
          subtitle: 'Booking & premium service fees',
          child: Row(children: [
            Expanded(child: TextField(controller: bookingPriceCnt, keyboardType: TextInputType.number, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Booking Fee (Rs)', prefixIcon: const Icon(Icons.monetization_on_outlined, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: premiumBookingPriceCnt, keyboardType: TextInputType.number, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Premium Fee (Rs)', prefixIcon: const Icon(Icons.workspace_premium, size: 18)))),
          ]),
        ),
        const SizedBox(height: 16),
        _settingsSection(
          icon: Icons.photo_library_outlined,
          title: 'Media',
          subtitle: 'Shop photo & gallery',
          child: Column(children: [
            if (shopPhotoUrlCnt.text.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(DS.rLg),
                child: Image.network(shopPhotoUrlCnt.text, height: 160, width: double.infinity, fit: BoxFit.cover,
                  loadingBuilder: (c, ch, p) => p == null ? ch : const ShimmerBox(height: 160, radius: DS.rLg)),
              ),
              const SizedBox(height: 10),
            ],
            uploadingShop
                ? const SizedBox(height: 56, child: Center(child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))))
                : PButton(text: shopPhotoUrlCnt.text.isEmpty ? 'Add Photo' : 'Change Photo', icon: Icons.add_photo_alternate_outlined, onPressed: () => pickUpload(shop: true), isOutlined: true),
            const SizedBox(height: 10),
            PButton(text: 'Manage Gallery', icon: Icons.photo_library_outlined, onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerGalleryScreen(shop: shop, ownerId: widget.user.uid)));
            }, isOutlined: true),
          ]),
        ),
        const SizedBox(height: 16),
        _settingsSection(
          icon: Icons.language,
          title: 'Preferences',
          subtitle: 'App language',
          child: InkWell(
            onTap: () => LanguageBottomSheet.show(context),
            borderRadius: BorderRadius.circular(DS.rMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: DS.surfaceC(context), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: DS.borderC(context))),
              child: Row(children: [
                const Icon(Icons.language, size: 20, color: DS.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(l.language, style: TextStyle(fontWeight: FontWeight.w600, color: DS.inkC(context)))),
                Icon(Icons.chevron_right, size: 20, color: DS.mutedC(context)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        PButton(text: 'Save Settings', icon: Icons.save, onPressed: () => save(), isGold: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: DS.surfaceC(context), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: DS.borderC(context))),
          child: FeedbackSupportSection(user: widget.user),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: DS.surfaceC(context), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: DS.borderC(context))),
          child: MyTicketsSection(user: widget.user),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: DS.surfaceC(context), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: DS.borderC(context))),
          child: DeleteAccountTile(email: widget.user.email),
        ),
      ]),
    );
  }

  Widget _settingsSection({required IconData icon, required String title, String? subtitle, required Widget child}) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: DS.gradientPrimary, borderRadius: BorderRadius.circular(DS.rMd), boxShadow: [DS.shadowPrimary]), child: Icon(icon, size: 18, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DS.inkC(context), letterSpacing: -0.3)),
            if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 12, color: DS.mutedC(context)))],
          ])),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _stepper({required int value, required int min, required ValueChanged<int> onChanged}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: DS.surfaceC(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: DS.borderC(context))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.remove, size: 16), color: DS.primary, onPressed: value > min ? () => onChanged(value - 1) : null, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
        SizedBox(width: 44, child: Text('$value', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DS.inkC(context)))),
        IconButton(icon: const Icon(Icons.add, size: 16), color: DS.primary, onPressed: () => onChanged(value + 1), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
      ]),
    );
  }

  // ── NOTIFICATIONS BOTTOM SHEET ──
  void _showNotifications(BuildContext context) {
    final notifDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (c) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (c, scrollCtrl) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: ListView(controller: scrollCtrl, children: [
                Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: DS.disabled.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [DS.primaryDark, DS.primary, DS.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(DS.rLg),
                    boxShadow: [DS.shadowPrimary],
                  ),
                  child: Stack(children: [
                    Positioned(right: -20, top: -20, child: Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
                    Row(children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: Colors.white.withValues(alpha: 0.18))), child: const Icon(Icons.notifications_active, color: DS.accent, size: 20)),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
                StreamBuilder<List<AppNotification>>(
                  stream: svc.watchNotifications(widget.user.uid),
                  builder: (c, snap) {
                    final notifs = snap.data ?? [];
                    if (notifs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(children: [
                          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(DS.rXl)), child: Icon(Icons.notifications_off, size: 48, color: notifDark ? DS.darkMuted : DS.muted)),
                          const SizedBox(height: 20),
                          Text('All Clear', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: notifDark ? DS.darkInk : DS.ink)),
                          const SizedBox(height: 6),
                          Text('No notifications yet', style: TextStyle(color: notifDark ? DS.darkMuted : DS.muted, fontSize: 14)),
                        ]),
                      );
                    }
                    return Column(
                      children: notifs.map((n) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: n.read ? Colors.transparent : DS.primaryVeryLight,
                          borderRadius: BorderRadius.circular(DS.rLg),
                          border: n.read ? Border.all(color: notifDark ? DS.darkBorder.withValues(alpha: 0.3) : DS.border.withValues(alpha: 0.3)) : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: n.read ? (notifDark ? DS.darkMuted : DS.muted).withValues(alpha: 0.1) : DS.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DS.rMd)),
                            child: Icon(n.read ? Icons.notifications_outlined : Icons.notifications, color: n.read ? (notifDark ? DS.darkMuted : DS.muted) : DS.primary, size: 22),
                          ),
                          title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w700, color: notifDark ? DS.darkInk : DS.ink, fontSize: 14)),
                          subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(n.body, style: TextStyle(height: 1.35, color: notifDark ? DS.darkMuted : DS.muted, fontSize: 12))),
                          onTap: () => svc.markNotificationRead(n.id),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

class _PreferredTimesCard extends StatelessWidget {
  final Booking b;
  final String? selectedTime;
  final ValueChanged<String> onSelect;
  const _PreferredTimesCard({required this.b, this.selectedTime, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final times = [b.preferredTime1, b.preferredTime2, b.preferredTime3].where((t) => t.isNotEmpty).toList();
    if (times.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DS.primaryVeryLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(DS.rMd),
        border: Border.all(color: DS.primary.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Preferred Times', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DS.primary)),
          const Spacer(),
          if (selectedTime != null)
            Text('Tap another time to change', style: TextStyle(fontSize: 10, color: DS.mutedC(context))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _timeChip('1st', times.isNotEmpty ? times[0] : '', Colors.blue),
          const SizedBox(width: 8),
          _timeChip('2nd', times.length > 1 ? times[1] : '', Colors.teal),
          const SizedBox(width: 8),
          _timeChip('3rd', times.length > 2 ? times[2] : '', Colors.deepPurple),
        ]),
        if (b.scheduledDate.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today, size: 12, color: DS.primary),
            const SizedBox(width: 6),
            Text(b.scheduledDate, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DS.primary)),
          ]),
        ],
      ]),
    );
  }

  Widget _timeChip(String label, String time, Color color) {
    final selected = time.isNotEmpty && time == selectedTime;
    return Expanded(
      child: GestureDetector(
        onTap: time.isNotEmpty ? () => onSelect(time) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : color.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: selected ? Colors.white : color)),
              if (selected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, size: 11, color: Colors.white),
              ],
            ]),
            const SizedBox(height: 2),
            Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? Colors.white : color)),
          ]),
        ),
      ),
    );
  }
}

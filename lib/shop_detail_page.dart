import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:salon_app/l10n/app_localizations.dart';

import 'firebase_service.dart';
import 'image_system/domain/image_metadata.dart';
import 'image_system/presentation/widgets/swipe_gallery.dart';
import 'image_system/presentation/widgets/image_viewer.dart';
import 'models.dart';
import 'payment_page.dart';
import 'design_system.dart';
import 'utils/maps_utils.dart';
import 'widgets/premium_card.dart';
import 'widgets/premium_button.dart';
import 'widgets/section_header.dart';

class ShopDetailPage extends StatefulWidget {
  final Shop shop;
  final AppUser user;
  final double? userLat;
  final double? userLng;
  const ShopDetailPage({super.key, required this.shop, required this.user, this.userLat, this.userLng});
  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage> with SingleTickerProviderStateMixin {
  final svc = FirebaseService();
  late AnimationController _staggerCtrl;
  late Animation<double> _stagger;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _stagger = CurvedAnimation(parent: _staggerCtrl, curve: DS.easeOut);
    _staggerCtrl.forward();
  }

  @override
  void dispose() { _staggerCtrl.dispose(); super.dispose(); }

  Widget _buildStagger(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _staggerCtrl,
      builder: (c, _) {
        final t = ((_stagger.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 20 * (1 - Curves.easeOut.transform(t))), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final shop = widget.shop;
    final canBook = shop.isOpen && shop.bookingsAvailable;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: DS.pageC(context),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => _openGallery(context, shop),
                    child: shop.shopPhotoUrl.isNotEmpty
                        ? Hero(tag: 'shop_${shop.shopName}', child: CachedNetworkImage(imageUrl: shop.shopPhotoUrl, fit: BoxFit.cover, placeholder: (_, _) => _shopPlaceholder(), errorWidget: (_, _, _) => _shopPlaceholder()))
                        : _shopPlaceholder(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, DS.pageC(context)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(bottom: 16, left: 16, child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: shop.isOpen ? DS.gradientPrimary : const LinearGradient(colors: [Color(0xFF6B7280), Color(0xFF4B5563)]),
                        borderRadius: BorderRadius.circular(DS.rFull),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(shop.isOpen ? Icons.check_circle : Icons.cancel, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(shop.isOpen ? l.open : l.closed, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),

                  ])),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildStagger(0.0, Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Hero(tag: 'shop_name_${shop.shopName}', child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: DS.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DS.rLg)),
                    child: Center(child: Text(shop.shopName.isNotEmpty ? shop.shopName[0].toUpperCase() : 'S',
                      style: TextStyle(color: DS.primary, fontWeight: FontWeight.w900, fontSize: 24))),
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(shop.shopName, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: DS.inkC(context), letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
                        Icon(Icons.star_rounded, size: 18, color: DS.accent),
                        Text('4.8', style: TextStyle(fontWeight: FontWeight.w700, color: DS.accent, fontSize: 14)),
                        Text('(120+ reviews)', style: TextStyle(color: DS.mutedC(context), fontSize: 12)),
                      ]),
                    ]),
                  ),
                ])),
                const SizedBox(height: 20),
                if (shop.description.isNotEmpty) ...[
                  _buildStagger(0.1, Text(shop.description, maxLines: 6, overflow: TextOverflow.ellipsis, style: TextStyle(color: DS.mutedC(context), fontSize: 14, height: 1.6))),
                  const SizedBox(height: 20),
                ],
                _buildStagger(0.15, GlassCard(padding: const EdgeInsets.all(20), child: Column(children: [
                  _infoRow(Icons.access_time_rounded, '${shop.openTime} - ${shop.closeTime}'),
                  if (shop.workingDays.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: _infoRow(Icons.calendar_today_rounded, _workingDays(shop.workingDays))),
                  Padding(padding: const EdgeInsets.only(top: 10), child: GestureDetector(
                    onTap: hasValidCoordinates(shop) ? () => openInGoogleMapsFromShop(shop) : null,
                    child: _infoRow(Icons.location_on_rounded, shop.address.isNotEmpty ? shop.address : 'Location not set'),
                  )),
                ]))),
                if (hasValidCoordinates(shop)) ...[
                  const SizedBox(height: 16),
                  _buildStagger(0.17, _buildLocationSection(context, shop)),
                ],
                if (!canBook) ...[
                  const SizedBox(height: 16),
                  _buildStagger(0.18, Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DS.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DS.rLg),
                      border: Border.all(color: DS.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      Icon(!shop.isOpen ? Icons.cancel_rounded : Icons.event_busy_rounded, color: DS.error, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Text(!shop.isOpen ? '${l.shopClosed} — ${l.notifBookingsUnavailable}' : '${l.bookingsUnavailable} — ${l.notifBookingsUnavailable}',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: DS.error))),
                    ]),
                  )),
                ],
                const SizedBox(height: 24),
                _buildStagger(0.19, _PremiumBookingBanner(shop: shop, user: widget.user)),
                const SizedBox(height: 24),
                _buildStagger(0.2, SectionHeader(title: l.services, subtitle: l.chooseService, icon: Icons.content_cut_rounded)),
                const SizedBox(height: 16),
                ...shop.services.where((s) => s.enabled).toList().asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildStagger(0.25 + entry.key * 0.05, _ServiceCard(shop: shop, service: entry.value, user: widget.user, bookingsAvailable: canBook)),
                )),
                const SizedBox(height: 24),
                _buildStagger(0.5, SectionHeader(title: 'Gallery', subtitle: 'Photos of our salon', icon: Icons.photo_library_rounded)),
                const SizedBox(height: 16),
                _buildStagger(0.55, SwipeGallery(
                  images: _parseGalleryImages(shop),
                  height: 200,
                )),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),

    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 18, color: DS.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: DS.inkC(context), fontSize: 14))),
    ]);
  }

  String _workingDays(List<int> days) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => names.elementAt((d - 1) % 7)).join(', ');
  }

  Widget _shopPlaceholder() {
    final d = DS.isDark(context);
    return Container(
      color: d ? DS.darkCard : const Color(0xFFE8E8F0),
      child: Center(child: Icon(Icons.store_outlined, size: 64, color: d ? DS.darkMuted : DS.disabled)),
    );
  }

  void _openGallery(BuildContext context, Shop shop) {
    final images = <ImageMetadata>[];
    if (shop.shopPhotoUrl.isNotEmpty) {
      images.add(ImageMetadata(id: 'cover', thumbnailUrl: shop.shopPhotoUrl, downloadUrl: shop.shopPhotoUrl, createdAt: DateTime.now(), uploadedBy: ''));
    }
    final raw = shop.gallery;
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        images.add(ImageMetadata.fromMap(e));
      } else if (e is String) {
        images.add(ImageMetadata(id: e, thumbnailUrl: e, downloadUrl: e, createdAt: DateTime.now(), uploadedBy: ''));
      }
    }
    if (images.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewer(images: images)));
  }

  List<ImageMetadata> _parseGalleryImages(Shop shop) {
    final images = <ImageMetadata>[];
    final raw = shop.gallery;
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        images.add(ImageMetadata.fromMap(e));
      } else if (e is String) {
        images.add(ImageMetadata(id: e, thumbnailUrl: e, downloadUrl: e, createdAt: DateTime.now(), uploadedBy: ''));
      }
    }
    images.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return 0;
    });
    return images;
  }

  Widget _buildLocationSection(BuildContext context, Shop shop) {
    final dist = widget.userLat != null && widget.userLng != null
        ? calculateDistance(widget.userLat!, widget.userLng!, shop.latitude, shop.longitude)
        : null;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: DS.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(DS.rMd)),
            child: const Icon(Icons.map_rounded, size: 18, color: DS.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Location & Directions', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: DS.inkC(context)))),
          const SizedBox(width: 8),
          if (dist != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: DS.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DS.rFull)),
              child: Text(formatDistance(dist), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: DS.primary)),
            ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Icon(Icons.location_on, size: 16, color: DS.mutedC(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              shop.address.isNotEmpty ? shop.address : 'Address not available',
              style: TextStyle(fontSize: 13, color: DS.mutedC(context), fontWeight: FontWeight.w500),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => openInGoogleMapsFromShop(shop),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: DS.primary,
                  borderRadius: BorderRadius.circular(DS.rSm),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.directions, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Get Directions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Shop shop; final ShopService service; final AppUser user; final bool bookingsAvailable;
  const _ServiceCard({required this.shop, required this.service, required this.user, this.bookingsAvailable = true});

  void _showTimeSlotSheet(BuildContext context) {
    final svc = FirebaseService();
    final now = DateTime.now();
    final dates = List.generate(2, (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)));
    int selectedDateIdx = 0;
    final List<String?> selected = [null, null, null];
    Map<String, int> availableSlots = {};
    bool loadingSlots = false;
    String loadingDate = '';
    String loadedDate = '';
    bool loadScheduled = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (c) {
        return StatefulBuilder(builder: (c, setSheetState) {
          Future<void> loadSlots(String date) async {
            loadingDate = date;
            setSheetState(() => loadingSlots = true);
            try {
              final chairs = shop.availableChairs > 0 ? shop.availableChairs : shop.chairCount;
              final slots = await svc.getAvailableSlots(
                ownerId: shop.ownerId, date: date, chairCount: shop.chairCount,
                availableChairsOverride: chairs, openTime: shop.openTime, closeTime: shop.closeTime,
              );
              if (loadingDate != date || !c.mounted) return;
              setSheetState(() { availableSlots = slots; loadingSlots = false; loadedDate = date; selected..[0]=null..[1]=null..[2]=null; });
            } catch (_) {
              if (loadingDate != date || !c.mounted) return;
              setSheetState(() { availableSlots = {}; loadingSlots = false; loadedDate = date; });
            }
          }

          bool canSelect() => selected.any((s) => s == null);

          void toggleSlot(String slot) {
            final idx = selected.indexOf(slot);
            if (idx != -1) {
              selected[idx] = null;
              setSheetState(() {});
            } else if (canSelect()) {
              final next = selected.indexOf(null);
              selected[next] = slot;
              setSheetState(() {});
            }
          }

          final allSelected = selected.where((s) => s != null).length == 3;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.8,
              expand: false,
              builder: (c, scrollCtrl) {
                final dateStr = dates[selectedDateIdx].toIso8601String().substring(0, 10);
                if (!loadScheduled && loadedDate != dateStr) {
                  loadScheduled = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    loadScheduled = false;
                    if (c.mounted) loadSlots(dateStr);
                  });
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: ListView(
                    controller: scrollCtrl,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: DS.mutedC(context), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),
                      Text('Select Date & Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: DS.inkC(context))),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < dates.length; i++) ...[
                              if (i > 0) const SizedBox(width: 10),
                              Builder(builder: (c) {
                                final d = dates[i];
                                final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
                                final sel = i == selectedDateIdx;
                                return GestureDetector(
                                  onTap: () {
                                    setSheetState(() { selectedDateIdx = i; availableSlots = {}; loadedDate = ''; });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: sel ? DS.gradientPrimary : null,
                                      color: sel ? null : DS.surfaceC(c),
                                      borderRadius: BorderRadius.circular(14),
                                      border: sel ? null : Border.all(color: DS.borderC(c)),
                                    ),
                                    child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                        Text(isToday ? 'Today' : dayNames[d.weekday - 1], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isToday ? DS.accent : (sel ? Colors.white70 : DS.mutedC(c)))),
                                        if (isToday && sel) ...[
                                          const SizedBox(width: 3),
                                          const Icon(Icons.star, size: 9, color: DS.accent),
                                        ],
                                      ]),
                                      Text('${d.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: sel ? Colors.white : DS.inkC(c))),
                                    ]),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: DS.accentLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.info_outline, size: 18, color: DS.accent),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Select your top 3 preferred appointment times. The shop owner will confirm the most suitable one.', style: TextStyle(fontSize: 12, color: DS.accent, height: 1.4))),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Text('Your Preferences', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DS.inkC(context))),
                      const SizedBox(height: 10),
                      Row(children: [
                        _prefChip(context, '1st', selected[0], Colors.blue, () { if (selected[0] != null) { selected[0] = null; setSheetState(() {}); } }),
                        const SizedBox(width: 8),
                        _prefChip(context, '2nd', selected[1], Colors.teal, () { if (selected[1] != null) { selected[1] = null; setSheetState(() {}); } }),
                        const SizedBox(width: 8),
                        _prefChip(context, '3rd', selected[2], Colors.deepPurple, () { if (selected[2] != null) { selected[2] = null; setSheetState(() {}); } }),
                      ]),
                      const SizedBox(height: 20),
                      Text('Available Slots', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DS.inkC(context))),
                      const SizedBox(height: 12),
                      if (loadingSlots)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))))
                      else if (availableSlots.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: DS.surfaceC(context), borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Text('No available slots for this date', style: TextStyle(color: DS.mutedC(context)))),
                        )
                      else
                        Wrap(
                          spacing: 10, runSpacing: 10,
                          children: availableSlots.entries.map((e) {
                            final inSel = selected.indexOf(e.key);
                            bool isSelected = inSel != -1;
                            return GestureDetector(
                              onTap: () => toggleSlot(e.key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? DS.gradientPrimary : null,
                                  color: isSelected ? null : DS.surfaceC(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected ? null : Border.all(color: DS.borderC(context)),
                                ),
                                child: Column(children: [
                                  Text(e.key, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isSelected ? Colors.white : DS.inkC(context))),
                                  if (isSelected)
                                    Text(['1st', '2nd', '3rd'][inSel], style: const TextStyle(fontSize: 10, color: Colors.white70))
                                  else
                                    Text('${e.value} chair${e.value > 1 ? 's' : ''}', style: TextStyle(fontSize: 11, color: DS.mutedC(context))),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),
                      PButton(
                        text: 'Continue to Payment',
                        icon: Icons.arrow_forward,
                        isGold: true,
                        onPressed: !allSelected ? null : () {
                          Navigator.pop(c);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(
                            shop: shop, service: service, user: user,
                            scheduledDate: dateStr,
                            preferredTime1: selected[0]!,
                            preferredTime2: selected[1]!,
                            preferredTime3: selected[2]!,
                          )));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        });
      },
    );
  }

  Widget _prefChip(BuildContext context, String label, String? time, Color color, VoidCallback onRemove) {
    return Expanded(
      child: GestureDetector(
        onTap: time != null ? onRemove : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: time != null ? color.withValues(alpha: 0.15) : DS.surfaceC(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: time != null ? color : DS.borderC(context)),
          ),
          child: Column(children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: time != null ? color : DS.mutedC(context))),
            const SizedBox(height: 4),
            Text(time ?? '—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: time != null ? color : DS.mutedC(context))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final canBook = bookingsAvailable;
    return AnimatedCard(
      onTap: canBook
          ? () => _showTimeSlotSheet(context)
          : () { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.shopClosed), behavior: SnackBarBehavior.floating)); },
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: DS.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DS.rLg)),
            child: service.photoUrl.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(DS.rLg), child: CachedNetworkImage(imageUrl: service.photoUrl, fit: BoxFit.cover,
                    placeholder: (_, _) => const Icon(Icons.image_outlined, color: DS.primary),
                    errorWidget: (_, _, _) => const Icon(Icons.broken_image, color: DS.primary)))
                : const Icon(Icons.content_cut_rounded, color: DS.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(service.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: DS.inkC(context)))),
              if (service.durationMinutes > 0)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: DS.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('${service.durationMinutes}${l.minutes}', style: TextStyle(color: DS.primary, fontWeight: FontWeight.w700, fontSize: 10))),
            ]),
            const SizedBox(height: 4),
            Text('\u20B9${service.price}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: DS.inkC(context))),
          ])),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DS.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(DS.rMd)),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: DS.primary),
          ),
        ]),
      ),
    );
  }
}

class _PremiumBookingBanner extends StatelessWidget {
  final Shop shop;
  final AppUser user;
  const _PremiumBookingBanner({required this.shop, required this.user});

  @override
  Widget build(BuildContext context) {
    final canBook = shop.isOpen && shop.bookingsAvailable;
    final fee = shop.premiumBookingPrice > 0 ? shop.premiumBookingPrice : shop.bookingPrice;
    return GestureDetector(
      onTap: () {
        if (!canBook) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.shopClosed), behavior: SnackBarBehavior.floating));
          return;
        }
        _showPremiumSlotSheet(context, shop: shop, user: user);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: DS.gradientGold,
          borderRadius: BorderRadius.circular(DS.rXl),
          boxShadow: [DS.shadowGold],
        ),
        child: Stack(children: [
          Positioned(right: -24, top: -24, child: Container(width: 96, height: 96, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)))),
          Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(DS.rLg)), child: const Icon(Icons.workspace_premium, color: Colors.white, size: 26)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Premium Booking', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
              const SizedBox(height: 2),
              Text('Pick your exact day & time and book instantly', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(DS.rFull)),
              child: Text('Rs $fee', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
          ]),
        ]),
      ),
    );
  }
}

Future<void> _showPremiumSlotSheet(BuildContext context, {required Shop shop, required AppUser user}) async {
  final svc = FirebaseService();
  final now = DateTime.now();
  final dates = List.generate(7, (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)));
  final services = shop.services.where((s) => s.enabled).toList();
  if (services.isEmpty) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No services available'), behavior: SnackBarBehavior.floating));
    return;
  }
  int serviceIdx = 0;
  int selectedDateIdx = 0;
  String? selectedSlot;
  Map<String, int> availableSlots = {};
  bool loadingSlots = false;
  String loadingDate = '';
  String loadedDate = '';
  bool loadScheduled = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) {
      return StatefulBuilder(builder: (c, setSheetState) {
        Future<void> loadSlots(String date) async {
          loadingDate = date;
          setSheetState(() => loadingSlots = true);
          try {
            final chairs = shop.availableChairs > 0 ? shop.availableChairs : shop.chairCount;
            final slots = await svc.getAvailableSlots(
              ownerId: shop.ownerId, date: date, chairCount: shop.chairCount,
              availableChairsOverride: chairs, openTime: shop.openTime, closeTime: shop.closeTime,
            );
            if (loadingDate != date || !c.mounted) return;
            setSheetState(() { availableSlots = slots; loadingSlots = false; loadedDate = date; selectedSlot = null; });
          } catch (_) {
            if (loadingDate != date || !c.mounted) return;
            setSheetState(() { availableSlots = {}; loadingSlots = false; loadedDate = date; selectedSlot = null; });
          }
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (c, scrollCtrl) {
              final dateStr = dates[selectedDateIdx].toIso8601String().substring(0, 10);
              if (!loadScheduled && loadedDate != dateStr) {
                loadScheduled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  loadScheduled = false;
                  if (c.mounted) loadSlots(dateStr);
                });
              }
              final premiumFee = shop.premiumBookingPrice > 0 ? shop.premiumBookingPrice : shop.bookingPrice;

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: DS.mutedC(c), borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Row(children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: DS.gradientGold, borderRadius: BorderRadius.circular(DS.rMd), boxShadow: [DS.shadowGold]), child: const Icon(Icons.workspace_premium, color: Colors.white, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Premium Booking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: DS.ink)),
                        const SizedBox(height: 2),
                        Text('Pick your exact day & time', style: TextStyle(fontSize: 12.5, color: DS.mutedC(c))),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    Text('Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DS.inkC(c))),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: services.asMap().entries.map((e) {
                      final sel = e.key == serviceIdx;
                      return GestureDetector(
                        onTap: () => setSheetState(() => serviceIdx = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: sel ? DS.gradientGold : null,
                            color: sel ? null : DS.surfaceC(c),
                            borderRadius: BorderRadius.circular(DS.rMd),
                            border: sel ? null : Border.all(color: DS.borderC(c)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.content_cut, size: 14, color: sel ? Colors.white : DS.mutedC(c)),
                            const SizedBox(width: 6),
                            Text(e.value.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : DS.inkC(c))),
                          ]),
                        ),
                      );
                    }).toList()),
                    const SizedBox(height: 16),
                    Text('Select Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DS.inkC(c))),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (var i = 0; i < dates.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Builder(builder: (c) {
                            final d = dates[i];
                            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
                            final sel = i == selectedDateIdx;
                            return GestureDetector(
                              onTap: () => setSheetState(() { selectedDateIdx = i; availableSlots = {}; loadedDate = ''; selectedSlot = null; }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: sel ? DS.gradientPrimary : null,
                                  color: sel ? null : DS.surfaceC(c),
                                  borderRadius: BorderRadius.circular(14),
                                  border: sel ? null : Border.all(color: DS.borderC(c)),
                                ),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text(isToday ? 'Today' : dayNames[d.weekday - 1], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sel ? Colors.white70 : DS.mutedC(c))),
                                  const SizedBox(height: 2),
                                  Text('${d.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: sel ? Colors.white : DS.inkC(c))),
                                ]),
                              ),
                            );
                          }),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Text('Pick Your Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DS.inkC(c))),
                    const SizedBox(height: 10),
                    if (loadingSlots)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))))
                    else if (availableSlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: DS.surfaceC(c), borderRadius: BorderRadius.circular(16)),
                        child: Center(child: Text('No available slots for this date', style: TextStyle(color: DS.mutedC(c), fontSize: 13))),
                      )
                    else
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: availableSlots.entries.map((e) {
                          final isSelected = e.key == selectedSlot;
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedSlot = e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected ? DS.gradientGold : null,
                                color: isSelected ? null : DS.surfaceC(c),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected ? null : Border.all(color: DS.borderC(c)),
                              ),
                              child: Column(children: [
                                Text(e.key, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isSelected ? Colors.white : DS.inkC(c))),
                                Text(isSelected ? 'YOUR SLOT' : '${e.value} chair${e.value > 1 ? 's' : ''}', style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : DS.mutedC(c))),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: DS.accentLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.info_outline, size: 18, color: DS.accent),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Pay Rs $premiumFee to reserve your slot. The owner will confirm it or mark it not available.', style: const TextStyle(fontSize: 12, color: DS.accent, height: 1.4))),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    PButton(
                      text: 'Continue to Payment',
                      icon: Icons.arrow_forward,
                      isGold: true,
                      onPressed: selectedSlot == null ? null : () {
                        Navigator.pop(c);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(
                          shop: shop, service: services[serviceIdx], user: user,
                          scheduledDate: dateStr,
                          preferredTime1: selectedSlot!,
                          preferredTime2: '',
                          preferredTime3: '',
                          isPremium: true,
                        )));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      });
    },
  );
}



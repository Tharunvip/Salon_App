import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../design_system.dart';
import '../models.dart';
import '../utils/maps_utils.dart';
import 'premium_card.dart';

class ShopCard extends StatelessWidget {
  final Shop shop;
  final double? userLat, userLng;
  final VoidCallback onTap;
  final Set<String> favouriteShopIds;
  final ValueChanged<String>? onToggleFavourite;

  const ShopCard({super.key, required this.shop, this.userLat, this.userLng, required this.onTap, this.favouriteShopIds = const {}, this.onToggleFavourite});

  @override
  Widget build(BuildContext context) {
    final d = DS.isDark(context);
    final dist = userLat != null && userLng != null ? calculateDistance(userLat!, userLng!, shop.latitude, shop.longitude) : null;

    return AnimatedCard(
      margin: const EdgeInsets.only(bottom: DS.md),
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(DS.rXl)),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: shop.shopPhotoUrl,
                  fit: BoxFit.cover,
                  placeholder: (c, _) => Container(color: d ? DS.darkBorder : DS.border),
                  errorWidget: (c, _, _) => Container(color: d ? DS.darkBorder : DS.border, child: Center(child: Icon(Icons.store, color: DS.mutedC(c), size: 40))),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                  ),
                ),
              ),
            ),
            if (dist != null)
              Positioned(top: 12, left: 12, child: _badge(Icons.location_on, '${dist.toStringAsFixed(1)} km', (d ? DS.darkSurface : DS.surface).withValues(alpha: 0.9), d ? DS.darkInk : DS.ink)),
            if (onToggleFavourite != null)
              Positioned(top: 12, right: 12, child: _favouriteButton(d)),
            Positioned(bottom: 12, left: 12, right: 12,
              child: Row(children: [
                Expanded(
                  child: Text(shop.shopName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
                const SizedBox(width: 8),
                _statusBadge(),
              ]),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(DS.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.star_rounded, size: 18, color: DS.accent),
              const SizedBox(width: 4),
              Text('4.5', style: TextStyle(fontWeight: FontWeight.w700, color: DS.inkC(context))),
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 16, color: DS.mutedC(context)),
              const SizedBox(width: 4),
              Flexible(child: Text('${shop.openTime} - ${shop.closeTime}', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 12, color: DS.mutedC(context)))),
              const Spacer(),
              if (shop.isOpen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: DS.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DS.rSm)),
                  child: Text('OPEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: DS.success, letterSpacing: 0.5)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: DS.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DS.rSm)),
                  child: Text('CLOSED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: DS.error, letterSpacing: 0.5)),
                ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _stat(context, Icons.build, '${shop.services.length} services')),
              const SizedBox(width: 16),
              Expanded(child: _stat(context, Icons.currency_rupee, '${shop.bookingPrice}')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _directionsButton(context, d)),
              if (dist != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: DS.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DS.rSm),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.near_me, size: 13, color: DS.primary),
                      const SizedBox(width: 4),
                      Text(formatDistance(dist), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DS.primary)),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _directionsButton(BuildContext context, bool isDark) {
    final hasCoords = hasValidCoordinates(shop);
    return GestureDetector(
      onTap: hasCoords
          ? () async {
              await openInGoogleMapsFromShop(shop);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: hasCoords ? DS.primary.withValues(alpha: 0.1) : DS.disabled.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DS.rSm),
          border: Border.all(
            color: hasCoords ? DS.primary.withValues(alpha: 0.25) : DS.disabled.withValues(alpha: 0.15),
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            hasCoords ? Icons.directions : Icons.location_off,
            size: 15,
            color: hasCoords ? DS.primary : DS.disabled,
          ),
          const SizedBox(width: 6),
          Text(
            hasCoords ? 'Directions' : 'Location Unavailable',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: hasCoords ? DS.primary : DS.disabled,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(DS.rFull)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }

  Widget _favouriteButton(bool isDark) {
    final isFav = favouriteShopIds.contains(shop.ownerId);
    return GestureDetector(
      onTap: () => onToggleFavourite?.call(shop.ownerId),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? DS.darkSurface : DS.surface).withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(isFav ? Icons.favorite : Icons.favorite_border, size: 20, color: isFav ? DS.gold : (isDark ? DS.darkInk : DS.ink)),
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: shop.isOpen ? DS.gradientPrimary : const LinearGradient(colors: [Color(0xFF6B7280), Color(0xFF4B5563)]),
        borderRadius: BorderRadius.circular(DS.rFull),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(shop.isOpen ? Icons.check_circle : Icons.cancel, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(shop.isOpen ? 'Open' : 'Closed', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _stat(BuildContext ctx, IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: DS.mutedC(ctx)),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, color: DS.mutedC(ctx), fontWeight: FontWeight.w500)),
    ]);
  }

}

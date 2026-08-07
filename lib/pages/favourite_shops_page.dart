import 'package:flutter/material.dart';

import '../firebase_service.dart';
import '../models.dart';
import '../shop_detail_page.dart';
import '../widgets/premium_nav.dart';
import '../widgets/shop_card.dart';
import '../widgets/shimmer.dart';
import '../widgets/empty_state.dart';

class FavouriteShopsPage extends StatefulWidget {
  final AppUser user;
  final double? userLat, userLng;
  const FavouriteShopsPage({super.key, required this.user, this.userLat, this.userLng});
  @override
  State<FavouriteShopsPage> createState() => _FavouriteShopsPageState();
}

class _FavouriteShopsPageState extends State<FavouriteShopsPage> {
  final svc = FirebaseService();

  Future<void> _toggle(String shopId, Set<String> currentFavs) async {
    if (currentFavs.contains(shopId)) {
      await svc.removeFavouriteShop(widget.user.uid, shopId);
    } else {
      await svc.addFavouriteShop(widget.user.uid, shopId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FloatingAppBar(title: 'Favourite Shops'),
      body: StreamBuilder<List<String>>(
        stream: svc.watchFavouriteShopIds(widget.user.uid),
        builder: (c, favSnap) {
          final favs = (favSnap.data ?? const <String>[]).toSet();
          return StreamBuilder<List<Shop>>(
            stream: svc.watchShops(),
            builder: (c, shopSnap) {
              if (!shopSnap.hasData) return const ShimmerList(itemHeight: 280);
              final shops = shopSnap.data!.where((s) => s.accessStatus == 'granted' && favs.contains(s.ownerId)).toList();
              if (shops.isEmpty) {
                return const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'No favourite shops yet',
                  subtitle: 'Tap the heart on any salon to save it here and skip the search next time.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: shops.length,
                itemBuilder: (c, i) {
                  final shop = shops[i];
                  return ShopCard(
                    shop: shop,
                    userLat: widget.userLat,
                    userLng: widget.userLng,
                    favouriteShopIds: favs,
                    onToggleFavourite: (id) => _toggle(id, favs),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailPage(shop: shop, user: widget.user, userLat: widget.userLat, userLng: widget.userLng))),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

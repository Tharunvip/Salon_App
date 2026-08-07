import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';

const double _earthRadiusKm = 6371;

bool hasValidCoordinates(Shop shop) {
  return shop.latitude != 0 || shop.longitude != 0;
}

double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return _earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRad(double deg) => deg * (math.pi / 180);

String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.round()} km';
}

Future<void> openInGoogleMaps(double lat, double lng) async {
  final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';

  final uri = Uri.parse(googleMapsUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    final fallback = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }
}

Future<void> openInGoogleMapsFromShop(Shop shop) async {
  if (!hasValidCoordinates(shop)) return;
  await openInGoogleMaps(shop.latitude, shop.longitude);
}

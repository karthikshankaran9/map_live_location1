// favorite_place.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FavoritePlace {
  final String id;
  final String name;
  final LatLng latLng;
  final String imageUrl;
  final String description;

  FavoritePlace({
    required this.id,
    required this.name,
    required this.latLng,
    required this.imageUrl,
    required this.description,
  });
}

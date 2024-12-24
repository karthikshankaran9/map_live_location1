import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:map/mapScreenPage/place_detail_page.dart';
import 'package:map/models/favorite_place.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Location controller to handle location services
  final Location _locationController = Location();
  final List<LatLng> _locations = []; // Stores live location coordinates
  final Map<String, BitmapDescriptor> _customMarkers = {}; // Custom markers for favorite places

  BitmapDescriptor? markerIcon; // Custom marker for live location
  late StreamSubscription<LocationData> _locationSubscription; // Location updates subscription
  bool isFullScreen = false; // Tracks full-screen map view state

  // List of favorite places
  final List<FavoritePlace> favoritePlaces = [
    FavoritePlace(
      id: '1',
      name: 'Santhome Cathedral Basilica',
      latLng: LatLng(13.03385, 80.27780),
      imageUrl: 'https://lh5.googleusercontent.com/p/AF1QipNkk27_3l_g4tK9xCTAS-MqjDtzL8wxPJ8N0Lch=w408-h725-k-no',
      description: 'Santhome Cathedral Basilica in Chennai is a must-visit destination for anyone interested in history, architecture, or spirituality.',
    ),
    FavoritePlace(
      id: '2',
      name: 'Marina Beach',
      latLng: LatLng(13.05738, 80.28613),
      imageUrl: 'https://lh5.googleusercontent.com/p/AF1QipOe0EVXkHRA-Kge8AgDBPH2p2t6KTNV86WVCOS7=w408-h306-k-no',
      description: 'Very good and biggest beach in India and South Asia. Marina Beach, or simply the Marina, is a natural urban beach in Chennai.',
    ),
    FavoritePlace(
      id: '3',
      name: 'Dr. M.G. Ramachandran Central Railway Station (Chennai)',
      latLng: LatLng(13.08337, 80.27557),
      imageUrl: 'https://lh5.googleusercontent.com/p/AF1QipPguY7_mH9pn84VhNAgskjmp-BXp3P9MzNwT9u0=w427-h240-k-no',
      description: 'Center of Chennai. Metro service, local train service, and city bus service are available.',
    ),
    FavoritePlace(
      id: '4',
      name: 'Kapaleeshwarar Temple',
      latLng: LatLng(13.03389, 80.26972),
      imageUrl: 'https://lh5.googleusercontent.com/p/AF1QipOKRixnXb7PwhyynBqHy79E6_HUcl41pfjv_vJY=w408-h544-k-no',
      description: 'Kapaleeshwar Temple is a place where you can truly feel the divine energy.',
    ),
    FavoritePlace(
      id: '5',
      name: 'Marina Mall',
      latLng: LatLng(12.83621, 80.22952),
      imageUrl: 'https://lh5.googleusercontent.com/p/AF1QipOZMcXn7aW1u_Z-lq1cIY26M5QeXm3jlExkbpgP=w408-h306-k-no',
      description: 'Vibrant complex of shops & services, featuring a food court, hypermarket & multiplex cinema.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    getLocationUpdates(); // Start listening for location updates
    generateCustomIcons(); // Generate custom markers for favorite places
  }

  @override
  void dispose() {
    _locationSubscription.cancel(); // Stop location updates
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox.expand(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onDoubleTap: () {
                  setState(() {
                    isFullScreen = !isFullScreen; // Toggle full-screen map
                  });
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _locations.isNotEmpty
                          ? _locations.first
                          : LatLng(0, 0),
                      zoom: 15,
                    ),
                    myLocationEnabled: true, // Enable current location
                    zoomControlsEnabled: false,
                    markers: {
                      // Markers for live locations
                      ..._locations.map(
                        (location) => Marker(
                          markerId: MarkerId(location.toString()),
                          icon: markerIcon ?? BitmapDescriptor.defaultMarker,
                          position: location,
                        ),
                      ),
                      // Markers for favorite places
                      ...favoritePlaces.map(
                        (place) => Marker(
                          markerId: MarkerId(place.id),
                          position: place.latLng,
                          icon: _customMarkers[place.id] ?? BitmapDescriptor.defaultMarker,
                          infoWindow: InfoWindow(
                            title: place.name,
                            snippet: 'Tap for details',
                          ),
                          onTap: () => _showPlaceDetails(context, place),
                        ),
                      ),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate custom icons for favorite places
  Future<void> generateCustomIcons() async {
    for (final place in favoritePlaces) {
      final icon = await _createCustomMarker(place.imageUrl);
      _customMarkers[place.id] = icon;
    }
    setState(() {}); // Update UI after generating markers
  }

  /// Create a custom marker from a network image
  Future<BitmapDescriptor> _createCustomMarker(String imageUrl) async {
    final http.Response response = await http.get(Uri.parse(imageUrl));
    final Uint8List imageData = response.bodyBytes;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint();

    const double size = 150;
    final Radius radius = Radius.circular(size / 2);

    // Draw circular background
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint..color = Colors.white,
    );

    // Draw network image
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageData,
      targetWidth: size.toInt(),
      targetHeight: size.toInt(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;
    paint.shader = ui.ImageShader(
      image,
      ui.TileMode.clamp,
      ui.TileMode.clamp,
      Matrix4.identity().storage,
    );
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    final ui.Image markerImage = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await markerImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(pngBytes);
  }

  /// Create a custom circular marker from an asset image
  Future<BitmapDescriptor> _createCircularMarker(String assetPath) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 150.0;

    final ByteData imageData = await rootBundle.load(assetPath);
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: size.toInt(),
      targetHeight: size.toInt(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    // Draw white circle background
    Paint paint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Clip image into circle and draw
    paint = Paint();
    final Path path = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size / 2, size / 2),
        radius: size / 2,
      ));
    canvas.clipPath(path);
    canvas.drawImage(image, Offset.zero, paint);

    final ui.Image markerImage = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await markerImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List markerBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(markerBytes);
  }

  /// Start location updates and add custom marker for live location
  Future<void> getLocationUpdates() async {
    _locationSubscription = _locationController.onLocationChanged.listen(
      (LocationData location) async {
        if (location.latitude != null && location.longitude != null) {
          BitmapDescriptor liveLocationMarker =
              await _createCircularMarker('assets/images/image.png');

          setState(() {
            _locations.add(LatLng(location.latitude!, location.longitude!));
            markerIcon = liveLocationMarker;
          });
        }
      },
    );
  }

  /// Show place details in a bottom sheet
  void _showPlaceDetails(BuildContext context, FavoritePlace place) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            place.imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          ListTile(
            title: Text(place.name),
            subtitle: Text(place.description),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceDetailPage(
                  place: place,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

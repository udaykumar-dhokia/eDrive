import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenroute/components/station_detail/station_details.dart';
import 'package:greenroute/constants/color/colors.dart';
import 'package:greenroute/screens/search/search.dart';
import 'package:latlong2/latlong.dart';

class CityMap extends StatefulWidget {
  String city;
  String image;
  CityMap({super.key, required this.city, required this.image});

  @override
  State<CityMap> createState() => _CityMapState();
}

class _CityMapState extends State<CityMap> {
  final MapController _mapController = MapController();
  final LatLng currentPosition = const LatLng(23.0225, 72.5714);
  bool isLoading = false;
  final List<Marker> _markers = [];
  LatLng? cityCenter;
  LatLngBounds? cityBounds;
  double _currentZoom = 12.0;
  List<Map<String, dynamic>> _cityStations = [];

  final Map<String, Map<String, LatLng>> cityCoordinates = {
    "Ahmedabad": {
      "center": const LatLng(23.0225, 72.5714),
      "southwest": const LatLng(22.8755, 72.5250),
      "northeast": const LatLng(23.1255, 72.6750),
    },
    "Porbandar": {
      "center": const LatLng(21.6417, 69.6293),
      "southwest": const LatLng(21.5917, 69.5793),
      "northeast": const LatLng(21.6917, 69.6793),
    },
  };

  void _loadStations() async {
    var firestore = FirebaseFirestore.instance;
    var stationsSnapshot = await firestore
        .collection('stations')
        .where("city", isEqualTo: widget.city)
        .get();

    final List<Marker> markers = [];
    final List<Map<String, dynamic>> nearbyStations = [];

    setState(() {
      isLoading = true;
    });

    for (var doc in stationsSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      double latitude = data['latitude'];
      double longitude = data['longitude'];
      String name = data['name'] ?? 'No Name';

      nearbyStations.add({
        'name': name,
        "latitude": latitude,
        "longitude": longitude,
        "address": data["Address"],
        "city": data["city"],
        "state": data["State"],
        "contact": data["contact"] ?? "-"
      });

      markers.add(
        Marker(
          point: LatLng(latitude, longitude),
          width: 80.0,
          height: 80.0,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              showStationDetails(context, data);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.black,
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.ev_station_rounded,
                    color: primary,
                    size: 25,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    setState(() {
      _markers.addAll(markers);
    });
    setState(() {
      isLoading = false;
    });
    setState(() {
      _cityStations = nearbyStations;
    });
  }

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
    });
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
    });
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _goToCurrentLocation() async {
    _mapController.move(
      LatLng(currentPosition.latitude, currentPosition.longitude),
      12,
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadStations();
    if (cityCoordinates.containsKey(widget.city)) {
      cityCenter = cityCoordinates[widget.city]!["center"];
      cityBounds = LatLngBounds(
        cityCoordinates[widget.city]!["southwest"]!,
        cityCoordinates[widget.city]!["northeast"]!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const Search(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: const Icon(
            Icons.close_rounded,
            color: white,
          ),
        ),
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        backgroundColor: primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'eDrive',
              style: GoogleFonts.quicksand(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: white,
                ),
              ),
            ),
            Text(
              "*Click on station for more details.",
              style: GoogleFonts.quicksand(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: white,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Stack(children: [
          Container(
            height: MediaQuery.sizeOf(context).height,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                maxZoom: 100,
                keepAlive: true,
                backgroundColor: primary.withOpacity(0.2),
                minZoom: 10,
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: cityBounds!,
                ),
                initialCenter: cityCenter!,
                initialZoom: _currentZoom,
              ),
              children: [
                TileLayer(
                  tileDisplay: const TileDisplay.fadeIn(),
                  urlTemplate:
                      "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                ),
                MarkerLayer(
                  rotate: true,
                  markers: _markers,
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: CachedNetworkImageProvider(widget.image),
                ),
                Text(
                  widget.city,
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  foregroundColor: Colors.white,
                  backgroundColor: primary,
                  mini: true,
                  shape: const CircleBorder(),
                  onPressed: _goToCurrentLocation,
                  child: const Icon(
                    Icons.location_searching_rounded,
                    size: 15,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  foregroundColor: Colors.white,
                  backgroundColor: primary,
                  mini: true,
                  shape: const CircleBorder(),
                  onPressed: _zoomIn,
                  child: const Icon(
                    Icons.zoom_in,
                    size: 15,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  foregroundColor: Colors.white,
                  backgroundColor: primary,
                  mini: true,
                  shape: const CircleBorder(),
                  onPressed: _zoomOut,
                  child: const Icon(
                    Icons.zoom_out,
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

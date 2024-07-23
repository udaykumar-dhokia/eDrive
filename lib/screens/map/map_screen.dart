import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenroute/components/appbar/appbar.dart';
import 'package:greenroute/components/station_detail/station_details.dart';
import 'package:greenroute/constants/color/colors.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Position currentPosition;
  final List<Marker> _markers = [];
  final List<Map<String, dynamic>> _nearbyStations = [];
  double _currentZoom = 13.0;
  final MapController _mapController = MapController();
  bool isLoading = false;
  bool dark = false;
  String mode = "light_all";
  bool isStationLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadStations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        Timer(const Duration(seconds: 2), (){
          showDownloadAlert(context);
        });
      }
    });
  }

  void showDownloadAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Row(
            children: [
              const CircleAvatar(backgroundImage: AssetImage("lib/assets/logo.png"),),
              const SizedBox(width: 10,),
              Text('eDrive App', style: GoogleFonts.quicksand(fontWeight: FontWeight.w500),),
            ],
          ),
          content: Text('The eDrive app is also available on mobile. Download now!', style: GoogleFonts.quicksand(),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Later', style: GoogleFonts.quicksand(color: primary, fontWeight: FontWeight.w500),),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor:  WidgetStateProperty.all<Color>(Colors.green),
              ),
              onPressed: () {
                final url = 'https://your-download-link.com';
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                Navigator.of(context).pop();
              },
              child: Text('Download', style: GoogleFonts.quicksand(color: white, fontWeight: FontWeight.w700),),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    setState(() {
      isLoading = true;
    });

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _markers.add(
      Marker(
        point: LatLng(position.latitude, position.longitude),
        width: 80.0,
        height: 80.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2.0),
              child: const Icon(
                Icons.location_on,
                color: primary,
                size: 30,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  "Your location",
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    setState(() {
      currentPosition = position;
    });
    setState(() {
      isLoading = false;
    });
  }

  void _loadStations() async {
    var firestore = FirebaseFirestore.instance;
    var stationsSnapshot = await firestore.collection('stations').get();

    final List<Marker> markers = [];
    final List<Map<String, dynamic>> nearbyStations = [];

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      isStationLoading = true;
    });

    for (var doc in stationsSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      double latitude = data['latitude'];
      double longitude = data['longitude'];
      String name = data['name'] ?? 'No Name';

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );

      if (distanceInMeters <= 5000) {
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
                        style:
                            const TextStyle(fontSize: 10, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        nearbyStations.add({
          'name': name,
          "latitude": latitude,
          "longitude": longitude,
          'distance': (distanceInMeters / 1000),
          "address": data["Address"],
        });
      }
    }

    setState(() {
      _markers.addAll(markers);
      _nearbyStations.clear();
      _nearbyStations.addAll(nearbyStations);
    });
    setState(() {
      isStationLoading = false;
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
      13,
    );
  }

  Future<void> _launchMaps(double startLat, double startLng, double endLat,
      double endLng, String address) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=${Uri.encodeComponent(address)}&travelmode=driving';
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildNearbyStationsList() {
    // Sort the list based on distance
    _nearbyStations.sort((a, b) => (a['distance'] as num).compareTo(b['distance'] as num));

    if (_nearbyStations.isEmpty) {
      return Center(
        child: Text(
          'No nearby stations found.',
          style: GoogleFonts.quicksand(
            textStyle: TextStyle(color: dark ? Colors.white : Colors.black),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _nearbyStations.length,
      itemBuilder: (context, index) {
        var station = _nearbyStations[index];
        return ListTile(
          title: Text(
            station['name'],
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.quicksand(
              textStyle: TextStyle(
                color: dark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          subtitle: Text(
            "~${station['distance'].toStringAsFixed(2)} km",
            style: GoogleFonts.quicksand(
              textStyle: TextStyle(
                color: dark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: IconButton(
            onPressed: () {
              _launchMaps(
                currentPosition.latitude,
                currentPosition.longitude,
                station["latitude"],
                station["longitude"],
                station["address"],
              );
            },
            icon: const Icon(
              Icons.directions_rounded,
              color: primary,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
            ? Scaffold(
                backgroundColor: primary,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "eDrive",
                        style: GoogleFonts.quicksand(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                            color: white,
                          ),
                        ),
                      ),
                      Text(
                        "Looking for stations...",
                        style: GoogleFonts.quicksand(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Scaffold(
                backgroundColor: dark ? const Color(0xff1d1d1d) : white,
                appBar: const Appbar(),
                body: Stack(
                  children: [
                    // Map View
                    Container(
                      height: _nearbyStations.isEmpty
                          ? MediaQuery.sizeOf(context).height * 0.7
                          : MediaQuery.sizeOf(context).height * 0.6,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          maxZoom: 100,
                          keepAlive: true,
                          backgroundColor: primary.withOpacity(0.2),
                          initialCenter: LatLng(currentPosition.latitude,
                              currentPosition.longitude),
                          initialZoom: _currentZoom,
                        ),
                        children: [
                          TileLayer(
                            tileDisplay: const TileDisplay.fadeIn(),
                            urlTemplate:
                                "https://cartodb-basemaps-{s}.global.ssl.fastly.net/$mode/{z}/{x}/{y}.png",
                          ),
                          MarkerLayer(
                            rotate: true,
                            markers: _markers,
                          ),
                        ],
                      ),
                    ),

                    // Options
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: DraggableScrollableSheet(
                        maxChildSize: 0.5,
                        initialChildSize: _nearbyStations.isEmpty ? 0.3 : 0.4,
                        minChildSize: 0.2,
                        builder: (context, scrollController) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: white,
                              boxShadow: [
                                BoxShadow(color: Colors.grey, blurRadius: 2),
                              ],
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(20),
                                topLeft: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(
                                      left: 15, right: 15, top: 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            overflow: TextOverflow.ellipsis,
                                            "Nearby Stations (${_nearbyStations.length})",
                                            style: GoogleFonts.quicksand(
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            overflow: TextOverflow.ellipsis,
                                            "*showing results within 5km.",
                                            style: GoogleFonts.quicksand(
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _getCurrentLocation();
                                        },
                                        icon: const Icon(
                                          Icons.refresh,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 15, right: 15),
                                  height: 1,
                                  width: MediaQuery.sizeOf(context).width,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Expanded(
                                  child: _buildNearbyStationsList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // if(kIsWeb)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Column(
                        children: [
                          Text(
                            "*Click on station for more details.",
                            style: GoogleFonts.quicksand(
                              fontSize: 10,
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
                  ],
                ),
              );
  }
}

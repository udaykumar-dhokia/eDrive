import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenroute/constants/color/colors.dart';
import 'package:greenroute/main.dart';
import 'package:greenroute/screens/map/map_screen.dart';

class Connectivity extends StatefulWidget {
  const Connectivity({super.key});

  @override
  State<Connectivity> createState() => _ConnectivityState();
}


class _ConnectivityState extends State<Connectivity> {

  Future<void> _checkLocationServices() async {
    bool serviceEnabled;

    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Connectivity(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled ){
       
      return;
    }
    else{
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MapScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                "Please enable location to continue.",
                style: GoogleFonts.quicksand(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: white,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () async {
                  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                  if(!serviceEnabled){
                    await Geolocator.openLocationSettings();
                  }
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> InitialScreen() ));
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh, color: primary,),
                ),
              ),
            ],
          ),
      ),
    );
  }
}

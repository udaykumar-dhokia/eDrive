import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenroute/constants/color/colors.dart';
import 'package:greenroute/screens/search/search.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  const Appbar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(80);
  

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 80,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      backgroundColor: primary,
      actions: [
        GestureDetector(
          onTap: (){
            HapticFeedback.mediumImpact();
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const Search(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
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
          },
          child: const Icon(
              Icons.search,
              color: white,
          ),
        ),
        const SizedBox(width: 10,),
        if(kIsWeb)
         IconButton(onPressed: (){
           final url = 'https://ud15.netlify.app/apps';
           launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
         } , icon: const Icon(Icons.download, color: white,
         )),

        const SizedBox(width: 15,),
      ],
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
            'EV Stations, Anytime & Anywhere.',
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
    );
  }
}

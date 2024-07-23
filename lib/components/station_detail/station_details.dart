import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenroute/constants/color/colors.dart';
import 'package:greenroute/utils/call.dart';
import 'package:url_launcher/url_launcher.dart';

void showStationDetails(BuildContext context, Map<String, dynamic> data) {

  Future<void> launchMap(double lat, double lng, String address) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng(${Uri.encodeComponent(address)})';
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }


  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['name'] ?? 'No Name',
                  style: GoogleFonts.quicksand(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      )),
                ),
                IconButton(
                  onPressed: () {
                    launchMap(data["latitude"], data["longitude"], data["Address"]);
                  },
                  icon: const Icon(
                    Icons.directions_rounded,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              'Address: ${data['Address']}',
              style: GoogleFonts.quicksand(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contact: ${data['contact'] ?? "Not available"}',
                  style: GoogleFonts.quicksand(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(onPressed: (){
                  data['contact']!=null ? makePhoneCall('tel:${data["contact"]}'): null;
                }, icon: Icon(data['contact'] !=null ? Icons.call: Icons.not_interested_rounded)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Location: ${data['city']}, ${data['State']}',
              style: GoogleFonts.quicksand(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

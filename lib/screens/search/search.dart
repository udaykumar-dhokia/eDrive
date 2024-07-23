import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenroute/components/city_map/city_map.dart';
import 'package:greenroute/constants/color/colors.dart';
import 'package:greenroute/screens/map/map_screen.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<Map<String, dynamic>> allCities = [];
  List<Map<String, dynamic>> filteredCities = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCities();
    searchController.addListener(_filterCities);
  }

  Future<void> _fetchCities() async {
    var firestore = FirebaseFirestore.instance;
    var citiesSnapshot = await firestore.collection('cities').get();

    List<Map<String, dynamic>> cities = [];
    for (var doc in citiesSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      cities.add({
        "city": data['name'],
        "isActive": data['isActive'],
        "image": data['image'],
      });
    }

    setState(() {
      allCities = cities;
      filteredCities = cities;
    });
  }

  void _filterCities() {
    String query = searchController.text.toLowerCase();
    List<Map<String, dynamic>> suggestions = allCities.where((city) {
      String cityName = city['city'].toLowerCase();
      return cityName.contains(query);
    }).toList();

    setState(() {
      filteredCities = suggestions;
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_filterCities);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MapScreen(),
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: searchController,
                cursorColor: primary,
                style: GoogleFonts.quicksand(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.grey,
                  ),
                  hintText: "Search City",
                  hintStyle: GoogleFonts.quicksand(
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.grey)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: primary),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "*Currently, the dataset is available for limited cities only.",
                style: GoogleFonts.quicksand(fontSize: 10),
              ),
              const SizedBox(height: 30),
              Text(
                "Select a city",
                style: GoogleFonts.quicksand(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 400,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Number of columns
                    crossAxisSpacing: 10, // Spacing between columns
                    mainAxisSpacing: 10, // Spacing between rows
                    childAspectRatio: 1, // Adjust the aspect ratio as needed
                  ),
                  itemCount:
                      filteredCities.length, // Number of items in the grid
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (filteredCities[index]["isActive"]) {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      CityMap(
                                city: filteredCities[index]["city"],
                                image: filteredCities[index]["image"],
                              ),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        } else {
                          showToast(
                            'Will be available soon.',
                            context: context,
                            backgroundColor: primary,
                            animation: StyledToastAnimation.slideFromBottom,
                          );
                        }
                      },
                      child: Opacity(
                        opacity: !filteredCities[index]["isActive"] ? 0.5 : 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                  filteredCities[index]["image"],
                                ),
                                backgroundColor: transparent,
                                radius: 30,
                              ),
                              Text(
                                filteredCities[index]["city"],
                                style: GoogleFonts.quicksand(
                                    textStyle: const TextStyle(color: black)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

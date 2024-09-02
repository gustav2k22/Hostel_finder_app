import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hostel_app/settings_page.dart';
import 'package:hostel_app/HostelDetailsForm.dart';
import 'package:hostel_app/favourite_data.dart';
import 'package:hostel_app/HostelSearch.dart';
import 'package:hostel_app/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hostel_app/HostelDetails.dart';

class LoggedHomePage extends StatefulWidget {
  const LoggedHomePage({Key? key}) : super(key: key);

  @override
  _LoggedHomePageState createState() => _LoggedHomePageState();
}

class _LoggedHomePageState extends State<LoggedHomePage> {
  final TextEditingController _searchController = TextEditingController();

  double lat = 0.0; // Renamed from $lat to lat
  double long = 0.0; // Renamed from $long to long
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    getCurrentLocation();
  }

  // Fetches all hostel documents from Firestore
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getDocuments() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('hostels').get();
    return snapshot.docs;
  }

  // Retrieves the current location of the user
  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Optionally, prompt the user to enable location services
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);

    setState(() {
      lat = position.latitude;
      long = position.longitude;
    });
  }

  // Navigates to the HostelSearch screen with the provided query
  void performSearch(String query) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HostelSearch(searchQuery: query),
      ),
    );
  }

  // Signs out the user and navigates back to the HomePage
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      print("User logged out successfully");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    } catch (e) {
      print("Error signing out: $e");
      // Optionally, show an error message to the user
    }
  }

  // Navigates to the HostelDetailsForm screen
  void navigateToUploadPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HostelDetailsForm()),
    );
  }

  // Builds the map widget using FutureBuilder
  Widget _buildMapWidget(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: getDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No hostels found.'));
        } else {
          return _buildMap(context, snapshot.data!, lat, long);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Hostel Finder', style: TextStyle(fontSize: 18.0)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSearchTextField(),
            const SizedBox(height: 16),
            _buildFeatureButtons(),
            const SizedBox(height: 16),
            _buildMapWidget(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Builds the search text field
  Widget _buildSearchTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Search for Hostels',
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              performSearch(_searchController.text);
            },
          ),
        ),
        onSubmitted: (value) {
          performSearch(value);
        },
      ),
    );
  }

  // Builds the feature buttons (Favourite and Upload)
  Widget _buildFeatureButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFeatureButton(
          onPressed: () {
            // Navigate to FavouritePage
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavouritePage()),
            );
          },
          icon: Icons.favorite_border,
          label: 'Favourite',
          backgroundColor: Colors.deepPurpleAccent,
          labelColor: Colors.white,
        ),
        _buildFeatureButton(
          onPressed: () {
            // Navigate to HostelDetailsForm
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HostelDetailsForm()),
            );
          },
          icon: Icons.add,
          label: 'Upload',
          backgroundColor: Colors.lightBlueAccent,
          labelColor: Colors.white,
        ),
      ],
    );
  }

  // Helper method to build individual feature buttons
  Widget _buildFeatureButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color labelColor,
  }) {
    return SizedBox(
      width: 150,
      height: 100,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Rounded edges
          ),
          backgroundColor: backgroundColor,
        ),
        icon: Icon(icon, color: Colors.black),
        label: Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 18.0,
          ),
        ),
      ),
    );
  }

  // Builds the bottom navigation bar with Home, Profile, Settings, and Logout icons
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 56.0,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarIcon(Icons.home),
          _buildNavBarIcon(Icons.account_circle),
          _buildNavBarIcon(Icons.settings),
          _buildNavBarIcon(Icons.logout),
        ],
      ),
    );
  }

  // Helper method to build individual navigation bar icons
  Widget _buildNavBarIcon(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Colors.white,
          width: 2.0,
        ),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: () {
          if (icon == Icons.home) {
            // Optionally, handle home icon press
            // For example, navigate to the home screen or refresh content
          } else if (icon == Icons.account_circle) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          } else if (icon == Icons.settings) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          } else if (icon == Icons.logout) {
            signOut();
          }
        },
      ),
    );
  }

  // Builds the map widget with hostels marked
  Widget _buildMap(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    double lat,
    double long,
  ) {
    return Container(
      height: 440,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: LatLng(lat, long),
              zoom: 12.0,
            ),
            mapController: _mapController,
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.hostel_app', // Replace with your package name
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: LatLng(lat, long),
                    builder: (ctx) => const Icon(
                      Icons.person_pin,
                      color: Colors.blue,
                      size: 35.0,
                    ),
                  ),
                ],
              ),
              MarkerLayer(
                markers: _buildMarkers(context, documents),
              ),
            ],
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                _goToCurrentLocation(lat, long);
              },
              child: Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  // Moves the map to the current location
  void _goToCurrentLocation(double lat, double long) {
    _mapController.move(LatLng(lat, long), 12.0);
  }

  // Builds markers for each hostel
  List<Marker> _buildMarkers(BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> documents) {
    return documents.map((document) {
      var geoTag = document['geopoint'];
      if (geoTag is GeoPoint) {
        var latitude = geoTag.latitude;
        var longitude = geoTag.longitude;

        return Marker(
          width: 40.0,
          height: 40.0,
          point: LatLng(latitude, longitude),
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.location_pin),
            color: Colors.red,
            onPressed: () {
              _showDocumentDetails(context, document.data());
            },
          ),
        );
      } else {
        return Marker(
          width: 0.0,
          height: 0.0,
          point: LatLng(0, 0),
          builder: (ctx) => const Icon(
            Icons.wrong_location_outlined,
            color: Colors.blue,
            size: 35.0,
          ),
        );
      }
    }).toList();
  }

  // Shows the details of a selected hostel in an AlertDialog
  void _showDocumentDetails(
      BuildContext context, Map<String, dynamic> documentData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hostel Details'),
          content: SingleChildScrollView(
            // Prevents overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Wrap content
              children: [
                Text('Hostel Name: ${documentData['name']}'),
                Text('Phone Number: ${documentData['contactNumber']}'),
                Text('For: ${documentData['for']}'),
                Text('Address: ${documentData['address']}'),
                Text('Price: ${documentData['price']}'),
                Text('Room Available: ${documentData['roomAvailable']}'),
                Text('GeoTag: ${documentData['geopoint']}'),
                Text('Facilities: ${documentData['facilities']}'),
                Text('Food Available: ${documentData['foodAvailability']}'),
                const SizedBox(height: 16.0),
                const Text('For More Details:'),
                const SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HostelDetailsScreen(hostelData: documentData),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

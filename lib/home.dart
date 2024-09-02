import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hostel_app/HostelSearch.dart';
import 'package:hostel_app/login_page.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  double lat = 0.0;
  double long = 0.0;
  bool isLoggedIn = false; // Track login status
  late MapController _mapController;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getDocuments() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('hostels').get();
    return snapshot.docs;
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      lat = position.latitude;
      long = position.longitude;
    });
  }

  void performSearch(String query) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HostelSearch(searchQuery: query),
      ),
    );
  }

  void navigateToLoginPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  Widget build1(BuildContext context) {
    return FutureBuilder(
      future: getDocuments(),
      builder: (context,
          AsyncSnapshot<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
              snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
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
        title: _buildSearchBar(),
        actions: <Widget>[
          if (_searchController.text.isEmpty)
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: navigateToLoginPage,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSearchTextField(),
            const SizedBox(height: 16),
            _buildFeatureButtons(),
            const SizedBox(height: 16),
            build1(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchBar() {
    return _searchController.text.isEmpty
        ? const Text('Hostel Finder')
        : TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              performSearch(value);
            },
            style: const TextStyle(color: Colors.blue),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Search for Hostels',
              hintStyle: TextStyle(color: Colors.blue),
            ),
          );
  }

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

  Widget _buildFeatureButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFeatureButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Login prompt'),
                  content: const Text('Please login for further access'),
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
          },
          icon: Icons.favorite_border,
          label: 'Favourite',
          backgroundColor: Colors.deepPurpleAccent,
          labelColor: Colors.white,
        ),
        _buildFeatureButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Login prompt'),
                  content: const Text('Please login for further access'),
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
          },
          icon: Icons.add,
          label: 'Upload',
          backgroundColor: Colors.lightBlueAccent,
          labelColor: Colors.white,
        ),
      ],
    );
  }

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
            borderRadius: BorderRadius.circular(12.0),
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

  Widget _buildBottomNavigationBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56.0),
      child: Container(
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
      ),
    );
  }

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
          if (icon == Icons.account_circle) {
            navigateToLoginPage();
          } else if (icon == Icons.logout) {
            // Handle logout button press
          }
        },
      ),
    );
  }

  Widget _buildMap(
    context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    double lat,
    double long,
  ) {
    double lat0 = lat;
    double long0 = long;
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
                    'com.example.app', // Add your package name here
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: LatLng(lat0, long0),
                    builder: (ctx) => const Icon(
                      Icons.person_pin,
                      color: Colors.blue,
                      size: 35.0,
                    ),
                  ),
                  ..._buildMarkers(context, documents),
                ],
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

  void _goToCurrentLocation(double lat, double long) {
    _mapController.move(LatLng(lat, long), 12.0);
  }

  List<Marker> _buildMarkers(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
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
              if (isLoggedIn) {
                _showDocumentDetails(context, document.data());
              } else {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Login prompt'),
                      content: const Text('Please login for further access'),
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

  void _showDocumentDetails(
    BuildContext context,
    Map<String, dynamic> documentData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hostel Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              SizedBox(height: 10.0),
              Text('Note:'),
              Text(
                  'For more details search the Hostel name or Area in the search bar'),
            ],
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

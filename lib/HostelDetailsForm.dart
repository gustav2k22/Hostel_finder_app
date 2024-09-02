import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:hostel_app/logged_homepage.dart';
import 'package:hostel_app/EditHostelDetails.dart';

class HostelDetailsForm extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final bool isEditing;




  HostelDetailsForm({Key? key, this.existingData, this.isEditing = false})
      : super(key: key);

  @override
  _HostelDetailsFormState createState() => _HostelDetailsFormState();
}

class _HostelDetailsFormState extends State<HostelDetailsForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController roomsAvailableController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController facilitiesController = TextEditingController();
  final GlobalKey<State> _facilitiesDialogKey = GlobalKey<State>();
  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;
  String selectedGender = 'Boys';

  // Location
  LocationData? _currentLocation;
  List<File>? _images;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool hasHostelDetails = false;

  // List of facilities
  List<String> facilitiesList = [
    'Food',
    'WiFi',
    'Parking',
    'AC',
    'Gym',
    'Cafeteria',
    // Add more facilities as needed
  ];

  List<String> selectedFacilities = [];

  @override
  void initState() {
    super.initState();
    // Check if the user has already entered hostel details
    checkHostelDetails();
  }

  Future<void> checkHostelDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Check if "Hostels" collection exists, and create it if not
        CollectionReference hostels = _firestore.collection('hostels');
        DocumentSnapshot document = await hostels.doc(user.uid).get();

        if (document.exists) {
          setState(() {
            hasHostelDetails = true;
          });

        }
      }
    } catch (e) {
      print('Error checking hostel details: $e');
    }
  }

  Future<void> addHostelDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Check if "Hostels" collection exists, and create it if not
        CollectionReference hostels = _firestore.collection('hostels');

        List<String> imageUrls = [];

        if (_images != null && _images!.isNotEmpty) {
          // Upload images to Firebase Storage and get download URLs
          for (int i = 0; i < _images!.length; i++) {
            String imageFileName =
                DateTime.now().millisecondsSinceEpoch.toString() + '_$i';

            Reference storageReference = FirebaseStorage.instance
                .ref()
                .child('$imageFileName.jpg');
            UploadTask uploadTask = storageReference.putFile(
                _images![i], SettableMetadata(contentType: "image/jpeg/png"));

            await uploadTask.whenComplete(() async {
              String imageUrl = await storageReference.getDownloadURL();
              imageUrls.add(imageUrl);
            });
          }
        }

        // Convert data to Map<String, dynamic>
        Map<String, dynamic> hostelData = {
          'userId':user.uid,
          'name': nameController.text,
          'for': selectedGender,
          'area': areaController.text,
          'address': addressController.text,
          'contactNumber': contactNumberController.text,
          'capacity': int.parse(capacityController.text),
          'roomsAvailable': int.parse(roomsAvailableController.text),
          'price': double.parse(priceController.text),
          'facilities': selectedFacilities, // Use the selectedFacilities list
          'image_urls': imageUrls,
          'geopoint': _currentLocation != null
              ? GeoPoint(
              _currentLocation!.latitude!, _currentLocation!.longitude!)
              : null,
        };

        // Add the document in the 'hostel' collection
        await hostels.doc(user.uid).set(hostelData);

        // Show a success message or navigate to the next screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hostel details added successfully!'),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoggedHomePage(),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Print detailed error information
      print('Error adding hostel details: $e');
      print('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding hostel details. Please try again.'),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      List<XFile>? pickedFiles = await _imagePicker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images =
              pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  // Method to get current location
  Future<void> _getCurrentLocation() async {
    try {
      Location location = Location();
      _currentLocation = await location.getLocation();
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Widget _buildFacilitiesDialog() {
    return AlertDialog(
      title: Text('Select Facilities'),

      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Column(
              children: facilitiesList.map((facility) {
                bool isSelected = selectedFacilities.contains(facility);
                return CheckboxListTile(
                  title: Text(facility),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value != null) {
                        if (value && !selectedFacilities.contains(facility)) {
                          selectedFacilities.add(facility);
                        } else if (!value &&
                            selectedFacilities.contains(facility)) {
                          selectedFacilities.remove(facility);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            setState(() {
              selectedFacilities.clear();
            });
            Navigator.of(context).pop();
          },
          child: Text('Clear Selection'),
        ),
        TextButton(
          onPressed: () async {
            // Close the dialog and show the selected facilities
            Navigator.of(context).pop();
           _showSelectedFacilitiesSnackBar();
          },
          child: Text('Done'),
        ),
      ],
    );
  }
  void _showSelectedFacilitiesSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected Facilities: ${selectedFacilities.join(', ')}'),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hostel Details Upload'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hostel Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Hostel Name'),

              ),

              // Hostel Gender (Boys/Girls)
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: ['Boys', 'Girls'].map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      selectedGender = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'FOR',
                  labelStyle: TextStyle(fontSize: 16.0), // Set the font size
                ),
              ),

              // Hostel Area
              SizedBox(height: 16),
              TextFormField(
                controller: areaController,
                decoration: InputDecoration(labelText: 'Hostel Area'),

              ),

              // Hostel Address
              SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Hostel Address'),

              ),

              // Hostel Contact Number
              SizedBox(height: 16),
              TextFormField(
                controller: contactNumberController,
                decoration: InputDecoration(labelText: 'Hostel Contact Number'),
                keyboardType: TextInputType.phone,

              ),

              // Hostel Capacity
              SizedBox(height: 16),
              TextFormField(
                controller: capacityController,
                decoration: InputDecoration(labelText: 'Hostel Capacity'),
                keyboardType: TextInputType.number,

              ),

              // Rooms Available
              SizedBox(height: 16),
              TextFormField(
                controller: roomsAvailableController,
                decoration: InputDecoration(labelText: 'Rooms Available'),
                keyboardType: TextInputType.number,

              ),

              // Price
              SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price per Room'),
                keyboardType: TextInputType.number,

              ),
              // Facilities selection
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildFacilitiesDialog(),
                  );
                },
               child: Text('Select Facilities'),
              ),
              //SizedBox(height: 8),
              //Text('Selected Facilities: ${selectedFacilities.join(', ')}'),

              // Hostel Images
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Hostel Images'),
              ),
              SizedBox(height: 8),
              _images != null && _images!.isNotEmpty
                  ? Column(
                children: _images!
                    .map(
                      (image) => Image.file(
                    image,
                    height: 100,
                  ),
                )
                    .toList(),
              )
                  : Container(),

              // Location
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: Text('Get Current Location'),
              ),
              SizedBox(height: 8),
              _currentLocation != null
                  ? Text(
                  'Current Location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}')
                  : Container(),

              // Save Button
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  hasHostelDetails ? editHostelDetails() : addHostelDetails();
                },
                child: Text(hasHostelDetails ? 'Edit Details' : 'Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }


Future<void> editHostelDetails() async {
  // You can implement the logic to edit existing hostel details here
  // For example, navigate to a new screen with pre-filled form fields
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditHostelDetailsForm(),
    ),
  );
}
}
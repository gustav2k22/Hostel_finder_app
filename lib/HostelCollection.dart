// ignore: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

class Hostel {
  final String name;
  final String address;
  final int capacity;
  final double price;
  final String foodAvailability;
  final String facilities;
  final String imageUrl; // URL to the hostel image
  final GeoPoint? geoPoint; // Location coordinates (optional)

  Hostel({
    required this.name,
    required this.address,
    required this.capacity,
    required this.price,
    required this.foodAvailability,
    required this.facilities,
    required this.imageUrl,
    this.geoPoint,
  });
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addHostelToFirestore(Hostel hostel) async {
    try {
      // Collection reference for hostels
      CollectionReference hostels = _firestore.collection('hostels');

      // Add hostel details to Firestore
      await hostels.add({
        'name': hostel.name,
        'address': hostel.address,
        'capacity': hostel.capacity,
        'price': hostel.price,
        'foodAvailability': hostel.foodAvailability,
        'facilities': hostel.facilities,
        'image_url': hostel.imageUrl,
        'geopoint': hostel.geoPoint,
      });

      print('Hostel added to Firestore successfully');
    } catch (e) {
      print('Error adding hostel to Firestore: $e');
      // Handle the error as needed
    }
  }
}
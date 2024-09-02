import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> hostelData;

  HostelDetailsScreen({required this.hostelData});

  @override
  _HostelDetailsScreenState createState() => _HostelDetailsScreenState();
}

class _HostelDetailsScreenState extends State<HostelDetailsScreen> {
  late List<String> imageUrls;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    imageUrls = List<String>.from(widget.hostelData['image_urls'] ?? []);
    pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hostel Details',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PhotoViewGallery.builder(
              itemCount: imageUrls.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(imageUrls[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              pageController: pageController,
              scrollPhysics: BouncingScrollPhysics(),
              backgroundDecoration: BoxDecoration(
                color: Colors.black,
              ),
              enableRotation: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hostelData['name'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rooms Available: ${widget.hostelData['roomsAvailable']}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Room Capacity: ${widget.hostelData['capacity']}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Address: ${widget.hostelData['address']}',
                  style: TextStyle(fontSize: 16),
                ),

                SizedBox(height: 8),
                Text(
                  'Price: \R\s\.${widget.hostelData['price']}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),

                SizedBox(height: 8),
                Text(
                  'Facilities: ${widget.hostelData['facilities'].join(', ')}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'For Directions:',
                  style: TextStyle(fontSize: 16),
                ),
                ElevatedButton.icon(

                  onPressed: () {
                    openMaps(widget.hostelData['geopoint'] as GeoPoint);
                  },
                  icon: Icon(Icons.location_on),
                  label: Text('Open in Maps'),
                ),
                SizedBox(height: 8),
                Text(
                  'Contact: ${widget.hostelData['contactNumber']}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        launchUrlString("tel:${widget.hostelData['contactNumber']}");
                      },
                      icon: Icon(Icons.phone),
                      label: Text('Contact'),
                    ),
                    SizedBox(width: 20)
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openMaps(GeoPoint geopoint) async {
    String googleUrl = 'https://www.google.com/maps/search/?api=1&query=${geopoint.latitude},${geopoint.longitude}';
    if (await canLaunchUrlString(googleUrl)) {
      await launchUrlString(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}

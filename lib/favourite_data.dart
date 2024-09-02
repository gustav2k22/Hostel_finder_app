import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_app/HostelDetails.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FavouritePage extends StatefulWidget {

  @override
  _FavouriteState createState() => _FavouriteState();
}

class _FavouriteState extends State<FavouritePage>{
  List<DocumentSnapshot> searchResults = [];
  List<DocumentSnapshot> filteredResults = [];
  List<DocumentSnapshot> favResults = [];
  List<String> selectedFacilities = [];
  String selectedSort = 'Name'; // Default sort option

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference favoriteHostelsRef =
  FirebaseFirestore.instance.collection('favoritehostels');

  List<String> favoriteHostelIds=[];

  @override
  void initState() {
    super.initState();
    favHostels();
    // Perform the initial search when the widget is created
  }
  Future<void> favHostels() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Fetch favorites for the current user
        CollectionReference favoriteHostelsRef =
        FirebaseFirestore.instance.collection('favoritehostels');
        QuerySnapshot querySnapshot = await favoriteHostelsRef
            .where('userId', isEqualTo: currentUser.uid)
            .get();
        setState(() {
          favResults = querySnapshot.docs;
        });

        querySnapshot.docs.forEach((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('favlist') && data['favlist'] is List) {
            var favIds = data['favlist'] as List<dynamic>;
            favoriteHostelIds = favIds.map((id) => id.toString()).toList();
          } else {
            favoriteHostelIds = [];
          }
        });
        searchHostels(favoriteHostelIds);
        print('favorite ids are : $favoriteHostelIds');
      }
    } catch (e) {
      print('Error fetching favorite hostels: $e');
    }
  }



  Future<void> searchHostels(List<String> favIds) async {
    try {
      User? currentUser=_auth.currentUser;
      if(currentUser!=null) {
        QuerySnapshot querySnapshot = await _firestore
            .collection('hostels')
            .where('name', whereIn: favIds)
            .get();

        setState(() {
          searchResults = querySnapshot.docs;
          applyFilterAndSort();
        });
      }
    } catch (e) {
      print('Error searching hostels: $e');
    }
  }



  void applyFilterAndSort() {
    // Apply filter
    filteredResults = searchResults
        .where((hostel) {
      // Check if the hostel has all selected facilities
      return selectedFacilities.every(
              (facility) => hostel['facilities'] != null && hostel['facilities'].contains(facility));
    })
        .toList();

    // Apply sort
    filteredResults.sort((a, b) {
      if (selectedSort == 'Name') {
        return a['name'].compareTo(b['name']);
      } else if (selectedSort == 'Price') {
        return a['price'].compareTo(b['price']);
      }
      // Add more sort options as needed
      return 0;
    });

  }


  Future<void> addFavoriteHostelIds(Map<String, dynamic> hostelId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Add the hostel ID to the user's favorite list
        CollectionReference favoriteHostelsRef =
        FirebaseFirestore.instance.collection('favoritehostels');
        var a=await favoriteHostelsRef.doc(currentUser.uid).get();
        if(a.exists) {
          await favoriteHostelsRef.doc(currentUser.uid).update({
            'favlist': FieldValue.arrayUnion([hostelId['name']]),
            'userId': currentUser.uid,
          });
        }
        else
        {
          await favoriteHostelsRef.doc(currentUser.uid).set({
            'favlist': FieldValue.arrayUnion([hostelId['name']]),
            'userId': currentUser.uid,
          });
        }
      }
    } catch (e) {
      print('Error fetching favorite hostels: $e');
    }
  }

  Future<void> removeFavoriteHostels(Map<String, dynamic> hostelId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Remove the hostel ID from the user's favorite list
        CollectionReference favoriteHostelsRef =
        FirebaseFirestore.instance.collection('favoritehostels');
        DocumentReference documentReference =
        favoriteHostelsRef.doc(currentUser.uid);

        DocumentSnapshot snapshot = await documentReference.get();

        if (snapshot.exists) {
          Map<String, dynamic> data =
          snapshot.data() as Map<String, dynamic>;
          List<dynamic> arrayData = data['favlist'] as List<dynamic>;

          if (arrayData.contains(hostelId['name'])) {
            arrayData.remove(hostelId['name']);
            await snapshot.reference.update({'favlist': arrayData});
            print('Value removed successfully');
          } else {
            print('Value not found in the array');
          }
        } else {
          print('Document does not exist');
        }
      }
    } catch (e) {
      print('Error removing value: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favourite Hostels'),
        actions: [
          _buildFilterDropdown(),
          _buildSortDropdown(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filteredResults.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> hostelData =
                filteredResults[index].data() as Map<String, dynamic>;
                bool isFavorite =
                favoriteHostelIds.contains(hostelData['name']);
                return ListTile(
                  title: Text(hostelData['name']),
                  subtitle: Row(
                    children: [
                      Text('Price: \$${hostelData['price']}'),
                      Spacer(),
                      IconButton(
                        icon: isFavorite
                            ? Icon(Icons.favorite)
                            : Icon(Icons.favorite_border),
                        color: Colors.red,
                        onPressed: () {
                          // Toggle favorite status when tapped
                          toggleFavoriteStatus(
                              hostelData, !isFavorite);
                        },
                      ),

                    ],
                  ),
                  onTap: () {
                    // Navigate to the details screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HostelDetailsScreen(
                          hostelData: hostelData,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  void toggleFavoriteStatus(Map<String,dynamic> hostelId, bool isFavorite) async {
    try {
      if (isFavorite) {
        await addFavoriteHostelIds(hostelId);
      } else {
        await removeFavoriteHostels(hostelId);
      }

      //await updateFavoriteHostelIds(); // Update the favorite hostel IDs list
      setState(() {
      });
    } catch (e) {
      print('Error toggling favorite status: $e');
    }
  }

  Widget _buildFilterDropdown() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.filter_list),
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'WiFi',
            child: CheckboxListTile(
              title: Text('WiFi'),
              value: selectedFacilities.contains('WiFi'),
              onChanged: (bool? value) {
                setState(() {
                  if (value != null) {
                    if (value) {
                      selectedFacilities.add('WiFi');
                    } else {
                      selectedFacilities.remove('WiFi');
                    }
                    applyFilterAndSort();
                  }
                });
              },
            ),
          ),
          PopupMenuItem<String>(
            value: 'Food',
            child: CheckboxListTile(
              title: Text('Food'),
              value: selectedFacilities.contains('Food'),
              onChanged: (bool? value) {
                setState(() {
                  if (value != null) {
                    if (value) {
                      selectedFacilities.add('Food');
                    } else {
                      selectedFacilities.remove('Food');
                    }
                    applyFilterAndSort();
                  }
                });
              },
            ),
          ),
          PopupMenuItem<String>(
            value: 'AC',
            child: CheckboxListTile(
              title: Text('AC'),
              value: selectedFacilities.contains('AC'),
              onChanged: (bool? value) {
                setState(() {
                  if (value != null) {
                    if (value) {
                      selectedFacilities.add('AC');
                    } else {
                      selectedFacilities.remove('AC');
                    }
                    applyFilterAndSort();
                  }
                });
              },
            ),
          ),
          PopupMenuItem<String>(
            value: 'Boys',
            child: CheckboxListTile(
              title: Text('Boys'),
              value: selectedFacilities.contains('Boys'),
              onChanged: (bool? value) {
                setState(() {
                  if (value != null) {
                    if (value) {
                      selectedFacilities.add('Boys');
                    } else {
                      selectedFacilities.remove('Boys');
                    }
                    applyFilterAndSort();
                  }
                });
              },
            ),
          ),
          PopupMenuItem<String>(
            value: 'Girls',
            child: CheckboxListTile(
              title: Text('Girls'),
              value: selectedFacilities.contains('Girls'),
              onChanged: (bool? value) {
                setState(() {
                  if (value != null) {
                    if (value) {
                      selectedFacilities.add('Girls');
                    } else {
                      selectedFacilities.remove('Girls');
                    }
                    applyFilterAndSort();
                  }
                });
              },
            ),
          ),
          // Add more filter options as needed
        ];
      },
    );
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort),
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'Name',
            child: Text('Sort by Name'),
          ),
          PopupMenuItem<String>(
            value: 'Price',
            child: Text('Sort by Price'),
          ),
          // Add more sort options as needed
        ];
      },
      onSelected: (value) {
        setState(() {
          selectedSort = value;
          applyFilterAndSort();
        });
      },
    );
  }

}
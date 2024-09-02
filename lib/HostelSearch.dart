import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_app/HostelDetails.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HostelSearch extends StatefulWidget {
  final String searchQuery;

  HostelSearch({required this.searchQuery});

  @override
  _HostelSearchState createState() => _HostelSearchState();
}
class _FilterCheckboxTile extends StatefulWidget {
  final String title;
  final bool value;
  final Function(bool) onChanged;

  const _FilterCheckboxTile({
    Key? key,
    required this.title,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  _FilterCheckboxTileState createState() => _FilterCheckboxTileState();
}
class _FilterCheckboxTileState extends State<_FilterCheckboxTile> {
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.title),
      value: widget.value,
      onChanged: (bool? value) {
        setState(() {
          if (value != null) {
            widget.onChanged(value);
          }
        });
      },
    );
  }
}

class _HostelSearchState extends State<HostelSearch> {
  final TextEditingController searchController = TextEditingController();
  List<DocumentSnapshot> searchResults = [];
  List<DocumentSnapshot> filteredResults = [];
  List<String> selectedFacilities = [];
  List<DocumentSnapshot> favResults = [];
  List<String> selectedFor = [];
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
    searchHostels(widget.searchQuery);
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
        print('favorite ids are : $favoriteHostelIds');
      }
    } catch (e) {
      print('Error fetching favorite hostels: $e');
    }
  }

  Future<void> searchHostels(String query) async {
    try {
      // Convert the search criteria to lowercase and trim trailing spaces
      String lowercaseQuery = query.toLowerCase().trim();

      QuerySnapshot querySnapshot = await _firestore
          .collection('hostels')
          .where('name', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('name', isLessThan: lowercaseQuery + 'z')
          .get();

      List<DocumentSnapshot> nameMatches = querySnapshot.docs;

      // If no matches were found by name, try searching by area
      if (nameMatches.isEmpty) {
        querySnapshot = await _firestore
            .collection('hostels')
            .where('area', isGreaterThanOrEqualTo: lowercaseQuery)
            .where('area', isLessThan: lowercaseQuery + 'z')
            .get();

        nameMatches = querySnapshot.docs;
      }

      // If no matches were found by area, try searching by address
      if (nameMatches.isEmpty) {
        querySnapshot = await _firestore
            .collection('hostels')
            .where('address', isGreaterThanOrEqualTo: lowercaseQuery)
            .where('address', isLessThan: lowercaseQuery + 'z')
            .get();

        // Filter the results to include only those with a substring match
        nameMatches = querySnapshot.docs
            .where((doc) =>
        doc['address'] != null &&
            doc['address'].toString().toLowerCase().contains(lowercaseQuery))
            .toList();
      }

      setState(() {
        searchResults = nameMatches;
        applyFilterAndSort();
      });
    } catch (e) {
      print('Error searching hostels: $e');
    }
  }






  void applyFilterAndSort() {
    // Apply filter
    filteredResults = searchResults.where((hostel) {
      // Check if the hostel has all selected facilities
      bool hasSelectedFacilities = selectedFacilities.isEmpty ||
          selectedFacilities.every((facility) =>
          hostel['facilities'] != null &&
              hostel['facilities'].contains(facility));

      // Check 'for' filter
      bool passesForFilter = selectedFor.isEmpty ||
          selectedFor.contains(hostel['for']); // Assuming 'for' has 'Boys' or 'Girls'

      return hasSelectedFacilities && passesForFilter;
    }).toList();

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
        title: Text('Hostel Search'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Show a dialog to input search query
              showSearchDialog();
            },
          ),
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
                      Text('Price: \R\s\.${hostelData['price']}'),
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
            value: 'FilterOptions',
            child: Column(
              children: [
                _buildFilterCheckbox('WiFi'),
                _buildFilterCheckbox('Food'),
                _buildFilterCheckbox('AC'),
                _buildFilterCheckbox('Boys'),
                _buildFilterCheckbox('Girls'),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildFilterCheckbox(String filterOption) {
    return CheckboxListTile(
      title: Text(filterOption),
      value: _isFilterOptionSelected(filterOption),
      onChanged: (bool? value) {
        setState(() {
          if (value != null) {
            _updateFilterOption(filterOption, value);
            applyFilterAndSort();
          }
        });
      },
    );
  }

  bool _isFilterOptionSelected(String filterOption) {
    switch (filterOption) {
      case 'WiFi':
        return selectedFacilities.contains('WiFi');
      case 'Food':
        return selectedFacilities.contains('Food');
      case 'AC':
        return selectedFacilities.contains('AC');
      case 'Boys':
        return selectedFor.contains('Boys');
      case 'Girls':
        return selectedFor.contains('Girls');
      default:
        return false;
    }
  }

  void _updateFilterOption(String filterOption, bool value) {
    setState(() {
      switch (filterOption) {
        case 'WiFi':
          _updateSelectedFacility('WiFi', value);
          break;
        case 'Food':
          _updateSelectedFacility('Food', value);
          break;
        case 'AC':
          _updateSelectedFacility('AC', value);
          break;
        case 'Boys':
          _updateSelectedFor('Boys', value);
          break;
        case 'Girls':
          _updateSelectedFor('Girls', value);
          break;
      }
    });
  }

  void _updateSelectedFacility(String facility, bool value) {
    if (value) {
      selectedFacilities.add(facility);
    } else {
      selectedFacilities.remove(facility);
    }
  }

  void _updateSelectedFor(String forOption, bool value) {
    if (value) {
      selectedFor.add(forOption);
    } else {
      selectedFor.remove(forOption);
    }
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

  void showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';

        return AlertDialog(
          title: Text('Search Hostels'),
          content: TextField(
            onChanged: (value) {
              query = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter search query',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (query.isNotEmpty) {
                  // Perform search with the entered query
                  searchHostels(query);
                  Navigator.pop(context);
                }
              },
              child: Text('Search'),
            ),
          ],
        );
      },
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homehunt/firebase/auth/auth_service.dart';
import 'package:homehunt/pages/login_page.dart';
import 'package:homehunt/error_widgets/error_banner.dart';
import 'package:homehunt/pages/my_listings_page.dart';
import 'package:homehunt/pages/new_listing_page.dart';
import 'package:homehunt/pages/profile_page.dart';
import 'package:homehunt/pages/property_listing.dart'; // Import the property listing model

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  User? user;
  bool isLoading = true;
  String? errorMessage;
  
  // Filter states
  String selectedPropertyType = 'Apartamente';
  String selectedTransactionType = 'De vânzare';
  String? selectedRooms;
  String? selectedLocation;
  double? minPrice;
  double? maxPrice;
  
  // Listings data
  List<PropertyListing> allListings = [];
  List<PropertyListing> filteredListings = [];
  List<String> favoriteListings = [];
  Map<String, bool> expandedPhones = {};

  @override
  void initState() {
    super.initState();
    loadUser();
    fetchListings();
    fetchFavorites();
  }

  Future<void> loadUser() async {
    setState(() => isLoading = true);
    user = FirebaseAuth.instance.currentUser;
    setState(() => isLoading = false);
  }
  
  Future<void> fetchListings() async {
    setState(() => isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('listings')
          .get();
          
      allListings = querySnapshot.docs
          .map((doc) => PropertyListing.fromFirestore(doc))
          .toList();
      
      applyFilters();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = 'Eroare la încărcarea anunțurilor: $e';
        isLoading = false;
      });
    }
  }
  
  Future<void> fetchFavorites() async {
    if (user != null) {
      try {
        final favDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('favorites')
            .get();
            
        favoriteListings = favDoc.docs.map((doc) => doc.id).toList();
        setState(() {});
      } catch (e) {
        print('Error fetching favorites: $e');
      }
    }
  }
  
  void applyFilters() {
    filteredListings = allListings.where((listing) {
      // Apply transaction type filter (vanzare/inchiriere)
      if (selectedTransactionType == 'De vânzare' && 
          !listing.isForSale) {
        return false;
      }
      if (selectedTransactionType == 'De închiriat' && 
          listing.isForSale) {
        return false;
      }
      
      // Apply property type filter
      if (selectedPropertyType != 'Toate' && 
          listing.propertyType != selectedPropertyType) {
        return false;
      }
      
      // Apply number of rooms filter
      if (selectedRooms != null && selectedRooms != 'Toate' && 
          listing.rooms.toString() != selectedRooms) {
        return false;
      }
      
      // Apply location filter
      if (selectedLocation != null && selectedLocation!.isNotEmpty && 
          !listing.location.toLowerCase().contains(selectedLocation!.toLowerCase())) {
        return false;
      }
      
      // Apply price range filter
      if (minPrice != null && listing.price < minPrice!) {
        return false;
      }
      if (maxPrice != null && listing.price > maxPrice!) {
        return false;
      }
      
      return true;
    }).toList();
    
    setState(() {});
  }
  
  void toggleFavorite(String listingId) async {
    if (user == null) {
      showLoginPrompt();
      return;
    }
    
    final userFavRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(listingId);
        
    if (favoriteListings.contains(listingId)) {
      // Remove from favorites
      await userFavRef.delete();
      setState(() {
        favoriteListings.remove(listingId);
      });
    } else {
      // Add to favorites
      await userFavRef.set({'addedAt': DateTime.now()});
      setState(() {
        favoriteListings.add(listingId);
      });
    }
  }
  
  void togglePhoneNumber(String listingId) {
    setState(() {
      expandedPhones[listingId] = !(expandedPhones[listingId] ?? false);
    });
  }
  
  void showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autentificare necesară'),
        content: const Text('Trebuie să fii autentificat pentru a adăuga anunțuri la favorite.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('Autentificare'),
          ),
        ],
      ),
    );
  }

  Future<void> signOut() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() => errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void clearError() {
    setState(() {
      errorMessage = null;
    });
  }

  Future<void> showSignOutConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Te vei deconecta de la contul tau'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Renunta'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                signOut();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  void addNewListing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNewListingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: SizedBox(
              height: 80,
              child: Image.asset(
                'lib/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 15),
              child: TextButton.icon(
                onPressed: addNewListing,
                icon: Icon(
                  Icons.add_box_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  'Anunt',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 20, top: 15),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                label: Text(
                  'Contul meu',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user?.email?.isNotEmpty == true
                        ? user!.email![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Marketplace'),
                  selected: true,
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Favorite'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.addchart_rounded),
                  title: const Text('Anunturile mele'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyListingsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Divider(height: 32, thickness: 0.5),

                // Vanzare Section
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedTransactionType = 'De vânzare';
                      selectedPropertyType = 'Apartamente';
                      applyFilters();
                    });
                  },
                  child: const Text('Apartamente de vanzare'),
                ),
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedTransactionType = 'De vânzare';
                      selectedPropertyType = 'Garsoniere';
                      applyFilters();
                    });
                  },
                  child: const Text('Garsoniere de vanzare'),
                ),
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedTransactionType = 'De vânzare';
                      selectedPropertyType = 'Case';
                      applyFilters();
                    });
                  },
                  child: const Text('Case de vanzare'),
                ),
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedTransactionType = 'De vânzare';
                      selectedPropertyType = 'Teren';
                      applyFilters();
                    });
                  },
                  child: const Text('Teren de vanzare'),
                ),
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedTransactionType = 'De vânzare';
                      selectedPropertyType = 'Spatii comerciale';
                      applyFilters();
                    });
                  },
                  child: const Text('Spatii comerciale de vanzare'),
                ),

                const Divider(height: 32, thickness: 0.5),

                // Inchiriere Section
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedTransactionType = 'De închiriat';
                      selectedPropertyType = 'Apartamente';
                      applyFilters();
                    });
                  },
                  child: const Text('Apartamente de inchiriat'),
                ),
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedTransactionType = 'De închiriat';
                      selectedPropertyType = 'Garsoniere';
                      applyFilters();
                    });
                  },
                  child: const Text('Garsoniere de inchiriat'),
                ),
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedTransactionType = 'De închiriat';
                      selectedPropertyType = 'Case';
                      applyFilters();
                    });
                  },
                  child: const Text('Case de inchiriat'),
                ),
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedTransactionType = 'De închiriat';
                      selectedPropertyType = 'Spatii comerciale';
                      applyFilters();
                    });
                  },
                  child: const Text('Spatii comerciale de inchiriat'),
                ),
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedTransactionType = 'De închiriat';
                      selectedPropertyType = 'Birouri';
                      applyFilters();
                    });
                  },
                  child: const Text('Birouri de inchiriat'),
                ),

                const SizedBox(height: 30),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: addNewListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Adauga anunt',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: showSignOutConfirmationDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('Deconectare'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      if (errorMessage != null) ...[
                        ErrorBanner(
                          message: errorMessage!,
                          onDismiss: clearError,
                        ),
                        const SizedBox(height: 10),
                      ],
                      
                      // First row of filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Transaction type filter (vanzare/inchiriere)
                            _buildFilterDropdown(
                              value: selectedTransactionType,
                              items: const ['De vânzare', 'De închiriat'],
                              onChanged: (value) {
                                setState(() {
                                  selectedTransactionType = value!;
                                  applyFilters();
                                });
                              },
                              icon: Icons.keyboard_arrow_down,
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Location filter
                            _buildFilterTextField(
                              hint: 'Adaugă localități, zone',
                              onChanged: (value) {
                                setState(() {
                                  selectedLocation = value;
                                  applyFilters();
                                });
                              },
                              width: 200,
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Property type filter
                            _buildFilterDropdown(
                              value: selectedPropertyType,
                              items: const ['Toate', 'Apartamente', 'Garsoniere', 'Case', 'Teren', 'Spatii comerciale', 'Birouri'],
                              onChanged: (value) {
                                setState(() {
                                  selectedPropertyType = value!;
                                  applyFilters();
                                });
                              },
                              icon: Icons.keyboard_arrow_down,
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Room number filter
                            _buildFilterDropdown(
                              value: selectedRooms ?? 'Nr. camere',
                              items: const ['Nr. camere', 'Toate', '1', '2', '3', '4+'],
                              onChanged: (value) {
                                setState(() {
                                  selectedRooms = value == 'Nr. camere' ? null : value;
                                  applyFilters();
                                });
                              },
                              icon: Icons.keyboard_arrow_down,
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Price filter
                            _buildFilterDropdown(
                              value: 'Preț',
                              items: const ['Preț', '< 50.000€', '50.000€ - 100.000€', '100.000€ - 200.000€', '> 200.000€'],
                              onChanged: (value) {
                                if (value == 'Preț') {
                                  setState(() {
                                    minPrice = null;
                                    maxPrice = null;
                                  });
                                } else if (value == '< 50.000€') {
                                  setState(() {
                                    minPrice = 0;
                                    maxPrice = 50000;
                                  });
                                } else if (value == '50.000€ - 100.000€') {
                                  setState(() {
                                    minPrice = 50000;
                                    maxPrice = 100000;
                                  });
                                } else if (value == '100.000€ - 200.000€') {
                                  setState(() {
                                    minPrice = 100000;
                                    maxPrice = 200000;
                                  });
                                } else if (value == '> 200.000€') {
                                  setState(() {
                                    minPrice = 200000;
                                    maxPrice = null;
                                  });
                                }
                                applyFilters();
                              },
                              icon: Icons.keyboard_arrow_down,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Results count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'S-au găsit ${filteredListings.length} rezultate',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: 'Cele mai noi',
                        items: ['Cele mai noi', 'Preț (crescător)', 'Preț (descrescător)']
                            .map((item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == 'Preț (crescător)') {
                            setState(() {
                              filteredListings.sort((a, b) => a.price.compareTo(b.price));
                            });
                          } else if (value == 'Preț (descrescător)') {
                            setState(() {
                              filteredListings.sort((a, b) => b.price.compareTo(a.price));
                            });
                          } else {
                            setState(() {
                              filteredListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                            });
                          }
                        },
                        underline: const SizedBox(),
                        icon: const Icon(Icons.sort),
                      ),
                    ],
                  ),
                ),

                // Listings
                Expanded(
                  child: filteredListings.isEmpty
                      ? const Center(child: Text('Nu există anunțuri care să corespundă filtrelor'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredListings.length,
                          itemBuilder: (context, index) {
                            final listing = filteredListings[index];
                            final isFavorite = favoriteListings.contains(listing.id);
                            final isPhoneExpanded = expandedPhones[listing.id] ?? false;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image section with favorite icon
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: listing.imageUrls.isNotEmpty
                                              ? Image.network(
                                                  listing.imageUrls[0],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                      child: Icon(Icons.image_not_supported),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  color: Colors.grey[300],
                                                  child: const Center(
                                                    child: Icon(Icons.image_not_supported),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFavorite ? Colors.red : Colors.grey,
                                            ),
                                            onPressed: () => toggleFavorite(listing.id),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            listing.isForSale ? 'De vânzare' : 'De închiriat',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Content section
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title and price
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                listing.title,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${listing.price.toStringAsFixed(0)} €',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                                if (!listing.isForSale)
                                                  const Text(
                                                    'pe lună',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        // Location
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                listing.location,
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Property details
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildPropertyDetail(
                                              Icons.square_foot,
                                              '${listing.surface} m²',
                                            ),
                                            _buildPropertyDetail(
                                              Icons.bedroom_parent,
                                              '${listing.rooms} camere',
                                            ),
                                            _buildPropertyDetail(
                                              Icons.bathroom,
                                              '${listing.bathrooms} ${listing.bathrooms == 1 ? 'baie' : 'băi'}',
                                            ),
                                            _buildPropertyDetail(
                                              Icons.calendar_today,
                                              'din ${_formatDate(listing.createdAt)}',
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Contact section
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              child: Text(
                                                listing.agentName.isNotEmpty
                                                    ? listing.agentName[0].toUpperCase()
                                                    : 'A',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    listing.agentName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  if (isPhoneExpanded)
                                                    Text(
                                                      listing.phoneNumber,
                                                      style: const TextStyle(color: Colors.grey),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.phone),
                                              color: Theme.of(context).colorScheme.primary,
                                              onPressed: () => togglePhoneNumber(listing.id),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButton<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
        underline: const SizedBox(), // Remove the default underline
        icon: Icon(icon),
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  Widget _buildFilterTextField({
    required String hint,
    required Function(String) onChanged,
    double? width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ),
    );
  }
  
  Widget _buildPropertyDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'ian', 'feb', 'mar', 'apr', 'mai', 'iun', 
      'iul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
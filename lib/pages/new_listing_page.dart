import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:homehunt/error_widgets/error_banner.dart';
import 'package:image_picker/image_picker.dart';

class AddNewListingPage extends StatefulWidget {
  const AddNewListingPage({super.key});

  @override
  State<AddNewListingPage> createState() => AddNewListingPageState();
}

class AddNewListingPageState extends State<AddNewListingPage> {
  bool isLoading = false;
  String selectedCategory = 'Apartament';
  String transactionType = 'De vanzare';

  String? errorMessage;
  String? successMessage;

  String? selectedAgent;
  String? selectedAgentId;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> agents = [];
  final formKey = GlobalKey<FormState>();

  List<XFile> selectedImages = [];
  List<String> imageUrls = [];
  final ImagePicker picker = ImagePicker();

  //Locatie form
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final cityController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final sectorController = TextEditingController();

  //Apartament form
  String? selectedNumarCamereApartament;
  String? selectedCompartimentare;
  final etajController = TextEditingController();
  final suprafataUtilaApartController = TextEditingController();
  final anConstructieApartController = TextEditingController();

  //Casa form
  String? selectedNumarCamereCasa;
  final suprafataUtilaCasaController = TextEditingController();
  final suprafataTerenCasaController = TextEditingController();
  final anConstructieCasaController = TextEditingController();
  final etajeCasaController = TextEditingController();

  //Teren form
  String? selectedTipTeren;
  String? selectedClasificare;
  final suprafataTerenController = TextEditingController();

  //Spatiu Comercial form
  String? selectedCategorieSpatiu;
  final suprafataSpatiuComController = TextEditingController();

  String? selectedJudet;

  final judete = [
    'Alba',
    'Arad',
    'Arges',
    'Bacau',
    'Bihor',
    'Bistrita-Nasaud',
    'Botosani',
    'Brasov',
    'Braila',
    'Buzau',
    'Caras-Severin',
    'Calarasi',
    'Cluj',
    'Constanta',
    'Covasna',
    'Dambovita',
    'Dolj',
    'Galati',
    'Giurgiu',
    'Gorj',
    'Harghita',
    'Hunedoara',
    'Ialomita',
    'Iasi',
    'Ilfov',
    'Maramures',
    'Mehedinti',
    'Mures',
    'Neamt',
    'Olt',
    'Prahova',
    'Satu Mare',
    'Salaj',
    'Sibiu',
    'Suceava',
    'Teleorman',
    'Timis',
    'Tulcea',
    'Valcea',
    'Vaslui',
    'Vrancea',
    'Bucuresti',
  ];

  final categories = ['Apartament', 'Casa', 'Teren', 'Spatiu comercial'];
  final transactionTypes = ['De vanzare', 'De inchiriat'];

  Future<void> getAgents() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('agents').get();
      setState(() {
        agents =
            snapshot.docs
                .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
                .toList();
      });
    } catch (e) {
      setState(() {
        errorMessage = "A aparut o eroare la incarcarea agentilor";
      });
    }
  }

  //adauga poze
  Future<void> pickImages() async {
    try {
      final pics = await picker.pickMultiImage(
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (pics.isEmpty) return;

      final maxPhotos = 12;
      final slotsLeft = maxPhotos - selectedImages.length;
      final toAdd = pics.take(slotsLeft).toList();

      setState(() {
        selectedImages.addAll(pics);
        imageUrls.addAll(toAdd.map((f) => f.path).whereType<String>());

        if (pics.length > slotsLeft) {
          errorMessage = "Poti incarca maxim $maxPhotos poze.";
        }
      });
    } catch (e) {
      setState(() => errorMessage = "Eroare la selectarea imaginilor: $e");
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
      imageUrls.removeAt(index);
    });
  }

  Future<List<String>> uploadImages(String propertyId) async {
    final downloadUrls = <String>[];

    for (var i = 0; i < selectedImages.length; i++) {
      final img = selectedImages[i];
      final ext = img.name.split('.').last;
      final path = 'properties/$propertyId/image_$i.$ext';
      final ref = FirebaseStorage.instance.ref(path);
      final bytes = await img.readAsBytes();

      final snap = await ref.putData(
        bytes,
        SettableMetadata(contentType: img.mimeType),
      );
      downloadUrls.add(await snap.ref.getDownloadURL());
    }

    return downloadUrls;
  }

  Future<void> saveProperty() async {
    if (formKey.currentState!.validate()) {
      if (selectedImages.isEmpty) {
        errorMessage = "Te rog incarca cel putin o imagine";
        return;
      }

      try {
        setState(() {
          isLoading = true;
          errorMessage = null;
          successMessage = null;
        });

        if (currentUser == null) {
          setState(() {
            errorMessage = "Userul nu a fost gasit";
          });
          return;
        }

        if (selectedAgent != null) {
          final agentSnapshot =
              await FirebaseFirestore.instance
                  .collection('agents')
                  .where('name', isEqualTo: selectedAgent)
                  .limit(1)
                  .get();

          if (agentSnapshot.docs.isEmpty) {
            errorMessage = "Agentul nu a fost gasit";
          } else {
            selectedAgentId = agentSnapshot.docs.first.id;
          }
        }

        final propertyRef =
            FirebaseFirestore.instance.collection('properties').doc();
        final propertyId = propertyRef.id;

        final uploadedImageUrls = await uploadImages(propertyId);

        Map<String, dynamic> propertyData = {
          'title': titleController.text,
          'price': int.parse(priceController.text),
          'description': descriptionController.text,
          'category': selectedCategory,
          'type': transactionType,
          'location': {
            'county': selectedJudet,
            'city': cityController.text,
            'street': streetController.text,
            'number': numberController.text,
            'sector': sectorController.text,
          },
          'images': uploadedImageUrls,
          'userId': currentUser!.uid,
          'agentId': selectedAgentId,
          'agentName': selectedAgent,
          'createdAt': FieldValue.serverTimestamp(),
        };
        switch (selectedCategory) {
          case 'Apartament':
            propertyData.addAll({
              'apartmentDetails': {
                'rooms': selectedNumarCamereApartament,
                'compartments': selectedCompartimentare,
                'floor': etajController.text,
                'area': int.parse(suprafataUtilaApartController.text),
                'yearBuilt': int.parse(anConstructieApartController.text),
              },
            });
            break;
          case 'Casa':
            propertyData.addAll({
              'houseDetails': {
                'rooms': selectedNumarCamereCasa,
                'area': int.parse(suprafataUtilaCasaController.text),
                'landArea': int.parse(suprafataTerenCasaController.text),
                'yearBuilt': int.parse(anConstructieCasaController.text),
                'floors': int.parse(etajeCasaController.text),
              },
            });
            break;
          case 'Teren':
            propertyData.addAll({
              'landDetails': {
                'type': selectedTipTeren,
                'classification': selectedClasificare,
                'area': int.parse(suprafataTerenController.text),
              },
            });
            break;
          case 'Spatiu comercial':
            propertyData.addAll({
              'commercialDetails': {
                'type': selectedCategorieSpatiu,
                'area': int.parse(suprafataSpatiuComController.text),
              },
            });
            break;
        }
        await propertyRef.set(propertyData);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({
              'properties': FieldValue.arrayUnion([propertyId]),
            });

        if (selectedAgentId != null) {
          await FirebaseFirestore.instance
              .collection('agents')
              .doc(selectedAgentId)
              .update({
                'properties': FieldValue.arrayUnion([propertyId]),
              });
        }

        setState(() {
          successMessage = 'Anunt publicat cu succes!';
        });
        resetForm();
      } catch (e) {
        setState(() {
          errorMessage = 'Eroare la salvarea anuntului: $e';
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getAgents();
  }

  void resetForm() {
    formKey.currentState?.reset();
    setState(() {
      selectedCategory = 'Apartament';
      transactionType = 'De inchiriat';
      selectedAgent = null;
      selectedAgentId = null;
      selectedImages.clear();
      imageUrls.clear();
      titleController.clear();
      priceController.clear();
      descriptionController.clear();
      cityController.clear();
      streetController.clear();
      numberController.clear();
      sectorController.clear();
      selectedNumarCamereApartament = null;
      selectedCompartimentare = null;
      etajController.clear();
      suprafataUtilaApartController.clear();
      anConstructieApartController.clear();
      selectedNumarCamereCasa = null;
      suprafataUtilaCasaController.clear();
      suprafataTerenCasaController.clear();
      anConstructieCasaController.clear();
      etajeCasaController.clear();
      selectedTipTeren = null;
      selectedClasificare = null;
      suprafataTerenController.clear();
      selectedCategorieSpatiu = null;
      suprafataSpatiuComController.clear();
      selectedJudet = null;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    cityController.dispose();
    streetController.dispose();
    numberController.dispose();
    sectorController.dispose();
    etajController.dispose();
    suprafataUtilaApartController.dispose();
    anConstructieApartController.dispose();
    suprafataUtilaCasaController.dispose();
    suprafataTerenCasaController.dispose();
    anConstructieCasaController.dispose();
    etajeCasaController.dispose();
    suprafataTerenController.dispose();
    suprafataSpatiuComController.dispose();

    super.dispose();
  }

  Widget buildLocalizareFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localizare:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Judet',
            border: OutlineInputBorder(),
          ),
          value: selectedJudet,
          validator: (value) => value == null ? 'Selecteaza judetul' : null,
          items:
              judete
                  .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                  .toList(),
          onChanged: (String? value) {
            setState(() {
              selectedJudet = value;
            });
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: cityController,
          decoration: const InputDecoration(
            labelText: 'Oras',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Introdu orasul' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: streetController,
          decoration: const InputDecoration(
            labelText: 'Strada',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Introdu strada' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: numberController,
          decoration: const InputDecoration(
            labelText: 'Numar',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu numarul strazii';
            if (int.tryParse(value) == null) {
              return 'Introdu un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: sectorController,
          decoration: const InputDecoration(
            labelText: 'Sector (optional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagini:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImages,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      imageUrls.isEmpty
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 50,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(height: 16),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Incarca fotografii',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          '\n\nMaxim 15 poze. Formate acceptate: PNG, JPG. Dimensiune maxima 10MB',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                          : Center(
                            child: Icon(
                              Icons.add_photo_alternate,
                              size: 30,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                ),
              ),
              if (imageUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      imageUrls.asMap().entries.map((entry) {
                        final index = entry.key;
                        final url = entry.value;

                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(url, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () => removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildChoiceChips(
    String label,
    List<String> options,
    String? selectedValue,
    Function(String?) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Wrap(
          spacing: 12,
          children:
              options.map((opt) {
                return ChoiceChip(
                  label: Text(opt),
                  selected: selectedValue == opt,
                  onSelected: (bool selected) {
                    if (selected) {
                      onSelect(opt);
                    }
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget buildTransactionTypeChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tip tranzactie'),
        SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children:
              transactionTypes.map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: transactionType == type,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        transactionType = type;
                      });
                    }
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget buildApartamentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Titlu',
            border: OutlineInputBorder(),
          ),
          maxLength: 150,
          validator: (value) => value!.isEmpty ? 'Introdu titlul' : null,
        ),
        const SizedBox(height: 10),
        buildChoiceChips(
          'Numar camere',
          List.generate(5, (i) => '${i + 1}'),
          selectedNumarCamereApartament,
          (value) => setState(() => selectedNumarCamereApartament = value),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: 'Compartimentare',
            border: OutlineInputBorder(),
          ),
          value: selectedCompartimentare,
          validator:
              (value) => value == null ? 'Selecteaza compartimentarea' : null,
          items:
              [
                'Decomandat',
                'Semidecomandat',
                'Nedecomandat',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {
            setState(() {
              selectedCompartimentare = value;
            });
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: etajController,
          decoration: const InputDecoration(
            labelText: 'Etaj',
            border: OutlineInputBorder(),
          ),
          inputFormatters: [
            // allow an optional leading P or p, then digits
            FilteringTextInputFormatter.allow(RegExp(r'^[P]?\d*$')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu etajul';
            if (!RegExp(r'^[Pp]?\d+$').hasMatch(value)) return 'Etaj invalid (ex: P, 1, 2)';
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataUtilaApartController,
          decoration: const InputDecoration(
            labelText: 'Suprafata utila (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu suprafata utila';
            if (int.tryParse(value) == null) {
              return 'Introdu un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: anConstructieApartController,
          decoration: const InputDecoration(
            labelText: 'An constructie',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu anul constructiei';
            if (int.tryParse(value) == null) {
              return 'Introdu un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: priceController,
          decoration: const InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu pretul';
            if (int.tryParse(value) == null) {
              return 'Introdu un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        buildImageSection(),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descriere',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          maxLength: 500,
          validator: (value) => value!.isEmpty ? 'Introdu descrierea' : null,
        ),
        const SizedBox(height: 10),
        buildTransactionTypeChips(),
        const SizedBox(height: 25),
        buildLocalizareFields(),
      ],
    );
  }

  Widget buildCasaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Titlu',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
          validator: (value) => value!.isEmpty ? 'Introduceti titlul' : null,
        ),
        const SizedBox(height: 10),
        buildChoiceChips(
          'Numar camere',
          List.generate(10, (i) => '${i + 1}'),
          selectedNumarCamereCasa,
          (value) => setState(() => selectedNumarCamereCasa = value),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: suprafataUtilaCasaController,
          decoration: const InputDecoration(
            labelText: 'Suprafata utila (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu suprafata utila';
            if (int.tryParse(value) == null) {
              return 'Introduceti un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataTerenCasaController,
          decoration: const InputDecoration(
            labelText: 'Suprafata teren (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu suprafata teren';
            if (int.tryParse(value) == null) {
              return 'Introduceti un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: anConstructieCasaController,
          decoration: const InputDecoration(
            labelText: 'An constructie',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu anul constructiei';
            if (int.tryParse(value) == null) {
              return 'Introduceti un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: etajeCasaController,
          decoration: const InputDecoration(
            labelText: 'Etaje',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu numarul de etaje';
            if (int.tryParse(value) == null) {
              return 'Introduceti un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: priceController,
          decoration: const InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu pretul';
            if (int.tryParse(value) == null) {
              return 'Introdu un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        buildImageSection(),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descriere',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          maxLength: 200,
          validator: (value) => value!.isEmpty ? 'Introdu descrierea' : null,
        ),
        const SizedBox(height: 10),
        buildTransactionTypeChips(),
        const SizedBox(height: 25),
        buildLocalizareFields(),
      ],
    );
  }

  Widget buildTerenForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Titlu',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
          validator: (value) => value!.isEmpty ? 'Introdu titlul' : null,
        ),
        DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: 'Tip teren',
            border: OutlineInputBorder(),
          ),
          value: selectedTipTeren,
          validator:
              (value) => value == null ? 'Selecteaza tipul terenului' : null,
          items:
              [
                'Constructii',
                'Agricol',
                'Forestier',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {
            setState(() {
              selectedTipTeren = value;
            });
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: 'Clasificare',
            border: OutlineInputBorder(),
          ),
          value: selectedClasificare,
          validator:
              (value) => value == null ? 'Selecteaza clasificarea' : null,
          items:
              [
                'Intravilan',
                'Extravilan',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {
            setState(() {
              selectedClasificare = value;
            });
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataTerenController,
          decoration: const InputDecoration(
            labelText: 'Suprafata teren (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu suprafata';
            if (int.tryParse(value) == null) {
              return 'Introdu un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: priceController,
          decoration: const InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu pretul';
            if (int.tryParse(value) == null) {
              return 'Introdu un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        buildImageSection(),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descriere',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          maxLength: 200,
          validator: (value) => value!.isEmpty ? 'Introdu descrierea' : null,
        ),
        const SizedBox(height: 10),
        buildTransactionTypeChips(),
        const SizedBox(height: 20),
        buildLocalizareFields(),
      ],
    );
  }

  Widget buildSpatiuComercialForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Titlu',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
          validator: (value) => value!.isEmpty ? 'Introdu titlul' : null,
        ),
        DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: 'Categorie',
            border: OutlineInputBorder(),
          ),
          value: selectedCategorieSpatiu,
          validator: (value) => value == null ? 'Selecteaza categoria' : null,
          items:
              [
                'Birouri',
                'Comercial',
                'Industrial',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {
            setState(() {
              selectedCategorieSpatiu = value;
            });
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataSpatiuComController,
          decoration: const InputDecoration(
            labelText: 'Suprafata (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu suprafata';
            if (int.tryParse(value) == null) {
              return 'Introdu un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: priceController,
          decoration: const InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Introdu pretul';
            if (int.tryParse(value) == null) {
              return 'Introdu un numar intreg valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        buildImageSection(),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descriere',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          maxLength: 200,
          validator: (value) => value!.isEmpty ? 'Introdu descrierea' : null,
        ),
        const SizedBox(height: 10),
        buildTransactionTypeChips(),
        const SizedBox(height: 20),
        buildLocalizareFields(),
      ],
    );
  }

  Widget buildDynamicForm() {
    switch (selectedCategory) {
      case 'Casa':
        return buildCasaForm();
      case 'Apartament':
        return buildApartamentForm();
      case 'Teren':
        return buildTerenForm();
      case 'Spatiu comercial':
        return buildSpatiuComercialForm();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Image.asset(
                'lib/images/logo.png',
                width: 220,
                height: 220,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null) ...[
                    ErrorBanner(
                      message: errorMessage!,
                      messageType: MessageType.error,
                      onDismiss: () => setState(() => errorMessage = null),
                    ),
                    const SizedBox(height: 20),
                  ] else if (successMessage != null) ...[
                    ErrorBanner(
                      message: successMessage!,
                      messageType: MessageType.success,
                      onDismiss: () => setState(() => successMessage = null),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        categories.map((cat) {
                          return ChoiceChip(
                            label: Text(cat),
                            selected: selectedCategory == cat,
                            onSelected: (_) {
                              setState(() {
                                selectedCategory = cat;
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 20),
                  buildDynamicForm(),
                  const SizedBox(height: 30),
                  agents.isEmpty
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Alege agentul de vanzari',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedAgent,
                        validator:
                            (value) =>
                                value == null ? 'Selecteaza agentul' : null,
                        items:
                            agents
                                .map(
                                  (agent) => DropdownMenuItem<String>(
                                    value: agent['name'],
                                    child: Text(agent['name']),
                                  ),
                                )
                                .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedAgent = newValue;
                          });
                        },
                      ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  if (selectedImages.isEmpty) {
                                    setState(() {
                                      errorMessage =
                                          'Te rog incarca cel putin o imagine';
                                    });
                                    return;
                                  }
                                  saveProperty();
                                },
                        child:
                            isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Publica anuntul',
                                  style: TextStyle(fontSize: 15),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

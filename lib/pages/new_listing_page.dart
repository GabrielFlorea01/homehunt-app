import 'package:flutter/material.dart';
import 'package:homehunt/error_widgets/error_banner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:html' as html;

class AddNewListingPage extends StatefulWidget {
  const AddNewListingPage({super.key});

  @override
  State<AddNewListingPage> createState() => AddNewListingPageState();
}

class AddNewListingPageState extends State<AddNewListingPage> {
  String selectedCategory = 'Apartament';
  String transactionType = 'De inchiriat';
  String? errorMessage;
  String? successMessage;
  String? selectedAgent;
  bool isLoading = false;
  User? get currentUser => FirebaseAuth.instance.currentUser;
  String? selectedAgentId;
  List<Map<String, dynamic>> agents = [];
  List<PlatformFile> selectedImages = [];
  List<html.File> webImages = [];
  List<String> imageUrls = [];
  final formKey = GlobalKey<FormState>();

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
  final suprafataSpatioController = TextEditingController();

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

  Future<void> pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        setState(() {
          selectedImages = result.files;

          for (var file in result.files) {
            if (file.bytes != null) {
              final url = html.Url.createObjectUrlFromBlob(
                html.Blob([file.bytes!], 'image/${file.extension}'),
              );
              imageUrls.add(url);
            }
          }
        });
      }
    } catch (e) {
      errorMessage = "Eroare la incarcarea imaginilor";
    }
  }

  void removeImage(int index) {
    setState(() {
      if (index < imageUrls.length) {
        html.Url.revokeObjectUrl(imageUrls[index]);
        imageUrls.removeAt(index);
      }
      if (index < selectedImages.length) {
        selectedImages.removeAt(index);
      }
    });
  }

  Future<List<String>> uploadImages(String propertyId) async {
    List<String> downloadUrls = [];

    try {
      for (var i = 0; i < selectedImages.length; i++) {
        final file = selectedImages[i];
        final path = 'properties/$propertyId/image_$i.${file.extension}';
        final ref = FirebaseStorage.instance.ref().child(path);

        if (file.bytes != null) {
          await ref.putData(
            file.bytes!,
            SettableMetadata(contentType: 'image/${file.extension}'),
          );

          final url = await ref.getDownloadURL();
          downloadUrls.add(url);
        }
      }
      return downloadUrls;
    } catch (e) {
      errorMessage = "Nu s-au putut incarca imaginile";
      throw Exception("Eroare la incarcarea imaginilor $e");
    }
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
          'price': double.parse(priceController.text),
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
                'area': double.parse(suprafataUtilaApartController.text),
                'yearBuilt': int.parse(anConstructieApartController.text),
              },
            });
            break;
          case 'Casa':
            propertyData.addAll({
              'houseDetails': {
                'rooms': selectedNumarCamereCasa,
                'area': double.parse(suprafataUtilaCasaController.text),
                'landArea': double.parse(suprafataTerenCasaController.text),
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
                'area': double.parse(suprafataTerenController.text),
              },
            });
            break;
          case 'Spatiu comercial':
            propertyData.addAll({
              'commercialDetails': {
                'type': selectedCategorieSpatiu,
                'area': double.parse(suprafataSpatioController.text),
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
      webImages.clear();
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
      suprafataSpatioController.clear();
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
    suprafataSpatioController.dispose();

    for (var url in imageUrls) {
      html.Url.revokeObjectUrl(url);
    }

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
          validator: (value) => value!.isEmpty ? 'Introdu numarul' : null,
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
                                          '\n\nMaxim 15 poze. Formate acceptate: PNG, JPG. Dimensiune maximă 10MB',
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
          maxLength: 30,
          validator: (value) => value!.isEmpty ? 'Introdu titlul' : null,
        ),
        const SizedBox(height: 10),
        buildChoiceChips(
          'Numar camere',
          List.generate(5, (i) => '${i + 1}'),
          selectedNumarCamereApartament,
          (value) => setState(() => selectedNumarCamereApartament = value),
        ),
        const SizedBox(height: 10),
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
          validator: (value) => value!.isEmpty ? 'Introdu etajul' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataUtilaApartController,
          decoration: const InputDecoration(
            labelText: 'Suprafata utila (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Introdu suprafata' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: anConstructieApartController,
          decoration: const InputDecoration(
            labelText: 'An constructie',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator:
              (value) => value!.isEmpty ? 'Introdu anul constructiei' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: priceController,
          decoration: const InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Introdu pretul' : null,
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataUtilaCasaController,
          decoration: const InputDecoration(
            labelText: 'Suprafata utila (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator:
              (value) => value!.isEmpty ? 'Introduceti suprafata utila' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataTerenCasaController,
          decoration: const InputDecoration(
            labelText: 'Suprafata teren (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator:
              (value) =>
                  value!.isEmpty ? 'Introduceti suprafata terenului' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: anConstructieCasaController,
          decoration: const InputDecoration(
            labelText: 'An constructie',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator:
              (value) => value!.isEmpty ? 'Introdu anul construcției' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: etajeCasaController,
          decoration: const InputDecoration(
            labelText: 'Etaje',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator:
              (value) => value!.isEmpty ? 'Introdu numarul de etaje' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: priceController,
          decoration: const InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Introdu pretul' : null,
        ),
        const SizedBox(height: 10),
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
                'Agricol',
                'Constructii',
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
          validator:
              (value) => value!.isEmpty ? 'Introdu suprafata terenului' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: priceController,
          decoration: const InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Introdu pretul' : null,
        ),
        const SizedBox(height: 10),
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
                'Birou',
                'Magazin',
                'Hala',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {
            setState(() {
              selectedCategorieSpatiu = value;
            });
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataSpatioController,
          decoration: const InputDecoration(
            labelText: 'Suprafata (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Introdu suprafata' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: priceController,
          decoration: const InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Introdu pretul' : null,
        ),
        const SizedBox(height: 10),
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
                    ErrorBanner(message: errorMessage!,
                    messageType: MessageType.error,
                    onDismiss: () => setState(() => errorMessage = null),
                    ),
                    const SizedBox(height: 20),
                  ] else if (successMessage != null) ...[
                    ErrorBanner(message: successMessage!,
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
                        onPressed: isLoading ? null : saveProperty,
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

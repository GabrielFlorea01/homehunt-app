import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:homehunt/error_widgets/error_banner.dart';

class EditListingPage extends StatefulWidget {
  final String listingId;
  const EditListingPage({super.key, required this.listingId});

  @override
  State<EditListingPage> createState() => EditListingPageState();
}

class EditListingPageState extends State<EditListingPage> {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  // common
  String selectedCategory = 'Apartament';
  String transactionType = 'De vanzare';

  // image & picker
  final ImagePicker picker = ImagePicker();
  List<String> imageUrls = []; // existing remote URLs
  List<XFile> selectedImages = []; // newly picked files
  List<Uint8List> selectedImageBytes = []; // bytes for preview
  int maxPhotos = 15;

  // form controllers
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final cityController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final sectorController = TextEditingController();

  // apartament
  String? selectedNumarCamereApartament;
  String? selectedCompartimentare;
  final etajController = TextEditingController();
  final suprafataUtilaApartController = TextEditingController();
  final anConstructieApartController = TextEditingController();

  // casa
  String? selectedNumarCamereCasa;
  final suprafataUtilaCasaController = TextEditingController();
  final suprafataTerenCasaController = TextEditingController();
  final anConstructieCasaController = TextEditingController();
  final etajeCasaController = TextEditingController();

  // teren
  String? selectedTipTeren;
  String? selectedClasificare;
  final suprafataTerenController = TextEditingController();

  // spatiu comercial
  String? selectedCategorieSpatiu;
  final suprafataSpatiuComController = TextEditingController();

  String? selectedJudet;
  List<Map<String, dynamic>> agents = [];
  String? selectedAgentName;
  String? selectedAgentId;

  @override
  void initState() {
    super.initState();
    loadAgents();
    loadExisting();
  }

  Future<void> loadAgents() async {
    final snap = await FirebaseFirestore.instance.collection('agents').get();
    if (!mounted) return;
    setState(() {
      agents =
          snap.docs
              .map((d) => {'id': d.id, 'name': d['name'] as String})
              .toList();
    });
  }

  Future<void> loadExisting() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(widget.listingId)
            .get();
    final data = doc.data()!;
    if (!mounted) return;
    setState(() {
      titleController.text = data['title'] as String? ?? '';
      priceController.text = (data['price'] as num?)?.toString() ?? '';
      descriptionController.text = data['description'] as String? ?? '';
      transactionType = data['type'] as String? ?? 'De vanzare';
      selectedCategory = data['category'] as String? ?? 'Apartament';
      imageUrls = List<String>.from(data['images'] as List? ?? []);
      selectedAgentName = data['agentName'] as String?;
      selectedAgentId = data['agentId'] as String?;
      final loc = data['location'] as Map<String, dynamic>? ?? {};
      selectedJudet = loc['county'] as String?;
      cityController.text = loc['city'] as String? ?? '';
      streetController.text = loc['street'] as String? ?? '';
      numberController.text = loc['number'] as String? ?? '';
      sectorController.text = loc['sector'] as String? ?? '';

      switch (selectedCategory) {
        case 'Apartament':
          final apt = data['apartmentDetails'] as Map<String, dynamic>? ?? {};
          selectedNumarCamereApartament = apt['rooms'] as String?;
          selectedCompartimentare = apt['compartments'] as String?;
          etajController.text = apt['floor'] as String? ?? '';
          suprafataUtilaApartController.text =
              (apt['area'] as num?)?.toString() ?? '';
          anConstructieApartController.text =
              (apt['yearBuilt'] as num?)?.toString() ?? '';
          break;
        case 'Casa':
          final c = data['houseDetails'] as Map<String, dynamic>? ?? {};
          selectedNumarCamereCasa = c['rooms'] as String?;
          suprafataUtilaCasaController.text =
              (c['area'] as num?)?.toString() ?? '';
          suprafataTerenCasaController.text =
              (c['landArea'] as num?)?.toString() ?? '';
          anConstructieCasaController.text =
              (c['yearBuilt'] as num?)?.toString() ?? '';
          etajeCasaController.text = (c['floors'] as num?)?.toString() ?? '';
          break;
        case 'Teren':
          final t = data['landDetails'] as Map<String, dynamic>? ?? {};
          selectedTipTeren = t['type'] as String?;
          selectedClasificare = t['classification'] as String?;
          suprafataTerenController.text = (t['area'] as num?)?.toString() ?? '';
          break;
        case 'Spatiu comercial':
          final sc = data['commercialDetails'] as Map<String, dynamic>? ?? {};
          selectedCategorieSpatiu = sc['type'] as String?;
          suprafataSpatiuComController.text =
              (sc['area'] as num?)?.toString() ?? '';
          break;
      }
    });
  }

  Future<void> pickImages() async {
    final pics = await picker.pickMultiImage(maxWidth: 1200, imageQuality: 80);
    if (pics.isEmpty) return;
    // how many more slots we have?
    final slotsLeft = maxPhotos - imageUrls.length - selectedImages.length;
    final toAdd = pics.take(slotsLeft).toList();
    // read bytes for preview
    for (final f in toAdd) {
      selectedImageBytes.add(await f.readAsBytes());
    }
    setState(() {
      selectedImages.addAll(toAdd);
      if (pics.length > slotsLeft) {
        errorMessage = 'Poți încărca maxim $maxPhotos poze.';
      }
    });
  }

  Future<List<String>> uploadImages(String propertyId) async {
    // preserve whatever old URLs are still in imageUrls
    final existing = List<String>.from(imageUrls);
    final newUrls = <String>[];

    for (final file in selectedImages) {
      final ext = file.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref(
        'properties/$propertyId/$fileName',
      );
      final snap = await ref.putData(
        await file.readAsBytes(),
        SettableMetadata(contentType: file.mimeType),
      );
      newUrls.add(await snap.ref.getDownloadURL());
    }

    return [...existing, ...newUrls];
  }

  void removeImage(int index) {
    if (index < imageUrls.length) {
      // removing an existing URL
      final url = imageUrls[index];
      // OPTIONAL: also delete from Storage:
      // await FirebaseStorage.instance.refFromURL(url).delete();
      setState(() {
        imageUrls.removeAt(index);
      });
    } else {
      // removing a newly picked file
      final localIdx = index - imageUrls.length;
      setState(() {
        selectedImages.removeAt(localIdx);
        selectedImageBytes.removeAt(localIdx);
      });
    }
  }

  Future<void> saveChanges() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final allUrls = await uploadImages(widget.listingId);
      final data = <String, dynamic>{
        'title': titleController.text,
        'price': int.parse(priceController.text),
        'description': descriptionController.text,
        'type': transactionType,
        'images': allUrls,
        'location': {
          'county': selectedJudet,
          'city': cityController.text,
          'street': streetController.text,
          'number': numberController.text,
          'sector': sectorController.text,
        },
        'agentId': selectedAgentId,
        'agentName': selectedAgentName,
      };

      switch (selectedCategory) {
        case 'Apartament':
          data['apartmentDetails'] = {
            'rooms': selectedNumarCamereApartament,
            'compartments': selectedCompartimentare,
            'floor': etajController.text,
            'area': int.parse(suprafataUtilaApartController.text),
            'yearBuilt': int.parse(anConstructieApartController.text),
          };
          break;
        case 'Casa':
          data['houseDetails'] = {
            'rooms': selectedNumarCamereCasa,
            'area': int.parse(suprafataUtilaCasaController.text),
            'landArea': int.parse(suprafataTerenCasaController.text),
            'yearBuilt': int.parse(anConstructieCasaController.text),
            'floors': int.parse(etajeCasaController.text),
          };
          break;
        case 'Teren':
          data['landDetails'] = {
            'type': selectedTipTeren,
            'classification': selectedClasificare,
            'area': int.parse(suprafataTerenController.text),
          };
          break;
        case 'Spatiu comercial':
          data['commercialDetails'] = {
            'type': selectedCategorieSpatiu,
            'area': int.parse(suprafataSpatiuComController.text),
          };
          break;
      }

      await FirebaseFirestore.instance
          .collection('properties')
          .doc(widget.listingId)
          .update(data);

      if (!mounted) return;
      setState(() {
        successMessage = 'Modificarile au fost salvate';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Eroare la salvare: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
          items: /* same list as AddNewListingPage */ [],
          onChanged: (v) => setState(() => selectedJudet = v),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: cityController,
          decoration: const InputDecoration(
            labelText: 'Oras',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Completati orasul' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: streetController,
          decoration: const InputDecoration(
            labelText: 'Strada',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Completati strada' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: numberController,
          decoration: const InputDecoration(
            labelText: 'Numar',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (v) => v!.isEmpty ? 'Completati numarul' : null,
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
    final total = imageUrls.length + selectedImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagini:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // existing URLs
            for (var i = 0; i < imageUrls.length; i++)
              buildThumb(
                Image.network(imageUrls[i], fit: BoxFit.cover),
                onRemove: () => removeImage(i),
              ),

            // newly picked
            for (var j = 0; j < selectedImageBytes.length; j++)
              buildThumb(
                Image.memory(selectedImageBytes[j], fit: BoxFit.cover),
                onRemove: () => removeImage(imageUrls.length + j),
              ),

            // add‐photo tile
            if (total < maxPhotos)
              GestureDetector(
                onTap: pickImages,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_a_photo,
                    size: 36,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildThumb(Widget child, {required VoidCallback onRemove}) {
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
              child: child,
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: onRemove,
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
    }

  Widget buildTransactionTypeChips() {
    final types = ['De vanzare', 'De inchiriat'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tip tranzactie'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children:
              types
                  .map(
                    (t) => ChoiceChip(
                      label: Text(t),
                      selected: transactionType == t,
                      onSelected: (_) => setState(() => transactionType = t),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget buildChoiceChips(
    String label,
    List<String> options,
    String? selected,
    void Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children:
              options
                  .map(
                    (opt) => ChoiceChip(
                      label: Text(opt),
                      selected: selected == opt,
                      onSelected: (_) => onSelect(opt),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget buildDynamicForm() {
    switch (selectedCategory) {
      case 'Apartament':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titlu',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Completati titlu' : null,
            ),
            const SizedBox(height: 10),
            buildChoiceChips(
              'Numar camere',
              ['1', '2', '3', '4', '5'],
              selectedNumarCamereApartament,
              (v) => setState(() => selectedNumarCamereApartament = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Compartimentare',
                border: OutlineInputBorder(),
              ),
              value: selectedCompartimentare,
              items:
                  ['Decomandat', 'Semidecomandat', 'Nedecomandat']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (v) => setState(() => selectedCompartimentare = v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: etajController,
              decoration: const InputDecoration(
                labelText: 'Etaj',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Completati etaj' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: suprafataUtilaApartController,
              decoration: const InputDecoration(
                labelText: 'Suprafata utila (mp)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Completati suprafata' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: anConstructieApartController,
              decoration: const InputDecoration(
                labelText: 'An constructie',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Completati anul' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Pret (EUR)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Completati pretul' : null,
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
              validator: (v) => v!.isEmpty ? 'Completati descrierea' : null,
            ),
            const SizedBox(height: 10),
            buildTransactionTypeChips(),
            const SizedBox(height: 20),
            buildLocalizareFields(),
          ],
        );
      case 'Casa':
        // … implement similar to AddNewListingPage, populating with current controllers
        return const SizedBox.shrink();
      case 'Teren':
      case 'Spatiu comercial':
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
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
                  buildDynamicForm(),
                  const SizedBox(height: 30),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Agent de vanzari',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedAgentName,
                    items:
                        agents
                            .map(
                              (a) => DropdownMenuItem<String>(
                                value: a['name'],
                                child: Text(a['name']),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => selectedAgentName = v),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: isLoading ? null : saveChanges,
                        child:
                            isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Salveaza modificarile',
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:homehunt/models/error_widgets/error_banner.dart';

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
  final int maxPhotos = 15;

  // form controllers
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final cityController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final sectorController = TextEditingController();

  // Apartament
  String? selectedNumarCamereApartament;
  String? selectedCompartimentare;
  final etajController = TextEditingController();
  final suprafataUtilaApartController = TextEditingController();
  final anConstructieApartController = TextEditingController();

  // Casa
  String? selectedNumarCamereCasa;
  final suprafataUtilaCasaController = TextEditingController();
  final suprafataTerenCasaController = TextEditingController();
  final anConstructieCasaController = TextEditingController();
  final etajeCasaController = TextEditingController();

  // Teren
  String? selectedTipTeren;
  String? selectedClasificare;
  final suprafataTerenController = TextEditingController();

  // Spatiu comercial
  String? selectedCategorieSpatiu;
  final suprafataSpatiuComController = TextEditingController();

  // agents
  List<Map<String, dynamic>> agents = [];
  String? selectedAgentName;
  String? selectedAgentId;

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

      // populate category-specific
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
    final slotsLeft = maxPhotos - imageUrls.length - selectedImages.length;
    final toAdd = pics.take(slotsLeft).toList();
    for (final f in toAdd) {
      selectedImageBytes.add(await f.readAsBytes());
    }
    setState(() {
      selectedImages.addAll(toAdd);
      if (pics.length > slotsLeft) {
        errorMessage = 'Poti incarca maxim $maxPhotos poze.';
      }
    });
  }

  Future<List<String>> uploadImages(String propertyId) async {
    final existing = List<String>.from(imageUrls);
    final newUrls = <String>[];
    for (final file in selectedImages) {
      final ext = file.name.split('.').last;
      final name = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref('properties/$propertyId/$name');
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
      imageUrls.removeAt(index);
    } else {
      final localIdx = index - imageUrls.length;
      selectedImages.removeAt(localIdx);
      selectedImageBytes.removeAt(localIdx);
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> saveChanges() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });
    try {
      final allUrls = await uploadImages(widget.listingId);
      final data = <String, dynamic>{
        'title': titleController.text,
        'price': int.parse(priceController.text),
        'description': descriptionController.text,
        'type': transactionType,
        'category': selectedCategory,
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

      //se actualizeaza Firestore
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(widget.listingId)
          .update(data);

      if (!mounted) return;
      setState(() => successMessage = 'Modificările au fost salvate');

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = 'Eroare la salvarea modificarilor');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildChoiceChips(
    String label,
    List<String> options,
    String? sel,
    void Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              options
                  .map(
                    (opt) => ChoiceChip(
                      label: Text(opt),
                      selected: sel == opt,
                      onSelected: (_) => onSelect(opt),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
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
          validator: (v) => v!.isEmpty ? 'Introdu orasul' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: streetController,
          decoration: const InputDecoration(
            labelText: 'Strada',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Introdu strada' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu numarul' : null,
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
              // the big upload/tap area
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
                      (imageUrls.isEmpty && selectedImageBytes.isEmpty)
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
                                          '\n\nMaxim 15 poze. PNG, JPG. Dimensiune maxima 10MB',
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

              // previews of both remote and local images
              if (imageUrls.isNotEmpty || selectedImageBytes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // already‐uploaded:
                    for (var i = 0; i < imageUrls.length; i++)
                      Stack(
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
                              child: Image.network(
                                imageUrls[i],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => removeImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.close, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // newly-picked local bytes:
                    for (var j = 0; j < selectedImageBytes.length; j++)
                      Stack(
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
                              child: Image.memory(
                                selectedImageBytes[j],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => removeImage(imageUrls.length + j),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.close, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
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
          validator: (v) => v!.isEmpty ? 'Introdu titlul' : null,
        ),
        const SizedBox(height: 10),
        buildChoiceChips(
          'Numar camere',
          ['1', '2', '3', '4', '5'],
          selectedNumarCamereApartament ?? '',
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
              [
                'Decomandat',
                'Semidecomandat',
                'Nedecomandat',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => selectedCompartimentare = v),
          validator: (v) => v == null ? 'Selecteaza compartimentarea' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: etajController,
          decoration: const InputDecoration(
            labelText: 'Etaj',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Introdu etaj' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu suprafata' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu anul' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu pretul' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu descrierea' : null,
        ),
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
          validator: (v) => v!.isEmpty ? 'Introdu titlul' : null,
        ),
        const SizedBox(height: 10),
        buildChoiceChips(
          'Numar camere',
          List.generate(10, (i) => '${i + 1}'),
          selectedNumarCamereCasa ?? '',
          (v) => setState(() => selectedNumarCamereCasa = v),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataUtilaCasaController,
          decoration: const InputDecoration(
            labelText: 'Suprafata utila (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v!.isEmpty ? 'Introdu suprafata utila' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu suprafata teren' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu anul constructiei' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu numarul de etaje' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu pretul' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu descrierea' : null,
        ),
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
          validator: (v) => v!.isEmpty ? 'Introdu titlul' : null,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Tip teren',
            border: OutlineInputBorder(),
          ),
          value: selectedTipTeren,
          items:
              [
                'Constructii',
                'Agricol',
                'Forestier',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => selectedTipTeren = v),
          validator: (v) => v == null ? 'Selecteaza tip teren' : null,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Clasificare',
            border: OutlineInputBorder(),
          ),
          value: selectedClasificare,
          items:
              [
                'Intravilan',
                'Extravilan',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => selectedClasificare = v),
          validator: (v) => v == null ? 'Selecteaza clasificare' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu suprafata teren' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu pretul' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu descrierea' : null,
        ),
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
          validator: (v) => v!.isEmpty ? 'Introdu titlul' : null,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Categorie',
            border: OutlineInputBorder(),
          ),
          value: selectedCategorieSpatiu,
          items:
              [
                'Birouri',
                'Comercial',
                'Industrial',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => selectedCategorieSpatiu = v),
          validator: (v) => v == null ? 'Selecteaza categoria' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu suprafata' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu pretul' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu descrierea' : null,
        ),
        const SizedBox(height: 10),
        buildLocalizareFields(),
      ],
    );
  }

  Widget buildDynamicForm() {
    switch (selectedCategory) {
      case 'Apartament':
        return buildApartamentForm();
      case 'Casa':
        return buildCasaForm();
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
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Image.asset('lib/images/logo.png', height: 80),
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
                  buildDynamicForm(),
                  const SizedBox(height: 30),
                  agents.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
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
                        validator:
                            (v) => v == null ? 'Selecteaza agentul' : null,
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

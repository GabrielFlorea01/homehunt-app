import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:homehunt/error_widgets/error_banner.dart';

class NewListingPage extends StatefulWidget {
  const NewListingPage({super.key});
  @override
  NewListingPageState createState() => NewListingPageState();
}

class NewListingPageState extends State<NewListingPage> {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  // common
  List<String> categories = ['Apartament', 'Casa', 'Teren', 'Spatiu comercial'];
  String selectedCategory = 'Apartament';
  String transactionType = 'De vanzare';

  // image picker
  final ImagePicker picker = ImagePicker();
  List<String> imageUrls = [];
  List<XFile> selectedImages = [];
  List<Uint8List> selectedImageBytes = [];
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

  // Apartament fields
  String? selectedNumarCamereApartament;
  String? selectedCompartimentare;
  final etajController = TextEditingController();
  final suprafataUtilaApartController = TextEditingController();
  final anConstructieApartController = TextEditingController();

  // Casa fields
  String? selectedNumarCamereCasa;
  final suprafataUtilaCasaController = TextEditingController();
  final suprafataTerenCasaController = TextEditingController();
  final anConstructieCasaController = TextEditingController();
  final etajeCasaController = TextEditingController();

  // Teren fields
  String? selectedTipTeren;
  String? selectedClasificare;
  final suprafataTerenController = TextEditingController();

  // Spatiu comercial fields
  String? selectedCategorieSpatiu;
  final suprafataSpatiuComController = TextEditingController();

  // agents
  List<Map<String, dynamic>> agents = [];
  String? selectedAgentName;
  String? selectedAgentId;

  // location
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
        errorMessage = 'Poti incarca maxim $maxPhotos poze';
      }
    });
  }

  Future<List<String>> uploadImages(String propertyId) async {
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
    return [...imageUrls, ...newUrls];
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

  Future<void> saveProperty() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });
    try {
      // create the doc with initial data
      final data = <String, dynamic>{
        'title': titleController.text,
        'price': int.parse(priceController.text),
        'description': descriptionController.text,
        'type': transactionType,
        'category': selectedCategory,
        'images': [],
        'location': {
          'county': selectedJudet,
          'city': cityController.text,
          'street': streetController.text,
          'number': numberController.text,
          'sector': sectorController.text,
        },
        'agentId': selectedAgentId,
        'agentName': selectedAgentName,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser!.uid,
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

      final docRef = await FirebaseFirestore.instance
          .collection('properties')
          .add(data);

      final allUrls = await uploadImages(docRef.id);
      await docRef.update({'images': allUrls});

      if (!mounted) return;
      setState(() => successMessage = 'Anunt publicat cu succes');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = 'Eroare la salvarea anuntului');
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Widget buildChoiceChips(
    String label,
    List<String> options,
    String? sel,
    Function(String) onSelect,
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

  Widget buildTransactionTypeChips() {
    final types = ['De vanzare', 'De inchiriat'];
    return buildChoiceChips(
      'Tip tranzactie',
      types,
      transactionType,
      (v) => setState(() => transactionType = v),
    );
  }

  Widget buildLocalizareFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localizare:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Judet',
            border: OutlineInputBorder(),
          ),
          value: selectedJudet,
          validator: (v) => v == null ? 'Selecteaza judetul' : null,
          items:
              judete
                  .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                  .toList(),
          onChanged: (v) => setState(() => selectedJudet = v),
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
                  child: (imageUrls.isEmpty && selectedImageBytes.isEmpty)
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
                              child: Image.network(imageUrls[i], fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => removeImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow:[BoxShadow(color:Colors.black26,blurRadius:3)]
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
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => removeImage(imageUrls.length + j),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow:[BoxShadow(color:Colors.black26,blurRadius:3)]
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


  Widget buildApartmentForm() {
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
          validator: (v) => v!.isEmpty ? 'Introdu titlul' : null,
        ),
        const SizedBox(height: 10),
        buildChoiceChips(
          'Numar camere',
          List.generate(10, (i) => '${i + 1}'),
          selectedNumarCamereCasa,
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
          validator: (v) => v!.isEmpty ? 'Introdu descrierea' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu descrierea' : null,
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
          validator: (v) => v!.isEmpty ? 'Introdu descrierea' : null,
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
      case 'Apartament':
        return buildApartmentForm();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      body:
          isWide
              ? Row(
                children: [
                  Expanded(child: buildFormSide()),
                  Expanded(child: buildImageSide()),
                ],
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 200, child: buildImageSide()),
                    buildFormSide(),
                  ],
                ),
              ),
    );
  }

  Widget buildFormSide() {
    return SingleChildScrollView(
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
                  const SizedBox(height: 16),
                ] else if (successMessage != null) ...[
                  ErrorBanner(
                    message: successMessage!,
                    messageType: MessageType.success,
                    onDismiss: () => setState(() => successMessage = null),
                  ),
                  const SizedBox(height: 16),
                ],

                // category chips
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

                // dynamic form
                buildDynamicForm(),
                const SizedBox(height: 30),

                // agent dropdown
                agents.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Alege agentul',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedAgentName,
                      validator: (v) => v == null ? 'Selecteaza agentul' : null,
                      items:
                          agents
                              .map(
                                (a) => DropdownMenuItem<String>(
                                  value: a['name'] as String,
                                  child: Text(a['name'] as String),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (v) => setState(() {
                            selectedAgentName = v;
                            selectedAgentId =
                                agents.firstWhere((a) => a['name'] == v)['id']
                                    as String;
                          }),
                    ),
                const SizedBox(height: 40),

                // publish button
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
                                if (selectedImages.isEmpty &&
                                    imageUrls.isEmpty) {
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
    );
  }

  Widget buildImageSide() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/images/homehuntlogin.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

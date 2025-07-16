import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:homehunt/models/error_widgets/error_banner.dart';
import 'package:intl/intl.dart';

class NewListingPage extends StatefulWidget {
  const NewListingPage({super.key});
  @override
  NewListingPageState createState() => NewListingPageState();
}

class NewListingPageState extends State<NewListingPage> {
  bool isLoading = false; // starea de incarcare
  String? errorMessage; // mesaj de eroare
  String? successMessage; // mesaj de succes

  // lista de categorii
  List<String> categories = [
    'Apartament',
    'Garsoniera',
    'Casa',
    'Teren',
    'Spatiu comercial',
  ];
  String selectedCategory = 'Apartament'; // categoria selectata -default
  String transactionType = 'De vanzare'; // tipul tranzactiei - default

  // initializare liste si metode pentru imagini
  final ImagePicker picker = ImagePicker();
  List<String> imageUrls = [];
  List<XFile> selectedImages = [];
  List<Uint8List> selectedImageBytes = [];
  final int maxPhotos = 15;

  // controllere pentru formular
  // cheia pentru validarea si controlul formularului
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final cityController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final sectorController = TextEditingController();

  // campuri pentru Apartament
  String? selectedNumarCamereApartament;
  String? selectedCompartimentare;
  final etajController = TextEditingController();
  final suprafataUtilaApartController = TextEditingController();
  final anConstructieApartController = TextEditingController();

  // campuri pentru Garsoniera
  final etajGarsonieraController = TextEditingController();
  final suprafataUtilaGarsonieraController = TextEditingController();
  final anConstructieGarsonieraController = TextEditingController();

  // campuri pentru Casa
  String? selectedNumarCamereCasa;
  final suprafataUtilaCasaController = TextEditingController();
  final suprafataTerenCasaController = TextEditingController();
  final anConstructieCasaController = TextEditingController();
  final etajeCasaController = TextEditingController();

  // campuri pentru Teren
  String? selectedTipTeren;
  String? selectedClasificare;
  final suprafataTerenController = TextEditingController();

  // campuri pentru Spatiu Comercial
  String? selectedCategorieSpatiu;
  final suprafataSpatiuComController = TextEditingController();

  // initializare lista agenti
  List<Map<String, dynamic>> agents = [];
  String? selectedAgentName; // numele agentului selectat
  String? selectedAgentId; // id-ul agentului selectat

  // lista cu judete pentru locatie
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

  // eticheta pentru pret in functie de tipul tranzactiei
  String get priceLabel =>
      transactionType == 'De inchiriat'
          ? 'Pret chirie (EUR/luna)'
          : 'Pret (EUR)';

  @override
  void initState() {
    super.initState();
    loadAgents();
  }

  // initializare lista de agenti din baza de date
  Future<void> loadAgents() async {
    final snap = await FirebaseFirestore.instance.collection('agents').get();
    if (!mounted) return;
    setState(() {
      agents =
          snap.docs
              .map((agent) => {'id': agent.id, 'name': agent['name'] as String})
              .toList();
    });
  }

  // dropdown pentru alegerea agentului
  Widget buildAgentDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Alege agentul',
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      value: selectedAgentId,
      validator: (v) => v == null ? 'Selecteaza agentul' : null,
      items:
          agents.map((agent) {
            return DropdownMenuItem<String>(
              value: agent['id'] as String,
              child: Text(agent['name'] as String),
            );
          }).toList(),
      onChanged: (id) {
        setState(() {
          selectedAgentId = id;
          selectedAgentName =
              agents.firstWhere((aName) => aName['id'] == id)['name'] as String;
        });
      },
    );
  }

  // selectarea imaginilor
  Future<void> pickImages() async {
    final pics = await picker.pickMultiImage(maxWidth: 1200, imageQuality: 80);
    if (pics.isEmpty) return;

    // verificam cate locuri sunt disponibile
    final slotsLeft = maxPhotos - imageUrls.length - selectedImages.length;
    final toAdd =
        pics.take(slotsLeft).toList(); // doar atat cate sunt disponibile
    for (final f in toAdd) {
      selectedImageBytes.add(
        await f.readAsBytes(),
      ); // adaugam imaginea in lista de bytes
    }
    setState(() {
      selectedImages.addAll(toAdd);
      if (pics.length > slotsLeft) {
        errorMessage = 'Poti incarca maxim $maxPhotos poze';
      }
    });
  }

  // incarcare imagini in Firebase Storage si returnare url-uri
  Future<List<String>> uploadImages(String propertyId) async {
    final newUrls = <String>[]; // lista pentru url-uri
    for (final file in selectedImages) {
      final ext = file.name.split('.').last;
      final name = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref(
        'properties/$propertyId/$name',
      ); // referinta la fisierul din storage
      final snap = await ref.putData(
        await file.readAsBytes(),
        SettableMetadata(contentType: file.mimeType),
      );
      newUrls.add(await snap.ref.getDownloadURL());
    }
    return [...imageUrls, ...newUrls];
  }

  // stergere imaginea selectata
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

  // salvare proprietate
  Future<void> saveProperty() async {
    // validare formular + validare numar camere formulare
    if (!formKey.currentState!.validate()) return;
    // validare numar camere pentru apartament si casa
    if (selectedCategory == 'Apartament' &&
        selectedNumarCamereApartament == null) {
      setState(() => errorMessage = 'Selecteaza numarul de camere');
      return;
    }
    if (selectedCategory == 'Casa' && selectedNumarCamereCasa == null) {
      setState(() {
        errorMessage = 'Selecteaza numarul de camere pentru casa';
      });
      return;
    }

    setState(() {
      isLoading = true; //se porneste starea de incarcare
      errorMessage = null; // se reseteaza mesajele de eroare si succes
      successMessage = null;
    });

    try {
      // documentul cu datele initiale preluate din controllere
      final data = <String, dynamic>{
        'title': titleController.text,
        'price': parseFormattedNumber(priceController.text),
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

      // detalii specifice in functie de categorie
      switch (selectedCategory) {
        case 'Apartament':
          data['apartmentDetails'] = {
            'rooms': selectedNumarCamereApartament,
            'compartments': selectedCompartimentare,
            'floor': etajController.text,
            'area': parseFormattedNumber(suprafataUtilaApartController.text),
            'yearBuilt': int.parse(anConstructieApartController.text),
          };
          break;
        case 'Garsoniera':
          data['garsonieraDetails'] = {
            'floor': etajGarsonieraController.text,
            'area': parseFormattedNumber(
              suprafataUtilaGarsonieraController.text,
            ),
            'yearBuilt': int.parse(anConstructieGarsonieraController.text),
          };
          break;
        case 'Casa':
          data['houseDetails'] = {
            'rooms': selectedNumarCamereCasa,
            'area': parseFormattedNumber(suprafataUtilaCasaController.text),
            'landArea': parseFormattedNumber(suprafataTerenCasaController.text),
            'yearBuilt': int.parse(anConstructieCasaController.text),
            'floors': int.parse(etajeCasaController.text),
          };
          break;
        case 'Teren':
          data['landDetails'] = {
            'type': selectedTipTeren,
            'classification': selectedClasificare,
            'area': parseFormattedNumber(suprafataTerenController.text),
          };
          break;
        case 'Spatiu comercial':
          data['commercialDetails'] = {
            'type': selectedCategorieSpatiu,
            'area': parseFormattedNumber(suprafataSpatiuComController.text),
          };
          break;
      }

      // se adauga datele pentru proprietate
      final docRef = await FirebaseFirestore.instance
          .collection('properties')
          .add(data);

      // se actualizeaza campul cu imaginile pentru proprietate
      final allUrls = await uploadImages(docRef.id);
      await docRef.update({'images': allUrls});

      // se actualizeaza lista cu proprietati pentru agenti
      await FirebaseFirestore.instance
          .collection('agents')
          .doc(selectedAgentId)
          .update({
            'properties': FieldValue.arrayUnion([docRef.id]),
          });

      if (!mounted) return;
      setState(
        () => successMessage = 'Anunt publicat cu succes',
      ); // mesaj de succes
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => errorMessage = 'Eroare la salvarea anuntului',
      ); // mesaj de eroare daca apare o exceptie
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // parse numar din text
  int parseFormattedNumber(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }

  // formatare numar la tastaare - live
  void formatNumber(TextEditingController controller, String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      controller.clear();
      return;
    }
    final formatted = NumberFormat.decimalPattern(
      'ro',
    ).format(int.parse(digits));
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // widget chips pentru alegerea diferitelor optiuni din formular
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

  // chips pentru tipul tranzactiei
  Widget buildTransactionTypeChips() {
    final types = ['De vanzare', 'De inchiriat'];
    return buildChoiceChips(
      'Tip tranzactie',
      types,
      transactionType,
      (v) => setState(() => transactionType = v),
    );
  }

  // campuri pentru localizare
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
                  .map(
                    (judet) =>
                        DropdownMenuItem(value: judet, child: Text(judet)),
                  )
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

  // widget pentru sectiunea de imagini
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
              // zona pentru upload/tap
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
                      // iconita si text daca nu sunt imagini
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
              // afisam preview pentru imagini daca exista
              if (imageUrls.isNotEmpty || selectedImageBytes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // imagini deja incarcate
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
                          // este imagine incarcata, afisam butonul de stergere cu functia de removeImage
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
                    // imagini noi selectate local, se afiseaza ca stack
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
                          // daca este imagine noua incarcata afisam butonul de stergere cu functia de removeImage si aici
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

  // widget/formular pentru apartament
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

        // chips pentru numarul de camere
        buildChoiceChips(
          'Numar camere',
          ['1', '2', '3', '4', '5', '5+'],
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
          onChanged: (v) => formatNumber(suprafataUtilaApartController, v),
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
        const SizedBox(height: 20),

        // chips pentru tipul tranzactiei
        buildTransactionTypeChips(),
        const SizedBox(height: 20),

        TextFormField(
          controller: priceController,
          onChanged: (v) => formatNumber(priceController, v),
          decoration: InputDecoration(
            labelText: priceLabel,
            border: const OutlineInputBorder(),
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
        const SizedBox(height: 30),

        // campuri pentru locatie
        buildLocalizareFields(),
      ],
    );
  }

  // widget/formular pentru garsoniera - la fel ca pentru apartament
  Widget buildGarsonieraForm() {
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
        TextFormField(
          controller: etajGarsonieraController,
          decoration: const InputDecoration(
            labelText: 'Etaj',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Introdu etaj' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataUtilaGarsonieraController,
          onChanged: (v) => formatNumber(suprafataUtilaGarsonieraController, v),
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
          controller: anConstructieGarsonieraController,
          decoration: const InputDecoration(
            labelText: 'An constructie',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v!.isEmpty ? 'Introdu anul' : null,
        ),
        const SizedBox(height: 20),
        buildTransactionTypeChips(),
        const SizedBox(height: 20),
        TextFormField(
          controller: priceController,
          onChanged: (v) => formatNumber(priceController, v),
          decoration: InputDecoration(
            labelText: priceLabel,
            border: const OutlineInputBorder(),
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
        const SizedBox(height: 30),
        buildLocalizareFields(),
      ],
    );
  }

  // widget/formular pentru casa
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
          [for (var i = 1; i <= 10; i++) '$i', '10+'],
          selectedNumarCamereCasa,
          (v) => setState(() => selectedNumarCamereCasa = v),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: suprafataUtilaCasaController,
          onChanged: (v) => formatNumber(suprafataUtilaCasaController, v),
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
          onChanged: (v) => formatNumber(suprafataTerenCasaController, v),
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
        const SizedBox(height: 20),
        buildTransactionTypeChips(),
        const SizedBox(height: 20),
        TextFormField(
          controller: priceController,
          onChanged: (v) => formatNumber(priceController, v),
          decoration: InputDecoration(
            labelText: priceLabel,
            border: const OutlineInputBorder(),
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
        const SizedBox(height: 30),
        buildLocalizareFields(),
      ],
    );
  }

  // widget/formular pentru teren
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
          onChanged: (v) => formatNumber(suprafataTerenController, v),
          decoration: const InputDecoration(
            labelText: 'Suprafata teren (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v!.isEmpty ? 'Introdu suprafata teren' : null,
        ),
        const SizedBox(height: 20),
        buildTransactionTypeChips(),
        const SizedBox(height: 20),
        TextFormField(
          controller: priceController,
          onChanged: (v) => formatNumber(priceController, v),
          decoration: InputDecoration(
            labelText: priceLabel,
            border: const OutlineInputBorder(),
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
        const SizedBox(height: 30),
        buildLocalizareFields(),
      ],
    );
  }

  // formular pentru spatiu comercial
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
          onChanged: (v) => formatNumber(suprafataSpatiuComController, v),
          decoration: const InputDecoration(
            labelText: 'Suprafata (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v!.isEmpty ? 'Introdu suprafata' : null,
        ),
        const SizedBox(height: 20),
        buildTransactionTypeChips(),
        const SizedBox(height: 20),
        TextFormField(
          controller: priceController,
          onChanged: (v) => formatNumber(priceController, v),
          decoration: InputDecoration(
            labelText: priceLabel,
            border: const OutlineInputBorder(),
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
        const SizedBox(height: 30),
        buildLocalizareFields(),
      ],
    );
  }

  // formular dinamic in functie de categoria selectata
  Widget buildDynamicForm() {
    switch (selectedCategory) {
      case 'Apartament':
        return buildApartmentForm();
      case 'Garsoniera':
        return buildGarsonieraForm();
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

  //widget default impartit cu fomrularul si imaginea
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

  // construire formularul si publicarea anuntului
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
                // categoria selectata din chips
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      categories.map((category) {
                        return ChoiceChip(
                          label: Text(category),
                          selected: selectedCategory == category,
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                // se genereaza formularul dinamic in functie de categorie
                buildDynamicForm(),
                const SizedBox(height: 30),
                // dropdown pentru selectarea agentului
                buildAgentDropdown(),
                const SizedBox(height: 40),
                // butonul de publicare anunt
                Center(
                  child: SizedBox(
                    width: 300,
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
                                //verificare daca sunt imagini incarcate
                                if (selectedImages.isEmpty &&
                                    imageUrls.isEmpty) {
                                  setState(() {
                                    errorMessage =
                                        'Te rog incarca cel putin o imagine';
                                  });
                                  return;
                                }
                                // se salveaza proprietatea daca formularul este in regula
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

  // widget pentru partea de imagine
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNewListingPage extends StatefulWidget {
  const AddNewListingPage({super.key});

  @override
  State<AddNewListingPage> createState() => AddNewListingPageState();
}

class AddNewListingPageState extends State<AddNewListingPage> {
  String selectedCategory = 'Apartament';
  String transactionType = 'De inchiriat';
  String? selectedAgent;
  List<String> agents = [];
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
        agents = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (_) {
      // handle error if needed
    }
  }

  @override
  void initState() {
    super.initState();
    getAgents();
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
          items:
              judete
                  .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                  .toList(),
          onChanged: (_) {},
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Oras',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Strada',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Numar',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Sector (optional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget buildChoiceChips(String label, List<String> options) {
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
                  selected: false,
                  onSelected: (_) {},
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget buildCommonFields({
    bool includeEtaj = false,
    bool includeAnConstructie = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        if (includeAnConstructie) ...[
          const SizedBox(height: 10),
          const TextField(
            decoration: InputDecoration(
              labelText: 'An constructie',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
        if (includeEtaj) ...[
          const SizedBox(height: 10),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Etaje',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Descriere',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget buildApartamentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Titlu',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Numar camere',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: 'Compartimentare',
            border: OutlineInputBorder(),
          ),
          items:
              [
                'Decomandat',
                'Semidecomandat',
                'Nedecomandat',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (_) {},
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Etaj',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Suprafata utila (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        buildCommonFields(includeAnConstructie: true),
        buildLocalizareFields(),
      ],
    );
  }

  Widget buildCasaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Titlu',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
        ),
        const SizedBox(height: 10),
        buildChoiceChips('Numar camere', List.generate(10, (i) => '${i + 1}')),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Suprafata utila (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Suprafata teren (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        buildCommonFields(includeEtaj: true, includeAnConstructie: true),
        buildLocalizareFields(),
      ],
    );
  }

  Widget buildTerenForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Titlu',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
        ),
        DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: 'Tip teren',
            border: OutlineInputBorder(),
          ),
          items:
              [
                'Agricol',
                'Constructii',
                'Forestier',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (_) {},
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: 'Clasificare',
            border: OutlineInputBorder(),
          ),
          items:
              [
                'Intravilan',
                'Extravilan',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (_) {},
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Suprafata teren (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        buildCommonFields(),
        buildLocalizareFields(),
      ],
    );
  }

  Widget buildSpatiuComercialForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Titlu',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
        ),
        DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: 'Categorie',
            border: OutlineInputBorder(),
          ),
          items:
              [
                'Birou',
                'Magazin',
                'Hala',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (_) {},
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Suprafata (mp)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Pret (EUR)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        buildCommonFields(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      items:
                          agents
                              .map(
                                (agent) => DropdownMenuItem<String>(
                                  value: agent,
                                  child: Text(agent),
                                ),
                              )
                              .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedAgent = newValue;
                        });
                      },
                    ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text('Publica anuntul'),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

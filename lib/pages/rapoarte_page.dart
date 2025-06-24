import 'package:flutter/material.dart';
import 'reports/properties_reports_page.dart';
import 'reports/users_report_page.dart';

class RapoartePage extends StatelessWidget {
  const RapoartePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: isWide
                  ? Row(children: [buildFormPane(context), buildImagePane()])
                  : Column(children: [buildImagePane(), buildFormPane(context)]),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFormPane(BuildContext context) {
    return Expanded(
      flex: 7,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Selectează raportul',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ReportCard(
                icon: Icons.people,
                title: 'Utilizatori inregistrati',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersReportPage()),
                ),
              ),
              const SizedBox(height: 16),
              ReportCard(
                icon: Icons.home,
                title: 'Proprietați vandute/inchiriate',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PropertiesReportPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildImagePane() {
    return Expanded(
      flex: 5,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/images/homehuntlogin.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ReportCard({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

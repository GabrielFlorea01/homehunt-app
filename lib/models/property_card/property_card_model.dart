import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef VoidStringCallback = void Function(String id);

class PropertyCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isFavorite;
  final VoidStringCallback? onToggleFavorite;
  final VoidStringCallback? onEdit;
  final VoidStringCallback? onDelete;
  final bool showBooking;
  final VoidStringCallback? onBook;
  final void Function(BuildContext, List<String>, int) openGallery;
  final Widget Function(String address) buildMapSection;
  final ScrollController? scrollController;

  const PropertyCard({
    super.key,
    required this.data,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.openGallery,
    required this.buildMapSection,
    this.onEdit,
    this.onDelete,
    this.showBooking = false,
    this.onBook, 
    this.scrollController
  });

  @override
  PropertyCardState createState() => PropertyCardState();
}

class PropertyCardState extends State<PropertyCard> {
  bool showPhone = false;

  List<Widget> _buildChips(Map<String, dynamic> data) {
    switch (data['category'] as String? ?? '') {
      case 'Garsoniera':
        final g = data['garsonieraDetails'] as Map<String, dynamic>? ?? {};
        return [
          const Chip(label: Text('1 camera'), visualDensity: VisualDensity.compact),
          Chip(label: Text('${g['area'] ?? ''} mp'), visualDensity: VisualDensity.compact),
          Chip(label: Text('Etaj ${g['floor'] ?? ''}'), visualDensity: VisualDensity.compact),
          Chip(label: Text('An ${g['yearBuilt'] ?? ''}'), visualDensity: VisualDensity.compact),
        ];
      case 'Apartament':
        final a = data['apartmentDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(label: Text('${a['rooms']} camere'), visualDensity: VisualDensity.compact),
          Chip(label: Text('${a['area']} mp'), visualDensity: VisualDensity.compact),
          Chip(label: Text('Etaj ${a['floor']}'), visualDensity: VisualDensity.compact),
          Chip(label: Text('An ${a['yearBuilt']}'), visualDensity: VisualDensity.compact),
        ];
      case 'Casa':
        final c = data['houseDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(label: Text('${c['rooms']} camere'), visualDensity: VisualDensity.compact),
          Chip(label: Text('${c['area']} mp utili'), visualDensity: VisualDensity.compact),
          Chip(label: Text('${c['landArea']} mp teren'), visualDensity: VisualDensity.compact),
          Chip(label: Text('${c['floors']} etaje'), visualDensity: VisualDensity.compact),
          Chip(label: Text('An ${c['yearBuilt']}'), visualDensity: VisualDensity.compact),
        ];
      case 'Teren':
        final t = data['landDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(label: Text(t['classification'] ?? ''), visualDensity: VisualDensity.compact),
          Chip(label: Text('${t['area']} mp'), visualDensity: VisualDensity.compact),
        ];
      case 'Spatiu comercial':
        final sc = data['commercialDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(label: Text('${sc['area']} mp'), visualDensity: VisualDensity.compact),
        ];
      default:
        return [];
    }
  }

  String get fullAddress {
    final loc = widget.data['location'] as Map<String, dynamic>? ?? {};
    return [
      loc['street'] ?? '',
      loc['number'] ?? '',
      if ((loc['sector'] ?? '').toString().isNotEmpty) 'Sector ${loc['sector']}',
      loc['city'] ?? '',
      loc['county'] ?? '',
    ].where((s) => s.trim().isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final images = List<String>.from(data['images'] as List? ?? []);
    final id = data['id'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE + FAVORITE + TAG
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: images.isNotEmpty
                      ? Image.network(
                          images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
                        )
                      : Container(color: Colors.grey.shade300),
                ),
              ),
              if (widget.onToggleFavorite != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(
                        widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: widget.isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => widget.onToggleFavorite!(id),
                    ),
                  ),
                ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data['type'] as String? ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (widget.onEdit != null || widget.onDelete != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      if (widget.onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => widget.onEdit!(id),
                        ),
                      if (widget.onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => widget.onDelete!(id),
                        ),
                    ],
                  ),
                ),
            ],
          ),

          // DETAILS & EXPANSION TILE
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              data['title'] as String? ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '€ ${NumberFormat.decimalPattern('ro').format((data['price'] as num?) ?? 0)}',
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (fullAddress.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(fullAddress)),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 4, children: _buildChips(data)),
              if ((data['description'] as String?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Text(data['description'] as String),
              ],
              if (images.length > 1) ...[
                SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: () => widget.scrollController!.animateTo(
                          widget.scrollController!.offset - 100,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: widget.scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) => SizedBox(width: 8),
                          itemBuilder: (_, idx) => GestureDetector(
                            onTap: () => widget.openGallery(context, images, idx),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                images[idx],
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: () => widget.scrollController!.animateTo(
                          widget.scrollController!.offset + 100,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // MAP
              widget.buildMapSection(fullAddress),
              const SizedBox(height: 12),

              // AGENT + BOOKING
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('agents')
                    .doc(data['agentId'] as String)
                    .get(),
                builder: (ctx, snap) {
                  final agentName = data['agentName'] as String? ?? '';
                  final phone = snap.hasData ? (snap.data!['phone'] as String? ?? '') : '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(agentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (showPhone) ...[
                                  const SizedBox(height: 4),
                                  Text(phone, style: const TextStyle(color: Colors.grey)),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () => setState(() => showPhone = !showPhone),
                          ),
                        ],
                      ),
                      if (widget.showBooking && widget.onBook != null) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => widget.onBook!(id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Programeaza o vizionare'),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

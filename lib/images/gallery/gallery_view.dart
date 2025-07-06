import 'package:flutter/material.dart';

// Fullscreen gallery view for pics
class GalleryView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const GalleryView({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<GalleryView> createState() => GalleryViewState();
}

class GalleryViewState extends State<GalleryView> {
  late PageController pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => currentIndex = i),
            itemBuilder:
                (_, i) => InteractiveViewer(
                  child: Image.network(
                    widget.images[i],
                    fit: BoxFit.contain,
                    loadingBuilder:
                        (_, child, prog) =>
                            prog == null
                                ? child
                                : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                    errorBuilder:
                        (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.white70,
                          ),
                        ),
                  ),
                ),
          ),
        ),
        Container(
          color: Colors.black,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed:
                    currentIndex > 0
                        ? () => pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                        : null,
              ),
              Text(
                '${currentIndex + 1}/${widget.images.length}',
                style: const TextStyle(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onPressed:
                    currentIndex < widget.images.length - 1
                        ? () => pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                        : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';

class TipsDialog extends StatefulWidget {
  const TipsDialog({super.key});

  static void show() {
    Get.dialog(
      const TipsDialog(),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
    );
  }

  @override
  State<TipsDialog> createState() => _TipsDialogState();
}

class _TipsDialogState extends State<TipsDialog> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  final List<Map<String, String>> _tips = [
    {
      "icon": "🤲",
      "title": "Hands Off the Pills",
      "desc": "Avoid touching the outside of homeopathic pellets. Pour them directly into the cap or a spoon before taking them.",
    },
    {
      "icon": "⏳",
      "title": "No Food or Drink\nBefore & After",
      "desc": "For best absorption, avoid eating, drinking, or brushing your teeth 15 minutes before and after your dose.",
    },
    {
      "icon": "🔥",
      "title": "Store with Care",
      "desc": "Keep remedies away from heat, sunlight, electronics, and strong smells like perfumes or essential oils.",
    },
    {
      "icon": "💊",
      "title": "Starting a Banerji\nProtocol?",
      "desc": "Take Camphora 200C one day before beginning any Banerji protocol to clear interference.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Skip Button
            if (_currentIndex < _tips.length)
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 18),

            const SizedBox(height: 10),

            // Carousel
            CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                height: 160,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: List.generate(_tips.length + 1, (index) {
                if (index == _tips.length) {
                  // Final Slide
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Now you're ready to\nget started!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  );
                }
                
                final tip = _tips[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tip['icon']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            tip['title']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tip['desc']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textGrey,
                        height: 1.5,
                      ),
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 20),

            // Dots Indicator
            if (_currentIndex < _tips.length)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_tips.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? AppColors.textBlack : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

            const SizedBox(height: 24),

            // Next / Get Started Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentIndex < _tips.length) {
                    _carouselController.nextPage();
                  } else {
                    Get.back(); // Close dialog
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  _currentIndex < _tips.length ? 'Next' : 'Get Started',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

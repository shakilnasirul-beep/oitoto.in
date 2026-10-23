import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import '../core/localization/app_localizations.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class RideCategoryScreen extends StatefulWidget {
  const RideCategoryScreen({super.key});

  @override
  State<RideCategoryScreen> createState() => _RideCategoryScreenState();
}

class _RideCategoryScreenState extends State<RideCategoryScreen> {
  String _selectedCategory = 'toto';

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'toto',
      'name': 'Oi Toto (E-Rickshaw)',
      'name_bn': 'ওই টোটো (ই-রিকশা)',
      'icon': '🛺',
      'desc': 'Eco-friendly 4-seater Toto with fixed low fares & zero surge',
      'desc_bn': 'পরিবেশবান্ধব ৪-আসন টোটো, স্থির স্বল্প ভাড়া ও জিরো সার্জ',
      'base_fare': '₹20 Base',
      'badge': 'MOST POPULAR',
      'badge_color': AppColors.primaryGreen,
      'is_featured': true,
    },
    {
      'id': 'bike',
      'name': 'Oi Moto / Bike',
      'name_bn': 'ওই বাইক ট্যাক্সি',
      'icon': '🏍️',
      'desc': 'Fastest single passenger moto ride to cut through metro traffic',
      'desc_bn': 'শহরের ট্রাফিকের জন্য দ্রুতগতির একক যাত্রী বাইক ট্যাক্সি',
      'base_fare': '₹15 Base',
      'badge': 'QUICK RIDE',
      'badge_color': Color(0xFF0284C7),
      'is_featured': false,
    },
    {
      'id': 'cab',
      'name': 'Oi Cab (4-Wheeler)',
      'name_bn': 'ওই ক্যাব (৪-হুইলার)',
      'icon': '🚗',
      'desc': 'Comfortable AC electric cab for families with luggage space',
      'desc_bn': 'পরিবার ও লাগেজের জন্য আরামদায়ক এসি ইলেকট্রিক ক্যাব',
      'base_fare': '₹50 Base',
      'badge': 'AC COMFORT',
      'badge_color': Color(0xFF7C3AED),
      'is_featured': false,
    },
    {
      'id': 'cargo',
      'name': 'Oi Cargo (Heavy)',
      'name_bn': 'ওই কার্গো / মিনি-ট্রাক',
      'icon': '🚛',
      'desc': 'Commercial mini-truck for bulky cargo, shop goods & shifting',
      'desc_bn': 'ভারী মালামাল, দোকানের মাল ও বাসা বদলের জন্য মিনি-ট্রাক',
      'base_fare': '₹120 Base',
      'badge': 'HEAVY LOADS',
      'badge_color': Color(0xFFD97706),
      'is_featured': false,
    },
    {
      'id': 'parcel',
      'name': 'Oi Parcel Delivery',
      'name_bn': 'ওই পার্সেল ডেলিভারি',
      'icon': '📦',
      'desc': 'Door-to-door courier service with instant secure OTP delivery',
      'desc_bn': 'ডোর-টু-ডোর দ্রুত পার্সেল ডেলিভারি ও নিরাপদ ওটিপি হ্যান্ডওভার',
      'base_fare': '₹25 Base',
      'badge': 'DOORSTEP',
      'badge_color': Color(0xFF059669),
      'is_featured': false,
    },
  ];

  Map<String, dynamic> get _currentCat =>
      _categories.firstWhere((c) => c['id'] == _selectedCategory);

  void _proceedToMap() {
    final cat = _currentCat;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          selectedCategory: cat['id'] as String,
          categoryName: cat['name'] as String,
          categoryIcon: cat['icon'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = ApiService().language == 'bn';
    final loc = AppLocalizations(ApiService().language);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png', width: 28, height: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            const Text(
              'Oi Toto!',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.deepNavy),
            ),
          ],
        ),
        actions: [
          // Language Switcher
          TextButton.icon(
            onPressed: () {
              setState(() {
                final nextLang = isBn ? 'en' : 'bn';
                ApiService().setLanguage(nextLang);
              });
            },
            icon: const Icon(Icons.translate, size: 16, color: AppColors.primaryGreen),
            label: Text(
              isBn ? 'বাংলা' : 'EN',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryGreenDark),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person_outline, color: AppColors.textMain),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? 'আপনার রাইড বেছে নিন' : 'Select Ride Category',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.deepNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBn
                      ? 'পশ্চিমবঙ্গ ও বিহার জুড়ে পরিবেশবান্ধব নির্দিষ্ট ভাড়ার ভ্রমণ'
                      : 'Fast, fixed-fare & zero-surge mobility across Bengal & Bihar',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat['id'] == _selectedCategory;
                final name = isBn ? (cat['name_bn'] ?? cat['name']) : cat['name'];
                final desc = isBn ? (cat['desc_bn'] ?? cat['desc']) : cat['desc'];

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat['id']);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryGreen : AppColors.border,
                        width: isSelected ? 2.2 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.primaryGreen.withOpacity(0.12)
                              : Colors.black.withOpacity(0.03),
                          blurRadius: isSelected ? 10 : 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vehicle Emoji / Icon Box
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGreenLight
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              cat['icon'] as String,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title, Description & Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? AppColors.primaryGreenDark : AppColors.deepNavy,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (cat['badge_color'] as Color).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cat['badge'] as String,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: cat['badge_color'] as Color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    cat['base_fare'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('•', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '100% Fixed Fare',
                                    style: TextStyle(fontSize: 11, color: AppColors.primaryGreenDark, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Selection Radio Icon
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
                          color: isSelected ? AppColors.primaryGreen : Colors.grey.shade400,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Continue Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _proceedToMap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isBn
                            ? 'ম্যাপে যান — চলো!'
                            : 'Continue with ${_currentCat['name']} — Chalo!',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

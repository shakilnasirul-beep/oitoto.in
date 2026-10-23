import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/driver_theme.dart';
import '../core/localization/driver_localizations.dart';
import '../core/services/driver_api_service.dart';
import 'driver_home_screen.dart';
import 'kyc_documents_screen.dart';

class DriverAuthScreen extends StatefulWidget {
  const DriverAuthScreen({super.key});

  @override
  State<DriverAuthScreen> createState() => _DriverAuthScreenState();
}

class _DriverAuthScreenState extends State<DriverAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _sandboxOtpHint;
  String _currentLang = 'en';
  String _selectedCategory = 'toto';

  final List<Map<String, String>> _categories = [
    {'id': 'toto', 'name': 'Oi Toto (E-Rickshaw)', 'icon': '🛺'},
    {'id': 'bike', 'name': 'Oi Bike / Moto', 'icon': '🏍️'},
    {'id': 'cab', 'name': 'Oi Cab (4-Wheeler)', 'icon': '🚗'},
    {'id': 'cargo', 'name': 'Oi Cargo (Heavy)', 'icon': '🚛'},
    {'id': 'parcel', 'name': 'Oi Parcel Delivery', 'icon': '📦'},
  ];

  @override
  void initState() {
    super.initState();
    _currentLang = DriverApiService().language;
    // Default test driver phone for fast demo testing
    _phoneController.text = '9831100001';
  }

  Future<void> _handleRequestOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await DriverApiService().requestOtp(phone);
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        setState(() {
          _isOtpSent = true;
          _sandboxOtpHint = res['data']?['sandbox_otp'];
        });
        if (_sandboxOtpHint != null) {
          _otpController.text = _sandboxOtpHint!;
        }
      } else {
        setState(() => _errorMessage = res['message'] ?? 'Failed to send OTP.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error with backend server.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() => _errorMessage = 'Please enter the verification code.');
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = _currentLang == 'bn'
          ? 'অনুগ্রহ করে আপনার পুরো নাম লিখুন (নাম আবশ্যক)।'
          : (_currentLang == 'hi'
              ? 'कृपया अपना पूरा नाम दर्ज करें (अनिवार्य)।'
              : 'Please enter your Full Name (Mandatory).'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await DriverApiService().verifyOtp(
        _phoneController.text.trim(),
        otp,
        fullName: name,
        vehicleCategory: _selectedCategory,
      );

      setState(() => _isLoading = false);

      if (res['success'] == true) {
        if (!mounted) return;
        final profile = res['data']?['profile'];
        final isVerified = profile != null && profile['status'] == 'verified_active';

        if (isVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
          );
        } else {
          // Mandatory first-time vehicle document upload screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const KycDocumentsScreen(isOnboarding: true)),
          );
        }
      } else {
        setState(() => _errorMessage = res['message'] ?? 'Verification failed.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification error. Please retry.';
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = DriverLocalizations(_currentLang);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Oi Toto! Partner Login'),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DriverColors.primaryGreenLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentLang == 'bn' ? 'বাংলা' : (_currentLang == 'hi' ? 'हिन्दी' : 'English'),
                style: const TextStyle(fontWeight: FontWeight.w700, color: DriverColors.primaryGreenDark, fontSize: 13),
              ),
            ),
            onSelected: (code) async {
              await DriverApiService().setLanguage(code);
              setState(() => _currentLang = code);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
              const PopupMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'E-Rickshaw Driver Partner',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: DriverColors.deepNavy),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to receive bookings, navigate pickups, and track daily earnings.',
                style: TextStyle(color: DriverColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                ),

              if (!_isOtpSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Registered Mobile Number',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRequestOtp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Get Driver Login OTP'),
                  ),
                ),
              ] else ...[
                if (_sandboxOtpHint != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: DriverColors.warmYellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DriverColors.warmYellow),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.vpn_key_rounded, color: Color(0xFF854D0E), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '[SANDBOX] Demo Driver OTP: $_sandboxOtpHint',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF854D0E)),
                          ),
                        ),
                      ],
                    ),
                  ),

                Text(
                  _currentLang == 'bn'
                      ? 'যাচাইকরণ কোড (OTP) লিখুন'
                      : (_currentLang == 'hi' ? 'सत्यापन कोड (OTP) दर्ज करें' : 'Enter 6-Digit OTP'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DriverColors.deepNavy),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: const InputDecoration(hintText: '000000', counterText: ''),
                ),
                const SizedBox(height: 18),

                // Mandatory Full Name Field
                Text(
                  _currentLang == 'bn'
                      ? 'ড্রাইভারের পুরো নাম (বাধ্যতামূলক) *'
                      : (_currentLang == 'hi' ? 'चालक का पूरा नाम (अनिवार्य) *' : 'Driver Full Name (Mandatory) *'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DriverColors.deepNavy),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person, color: DriverColors.primaryGreen),
                    hintText: _currentLang == 'bn'
                        ? 'আপনার পুরো নাম লিখুন'
                        : (_currentLang == 'hi' ? 'अपना पूरा नाम दर्ज करें' : 'e.g. Ramesh Ghosh'),
                  ),
                ),
                const SizedBox(height: 20),

                // Mandatory Vehicle Category Selection
                Row(
                  children: [
                    Text(
                      _currentLang == 'bn'
                          ? 'গাড়ির ক্যাটাগরি (বাধ্যতামূলক) *'
                          : (_currentLang == 'hi' ? 'वाहन श्रेणी (अनिवार्य) *' : 'Vehicle Category (Mandatory) *'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DriverColors.deepNavy),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currentLang == 'bn'
                      ? 'আপনি যে ক্যাটাগরি বেছে নেবেন, শুধুমাত্র সেই ক্যাটাগরির যাত্রীর বুকিং আপনার কাছে আসবে।'
                      : (_currentLang == 'hi'
                          ? 'आप जो श्रेणी चुनेंगे, केवल उसी श्रेणी के यात्रियों की बुकिंग आपको मिलेगी।'
                          : 'You will strictly receive ride requests for this chosen category only.'),
                  style: const TextStyle(fontSize: 11, color: DriverColors.textMuted),
                ),
                const SizedBox(height: 10),

                // Category selector cards
                Column(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['id'];
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = cat['id']!);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? DriverColors.primaryGreenLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? DriverColors.primaryGreen : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(cat['icon']!, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat['name']!,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? DriverColors.primaryGreenDark : DriverColors.deepNavy,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: DriverColors.primaryGreen, size: 22)
                            else
                              Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400, size: 22),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyOtp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _currentLang == 'bn'
                                ? 'যাচাই করুন ও প্রবেশ করুন'
                                : (_currentLang == 'hi' ? 'सत्यापित करें और प्रवेश करें' : 'Verify & Enter Driver Console'),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isOtpSent = false;
                        _errorMessage = null;
                      });
                    },
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(
                      _currentLang == 'bn' ? 'নম্বর পরিবর্তন করুন' : (_currentLang == 'hi' ? 'नंबर बदलें' : 'Change Mobile Number'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

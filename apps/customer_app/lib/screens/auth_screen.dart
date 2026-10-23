import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import 'home_screen.dart';
import 'ride_category_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _sandboxOtpHint;
  int _timerSeconds = 30;
  Timer? _countdownTimer;

  String _currentLang = 'en';

  @override
  void initState() {
    super.initState();
    _currentLang = ApiService().language;
  }

  void _startTimer() {
    setState(() => _timerSeconds = 30);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
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
      final res = await ApiService().requestOtp(phone);
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        setState(() {
          _isOtpSent = true;
          _sandboxOtpHint = res['data']?['sandbox_otp'];
        });
        if (_sandboxOtpHint != null) {
          _otpController.text = _sandboxOtpHint!;
        }
        _startTimer();
      } else {
        setState(() => _errorMessage = res['message'] ?? 'Failed to send OTP.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error. Ensure backend server is active.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() => _errorMessage = 'Please enter the verification code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService().verifyOtp(
        _phoneController.text.trim(),
        otp,
        fullName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      );

      setState(() => _isLoading = false);

      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RideCategoryScreen()),
        );
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
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(_currentLang);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 28, height: 28),
            const SizedBox(width: 8),
            const Text('Oi Toto!', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          ],
        ),
        actions: [
          // Language Switcher Pill
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreenLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.translate, size: 16, color: AppColors.primaryGreenDark),
                  const SizedBox(width: 4),
                  Text(
                    _currentLang == 'bn' ? 'বাং' : (_currentLang == 'hi' ? 'हिं' : 'EN'),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryGreenDark, fontSize: 13),
                  ),
                ],
              ),
            ),
            onSelected: (code) async {
              await ApiService().setLanguage(code);
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
              const SizedBox(height: 12),
              Text(
                !_isOtpSent ? loc.tr('login_title') : loc.tr('verify_title'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepNavy,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                !_isOtpSent
                    ? loc.tr('login_subtitle')
                    : '${loc.tr('verify_subtitle')} +91 ${_phoneController.text}',
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
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
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_isOtpSent) ...[
                // Mobile Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          border: Border(right: BorderSide(color: AppColors.border)),
                        ),
                        child: const Text(
                          '🇮🇳 +91',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textMain),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: '9876543210',
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRequestOtp,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(loc.tr('send_otp')),
                  ),
                ),
              ] else ...[
                // Sandbox OTP Banner Hint
                if (_sandboxOtpHint != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.warmYellowLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warmYellow.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.warmYellowDark, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '[SANDBOX MODE] Demo OTP auto-filled: $_sandboxOtpHint',
                            style: const TextStyle(color: Color(0xFF854D0E), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // OTP Field
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 8),
                  ),
                ),
                const SizedBox(height: 16),

                // Optional Name Field for first time riders
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name (Optional for new users)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyOtp,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(loc.tr('verify_button')),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isOtpSent = false),
                      child: const Text('Change Number', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    TextButton(
                      onPressed: _timerSeconds == 0 ? _handleRequestOtp : null,
                      child: Text(
                        _timerSeconds > 0 ? 'Resend in ${_timerSeconds}s' : loc.tr('resend_otp'),
                        style: TextStyle(
                          color: _timerSeconds == 0 ? AppColors.primaryGreen : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

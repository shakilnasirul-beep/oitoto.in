import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/driver_theme.dart';
import '../core/localization/driver_localizations.dart';
import '../core/services/driver_api_service.dart';
import 'driver_home_screen.dart';

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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await DriverApiService().verifyOtp(
        _phoneController.text.trim(),
        otp,
        fullName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      );

      setState(() => _isLoading = false);

      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
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
                  margin: const EdgeInsets.bottom(20),
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
                    margin: const EdgeInsets.bottom(20),
                    decoration: BoxDecoration(
                      color: DriverColors.warmYellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '[SANDBOX] Demo Driver OTP: $_sandboxOtpHint',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF854D0E)),
                    ),
                  ),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: const InputDecoration(hintText: '000000'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyOtp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify & Enter Driver Console'),
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

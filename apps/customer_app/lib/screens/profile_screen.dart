import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prof = await ApiService().getProfile();
    if (mounted) {
      setState(() {
        _profile = prof;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await ApiService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Language / ভাষা / भाषा'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              await ApiService().setLanguage('en');
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('English', style: TextStyle(fontSize: 16)),
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              await ApiService().setLanguage('bn');
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('বাংলা (Bengali)', style: TextStyle(fontSize: 16)),
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              await ApiService().setLanguage('hi');
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('हिन्दी (Hindi)', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(ApiService().language);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.tr('profile')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // User Avatar & Name
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreenLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryGreen, width: 2),
                          ),
                          child: const Icon(Icons.person, size: 44, color: AppColors.primaryGreenDark),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profile?['full_name'] ?? 'Oi Toto Rider',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+91 ${_profile?['phone'] ?? ''}',
                          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: AppColors.warmYellow, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${_profile?['rating_avg'] ?? '5.0'} Rating',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '• ${_profile?['total_rides'] ?? 0} Rides',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Menu Options
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.translate, color: AppColors.primaryGreen),
                          title: Text(loc.tr('change_language')),
                          subtitle: Text(
                            ApiService().language == 'bn'
                                ? 'বাংলা'
                                : (ApiService().language == 'hi' ? 'हिन्दी' : 'English'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showLanguageDialog,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.security, color: AppColors.primaryGreen),
                          title: Text(loc.tr('emergency_contacts')),
                          subtitle: Text(
                            _profile?['emergency_contact_phone'] != null
                                ? '${_profile!['emergency_contact_name']} (${_profile!['emergency_contact_phone']})'
                                : 'Configure trusted contact for SOS',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Emergency contact can be edited here.')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.info_outline, color: AppColors.primaryGreen),
                          title: const Text('About Oi Toto!'),
                          subtitle: const Text('Version 1.0.0 — Pan-India E-Rickshaws', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Oi Toto!',
                              applicationVersion: '1.0.0',
                              applicationLegalese: '© 2026 Oi Toto Technologies Private Limited. All rights reserved.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(color: AppColors.errorRed),
                      ),
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

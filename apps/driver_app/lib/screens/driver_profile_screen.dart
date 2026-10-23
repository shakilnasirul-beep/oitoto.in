import 'package:flutter/material.dart';
import '../core/theme/driver_theme.dart';
import '../core/localization/driver_localizations.dart';
import '../core/services/driver_api_service.dart';
import 'driver_auth_screen.dart';
import 'kyc_documents_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prof = await DriverApiService().getProfile();
    if (mounted) {
      setState(() {
        _profile = prof;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await DriverApiService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DriverAuthScreen()),
      (route) => false,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('ভাষা নির্বাচন করুন / Select Language'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              await DriverApiService().setLanguage('en');
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Padding(padding: EdgeInsets.all(8), child: Text('English')),
          ),
          SimpleDialogOption(
            onPressed: () async {
              await DriverApiService().setLanguage('bn');
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Padding(padding: EdgeInsets.all(8), child: Text('বাংলা (Bengali)')),
          ),
          SimpleDialogOption(
            onPressed: () async {
              await DriverApiService().setLanguage('hi');
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Padding(padding: EdgeInsets.all(8), child: Text('हिन्दी (Hindi)')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = DriverLocalizations(DriverApiService().language);

    return Scaffold(
      appBar: AppBar(title: Text(loc.tr('profile'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DriverColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: DriverColors.primaryGreenLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: DriverColors.primaryGreen, width: 2),
                          ),
                          child: const Icon(Icons.person, size: 44, color: DriverColors.primaryGreenDark),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profile?['full_name'] ?? 'Driver Partner',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DriverColors.deepNavy),
                        ),
                        Text(
                          '+91 ${_profile?['phone'] ?? ''}',
                          style: const TextStyle(fontSize: 14, color: DriverColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: DriverColors.primaryGreenLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Status: ${(_profile?['status'] ?? 'pending_review').toString().replaceAll('_', ' ').toUpperCase()}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DriverColors.primaryGreenDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Assigned Toto Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.ev_station, color: DriverColors.primaryGreen),
                              SizedBox(width: 8),
                              Text('Assigned E-Rickshaw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const Divider(height: 18),
                          Text(
                            'Plate: ${_profile?['vehicle_number'] ?? 'Not Assigned'}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          Text(
                            'Make: ${_profile?['brand_make'] ?? 'Mayuri EV'} • Model: ${_profile?['ownership_model'] ?? 'Owner Operator'}',
                            style: const TextStyle(color: DriverColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.description, color: DriverColors.primaryGreen),
                          title: Text(loc.tr('kyc_documents')),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const KycDocumentsScreen()));
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.translate, color: DriverColors.primaryGreen),
                          title: const Text('Change App Language (ভাষা / भाषा)'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showLanguageDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DriverColors.errorRed,
                        side: const BorderSide(color: DriverColors.errorRed),
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

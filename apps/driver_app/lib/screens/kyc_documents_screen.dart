import 'package:flutter/material.dart';
import '../core/theme/driver_theme.dart';
import '../core/services/driver_api_service.dart';
import 'driver_home_screen.dart';

class KycDocumentsScreen extends StatefulWidget {
  final bool isOnboarding;
  const KycDocumentsScreen({super.key, this.isOnboarding = false});

  @override
  State<KycDocumentsScreen> createState() => _KycDocumentsScreenState();
}

class _KycDocumentsScreenState extends State<KycDocumentsScreen> {
  List<dynamic> _docs = [];
  bool _isLoading = true;

  final List<Map<String, String>> _requiredDocTypes = [
    {'type': 'driving_license', 'title': 'Driving Licence (Commercial / EV)'},
    {'type': 'vehicle_rc', 'title': 'Vehicle Registration Certificate (RC)'},
    {'type': 'aadhaar_card', 'title': 'Aadhaar Card (Identity Verification)'},
    {'type': 'insurance_policy', 'title': 'E-Rickshaw Commercial Insurance'},
    {'type': 'fitness_certificate', 'title': 'Vehicle Fitness Certificate'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final docs = await DriverApiService().getDocuments();
    if (mounted) {
      setState(() {
        _docs = docs;
        _isLoading = false;
      });
    }
  }

  void _showUploadDialog(String docType, String docTitle) {
    final numController = TextEditingController();
    String hint = 'Document Number';
    if (docType == 'vehicle_rc') {
      hint = 'Vehicle Registration No (e.g. WB-01-E-1008)';
    } else if (docType == 'driving_license') {
      hint = 'Driving Licence No (e.g. WB-01-2024-001234)';
    } else if (docType == 'aadhaar_card') {
      hint = 'Aadhaar Number (12 Digits)';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Upload $docTitle', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numController,
              decoration: InputDecoration(
                labelText: hint,
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final docNum = numController.text.trim();
                if (docNum.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter the document number.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await DriverApiService().uploadDocument(
                  docType,
                  docNum,
                  '/uploads/documents/doc_${DateTime.now().millisecondsSinceEpoch}.pdf',
                );
                _loadDocs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document & vehicle details submitted for Admin review.')),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Select File & Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC Documents & Licences')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DriverColors.primaryGreen))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DriverColors.primaryGreenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.verified_user, color: DriverColors.primaryGreenDark, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upload government-issued documents to keep your E-Rickshaw active and verified for passenger trips.',
                          style: TextStyle(fontSize: 13, color: DriverColors.primaryGreenDark, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ..._requiredDocTypes.map((req) {
                  final existing = _docs.firstWhere(
                    (d) => d['document_type'] == req['type'],
                    orElse: () => null,
                  );

                  final status = existing?['verification_status'] ?? 'not_uploaded';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(req['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(
                        existing != null ? 'Doc No: ${existing['document_number'] ?? 'On file'}' : 'Tap to upload certificate',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'approved'
                              ? DriverColors.primaryGreenLight
                              : (status == 'pending' ? DriverColors.warmYellow.withOpacity(0.2) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: status == 'approved' ? DriverColors.primaryGreenDark : (status == 'pending' ? Colors.orange.shade800 : Colors.grey.shade700),
                          ),
                        ),
                      ),
                      onTap: () => _showUploadDialog(req['type']!, req['title']!),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (widget.isOnboarding) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: DriverColors.primaryGreen,
                          content: Text('KYC documents submitted. Awaiting Admin verification.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete & Submit to Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

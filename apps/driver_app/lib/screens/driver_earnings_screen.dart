import 'package:flutter/material.dart';
import '../core/theme/driver_theme.dart';
import '../core/services/driver_api_service.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  Map<String, dynamic>? _earnings;
  Map<String, dynamic>? _wallet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final e = await DriverApiService().getEarnings();
    final w = await DriverApiService().getWallet();
    if (mounted) {
      setState(() {
        _earnings = e;
        _wallet = w;
        _isLoading = false;
      });
    }
  }

  void _showPayoutDialog() {
    final amountController = TextEditingController(text: '500');
    final upiController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Wallet Balance', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upiController,
              decoration: const InputDecoration(labelText: 'UPI ID (e.g. driver@upi)', hintText: 'driver@okaxis'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountController.text) ?? 0.0;
              final res = await DriverApiService().requestPayout(amt, upiId: upiController.text.trim());
              Navigator.pop(ctx);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message'] ?? 'Payout requested.')),
              );
            },
            child: const Text('Request Payout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayEarn = _earnings?['today']?['earnings'] ?? 0.0;
    final todayTrips = _earnings?['today']?['trips'] ?? 0;
    final todayCash = _earnings?['today']?['cash_collected'] ?? 0.0;
    final balance = _wallet?['wallet']?['current_balance'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings & Settlements')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DriverColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Digital Wallet Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [DriverColors.darkTeal, DriverColors.deepNavy],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: DriverColors.deepNavy.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available Digital Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${balance.toString()}',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DriverColors.warmYellow,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _showPayoutDialog,
                            child: const Text('Instant Withdrawal to UPI / Bank'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Today's Stats
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Today's Earnings", style: TextStyle(color: DriverColors.textMuted, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('₹$todayEarn', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: DriverColors.primaryGreen)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Trips Completed', style: TextStyle(color: DriverColors.textMuted, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('$todayTrips', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: DriverColors.deepNavy)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Cash Collected in Hand Warning/Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DriverColors.warmYellow.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DriverColors.warmYellow.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined, color: DriverColors.warmYellowDark, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cash In Hand Collected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('₹$todayCash (Platform 10% fee settled via digital wallet)', style: const TextStyle(fontSize: 12, color: DriverColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

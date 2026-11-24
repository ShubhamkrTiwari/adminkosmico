import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/payment_provider.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.getSubtleGradient(isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transactions', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
            Text('Monitor all payments and revenue flow', style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
            const SizedBox(height: 32),
            Expanded(child: _buildPaymentList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList() {
    return Consumer<PaymentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.payments.isEmpty) return const Center(child: Text('No transactions found'));

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                horizontalMargin: 24,
                columns: const [
                  DataColumn(label: Text('Transaction ID')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Method')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Date')),
                ],
                rows: provider.payments.map((p) => DataRow(cells: [
                  DataCell(Text(p['_id'].toString().substring(p['_id'].toString().length - 10).toUpperCase())),
                  DataCell(Text(p['user']?['name'] ?? 'Guest')),
                  DataCell(Text('₹${p['amount'] ?? p['total']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(p['paymentMethod']?.toUpperCase() ?? 'N/A')),
                  DataCell(_buildStatusChip(p['paymentStatus'])),
                  DataCell(Text(DateFormat('MMM dd, hh:mm a').format(DateTime.parse(p['createdAt'])))),
                ])).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'completed' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

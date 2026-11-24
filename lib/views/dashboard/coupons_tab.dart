import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/coupon.dart';
import '../../providers/coupon_provider.dart';

class CouponsTab extends StatefulWidget {
  const CouponsTab({super.key});

  @override
  State<CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends State<CouponsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CouponProvider>().fetchCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: () => _showCouponDialog(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getSubtleGradient(Theme.of(context).brightness == Brightness.dark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isDesktop),
              const SizedBox(height: 32),
              Expanded(child: _buildCouponList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coupons', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
            Text('Manage discount codes and promotions', style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
          ],
        ),
        if (isDesktop)
          ElevatedButton.icon(
            onPressed: () => _showCouponDialog(),
            icon: const Icon(Icons.add_box_rounded),
            label: const Text('New Coupon'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 50)),
          ),
      ],
    );
  }

  Widget _buildCouponList() {
    return Consumer<CouponProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.coupons.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.coupons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(provider.error!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchCoupons(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.coupons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No coupons found', style: TextStyle(color: Colors.black54, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.coupons.length,
          itemBuilder: (context, index) => _buildCouponCard(provider.coupons[index]),
        );
      },
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpired = coupon.expiryDate.isBefore(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_offer_rounded, color: AppColors.primary),
        ),
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              coupon.code,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (coupon.isActive && !isExpired ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isExpired ? 'EXPIRED' : (coupon.isActive ? 'ACTIVE' : 'INACTIVE'),
                style: TextStyle(
                  color: coupon.isActive && !isExpired ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              coupon.discountType == 'percentage' 
                ? '${coupon.discountAmount.toStringAsFixed(0)}% OFF' 
                : '₹${coupon.discountAmount.toStringAsFixed(0)} OFF',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            Text('Min Order: ₹${coupon.minOrderAmount.toStringAsFixed(0)} | Expires: ${DateFormat('dd MMM yyyy').format(coupon.expiryDate)}'),
            if (coupon.description != null) Text(coupon.description!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: isDesktop 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch.adaptive(
                  value: coupon.isActive,
                  onChanged: (val) => context.read<CouponProvider>().toggleStatus(coupon.id),
                  activeColor: AppColors.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _showCouponDialog(coupon: coupon),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => _showDeleteConfirm(coupon),
                ),
              ],
            )
          : PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.toggle_on, color: coupon.isActive ? AppColors.primary : Colors.grey),
                      const SizedBox(width: 8),
                      Text(coupon.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                  onTap: () => Future.delayed(Duration.zero, () => context.read<CouponProvider>().toggleStatus(coupon.id)),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                  onTap: () => Future.delayed(Duration.zero, () => _showCouponDialog(coupon: coupon)),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                  onTap: () => Future.delayed(Duration.zero, () => _showDeleteConfirm(coupon)),
                ),
              ],
            ),
      ),
    );
  }

  void _showCouponDialog({Coupon? coupon}) {
    showDialog(
      context: context,
      builder: (context) => CouponDialog(coupon: coupon),
    );
  }

  void _showDeleteConfirm(Coupon coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text('Are you sure you want to delete "${coupon.code}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<CouponProvider>().deleteCoupon(coupon.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class CouponDialog extends StatefulWidget {
  final Coupon? coupon;
  const CouponDialog({super.key, this.coupon});

  @override
  State<CouponDialog> createState() => _CouponDialogState();
}

class _CouponDialogState extends State<CouponDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _amountController;
  late TextEditingController _minAmountController;
  late TextEditingController _descController;
  late DateTime _expiryDate;
  String _discountType = 'percentage';

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.coupon?.code);
    _amountController = TextEditingController(text: widget.coupon?.discountAmount.toString());
    _minAmountController = TextEditingController(text: widget.coupon?.minOrderAmount.toString());
    _descController = TextEditingController(text: widget.coupon?.description);
    _expiryDate = widget.coupon?.expiryDate ?? DateTime.now().add(const Duration(days: 30));
    _discountType = widget.coupon?.discountType ?? 'percentage';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.coupon == null ? 'New Coupon' : 'Edit Coupon'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Coupon Code (e.g. WELCOME50)'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _discountType,
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (₹)')),
                ],
                onChanged: (v) => setState(() => _discountType = v!),
                decoration: const InputDecoration(labelText: 'Discount Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: _discountType == 'percentage' ? 'Percentage' : 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minAmountController,
                decoration: const InputDecoration(labelText: 'Min Order Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Expiry Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_expiryDate)),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _expiryDate = picked);
                },
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description (Internal)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final data = {
                'code': _codeController.text,
                'discountType': _discountType,
                'discountValue': double.parse(_amountController.text),
                'minOrderAmount': double.tryParse(_minAmountController.text) ?? 0,
                'validUntil': _expiryDate.toIso8601String(),
                'title': _descController.text,
              };

              bool success;
              if (widget.coupon == null) {
                success = await context.read<CouponProvider>().addCoupon(data);
              } else {
                success = await context.read<CouponProvider>().updateCoupon(widget.coupon!.id, data);
              }

              if (success && mounted) Navigator.pop(context);
            }
          },
          child: const Text('Save Coupon'),
        ),
      ],
    );
  }
}

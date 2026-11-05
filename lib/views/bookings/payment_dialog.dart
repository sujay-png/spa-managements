import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/bookings_model.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

/// Holds the confirmed payment data returned from the dialog
class PaymentResult {
  final double rate;
  final double totalAmount;
  final String paymentMethod;
  final bool withGst;
  final double gstAmount;

  const PaymentResult({
    required this.rate,
    required this.totalAmount,
    required this.paymentMethod,
    required this.withGst,
    required this.gstAmount,
  });
}

/// Helper function to open the payment dialog from anywhere
Future<PaymentResult?> showPaymentConfirmationDialog({
  required BuildContext context,
  required BookingsModel item,
  required ServiceModel? service,
}) async {
  final result = await showDialog<PaymentResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PaymentConfirmationDialog(
      item: item,
      service: service,
    ),
  );
  return result;
}

//==============================================================================
// Payment & GST Confirmation Dialog (2-Step Flow)
//==============================================================================
class PaymentConfirmationDialog extends StatefulWidget {
  final BookingsModel item;
  final ServiceModel? service;

  const PaymentConfirmationDialog({
    super.key,
    required this.item,
    required this.service,
  });

  @override
  State<PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState extends State<PaymentConfirmationDialog> {
  int _currentStep = 1; // 1 = Receptionist QR notice, 2 = GST & Payment Mode
  bool _withGst = false;
  String _selectedPaymentMode = 'QR Code / UPI';
  late final TextEditingController _priceController;
  double _initialBasePrice = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.service != null && widget.service!.price > 0) {
      _initialBasePrice = widget.service!.price.toDouble();
    } else if (widget.item.servicePrice != null &&
        widget.item.servicePrice!.isNotEmpty) {
      final clean =
          widget.item.servicePrice!.replaceAll(RegExp(r'[^\d.]'), '');
      _initialBasePrice = double.tryParse(clean) ?? 0.0;
    }
    _priceController = TextEditingController(
      text: _initialBasePrice > 0 ? _initialBasePrice.toStringAsFixed(0) : '0',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String _formatId(int? id) {
    if (id == null) return 'BK---';
    return 'Bk${id.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final enteredPrice =
        double.tryParse(_priceController.text.trim()) ?? 0.0;
    const gstRate = 0.18; // 18% standard GST rate
    final gstAmount = _withGst ? (enteredPrice * gstRate) : 0.0;
    final totalPayable = enteredPrice + gstAmount;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 660,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Step Indicator Pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepPill(
                    stepNumber: 1,
                    title: '1. QR Notice',
                    isActive: _currentStep == 1,
                    onTap: () => setState(() => _currentStep = 1),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 1.5,
                    color: AppColors.border,
                  ),
                  const SizedBox(width: 8),
                  _buildStepPill(
                    stepNumber: 2,
                    title: '2. GST & Payment Mode',
                    isActive: _currentStep == 2,
                    onTap: () => setState(() => _currentStep = 2),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Scrollable Step Content
              Flexible(
                child: SingleChildScrollView(
                  child: _currentStep == 1
                      ? _buildStep1Content()
                      : _buildStep2Content(
                          enteredPrice: enteredPrice,
                          gstAmount: gstAmount,
                          totalPayable: totalPayable,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPill({
    required int stepNumber,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF8C7B68).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF8C7B68) : Colors.transparent,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? const Color(0xFF8C7B68)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Step 1: Receptionist QR Notice ─────────────────────────────────────────
  Widget _buildStep1Content() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code Header Icon
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFF8C7B68).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.qr_code_2_rounded,
            size: 38,
            color: Color(0xFF8C7B68),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Payment Request',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Receptionist Notice Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFFB78103),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please make payment through the QR code provided by the receptionist.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.brown.shade900,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Booking details card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildDetailRow('Booking ID', _formatId(widget.item.id)),
              const SizedBox(height: 8),
              _buildDetailRow('Customer', widget.item.customer),
              const SizedBox(height: 8),
              _buildDetailRow('Service', widget.item.servicename),
              const SizedBox(height: 8),
              _buildDetailRow('Therapist', widget.item.therapistname),
              if (_initialBasePrice > 0) ...[
                const Divider(height: 18, color: AppColors.border),
                _buildDetailRow(
                  'Service Rate',
                  '₹${_initialBasePrice.toStringAsFixed(0)}',
                  isBold: true,
                  valueColor: const Color(0xFF8C7B68),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(null),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 2;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8C7B68),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 2: GST Toggle, Calculation & Payment Mode ─────────────────────────
  Widget _buildStep2Content({
    required double enteredPrice,
    required double gstAmount,
    required double totalPayable,
  }) {
    final paymentModes = [
      ('QR Code / UPI', Icons.qr_code_scanner_rounded),
      ('Cash', Icons.payments_outlined),
      ('Card', Icons.credit_card_outlined),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Billing & Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              _formatId(widget.item.id),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8C7B68),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Customer: ${widget.item.customer} • Service: ${widget.item.servicename}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // GST Toggle Segmented Bar
        const Text(
          'GST Option',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F1ED),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _withGst = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_withGst ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !_withGst
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Without GST',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            !_withGst ? FontWeight.bold : FontWeight.w500,
                        color: !_withGst
                            ? const Color(0xFF8C7B68)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _withGst = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _withGst ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _withGst
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'With GST (18%)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            _withGst ? FontWeight.bold : FontWeight.w500,
                        color: _withGst
                            ? const Color(0xFF8C7B68)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Amount Calculation Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Base amount row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Base Amount',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // GST row
              _buildDetailRow(
                _withGst ? 'GST (18%)' : 'GST',
                _withGst
                    ? '+ ₹${gstAmount.toStringAsFixed(2)}'
                    : '₹0.00 (Exempt)',
                valueColor: _withGst ? Colors.orange.shade800 : Colors.grey,
              ),
              const Divider(height: 20, color: AppColors.border),

              // Total Payable row
              _buildDetailRow(
                'Total Payable',
                '₹${totalPayable.toStringAsFixed(2)}',
                isBold: true,
                valueColor: const Color(0xFF8C7B68),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Mode
        const Text(
          'Payment Mode',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: paymentModes.map((mode) {
            final isSelected = _selectedPaymentMode == mode.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPaymentMode = mode.$1),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8C7B68).withOpacity(0.10)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8C7B68)
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode.$2,
                        size: 20,
                        color: isSelected
                            ? const Color(0xFF8C7B68)
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode.$1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF8C7B68)
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final result = PaymentResult(
                    rate: enteredPrice,
                    totalAmount: totalPayable,
                    paymentMethod: _selectedPaymentMode,
                    withGst: _withGst,
                    gstAmount: gstAmount,
                  );
                  Navigator.of(context).pop(result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8C7B68),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Confirm & Complete',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/payment_controller.dart';
import 'package:ira_spa_webapp/models/invoice_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/utils/payment_utils.dart';
import 'package:ira_spa_webapp/views/service/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _brandDark = Color(0xFF665646);

Future<void> showBillingSettingsDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const BillingSettingsDialog(),
  );
}

class BillingSettingsDialog extends StatefulWidget {
  const BillingSettingsDialog({super.key});

  @override
  State<BillingSettingsDialog> createState() => _BillingSettingsDialogState();
}

class _BillingSettingsDialogState extends State<BillingSettingsDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _address, _phone, _email, _gstin,
      _upi, _payee, _prefix, _gstRate, _sac, _footer;
  bool _inclusive = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final pay = context.read<PaymentController>();
    final auth = context.read<AuthController>();
    final ref = pay.businessRef ?? auth.businessRef ?? 0;
    final s = pay.settings ??
        BillingSettings.empty(ref, businessName: auth.Bussiness);
    _name = TextEditingController(
        text: s.businessName.isNotEmpty ? s.businessName : (auth.Bussiness ?? ''));
    _address = TextEditingController(text: s.address ?? '');
    _phone = TextEditingController(text: s.phone ?? '');
    _email = TextEditingController(text: s.email ?? '');
    _gstin = TextEditingController(text: s.gstin ?? '');
    _upi = TextEditingController(text: s.upiId ?? '');
    _payee = TextEditingController(text: s.upiPayeeName ?? s.businessName);
    _prefix = TextEditingController(text: s.invoicePrefix);
    _gstRate = TextEditingController(text: s.defaultGstRate.toStringAsFixed(0));
    _sac = TextEditingController(text: s.sacCode);
    _footer = TextEditingController(text: s.footerNote ?? '');
    _inclusive = s.gstInclusive;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _address, _phone, _email, _gstin, _upi, _payee, _prefix,
      _gstRate, _sac, _footer,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nz(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final pay = context.read<PaymentController>();
    final ref = pay.businessRef ?? context.read<AuthController>().businessRef;
    if (ref == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await pay.saveSettings(BillingSettings(
        businessRef: ref,
        businessName: _name.text.trim(),
        address: _nz(_address),
        phone: _nz(_phone),
        email: _nz(_email),
        gstin: _nz(_gstin)?.toUpperCase(),
        upiId: _nz(_upi),
        upiPayeeName: _nz(_payee) ?? _name.text.trim(),
        invoicePrefix: (_nz(_prefix) ?? 'INV').toUpperCase(),
        defaultGstRate: double.tryParse(_gstRate.text.trim()) ?? 9,
        gstInclusive: _inclusive,
        sacCode: _nz(_sac) ?? '999722',
        footerNote: _nz(_footer),
      ));
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Billing settings saved')),
        );
        return;
      }
    } on PaymentsSetupMissing {
      setState(() => _error =
          'Run the payments SQL migration in Supabase first (supabase/migrations).');
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final upiOk = isValidUpiId(_upi.text);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 780),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_outlined, color: _brandDark),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Billing & UPI settings',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('UPI collection'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _f(_upi, 'UPI ID (VPA)', hint: 'yourspa@okhdfcbank',
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) => (v ?? '').trim().isEmpty ||
                                            isValidUpiId(v!)
                                        ? null
                                        : 'Enter a valid UPI ID like name@bank'),
                                _f(_payee, 'Payee name shown in UPI app'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 120,
                            height: 120,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: upiOk
                                ? QrImageView(
                                    data: buildUpiUri(
                                      upiId: _upi.text,
                                      payeeName: _payee.text,
                                      amount: 1,
                                      note: 'Test',
                                    ),
                                    size: 108,
                                  )
                                : const Center(
                                    child: Text(
                                      'QR preview',
                                      style: TextStyle(
                                          fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const Text(
                        'Tip: scan the preview with your phone — it should open a ₹1 payment '
                        'to your account. Use the merchant/business UPI ID linked to your '
                        'soundbox so you get instant payment alerts.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      _section('Invoice header'),
                      _f(_name, 'Business name',
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Required' : null),
                      _f(_address, 'Address', maxLines: 2),
                      Row(
                        children: [
                          Expanded(child: _f(_phone, 'Phone')),
                          const SizedBox(width: 12),
                          Expanded(child: _f(_email, 'Email')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _section('Tax & numbering'),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _f(_gstin, 'GSTIN (leave empty if not registered)',
                                validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return null;
                              return RegExp(r'^[0-9]{2}[A-Z0-9]{13}$')
                                      .hasMatch(t.toUpperCase())
                                  ? null
                                  : '15-character GSTIN';
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _f(_gstRate, 'GST %')),
                          const SizedBox(width: 12),
                          Expanded(child: _f(_sac, 'SAC code')),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _inclusive,
                        activeThumbColor: _brandDark,
                        onChanged: (v) => setState(() => _inclusive = v),
                        title: const Text('Service prices already include GST',
                            style: TextStyle(fontSize: 13)),
                        subtitle: const Text(
                          'On: ₹1000 service → ₹847.46 + ₹152.54 GST. Off: ₹1000 + ₹180 GST.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _f(_prefix, 'Invoice prefix',
                                hint: 'IRA → IRA/26-27/0001'),
                          ),
                        ],
                      ),
                      _f(_footer, 'Footer note on invoice', maxLines: 2),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_error!,
                              style: TextStyle(color: Colors.red.shade700)),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        backgroundColor: _brandDark,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          t.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _f(
    TextEditingController c,
    String label, {
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
}

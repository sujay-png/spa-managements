import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/service_controller.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:provider/provider.dart';

class AddServiceDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const AddServiceDialog({super.key, required this.onSaved});

  @override
  State<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Each option: {duration: TextEditingController, price: TextEditingController}
  final List<Map<String, TextEditingController>> _options = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Start with one option row
    _addOptionRow();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _descCtrl.dispose();
    for (final o in _options) {
      o['duration']!.dispose();
      o['price']!.dispose();
    }
    super.dispose();
  }

  void _addOptionRow() {
    setState(() {
      _options.add({
        'duration': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void _removeOptionRow(int idx) {
    setState(() {
      _options[idx]['duration']!.dispose();
      _options[idx]['price']!.dispose();
      _options.removeAt(idx);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    if (auth.businessRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business reference not found')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final serviceName = _nameCtrl.text.trim();
      final category = _catCtrl.text.trim();
      final description = _descCtrl.text.trim();
      final businessRef = auth.businessRef!;

      final List<ServiceModel> rows = [];
      final usedNames = <String>{};
      for (int i = 0; i < _options.length; i++) {
        final o = _options[i];
        final dur = o['duration']!.text.trim();
        final price = double.tryParse(o['price']!.text.trim()) ?? 0;
        final durLabel = RegExp(r'^\d+$').hasMatch(dur) ? '$dur min' : dur;

        String name = serviceName;
        if (_options.length > 1) {
          name = '$serviceName - $durLabel';
          if (usedNames.contains(name.toLowerCase())) {
            name = '$serviceName - $durLabel (#${i + 1})';
          }
        }
        usedNames.add(name.toLowerCase());

        rows.add(
          ServiceModel(
            serviceName: name,
            designation: category,
            duration: durLabel,
            price: price,
            businessRef: businessRef,
            description: description.isEmpty ? null : description,
          ),
        );
      }

      await context.read<ServiceController>().addServiceWithOptions(rows);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Service "$serviceName" saved with ${rows.length} option(s)!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F6F3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A373).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.spa_outlined,
                        color: Color(0xFFD4A373), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Service',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2E3E),
                          ),
                        ),
                        Text(
                          'Configure service details and duration/pricing options',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF8B7D76)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('BASIC INFORMATION'),
                      const SizedBox(height: 12),

                      _fieldLabel(Icons.spa_outlined, 'Service Name *'),
                      const SizedBox(height: 6),
                      _field(_nameCtrl, 'e.g. Classic Swedish Therapy',
                          required: true),
                      const SizedBox(height: 16),

                      _fieldLabel(Icons.category_outlined, 'Category *'),
                      const SizedBox(height: 6),
                      _field(_catCtrl, 'e.g. Body Massage', required: true),
                      const SizedBox(height: 16),

                      _fieldLabel(Icons.description_outlined, 'Description'),
                      const SizedBox(height: 6),
                      _field(_descCtrl,
                          'Brief overview of the treatment and benefits...',
                          maxLines: 3),
                      const SizedBox(height: 24),

                      // Options section header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionLabel('DURATION & PRICING OPTIONS'),
                          TextButton.icon(
                            onPressed: _addOptionRow,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Option',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8C7A6B),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ..._options.asMap().entries.map((e) => _buildOptionRow(e.key, e.value)),

                      const SizedBox(height: 20),

                      // Live Preview
                      _sectionLabel('LIVE CARD PREVIEW'),
                      const SizedBox(height: 10),
                      _buildPreviewCard(),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEDE8E3))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFF55596E))),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(130, 44),
                        backgroundColor: const Color(0xFF8C7A6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Service',
                              style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildPreviewCard() {
    final title = _nameCtrl.text.trim().isEmpty
        ? 'SERVICE TITLE'
        : _nameCtrl.text.trim().toUpperCase();
    final desc = _descCtrl.text.trim().isEmpty
        ? 'Description of the treatment will appear here...'
        : _descCtrl.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE8E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E202B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF75788D),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _options.map((o) {
              final dur = o['duration']!.text.trim().isEmpty
                  ? '60 min'
                  : '${o['duration']!.text.trim()} min';
              final price = o['price']!.text.trim().isEmpty
                  ? '2200'
                  : o['price']!.text.trim();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD0D9)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.access_time,
                      size: 13, color: Color(0xFF75788D)),
                  const SizedBox(width: 4),
                  Text(
                    '$dur  ₹$price',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A4D5E),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(int idx, Map<String, TextEditingController> option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E5E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 24, right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A373).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${idx + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4A373),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(Icons.access_time_outlined, 'Duration'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: option['duration'],
                        decoration: _dec('e.g. 60'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter duration'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(Icons.currency_rupee, 'Price (₹)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: option['price'],
                        decoration: _dec('e.g. 2200'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter price';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_options.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.red, size: 20),
              onPressed: () => _removeOptionRow(idx),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.3,
          color: Color(0xFF8B7D76),
        ),
      );

  Widget _fieldLabel(IconData? icon, String text) => Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.grey.shade600),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: _dec(hint),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required field' : null
            : null,
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF7F5F0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD4A373)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      );
}

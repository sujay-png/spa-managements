import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/invoice_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/utils/payment_utils.dart';
import 'package:ira_spa_webapp/views/payments/invoice_pdf.dart';
import 'package:url_launcher/url_launcher.dart';

const _brandDark = Color(0xFF665646);

/// Print (A4 / 80mm), download and WhatsApp buttons for an invoice.
class InvoiceActions extends StatefulWidget {
  final InvoiceModel invoice;
  final BillingSettings settings;
  final bool compact;

  const InvoiceActions({
    super.key,
    required this.invoice,
    required this.settings,
    this.compact = false,
  });

  @override
  State<InvoiceActions> createState() => _InvoiceActionsState();
}

class _InvoiceActionsState extends State<InvoiceActions> {
  String? _busy;

  Future<void> _do(String key, Future<void> Function() fn) async {
    setState(() => _busy = key);
    try {
      await fn();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not complete: $e')),
        );
      }
    }
    if (mounted) setState(() => _busy = null);
  }

  Future<void> _whatsapp() async {
    final inv = widget.invoice;
    final s = widget.settings;
    final items = inv.items.map((e) => '• ${e.description}  ${inr(e.amount)}').join('\n');
    final text = StringBuffer()
      ..writeln('Hi ${inv.customerName.isEmpty ? 'there' : inv.customerName},')
      ..writeln('Thank you for visiting *${s.businessName}* 🌿')
      ..writeln()
      ..writeln('*Invoice:* ${inv.invoiceNumber}')
      ..writeln('*Date:* ${formatDate(inv.createdAt)}')
      ..writeln(items);
    if (inv.discount > 0) text.writeln('Discount: -${inr(inv.discount)}');
    if (inv.hasGst) text.writeln('GST: ${inr(inv.gst)}');
    text.writeln('*Total: ${inr(inv.total)}*');
    if (inv.isPaid) {
      text.writeln('Paid via ${inv.paymentMethod ?? ''} ✅');
    } else if (s.hasUpi) {
      text
        ..writeln()
        ..writeln('Pay via UPI: ${s.upiId}');
    }
    if ((s.footerNote ?? '').isNotEmpty) {
      text
        ..writeln()
        ..writeln(s.footerNote);
    }

    final phone = whatsappNumber(inv.customerPhone);
    final encoded = Uri.encodeComponent(text.toString());
    final url = phone != null
        ? 'https://wa.me/$phone?text=$encoded'
        : 'https://wa.me/?text=$encoded';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final s = widget.settings;
    final buttons = [
      _btn('a4', Icons.print_outlined, 'Print A4',
          () => InvoicePdf.printInvoice(inv, s)),
      _btn('rcpt', Icons.receipt_long_outlined, 'Receipt 80mm',
          () => InvoicePdf.printInvoice(inv, s, paper: InvoicePaper.thermal80)),
      _btn('dl', Icons.download_outlined, 'Download PDF',
          () => InvoicePdf.download(inv, s)),
      _btn('wa', Icons.chat_outlined, 'WhatsApp', _whatsapp,
          color: const Color(0xFF25D366)),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }

  Widget _btn(String key, IconData icon, String label, Future<void> Function() fn,
      {Color? color}) {
    final busy = _busy == key;
    return SizedBox(
      width: widget.compact ? null : 140,
      child: OutlinedButton.icon(
        onPressed: _busy != null ? null : () => _do(key, fn),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          side: BorderSide(color: color ?? AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18, color: color ?? _brandDark),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: color != null ? const Color(0xFF128C7E) : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

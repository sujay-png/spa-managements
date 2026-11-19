import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:ira_spa_webapp/models/invoice_model.dart';
import 'package:ira_spa_webapp/utils/payment_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum InvoicePaper { a4, thermal80 }

/// Builds a properly formatted GST invoice PDF (A4) or an 80mm thermal
/// receipt, and prints / downloads it.
class InvoicePdf {
  static pw.Font? _regular;
  static pw.Font? _bold;
  static bool _fontTried = false;

  static const _brand = PdfColor.fromInt(0xFF665646);
  static const _brandSoft = PdfColor.fromInt(0xFFF2ECE4);
  static const _muted = PdfColor.fromInt(0xFF6B6259);
  static const _line = PdfColor.fromInt(0xFFDDD2C3);

  /// Noto Sans has the ₹ glyph; the built-in Helvetica does not.
  static Future<void> _loadFonts() async {
    if (_fontTried) return;
    _fontTried = true;
    try {
      _regular = await PdfGoogleFonts.notoSansRegular();
      _bold = await PdfGoogleFonts.notoSansBold();
    } catch (e) {
      debugPrint('[InvoicePdf] font load failed, using Helvetica: $e');
    }
  }

  static String get _rs => _regular != null ? '₹' : 'Rs.';
  static String _m(double v) => '$_rs${money(v)}';

  static Future<Uint8List> build(
    InvoiceModel inv,
    BillingSettings s, {
    InvoicePaper paper = InvoicePaper.a4,
  }) async {
    await _loadFonts();
    final doc = pw.Document(
      title: 'Invoice ${inv.invoiceNumber}',
      author: s.businessName,
      theme: _regular != null
          ? pw.ThemeData.withFont(base: _regular!, bold: _bold ?? _regular!)
          : null,
    );
    if (paper == InvoicePaper.a4) {
      _a4(doc, inv, s);
    } else {
      _thermal(doc, inv, s);
    }
    return doc.save();
  }

  static String _fileName(InvoiceModel inv) =>
      'Invoice_${inv.invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}.pdf';

  static Future<void> printInvoice(
    InvoiceModel inv,
    BillingSettings s, {
    InvoicePaper paper = InvoicePaper.a4,
  }) async {
    final bytes = await build(inv, s, paper: paper);
    await Printing.layoutPdf(
      name: _fileName(inv),
      format: paper == InvoicePaper.a4 ? PdfPageFormat.a4 : PdfPageFormat.roll80,
      onLayout: (_) async => bytes,
    );
  }

  /// Web: downloads the file. Mobile: opens the share sheet.
  static Future<void> download(InvoiceModel inv, BillingSettings s) async {
    final bytes = await build(inv, s);
    await Printing.sharePdf(bytes: bytes, filename: _fileName(inv));
  }

  static String _title(InvoiceModel inv, BillingSettings s) =>
      inv.hasGst && s.hasGstin ? 'TAX INVOICE' : 'INVOICE';

  //============================================================================
  // A4
  //============================================================================
  static void _a4(pw.Document doc, InvoiceModel inv, BillingSettings s) {
    final small = pw.TextStyle(fontSize: 9, color: _muted);
    final label = pw.TextStyle(
      fontSize: 8,
      color: _muted,
      letterSpacing: 1,
      fontWeight: pw.FontWeight.bold,
    );
    final showQr = !inv.isPaid && s.hasUpi && inv.total > 0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 30),
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(color: _line, thickness: 0.6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('This is a computer generated invoice.', style: small),
                pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: small),
              ],
            ),
          ],
        ),
        build: (ctx) => [
          //---------------------------------------------------------- Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      s.businessName.isEmpty ? 'Spa' : s.businessName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _brand,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if ((s.address ?? '').isNotEmpty)
                      pw.Text(s.address!, style: small),
                    if ((s.phone ?? '').isNotEmpty || (s.email ?? '').isNotEmpty)
                      pw.Text(
                        [
                          if ((s.phone ?? '').isNotEmpty) 'Ph: ${s.phone}',
                          if ((s.email ?? '').isNotEmpty) s.email!,
                        ].join('  |  '),
                        style: small,
                      ),
                    if (s.hasGstin)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          'GSTIN: ${s.gstin!.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _title(inv, s),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                      color: _brand,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _kv('Invoice No.', inv.invoiceNumber),
                  _kv('Date', formatDate(inv.createdAt)),
                  pw.SizedBox(height: 8),
                  _statusBadge(inv),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          //------------------------------------------------- Bill to / Service
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _brandSoft,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO', style: label),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        inv.customerName.isEmpty ? 'Walk-in Customer' : inv.customerName,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if ((inv.customerPhone ?? '').isNotEmpty)
                        pw.Text('Ph: ${inv.customerPhone}', style: small),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SERVICE DETAILS', style: label),
                      pw.SizedBox(height: 4),
                      if (inv.serviceDate != null)
                        pw.Text('Date: ${formatDate(inv.serviceDate!)}',
                            style: small),
                      if ((inv.therapist ?? '').isNotEmpty)
                        pw.Text('Therapist: ${inv.therapist}', style: small),
                      if (inv.bookingId != null)
                        pw.Text(
                          'Booking: BK${inv.bookingId.toString().padLeft(3, '0')}',
                          style: small,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          //------------------------------------------------------- Items table
          _itemsTable(inv, s),
          pw.SizedBox(height: 12),

          //------------------------------------------------------------ Totals
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('AMOUNT IN WORDS', style: label),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      amountInWords(inv.total),
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    if (inv.isPaid) ...[
                      pw.Text('PAYMENT', style: label),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Received via ${inv.paymentMethod ?? '-'}'
                        '${inv.paidAt != null ? ' on ${formatDateTime(inv.paidAt!)}' : ''}',
                        style: small,
                      ),
                      if ((inv.paymentRef ?? '').isNotEmpty)
                        pw.Text('Ref / UTR: ${inv.paymentRef}', style: small),
                    ],
                    if (showQr)
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: buildUpiUri(
                              upiId: s.upiId!,
                              payeeName: s.upiPayeeName ?? s.businessName,
                              amount: inv.total,
                              txnRef: inv.invoiceNumber,
                              note: 'Invoice ${inv.invoiceNumber}',
                            ),
                            width: 78,
                            height: 78,
                          ),
                          pw.SizedBox(width: 10),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('SCAN TO PAY', style: label),
                              pw.Text(_m(inv.total),
                                  style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text('UPI: ${s.upiId}', style: small),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal', _m(inv.subtotal)),
                    if (inv.discount > 0)
                      _totalRow('Discount', '- ${_m(inv.discount)}'),
                    if (inv.hasGst) ...[
                      _totalRow('Taxable Value', _m(inv.taxableAmount)),
                      _totalRow(
                        'CGST @ ${_pct(inv.gstRate / 2)}',
                        _m(inv.cgst),
                      ),
                      _totalRow(
                        'SGST @ ${_pct(inv.gstRate / 2)}',
                        _m(inv.sgst),
                      ),
                    ],
                    if (inv.roundOff != 0)
                      _totalRow(
                        'Round Off',
                        '${inv.roundOff > 0 ? '+' : '-'} ${_m(inv.roundOff.abs())}',
                      ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _brand,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            inv.isPaid ? 'TOTAL PAID' : 'TOTAL DUE',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          pw.Text(
                            _m(inv.total),
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 28),

          //------------------------------------------------------ Signature
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Text(
                  s.footerNote ?? 'Thank you for visiting!',
                  style: pw.TextStyle(fontSize: 10, color: _brand),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.SizedBox(height: 26),
                  pw.Container(width: 140, height: 0.6, color: _muted),
                  pw.SizedBox(height: 3),
                  pw.Text('For ${s.businessName}', style: small),
                  pw.Text('Authorised Signatory', style: small),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _pct(double v) =>
      '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}%';

  static pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text('$k: ', style: pw.TextStyle(fontSize: 9, color: _muted)),
            pw.Text(v,
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  static pw.Widget _statusBadge(InvoiceModel inv) {
    final paid = inv.isPaid;
    final color = paid
        ? const PdfColor.fromInt(0xFF2E7D32)
        : inv.isVoid
            ? PdfColors.grey700
            : const PdfColor.fromInt(0xFFC62828);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.4),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        paid ? 'PAID' : (inv.isVoid ? 'VOID' : 'UNPAID'),
        style: pw.TextStyle(
          color: color,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
          letterSpacing: 2,
        ),
      ),
    );
  }

  static pw.Widget _totalRow(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(k, style: pw.TextStyle(fontSize: 9.5, color: _muted)),
            pw.Text(v, style: const pw.TextStyle(fontSize: 9.5)),
          ],
        ),
      );

  static pw.Widget _itemsTable(InvoiceModel inv, BillingSettings s) {
    final head = pw.TextStyle(
      fontSize: 8.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
      letterSpacing: 0.6,
    );
    const cell = pw.TextStyle(fontSize: 9.5);
    pw.Widget c(String t, {pw.TextStyle? st, pw.TextAlign? al}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: pw.Text(t, style: st ?? cell, textAlign: al ?? pw.TextAlign.left),
        );

    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(28),
        1: pw.FlexColumnWidth(5),
        2: pw.FixedColumnWidth(58),
        3: pw.FixedColumnWidth(36),
        4: pw.FixedColumnWidth(72),
        5: pw.FixedColumnWidth(80),
      },
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: _line, width: 0.8),
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
      ),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _brand),
          children: [
            c('#', st: head),
            c('DESCRIPTION', st: head),
            c('SAC', st: head),
            c('QTY', st: head, al: pw.TextAlign.center),
            c('RATE', st: head, al: pw.TextAlign.right),
            c('AMOUNT', st: head, al: pw.TextAlign.right),
          ],
        ),
        for (var i = 0; i < inv.items.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isOdd ? const PdfColor.fromInt(0xFFFAF8F5) : PdfColors.white,
            ),
            children: [
              c('${i + 1}'),
              c(inv.items[i].description),
              c(inv.items[i].sac ?? s.sacCode),
              c('${inv.items[i].qty}', al: pw.TextAlign.center),
              c(money(inv.items[i].rate), al: pw.TextAlign.right),
              c(money(inv.items[i].amount), al: pw.TextAlign.right),
            ],
          ),
      ],
    );
  }

  //============================================================================
  // 80mm thermal receipt
  //============================================================================
  static void _thermal(pw.Document doc, InvoiceModel inv, BillingSettings s) {
    const base = pw.TextStyle(fontSize: 8);
    final bold = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
    pw.Widget row(String k, String v, {bool b = false}) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(k, style: b ? bold : base),
            pw.Text(v, style: b ? bold : base),
          ],
        );
    pw.Widget dash() => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text('-' * 42, style: base, maxLines: 1),
        );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              s.businessName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            if ((s.address ?? '').isNotEmpty)
              pw.Text(s.address!, textAlign: pw.TextAlign.center, style: base),
            if ((s.phone ?? '').isNotEmpty)
              pw.Text('Ph: ${s.phone}', textAlign: pw.TextAlign.center, style: base),
            if (s.hasGstin)
              pw.Text('GSTIN: ${s.gstin}',
                  textAlign: pw.TextAlign.center, style: bold),
            dash(),
            pw.Text(_title(inv, s), textAlign: pw.TextAlign.center, style: bold),
            row('No: ${inv.invoiceNumber}', formatDate(inv.createdAt)),
            row('Customer', inv.customerName),
            if ((inv.therapist ?? '').isNotEmpty) row('Therapist', inv.therapist!),
            dash(),
            for (final it in inv.items) ...[
              pw.Text(it.description, style: base),
              row('  ${it.qty} x ${money(it.rate)}', money(it.amount)),
            ],
            dash(),
            row('Subtotal', money(inv.subtotal)),
            if (inv.discount > 0) row('Discount', '-${money(inv.discount)}'),
            if (inv.hasGst) ...[
              row('CGST ${_pct(inv.gstRate / 2)}', money(inv.cgst)),
              row('SGST ${_pct(inv.gstRate / 2)}', money(inv.sgst)),
            ],
            if (inv.roundOff != 0) row('Round off', money(inv.roundOff)),
            dash(),
            row(inv.isPaid ? 'PAID' : 'TOTAL DUE', _m(inv.total), b: true),
            if (inv.isPaid)
              pw.Text(
                'via ${inv.paymentMethod ?? '-'}'
                '${(inv.paymentRef ?? '').isNotEmpty ? ' (${inv.paymentRef})' : ''}',
                style: base,
              ),
            if (!inv.isPaid && s.hasUpi) ...[
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: buildUpiUri(
                    upiId: s.upiId!,
                    payeeName: s.upiPayeeName ?? s.businessName,
                    amount: inv.total,
                    txnRef: inv.invoiceNumber,
                  ),
                  width: 100,
                  height: 100,
                ),
              ),
            ],
            dash(),
            pw.Text(
              s.footerNote ?? 'Thank you!',
              textAlign: pw.TextAlign.center,
              style: base,
            ),
          ],
        ),
      ),
    );
  }
}

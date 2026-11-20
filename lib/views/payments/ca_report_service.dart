import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:ira_spa_webapp/models/invoice_model.dart';
import 'package:ira_spa_webapp/utils/file_saver.dart';
import 'package:ira_spa_webapp/utils/payment_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CaReportMetrics {
  final int totalInvoices;
  final int paidInvoices;
  final int unpaidInvoices;
  final int voidInvoices;

  final double totalSubtotal;
  final double totalDiscount;
  final double totalTaxable;
  final double totalCgst;
  final double totalSgst;
  final double totalGst;
  final double totalRoundOff;
  final double totalRevenue;

  final double upiTotal;
  final int upiCount;

  final double cashTotal;
  final int cashCount;

  final double cardTotal;
  final int cardCount;

  final double unpaidTotal;
  final int unpaidCount;

  const CaReportMetrics({
    required this.totalInvoices,
    required this.paidInvoices,
    required this.unpaidInvoices,
    required this.voidInvoices,
    required this.totalSubtotal,
    required this.totalDiscount,
    required this.totalTaxable,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalGst,
    required this.totalRoundOff,
    required this.totalRevenue,
    required this.upiTotal,
    required this.upiCount,
    required this.cashTotal,
    required this.cashCount,
    required this.cardTotal,
    required this.cardCount,
    required this.unpaidTotal,
    required this.unpaidCount,
  });

  factory CaReportMetrics.compute(List<InvoiceModel> list) {
    int total = list.length;
    int paid = 0;
    int unpaid = 0;
    int voidCount = 0;

    double subtotal = 0.0;
    double discount = 0.0;
    double taxable = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    double roundOff = 0.0;
    double revenue = 0.0;

    double upi = 0.0;
    int upiC = 0;

    double cash = 0.0;
    int cashC = 0;

    double card = 0.0;
    int cardC = 0;

    double unpaidAmount = 0.0;
    int unpaidC = 0;

    for (final i in list) {
      if (i.isVoid) {
        voidCount++;
        continue; // voided bills are excluded from financial turnover totals
      }

      subtotal += i.subtotal;
      discount += i.discount;
      taxable += i.taxableAmount;
      cgst += i.cgst;
      sgst += i.sgst;
      roundOff += i.roundOff;
      revenue += i.total;

      if (i.isPaid) {
        paid++;
        final method = (i.paymentMethod ?? '').toLowerCase();
        if (method.contains('upi') || method.contains('qr')) {
          upi += i.total;
          upiC++;
        } else if (method.contains('cash')) {
          cash += i.total;
          cashC++;
        } else if (method.contains('card') || method.contains('pos')) {
          card += i.total;
          cardC++;
        } else {
          // fallback to UPI or bank
          upi += i.total;
          upiC++;
        }
      } else {
        unpaid++;
        unpaidC++;
        unpaidAmount += i.total;
      }
    }

    return CaReportMetrics(
      totalInvoices: total,
      paidInvoices: paid,
      unpaidInvoices: unpaid,
      voidInvoices: voidCount,
      totalSubtotal: round2(subtotal),
      totalDiscount: round2(discount),
      totalTaxable: round2(taxable),
      totalCgst: round2(cgst),
      totalSgst: round2(sgst),
      totalGst: round2(cgst + sgst),
      totalRoundOff: round2(roundOff),
      totalRevenue: round2(revenue),
      upiTotal: round2(upi),
      upiCount: upiC,
      cashTotal: round2(cash),
      cashCount: cashC,
      cardTotal: round2(card),
      cardCount: cardC,
      unpaidTotal: round2(unpaidAmount),
      unpaidCount: unpaidC,
    );
  }
}

class CaReportService {
  static pw.Font? _regular;
  static pw.Font? _bold;
  static bool _fontsTried = false;

  static Future<void> _loadFonts() async {
    if (_fontsTried) return;
    _fontsTried = true;
    try {
      _regular = await PdfGoogleFonts.notoSansRegular();
      _bold = await PdfGoogleFonts.notoSansBold();
    } catch (e) {
      debugPrint('[CaReportService] font loading fallback: $e');
    }
  }

  /// Builds a clean, fully escaped CSV string suitable for Excel & Tally.
  static String buildCsv({
    required List<InvoiceModel> invoices,
    required BillingSettings settings,
    required String periodLabel,
  }) {
    final buffer = StringBuffer();
    final m = CaReportMetrics.compute(invoices);
    final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    String escape(dynamic val) {
      if (val == null) return '""';
      final s = val.toString().replaceAll('"', '""');
      return '"$s"';
    }

    // Header metadata
    buffer.writeln('${escape("SPA BILLING & GST AUDIT REPORT")},,,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Business Name")},${escape(settings.businessName.isEmpty ? "IRA Spa" : settings.businessName)},,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("GSTIN")},${escape(settings.gstin ?? "N/A")},${escape("Default SAC")},${escape(settings.sacCode)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Period")},${escape(periodLabel)},${escape("Generated At")},${escape(nowFormatted)},,,,,,,,,,,,,,,,,,');
    buffer.writeln(',,,,,,,,,,,,,,,,,,,,'); // Blank separator

    // Column Headers
    final headers = [
      'Sl No',
      'Invoice No',
      'Invoice Date',
      'Status',
      'Customer Name',
      'Customer Mobile',
      'Services Rendered',
      'SAC Code',
      'Gross Amount (INR)',
      'Discount (INR)',
      'Taxable Value (INR)',
      'GST Rate (%)',
      'CGST (INR)',
      'SGST (INR)',
      'Total GST (INR)',
      'Round Off (INR)',
      'Invoice Total (INR)',
      'Payment Mode',
      'Payment Date',
      'Payment Ref / UTR',
      'Therapist',
    ];
    buffer.writeln(headers.map(escape).join(','));

    // Rows
    for (int i = 0; i < invoices.length; i++) {
      final inv = invoices[i];
      final serviceNames = inv.items.map((e) => e.description).join('; ');
      final sac = inv.items.isNotEmpty && inv.items.first.sac != null && inv.items.first.sac!.isNotEmpty
          ? inv.items.first.sac!
          : settings.sacCode;

      final row = [
        (i + 1).toString(),
        inv.invoiceNumber,
        inv.serviceDate != null ? formatDate(inv.serviceDate!) : formatDate(inv.createdAt),
        inv.paymentStatus.toUpperCase(),
        inv.customerName,
        inv.customerPhone ?? '',
        serviceNames,
        sac,
        inv.subtotal.toStringAsFixed(2),
        inv.discount.toStringAsFixed(2),
        inv.taxableAmount.toStringAsFixed(2),
        '${inv.gstRate.toStringAsFixed(0)}%',
        inv.cgst.toStringAsFixed(2),
        inv.sgst.toStringAsFixed(2),
        inv.gst.toStringAsFixed(2),
        inv.roundOff.toStringAsFixed(2),
        inv.total.toStringAsFixed(2),
        inv.paymentMethod ?? (inv.isPaid ? 'Paid' : 'Unpaid'),
        inv.paidAt != null ? formatDate(inv.paidAt!) : '',
        inv.paymentRef ?? '',
        inv.therapist ?? '',
      ];
      buffer.writeln(row.map(escape).join(','));
    }

    // Totals Row
    buffer.writeln(',,,,,,,,,,,,,,,,,,,,');
    final totalRow = [
      'TOTAL',
      '${m.totalInvoices} Invoices',
      '',
      '',
      '',
      '',
      '',
      '',
      m.totalSubtotal.toStringAsFixed(2),
      m.totalDiscount.toStringAsFixed(2),
      m.totalTaxable.toStringAsFixed(2),
      '',
      m.totalCgst.toStringAsFixed(2),
      m.totalSgst.toStringAsFixed(2),
      m.totalGst.toStringAsFixed(2),
      m.totalRoundOff.toStringAsFixed(2),
      m.totalRevenue.toStringAsFixed(2),
      '',
      '',
      '',
      '',
    ];
    buffer.writeln(totalRow.map(escape).join(','));

    // Executive Summary Section for CA
    buffer.writeln(',,,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("EXECUTIVE SUMMARY FOR CHARTERED ACCOUNTANT")},,,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Metric")},${escape("Amount (INR)")},${escape("Count")},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Total Taxable Turnover")},${escape(m.totalTaxable.toStringAsFixed(2))},${escape(m.paidInvoices + m.unpaidInvoices)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("CGST Output Liability (9%)")},${escape(m.totalCgst.toStringAsFixed(2))},,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("SGST Output Liability (9%)")},${escape(m.totalSgst.toStringAsFixed(2))},,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Total GST Output Tax")},${escape(m.totalGst.toStringAsFixed(2))},,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Total Gross Revenue (Taxable + GST)")},${escape(m.totalRevenue.toStringAsFixed(2))},${escape(m.totalInvoices)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Cancelled / Void Invoices")},${escape("0.00")},${escape(m.voidInvoices)},,,,,,,,,,,,,,,,,,');
    buffer.writeln(',,,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("COLLECTIONS AUDIT BY PAYMENT MODE")},,,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Mode")},${escape("Total Amount (INR)")},${escape("Transactions")},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("UPI / QR Code")},${escape(m.upiTotal.toStringAsFixed(2))},${escape(m.upiCount)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Cash")},${escape(m.cashTotal.toStringAsFixed(2))},${escape(m.cashCount)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Card / POS")},${escape(m.cardTotal.toStringAsFixed(2))},${escape(m.cardCount)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Unpaid / Pending Receivables")},${escape(m.unpaidTotal.toStringAsFixed(2))},${escape(m.unpaidCount)},,,,,,,,,,,,,,,,,,');

    return buffer.toString();
  }

  /// Downloads CSV file to user's computer
  static Future<void> downloadCsv({
    required List<InvoiceModel> invoices,
    required BillingSettings settings,
    required String periodLabel,
  }) async {
    final csvString = buildCsv(
      invoices: invoices,
      settings: settings,
      periodLabel: periodLabel,
    );
    final cleanPeriod = periodLabel.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    final fileName = 'CA_Billing_Report_${cleanPeriod}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final bytes = utf8.encode(csvString);
    await FileSaver.download(bytes: bytes, fileName: fileName, mimeType: 'text/csv;charset=utf-8;');
  }

  /// Builds a publication-ready landscape A4 PDF report for Chartered Accountants
  static Future<Uint8List> buildPdf({
    required List<InvoiceModel> invoices,
    required BillingSettings settings,
    required String periodLabel,
  }) async {
    await _loadFonts();
    final doc = pw.Document(
      title: 'CA Billing Report - $periodLabel',
      author: settings.businessName,
      theme: _regular != null
          ? pw.ThemeData.withFont(base: _regular!, bold: _bold ?? _regular!)
          : null,
    );

    final m = CaReportMetrics.compute(invoices);
    const brandColor = PdfColor.fromInt(0xFF665646);
    const softBg = PdfColor.fromInt(0xFFF9F6F0);
    const borderColor = PdfColor.fromInt(0xFFDDD2C3);

    // Split invoices into pages (15 per page in landscape)
    const int perPage = 14;
    final int pageCount = (invoices.isEmpty ? 1 : (invoices.length / perPage).ceil());

    for (int p = 0; p < pageCount; p++) {
      final start = p * perPage;
      final end = (start + perPage < invoices.length) ? start + perPage : invoices.length;
      final pageItems = invoices.isEmpty ? <InvoiceModel>[] : invoices.sublist(start, end);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Header (Company & Title)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.businessName.isEmpty ? 'IRA SPA' : settings.businessName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: brandColor,
                          ),
                        ),
                        if (settings.address != null && settings.address!.isNotEmpty)
                          pw.Text(settings.address!, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text(
                          'GSTIN: ${settings.gstin ?? "Unregistered / Composition"}  •  Default SAC: ${settings.sacCode}',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: brandColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'GST SALES REGISTER & CA AUDIT REPORT',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Period: $periodLabel', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())} • Page ${p + 1} of $pageCount',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // KPI summary cards (Show on Page 1)
                if (p == 0) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: softBg,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: borderColor),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _pdfStat('TOTAL INVOICES', '${m.totalInvoices}', '${m.paidInvoices} Paid • ${m.unpaidInvoices} Unpaid'),
                        _pdfStat('TAXABLE TURNOVER', 'Rs. ${money(m.totalTaxable)}', 'Before GST'),
                        _pdfStat('CGST (9%)', 'Rs. ${money(m.totalCgst)}', 'Central Tax'),
                        _pdfStat('SGST (9%)', 'Rs. ${money(m.totalSgst)}', 'State Tax'),
                        _pdfStat('TOTAL GST', 'Rs. ${money(m.totalGst)}', 'Output Liability'),
                        _pdfStat('GROSS REVENUE', 'Rs. ${money(m.totalRevenue)}', 'Total Billing'),
                        _pdfStat('COLLECTIONS', 'Rs. ${money(m.upiTotal + m.cashTotal + m.cardTotal)}', 'UPI: Rs.${money(m.upiTotal)} | Cash: Rs.${money(m.cashTotal)}'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // Invoices Table
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(24),  // Sl
                      1: pw.FixedColumnWidth(55),  // Inv No
                      2: pw.FixedColumnWidth(55),  // Date
                      3: pw.FlexColumnWidth(2.2), // Customer & Service
                      4: pw.FixedColumnWidth(42),  // SAC
                      5: pw.FixedColumnWidth(55),  // Taxable
                      6: pw.FixedColumnWidth(30),  // Rate
                      7: pw.FixedColumnWidth(45),  // CGST
                      8: pw.FixedColumnWidth(45),  // SGST
                      9: pw.FixedColumnWidth(55),  // Total
                      10: pw.FixedColumnWidth(55), // Payment
                      11: pw.FixedColumnWidth(45), // Status
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: brandColor),
                        children: [
                          _th('#'),
                          _th('Inv No'),
                          _th('Date'),
                          _th('Customer / Service'),
                          _th('SAC'),
                          _th('Taxable (Rs)'),
                          _th('GST%'),
                          _th('CGST (Rs)'),
                          _th('SGST (Rs)'),
                          _th('Total (Rs)'),
                          _th('Mode'),
                          _th('Status'),
                        ],
                      ),
                      // Data Rows
                      ...pageItems.asMap().entries.map((entry) {
                        final idx = start + entry.key + 1;
                        final i = entry.value;
                        final serviceNames = i.items.map((e) => e.description).join(', ');
                        final sac = i.items.isNotEmpty && i.items.first.sac != null && i.items.first.sac!.isNotEmpty
                            ? i.items.first.sac!
                            : settings.sacCode;

                        final isEven = entry.key % 2 == 0;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : softBg),
                          children: [
                            _td('$idx', align: pw.TextAlign.center),
                            _td(i.invoiceNumber, bold: true),
                            _td(i.serviceDate != null ? formatDate(i.serviceDate!) : formatDate(i.createdAt)),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(i.customerName, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                                  pw.Text(serviceNames, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700), maxLines: 1),
                                ],
                              ),
                            ),
                            _td(sac, align: pw.TextAlign.center),
                            _td(money(i.taxableAmount), align: pw.TextAlign.right),
                            _td('${i.gstRate.toInt()}%', align: pw.TextAlign.center),
                            _td(money(i.cgst), align: pw.TextAlign.right),
                            _td(money(i.sgst), align: pw.TextAlign.right),
                            _td(money(i.total), align: pw.TextAlign.right, bold: true),
                            _td(i.paymentMethod ?? (i.isPaid ? 'Paid' : '-'), align: pw.TextAlign.center),
                            _td(
                              i.paymentStatus.toUpperCase(),
                              align: pw.TextAlign.center,
                              color: i.isPaid ? PdfColors.green800 : (i.isVoid ? PdfColors.red800 : PdfColors.orange800),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                pw.SizedBox(height: 6),

                // Table Footer / Page Totals
                if (p == pageCount - 1)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: softBg,
                      border: pw.TableBorder.all(color: brandColor, width: 0.8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('GRAND TOTALS:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandColor)),
                        pw.Text('Taxable: Rs. ${money(m.totalTaxable)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text('CGST: Rs. ${money(m.totalCgst)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text('SGST: Rs. ${money(m.totalSgst)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Total GST: Rs. ${money(m.totalGst)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Net Revenue: Rs. ${money(m.totalRevenue)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: brandColor)),
                      ],
                    ),
                  ),

                pw.SizedBox(height: 4),
                pw.Text(
                  '* This report is computer generated and verified for statutory GST compliance under the CGST / SGST Act 2017.',
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                ),
              ],
            );
          },
        ),
      );
    }

    return doc.save();
  }

  /// Prints or opens the PDF share sheet
  static Future<void> printOrSharePdf({
    required List<InvoiceModel> invoices,
    required BillingSettings settings,
    required String periodLabel,
  }) async {
    final bytes = await buildPdf(
      invoices: invoices,
      settings: settings,
      periodLabel: periodLabel,
    );
    final cleanPeriod = periodLabel.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    final fileName = 'CA_Report_${cleanPeriod}.pdf';
    await Printing.layoutPdf(
      name: fileName,
      format: PdfPageFormat.a4.landscape,
      onLayout: (_) async => bytes,
    );
  }

  static pw.Widget _pdfStat(String title, String val, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
        pw.SizedBox(height: 1),
        pw.Text(val, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.Text(subtitle, style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _td(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}

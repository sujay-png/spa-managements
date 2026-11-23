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

  final int gstInvoicesCount;
  final int nonGstInvoicesCount;

  final double totalSubtotal;
  final double totalDiscount;
  final double totalTaxable;
  final double totalCgst;
  final double totalSgst;
  final double totalGst;
  final double totalRoundOff;
  final double totalRevenue;

  final double gstTaxable;
  final double gstCgst;
  final double gstSgst;
  final double gstTotalTax;
  final double gstTotalRevenue;

  final double nonGstTotalRevenue;

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
    required this.gstInvoicesCount,
    required this.nonGstInvoicesCount,
    required this.totalSubtotal,
    required this.totalDiscount,
    required this.totalTaxable,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalGst,
    required this.totalRoundOff,
    required this.totalRevenue,
    required this.gstTaxable,
    required this.gstCgst,
    required this.gstSgst,
    required this.gstTotalTax,
    required this.gstTotalRevenue,
    required this.nonGstTotalRevenue,
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

    int gstCount = 0;
    int nonGstCount = 0;

    double subtotal = 0.0;
    double discount = 0.0;
    double taxable = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    double roundOff = 0.0;
    double revenue = 0.0;

    double gstTaxableSum = 0.0;
    double gstCgstSum = 0.0;
    double gstSgstSum = 0.0;
    double gstRevenueSum = 0.0;

    double nonGstRevenueSum = 0.0;

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
        continue;
      }

      subtotal += i.subtotal;
      discount += i.discount;
      taxable += i.taxableAmount;
      cgst += i.cgst;
      sgst += i.sgst;
      roundOff += i.roundOff;
      revenue += i.total;

      final isGst = i.hasGst || i.gst > 0;
      if (isGst) {
        gstCount++;
        gstTaxableSum += i.taxableAmount;
        gstCgstSum += i.cgst;
        gstSgstSum += i.sgst;
        gstRevenueSum += i.total;
      } else {
        nonGstCount++;
        nonGstRevenueSum += i.total;
      }

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
      gstInvoicesCount: gstCount,
      nonGstInvoicesCount: nonGstCount,
      totalSubtotal: round2(subtotal),
      totalDiscount: round2(discount),
      totalTaxable: round2(taxable),
      totalCgst: round2(cgst),
      totalSgst: round2(sgst),
      totalGst: round2(cgst + sgst),
      totalRoundOff: round2(roundOff),
      totalRevenue: round2(revenue),
      gstTaxable: round2(gstTaxableSum),
      gstCgst: round2(gstCgstSum),
      gstSgst: round2(gstSgstSum),
      gstTotalTax: round2(gstCgstSum + gstSgstSum),
      gstTotalRevenue: round2(gstRevenueSum),
      nonGstTotalRevenue: round2(nonGstRevenueSum),
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
      _regular = await PdfGoogleFonts.notoSansRegular()
          .timeout(const Duration(seconds: 3));
      _bold = await PdfGoogleFonts.notoSansBold()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[CaReportService] font loading fallback: $e');
    }
  }

  static String _clean(String text) {
    if (_regular != null) return text;
    return text.replaceAll('₹', 'Rs.');
  }

  /// Builds a clean, fully escaped CSV string separating GST and Non-GST bills with subtotals.
  static String buildCsv({
    required List<InvoiceModel> invoices,
    required BillingSettings settings,
    required String periodLabel,
    String taxFilter = 'all', // 'all', 'gst', 'non_gst'
  }) {
    final buffer = StringBuffer();
    final m = CaReportMetrics.compute(invoices);
    final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    String escape(dynamic val) {
      if (val == null) return '""';
      final s = val.toString().replaceAll('"', '""');
      return '"$s"';
    }

    final gstInvoices = invoices.where((i) => (i.hasGst || i.gst > 0) && !i.isVoid).toList();
    final nonGstInvoices = invoices.where((i) => !i.hasGst && i.gst == 0 && !i.isVoid).toList();
    final voidInvoices = invoices.where((i) => i.isVoid).toList();

    // 1. Report Header
    buffer.writeln('${escape("SPA BILLING & GST AUDIT REPORT")},,,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Business Name")},${escape(settings.businessName.isEmpty ? "IRA Spa" : settings.businessName)},,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("GSTIN")},${escape(settings.gstin ?? "N/A")},${escape("Default SAC")},${escape(settings.sacCode)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Period")},${escape(periodLabel)},${escape("Generated At")},${escape(nowFormatted)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Report Mode")},${escape(taxFilter == "gst" ? "GST Bills Only" : taxFilter == "non_gst" ? "Non-GST Bills Only" : "All Bills (GST & Non-GST Separated)")},,,,,,,,,,,,,,,,,,,');
    buffer.writeln(',,,,,,,,,,,,,,,,,,,,');

    final gstHeaders = [
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

    // 2. SECTION 1: GST BILLS
    if (taxFilter != 'non_gst') {
      buffer.writeln('${escape("--- SECTION 1: GST TAX INVOICES (WITH SAC & TAX LIABILITY) ---")},,,,,,,,,,,,,,,,,,,,');
      buffer.writeln(gstHeaders.map(escape).join(','));

      if (gstInvoices.isEmpty) {
        buffer.writeln('${escape("No GST invoices in this period")},,,,,,,,,,,,,,,,,,,,');
      } else {
        for (int i = 0; i < gstInvoices.length; i++) {
          final inv = gstInvoices[i];
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

        // GST Subtotal Row
        final gstTotalRow = [
          'SUBTOTAL (GST BILLS)',
          '${m.gstInvoicesCount} Invoices',
          '',
          '',
          '',
          '',
          '',
          '',
          m.gstTaxable.toStringAsFixed(2),
          '',
          m.gstTaxable.toStringAsFixed(2),
          '',
          m.gstCgst.toStringAsFixed(2),
          m.gstSgst.toStringAsFixed(2),
          m.gstTotalTax.toStringAsFixed(2),
          '',
          m.gstTotalRevenue.toStringAsFixed(2),
          '',
          '',
          '',
          '',
        ];
        buffer.writeln(gstTotalRow.map(escape).join(','));
      }
      buffer.writeln(',,,,,,,,,,,,,,,,,,,,');
    }

    // 3. SECTION 2: NON-GST BILLS
    if (taxFilter != 'gst') {
      buffer.writeln('${escape("--- SECTION 2: NON-GST BILLS / BILL OF SUPPLY (WITHOUT GST) ---")},,,,,,,,,,,,,,,,,,,,');
      final nonGstHeaders = [
        'Sl No',
        'Bill No',
        'Date',
        'Status',
        'Customer Name',
        'Customer Mobile',
        'Services Rendered',
        'SAC Code',
        'Gross Amount (INR)',
        'Discount (INR)',
        'Net Total (INR)',
        'Payment Mode',
        'Payment Date',
        'Payment Ref / UTR',
        'Therapist',
      ];
      buffer.writeln(nonGstHeaders.map(escape).join(','));

      if (nonGstInvoices.isEmpty) {
        buffer.writeln('${escape("No Non-GST bills in this period")},,,,,,,,,,,,,,');
      } else {
        for (int i = 0; i < nonGstInvoices.length; i++) {
          final inv = nonGstInvoices[i];
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
            inv.total.toStringAsFixed(2),
            inv.paymentMethod ?? (inv.isPaid ? 'Paid' : 'Unpaid'),
            inv.paidAt != null ? formatDate(inv.paidAt!) : '',
            inv.paymentRef ?? '',
            inv.therapist ?? '',
          ];
          buffer.writeln(row.map(escape).join(','));
        }

        // Non-GST Subtotal Row
        final nonGstTotalRow = [
          'SUBTOTAL (NON-GST BILLS)',
          '${m.nonGstInvoicesCount} Bills',
          '',
          '',
          '',
          '',
          '',
          '',
          m.nonGstTotalRevenue.toStringAsFixed(2),
          '',
          m.nonGstTotalRevenue.toStringAsFixed(2),
          '',
          '',
          '',
          '',
        ];
        buffer.writeln(nonGstTotalRow.map(escape).join(','));
      }
      buffer.writeln(',,,,,,,,,,,,,,,,,,,,');
    }

    // 4. VOID BILLS (IF ANY)
    if (voidInvoices.isNotEmpty) {
      buffer.writeln('${escape("--- VOID / CANCELLED BILLS (AUDIT TRAIL) ---")},,,,,,,,,,,,,,,,,,,,');
      for (final inv in voidInvoices) {
        buffer.writeln('${escape(inv.invoiceNumber)},${escape(inv.customerName)},${escape(formatDate(inv.createdAt))},${escape("VOIDED")},${escape(inv.total.toStringAsFixed(2))},,,,,,,,,,,,,,,');
      }
      buffer.writeln(',,,,,,,,,,,,,,,,,,,,');
    }

    // 5. EXECUTIVE SUMMARY FOR CA AUDIT & GSTR RECONCILIATION
    buffer.writeln('${escape("=========================================================")},,,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("EXECUTIVE SUMMARY FOR CHARTERED ACCOUNTANT & GSTR RECONCILIATION")},,,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Category / Metric")},${escape("Amount (INR)")},${escape("Invoice Count")},${escape("Notes")},,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("GST Invoices (With 9% GST)")},${escape(m.gstTotalRevenue.toStringAsFixed(2))},${escape(m.gstInvoicesCount)},${escape("Taxable: Rs. " + m.gstTaxable.toStringAsFixed(2))},,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("  - CGST Output Tax (9%)")},${escape(m.gstCgst.toStringAsFixed(2))},,${escape("Central Tax Component")},,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("  - SGST Output Tax (9%)")},${escape(m.gstSgst.toStringAsFixed(2))},,${escape("State Tax Component")},,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("  - Total Output GST Liability")},${escape(m.gstTotalTax.toStringAsFixed(2))},,${escape("GSTR-1 / GSTR-3B Liability")},,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Non-GST Bills (Zero / Exempt)")},${escape(m.nonGstTotalRevenue.toStringAsFixed(2))},${escape(m.nonGstInvoicesCount)},${escape("Composition / Bill of Supply")},,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("GRAND TOTAL BILLING (TURNOVER)")},${escape(m.totalRevenue.toStringAsFixed(2))},${escape(m.totalInvoices)},${escape("Total Spa Revenue")},,,,,,,,,,,,,,,,,');
    buffer.writeln(',,,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("COLLECTIONS AUDIT BY PAYMENT MODE")},,,,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Payment Mode")},${escape("Total Amount (INR)")},${escape("Transactions")},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("UPI / QR Code")},${escape(m.upiTotal.toStringAsFixed(2))},${escape(m.upiCount)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Cash")},${escape(m.cashTotal.toStringAsFixed(2))},${escape(m.cashCount)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Card / POS")},${escape(m.cardTotal.toStringAsFixed(2))},${escape(m.cardCount)},,,,,,,,,,,,,,,,,,');
    buffer.writeln('${escape("Unpaid / Pending Receivables")},${escape(m.unpaidTotal.toStringAsFixed(2))},${escape(m.unpaidCount)},,,,,,,,,,,,,,,,,,');

    return buffer.toString();
  }

  /// Downloads CSV file to user's computer with separate GST & Non-GST files or combined.
  static Future<void> downloadCsv({
    required List<InvoiceModel> invoices,
    required BillingSettings settings,
    required String periodLabel,
    String taxFilter = 'all',
  }) async {
    final csvString = buildCsv(
      invoices: invoices,
      settings: settings,
      periodLabel: periodLabel,
      taxFilter: taxFilter,
    );
    final cleanPeriod = periodLabel.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    final tag = taxFilter == 'gst'
        ? 'GST_Bills_'
        : taxFilter == 'non_gst'
            ? 'Non_GST_Bills_'
            : 'Billing_Report_Separated_';
    final fileName = 'CA_${tag}${cleanPeriod}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final bytes = utf8.encode(csvString);
    await FileSaver.download(bytes: bytes, fileName: fileName, mimeType: 'text/csv;charset=utf-8;');
  }

  /// Builds a publication-ready landscape A4 PDF report for Chartered Accountants with clearly separated GST & Non-GST sections
  static Future<Uint8List> buildPdf({
    required List<InvoiceModel> invoices,
    required BillingSettings settings,
    required String periodLabel,
    String taxFilter = 'all',
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

    final gstInvoices = invoices.where((i) => (i.hasGst || i.gst > 0) && !i.isVoid).toList();
    final nonGstInvoices = invoices.where((i) => !i.hasGst && i.gst == 0 && !i.isVoid).toList();

    List<InvoiceModel> displayList;
    if (taxFilter == 'gst') {
      displayList = gstInvoices;
    } else if (taxFilter == 'non_gst') {
      displayList = nonGstInvoices;
    } else {
      // In combined mode: GST invoices first, then Non-GST invoices
      displayList = [...gstInvoices, ...nonGstInvoices];
    }

    const int perPage = 13;
    final int pageCount = (displayList.isEmpty ? 1 : (displayList.length / perPage).ceil());

    for (int p = 0; p < pageCount; p++) {
      final start = p * perPage;
      final end = (start + perPage < displayList.length) ? start + perPage : displayList.length;
      final pageItems = displayList.isEmpty ? <InvoiceModel>[] : displayList.sublist(start, end);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(22),
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
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            color: brandColor,
                          ),
                        ),
                        if (settings.address != null && settings.address!.isNotEmpty)
                          pw.Text(_clean(settings.address!), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
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
                            taxFilter == 'gst'
                                ? 'GST TAX INVOICES REGISTER'
                                : taxFilter == 'non_gst'
                                    ? 'NON-GST BILLS REGISTER'
                                    : 'GST & NON-GST AUDIT REPORT',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('Period: $periodLabel', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())} • Page ${p + 1} of $pageCount',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),

                // KPI summary cards (Show on Page 1)
                if (p == 0) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: pw.BoxDecoration(
                      color: softBg,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: borderColor),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _pdfStat('TOTAL INVOICES', '${m.totalInvoices}', '${m.gstInvoicesCount} GST • ${m.nonGstInvoicesCount} Non-GST'),
                        _pdfStat('GST TAXABLE', 'Rs. ${money(m.gstTaxable)}', '${m.gstInvoicesCount} GST Invoices'),
                        _pdfStat('CGST (9%)', 'Rs. ${money(m.gstCgst)}', 'Central Tax'),
                        _pdfStat('SGST (9%)', 'Rs. ${money(m.gstSgst)}', 'State Tax'),
                        _pdfStat('OUTPUT GST TAX', 'Rs. ${money(m.gstTotalTax)}', 'GSTR Liability'),
                        _pdfStat('NON-GST TURNOVER', 'Rs. ${money(m.nonGstTotalRevenue)}', '${m.nonGstInvoicesCount} Non-GST Bills'),
                        _pdfStat('GROSS BILLING', 'Rs. ${money(m.totalRevenue)}', 'Total Sales'),
                        _pdfStat('COLLECTIONS', 'Rs. ${money(m.upiTotal + m.cashTotal + m.cardTotal)}', 'UPI: Rs.${money(m.upiTotal)} | Cash: Rs.${money(m.cashTotal)}'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),
                ],

                // Invoices Table
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(22),  // Sl
                      1: pw.FixedColumnWidth(55),  // Inv No
                      2: pw.FixedColumnWidth(50),  // Date
                      3: pw.FixedColumnWidth(48),  // Type (GST/NON-GST)
                      4: pw.FlexColumnWidth(2.2), // Customer & Service
                      5: pw.FixedColumnWidth(38),  // SAC
                      6: pw.FixedColumnWidth(52),  // Taxable
                      7: pw.FixedColumnWidth(28),  // Rate
                      8: pw.FixedColumnWidth(42),  // CGST
                      9: pw.FixedColumnWidth(42),  // SGST
                      10: pw.FixedColumnWidth(52), // Total
                      11: pw.FixedColumnWidth(50), // Payment
                      12: pw.FixedColumnWidth(42), // Status
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: brandColor),
                        children: [
                          _th('#'),
                          _th('Inv No'),
                          _th('Date'),
                          _th('Type'),
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
                        final isGstBill = i.hasGst || i.gst > 0;

                        final isEven = entry.key % 2 == 0;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : softBg),
                          children: [
                            _td('$idx', align: pw.TextAlign.center),
                            _td(i.invoiceNumber, bold: true),
                            _td(i.serviceDate != null ? formatDate(i.serviceDate!) : formatDate(i.createdAt)),
                            _td(
                              isGstBill ? 'GST (9%)' : 'NON-GST',
                              align: pw.TextAlign.center,
                              bold: true,
                              color: isGstBill ? const PdfColor.fromInt(0xFF1E7E34) : PdfColors.grey700,
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3.5),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(_clean(i.customerName), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                                  pw.Text(_clean(serviceNames), style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700), maxLines: 1),
                                ],
                              ),
                            ),
                            _td(sac, align: pw.TextAlign.center),
                            _td(money(i.taxableAmount), align: pw.TextAlign.right),
                            _td(isGstBill ? '${i.gstRate.toInt()}%' : '0%', align: pw.TextAlign.center),
                            _td(isGstBill ? money(i.cgst) : '-', align: pw.TextAlign.right),
                            _td(isGstBill ? money(i.sgst) : '-', align: pw.TextAlign.right),
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

                pw.SizedBox(height: 5),

                // Table Footer / Subtotals
                if (p == pageCount - 1)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: softBg,
                      border: pw.TableBorder.all(color: brandColor, width: 0.8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('GRAND TOTALS:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandColor)),
                        pw.Text('GST Bills: ${m.gstInvoicesCount} (Taxable: Rs. ${money(m.gstTaxable)} | Tax: Rs. ${money(m.gstTotalTax)})',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E7E34))),
                        pw.Text('Non-GST Bills: ${m.nonGstInvoicesCount} (Total: Rs. ${money(m.nonGstTotalRevenue)})',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Gross Sales: Rs. ${money(m.totalRevenue)}',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandColor)),
                      ],
                    ),
                  ),

                pw.SizedBox(height: 3),
                pw.Text(
                  '* Statutory Report: GST bills and Non-GST bills are segregated with SAC codes and tax breakdowns for GSTR-1, GSTR-3B and Income Tax audit.',
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

  /// Prints or opens the PDF in new tab
  static Future<void> printOrSharePdf({
    required List<InvoiceModel> invoices,
    required BillingSettings settings,
    required String periodLabel,
    String taxFilter = 'all',
  }) async {
    final bytes = await buildPdf(
      invoices: invoices,
      settings: settings,
      periodLabel: periodLabel,
      taxFilter: taxFilter,
    );
    final cleanPeriod = periodLabel.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    final tag = taxFilter == 'gst' ? 'GST_' : taxFilter == 'non_gst' ? 'Non_GST_' : '';
    final fileName = 'CA_Report_${tag}${cleanPeriod}.pdf';
    if (kIsWeb) {
      try {
        final ok = await Printing.layoutPdf(
          name: fileName,
          format: PdfPageFormat.a4.landscape,
          onLayout: (_) async => bytes,
        );
        if (!ok) {
          await FileSaver.openInNewTab(bytes: bytes);
        }
      } catch (e) {
        debugPrint('[CaReportService] layoutPdf fallback: $e');
        await FileSaver.openInNewTab(bytes: bytes);
      }
    } else {
      await Printing.layoutPdf(
        name: fileName,
        format: PdfPageFormat.a4.landscape,
        onLayout: (_) async => bytes,
      );
    }
  }

  static pw.Widget _pdfStat(String title, String val, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 1),
        pw.Text(val, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.Text(subtitle, style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}

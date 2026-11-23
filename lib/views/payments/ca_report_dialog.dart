import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ira_spa_webapp/controllers/payment_controller.dart';
import 'package:ira_spa_webapp/models/invoice_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/utils/payment_utils.dart';
import 'package:ira_spa_webapp/views/payments/ca_report_service.dart';
import 'package:provider/provider.dart';

enum CaPeriod {
  thisMonth,
  lastMonth,
  currentQuarter,
  financialYear,
  allTime,
  custom,
}

enum CaTaxFilter {
  all,
  gstOnly,
  nonGstOnly,
}

Future<void> showCaReportDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const CaReportDialog(),
  );
}

class CaReportDialog extends StatefulWidget {
  const CaReportDialog({super.key});

  @override
  State<CaReportDialog> createState() => _CaReportDialogState();
}

class _CaReportDialogState extends State<CaReportDialog> {
  CaPeriod _selectedPeriod = CaPeriod.thisMonth;
  CaTaxFilter _selectedTaxFilter = CaTaxFilter.all;
  DateTimeRange? _customRange;
  bool _includeVoid = false;
  bool _downloadingCsv = false;
  bool _generatingPdf = false;

  DateTimeRange _getRangeForPeriod(CaPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case CaPeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case CaPeriod.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case CaPeriod.currentQuarter:
        int qStartMonth;
        if (now.month >= 4 && now.month <= 6) {
          qStartMonth = 4;
        } else if (now.month >= 7 && now.month <= 9) {
          qStartMonth = 7;
        } else if (now.month >= 10 && now.month <= 12) {
          qStartMonth = 10;
        } else {
          qStartMonth = 1;
        }
        final start = DateTime(now.year, qStartMonth, 1);
        final end = DateTime(now.year, qStartMonth + 3, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case CaPeriod.financialYear:
        final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
        final start = DateTime(fyStartYear, 4, 1);
        final end = DateTime(fyStartYear + 1, 3, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case CaPeriod.allTime:
        return DateTimeRange(start: DateTime(2020, 1, 1), end: now);

      case CaPeriod.custom:
        return _customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            );
    }
  }

  String _getPeriodLabel() {
    final range = _getRangeForPeriod(_selectedPeriod);
    final f = DateFormat('dd MMM yyyy');
    switch (_selectedPeriod) {
      case CaPeriod.thisMonth:
        return 'This Month (${DateFormat('MMMM yyyy').format(range.start)})';
      case CaPeriod.lastMonth:
        return 'Last Month (${DateFormat('MMMM yyyy').format(range.start)})';
      case CaPeriod.currentQuarter:
        return 'Current Quarter (${f.format(range.start)} - ${f.format(range.end)})';
      case CaPeriod.financialYear:
        return 'Financial Year FY ${range.start.year}-${range.end.year}';
      case CaPeriod.allTime:
        return 'All Time (Cumulative)';
      case CaPeriod.custom:
        return '${f.format(range.start)} to ${f.format(range.end)}';
    }
  }

  List<InvoiceModel> _filterInvoices(List<InvoiceModel> all) {
    final range = _getRangeForPeriod(_selectedPeriod);
    return all.where((i) {
      if (!_includeVoid && i.isVoid) return false;
      final date = i.revenueDate;
      if (date.isBefore(range.start)) return false;
      if (date.isAfter(range.end)) return false;
      return true;
    }).toList();
  }

  String _getTaxFilterKey() {
    switch (_selectedTaxFilter) {
      case CaTaxFilter.gstOnly:
        return 'gst';
      case CaTaxFilter.nonGstOnly:
        return 'non_gst';
      case CaTaxFilter.all:
        return 'all';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF665646),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedPeriod = CaPeriod.custom;
      });
    }
  }

  Future<void> _handleDownloadCsv(
    List<InvoiceModel> filtered,
    BillingSettings settings, {
    String? specificTaxFilter,
  }) async {
    setState(() => _downloadingCsv = true);
    final filterKey = specificTaxFilter ?? _getTaxFilterKey();
    try {
      await CaReportService.downloadCsv(
        invoices: filtered,
        settings: settings,
        periodLabel: _getPeriodLabel(),
        taxFilter: filterKey,
      );
      if (!mounted) return;
      final typeLabel = filterKey == 'gst'
          ? 'GST Invoices'
          : filterKey == 'non_gst'
              ? 'Non-GST Bills'
              : 'Separated GST & Non-GST Report';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$typeLabel (CSV) downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download CSV: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloadingCsv = false);
    }
  }

  Future<void> _handlePrintPdf(
    List<InvoiceModel> filtered,
    BillingSettings settings,
  ) async {
    setState(() => _generatingPdf = true);
    try {
      await CaReportService.printOrSharePdf(
        invoices: filtered,
        settings: settings,
        periodLabel: _getPeriodLabel(),
        taxFilter: _getTaxFilterKey(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open PDF report: $e')),
      );
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pay = context.watch<PaymentController>();
    final settings = pay.settings ?? BillingSettings.empty(0, businessName: 'IRA Spa');
    final allPeriodInvoices = _filterInvoices(pay.invoices);
    final m = CaReportMetrics.compute(allPeriodInvoices);

    // Apply active tax filter
    final List<InvoiceModel> displayInvoices;
    if (_selectedTaxFilter == CaTaxFilter.gstOnly) {
      displayInvoices = allPeriodInvoices.where((i) => i.hasGst || i.gst > 0).toList();
    } else if (_selectedTaxFilter == CaTaxFilter.nonGstOnly) {
      displayInvoices = allPeriodInvoices.where((i) => !i.hasGst && i.gst == 0).toList();
    } else {
      displayInvoices = allPeriodInvoices;
    }

    const brandDark = Color(0xFF665646);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F6F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Color(0xFFEADBCE))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: brandDark.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_outlined,
                        color: brandDark, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export Billing & Tax Report (GST & Non-GST)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2E3E),
                          ),
                        ),
                        Text(
                          'Separate reports for GST tax invoices and Non-GST bills with SAC codes, tax liabilities & payment trails',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Tax Classification Selector
                    Row(
                      children: [
                        const Text(
                          'BILL CLASSIFICATION:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Color(0xFF8B7D76),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _taxFilterChip(
                          CaTaxFilter.all,
                          'All Bills (${allPeriodInvoices.length})',
                          subtitle: 'Separated in report',
                        ),
                        const SizedBox(width: 8),
                        _taxFilterChip(
                          CaTaxFilter.gstOnly,
                          'GST Bills (${m.gstInvoicesCount})',
                          badgeColor: const Color(0xFF28A745),
                        ),
                        const SizedBox(width: 8),
                        _taxFilterChip(
                          CaTaxFilter.nonGstOnly,
                          'Non-GST Bills (${m.nonGstInvoicesCount})',
                          badgeColor: const Color(0xFF17A2B8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. Period Selector
                    const Text(
                      'SELECT REPORTING PERIOD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFF8B7D76),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _periodChip(CaPeriod.thisMonth, 'This Month'),
                        _periodChip(CaPeriod.lastMonth, 'Last Month'),
                        _periodChip(CaPeriod.currentQuarter, 'Current Quarter'),
                        _periodChip(CaPeriod.financialYear, 'Financial Year (FY)'),
                        _periodChip(CaPeriod.allTime, 'All Time'),
                        ActionChip(
                          avatar: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            _selectedPeriod == CaPeriod.custom && _customRange != null
                                ? '${DateFormat('dd/MM').format(_customRange!.start)} - ${DateFormat('dd/MM').format(_customRange!.end)}'
                                : 'Custom Date Range',
                          ),
                          backgroundColor: _selectedPeriod == CaPeriod.custom
                              ? brandDark.withOpacity(0.12)
                              : Colors.grey.shade100,
                          side: BorderSide(
                            color: _selectedPeriod == CaPeriod.custom
                                ? brandDark
                                : Colors.grey.shade300,
                          ),
                          onPressed: _pickCustomRange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Active Range: ${_getPeriodLabel()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _includeVoid,
                              activeColor: brandDark,
                              onChanged: (v) => setState(() => _includeVoid = v ?? false),
                            ),
                            const Text('Include Voided Bills', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 3. Dual Metrics Breakdown Cards (GST vs Non-GST)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: GST Bills Card
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F9F4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFC3E6CB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF28A745),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'GST BILLS (TAX INVOICES)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${m.gstInvoicesCount} Invoices',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF155724),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _miniStat('Taxable Turnover', inr(m.gstTaxable), 'Base Sales')),
                                    Expanded(child: _miniStat('CGST (9%)', inr(m.gstCgst), 'Central Tax')),
                                    Expanded(child: _miniStat('SGST (9%)', inr(m.gstSgst), 'State Tax')),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _miniStat('Output GST Liability', inr(m.gstTotalTax), 'Payable to Govt',
                                          highlight: true),
                                    ),
                                    Expanded(child: _miniStat('GST Gross Billing', inr(m.gstTotalRevenue), 'Taxable + GST')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Right: Non-GST Bills Card
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD6D8DB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C757D),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'NON-GST BILLS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${m.nonGstInvoicesCount} Bills',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF383D41),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                _miniStat('Non-GST Turnover', inr(m.nonGstTotalRevenue), 'Exempt / Bill of Supply'),
                                const SizedBox(height: 10),
                                _miniStat('Combined Gross Turnover', inr(m.totalRevenue),
                                    '${allPeriodInvoices.length} Total Bills',
                                    highlight: true),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Payment mode audit strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE8E2D9)),
                      ),
                      child: Row(
                        children: [
                          const Text('Collections Trail:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 14),
                          _modeChip('UPI / QR', m.upiTotal, m.upiCount, Colors.purple),
                          const SizedBox(width: 14),
                          _modeChip('Cash', m.cashTotal, m.cashCount, Colors.green),
                          const SizedBox(width: 14),
                          _modeChip('Card', m.cardTotal, m.cardCount, Colors.blue),
                          if (m.unpaidCount > 0) ...[
                            const SizedBox(width: 14),
                            _modeChip('Unpaid', m.unpaidTotal, m.unpaidCount, Colors.orange),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Compliance notice
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CA Ready: GST bills and Non-GST bills are exported in separate sections with SAC code, 9% CGST / 9% SGST output liabilities, and audit trails for direct filing in GSTR-1 & Income Tax.',
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEDE8E3))),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 10),
                  // Download GST Bills only (Quick button)
                  if (m.gstInvoicesCount > 0 && _selectedTaxFilter == CaTaxFilter.all)
                    OutlinedButton.icon(
                      onPressed: _downloadingCsv
                          ? null
                          : () => _handleDownloadCsv(allPeriodInvoices, settings, specificTaxFilter: 'gst'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E7E34),
                        side: const BorderSide(color: Color(0xFF28A745)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.download, size: 16),
                      label: Text('Download GST Bills (${m.gstInvoicesCount})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  const Spacer(),
                  // Download CSV / Excel
                  OutlinedButton.icon(
                    onPressed: displayInvoices.isEmpty || _downloadingCsv
                        ? null
                        : () => _handleDownloadCsv(allPeriodInvoices, settings),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E7E34),
                      side: const BorderSide(color: Color(0xFF28A745)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _downloadingCsv
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E7E34)),
                          )
                        : const Icon(Icons.table_view_outlined, size: 18),
                    label: Text(
                      _selectedTaxFilter == CaTaxFilter.gstOnly
                          ? 'Download GST CSV (${m.gstInvoicesCount})'
                          : _selectedTaxFilter == CaTaxFilter.nonGstOnly
                              ? 'Download Non-GST CSV (${m.nonGstInvoicesCount})'
                              : 'Download CSV (Separated)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Download / Print PDF Report
                  ElevatedButton.icon(
                    onPressed: displayInvoices.isEmpty || _generatingPdf
                        ? null
                        : () => _handlePrintPdf(allPeriodInvoices, settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: _generatingPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text(
                      _selectedTaxFilter == CaTaxFilter.gstOnly
                          ? 'Print GST Report PDF'
                          : _selectedTaxFilter == CaTaxFilter.nonGstOnly
                              ? 'Print Non-GST Report PDF'
                              : 'Download / Print PDF Report',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _taxFilterChip(CaTaxFilter filter, String label, {Color? badgeColor, String? subtitle}) {
    final isSelected = _selectedTaxFilter == filter;
    const brandDark = Color(0xFF665646);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedTaxFilter = filter);
      },
      selectedColor: badgeColor ?? brandDark,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
        color: isSelected
            ? (badgeColor ?? brandDark)
            : Colors.grey.shade300,
      ),
    );
  }

  Widget _periodChip(CaPeriod period, String label) {
    final isSelected = _selectedPeriod == period;
    const brandDark = Color(0xFF665646);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedPeriod = period);
      },
      selectedColor: brandDark,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _miniStat(String label, String value, String sub, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6C757D))),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: highlight ? const Color(0xFF1E7E34) : const Color(0xFF2C2E3E),
          ),
        ),
        const SizedBox(height: 1),
        Text(sub, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _modeChip(String mode, double total, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$mode: ', style: const TextStyle(fontSize: 11, color: Colors.black87)),
        Text(inr(total, decimals: false),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        Text(' ($count)', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600)),
      ],
    );
  }
}

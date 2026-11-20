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
        // Indian Fiscal Quarter: Q1 (Apr-Jun), Q2 (Jul-Sep), Q3 (Oct-Dec), Q4 (Jan-Mar)
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
        // Apr 1 of current or previous year to Mar 31
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
    BillingSettings settings,
  ) async {
    setState(() => _downloadingCsv = true);
    try {
      await CaReportService.downloadCsv(
        invoices: filtered,
        settings: settings,
        periodLabel: _getPeriodLabel(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CA Billing Report (CSV) downloaded successfully!'),
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
    final filtered = _filterInvoices(pay.invoices);
    final m = CaReportMetrics.compute(filtered);

    const brandDark = Color(0xFF665646);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                          'Export Billing & Tax Report for Chartered Accountant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2E3E),
                          ),
                        ),
                        Text(
                          'Generates GSTR-1 & Audit-ready reports with SAC codes, GST breakups, and collection trails',
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    const Text(
                      'SELECT REPORTING PERIOD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFF8B7D76),
                      ),
                    ),
                    const SizedBox(height: 10),
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

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 15, color: Colors.grey.shade600),
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
                            const Text('Include Void / Cancelled',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Metrics Preview Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF9F6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8E2D9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TAX & TURNOVER PREVIEW (FOR CA AUDIT)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: brandDark,
                                ),
                              ),
                              Text(
                                '${filtered.length} Invoices Found',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              _metricBox('Taxable Turnover', inr(m.totalTaxable), 'Base Sales'),
                              _metricBox('CGST (9%)', inr(m.totalCgst), 'Central GST'),
                              _metricBox('SGST (9%)', inr(m.totalSgst), 'State GST'),
                              _metricBox('Total GST Liability', inr(m.totalGst), 'Total Output Tax'),
                              _metricBox('Gross Revenue', inr(m.totalRevenue), 'Total Invoiced'),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Payment mode split
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Text('Collection Audit:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Compliance notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.verified_outlined, size: 18, color: Colors.blue.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The exported files include SAC 999722, GSTIN (${settings.gstin ?? "Not Set"}), customer details, line-item tax breakdowns, and payment reconciliation codes formatted for instant import into Tally, ClearTax, Marg, and Excel.',
                              style: TextStyle(fontSize: 11.5, color: Colors.blue.shade900, height: 1.4),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEDE8E3))),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close'),
                  ),
                  const Spacer(),
                  // Download CSV / Excel
                  OutlinedButton.icon(
                    onPressed: filtered.isEmpty || _downloadingCsv
                        ? null
                        : () => _handleDownloadCsv(filtered, settings),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E7E34),
                      side: const BorderSide(color: Color(0xFF28A745)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _downloadingCsv
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E7E34)),
                          )
                        : const Icon(Icons.table_view_outlined, size: 18),
                    label: const Text('Download Excel / CSV', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  // Download / Print PDF Report
                  ElevatedButton.icon(
                    onPressed: filtered.isEmpty || _generatingPdf
                        ? null
                        : () => _handlePrintPdf(filtered, settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    label: const Text('Download / Print PDF Report',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _metricBox(String label, String value, String sub) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF75788D))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C2E3E))),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _modeChip(String mode, double total, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text('$mode: ', style: const TextStyle(fontSize: 11.5, color: Colors.black87)),
        Text(inr(total, decimals: false),
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
        Text(' ($count)', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}

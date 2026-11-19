import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/payment_controller.dart';
import 'package:ira_spa_webapp/models/bookings_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/utils/payment_utils.dart';
import 'package:ira_spa_webapp/views/payments/billing_settings_dialog.dart';
import 'package:ira_spa_webapp/views/payments/checkout_dialog.dart';
import 'package:ira_spa_webapp/views/payments/payments_page.dart';
import 'package:provider/provider.dart';

const _brand = Color(0xFF8C7B68);
const _brandDark = Color(0xFF665646);

/// Dashboard block: 7-day collection chart, method split, dues and the
/// latest invoices. Everything updates live through Supabase realtime.
class PaymentsOverview extends StatelessWidget {
  final VoidCallback? onViewAll;
  const PaymentsOverview({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final pay = context.watch<PaymentController>();
    if (pay.setupMissing) return const SizedBox.shrink();
    final bookings = context.watch<BookingController>().bookings;
    final uncollected = pay.uncollectedBookings(bookings);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 900;
      final pending = _card(
        title: 'Pending payments',
        trailing: TextButton(onPressed: onViewAll, child: const Text('View all')),
        child: _pending(context, pay, uncollected),
      );
      final issues = _card(
        title: 'Payment issues',
        child: _issues(context, pay, bookings, uncollected.length),
      );
      final chart = _card(
        title: 'Collections — last 7 days',
        trailing: Text(
          inr(pay.lastDays(7).fold(0.0, (s, d) => s + d.amount), decimals: false),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        child: _WeekChart(days: pay.lastDays(7)),
      );
      final split = _card(
        title: 'This month by method',
        child: _MethodSplit(split: pay.monthByMethod),
      );

      if (!wide) {
        return Column(spacing: 15, children: [pending, issues, chart, split]);
      }
      return Column(
        spacing: 15,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 15,
            children: [
              Expanded(flex: 3, child: pending),
              Expanded(flex: 2, child: issues),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 15,
            children: [
              Expanded(flex: 3, child: chart),
              Expanded(flex: 2, child: split),
            ],
          ),
        ],
      );
    });
  }

  //---------------------------------------------------------------- Pending
  Widget _pending(
    BuildContext context,
    PaymentController pay,
    List<BookingsModel> uncollected,
  ) {
    final unpaid = pay.unpaidInvoices;
    if (unpaid.isEmpty && uncollected.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.verified_outlined, color: AppColors.success),
            SizedBox(width: 8),
            Text('All caught up — nothing pending',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    final unbilledTotal = uncollected.fold(0.0, (s, b) {
      final v = double.tryParse(
              (b.servicePrice ?? '').replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;
      return s + v;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(inr(pay.unpaidTotal + unbilledTotal, decimals: false),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${unpaid.length} unpaid invoices • ${uncollected.length} not billed',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final inv in unpaid)
                _pendingTile(
                  icon: Icons.receipt_long_outlined,
                  title: inv.customerName.isEmpty ? 'Walk-in' : inv.customerName,
                  subtitle:
                      '${inv.invoiceNumber} • ${_ago(inv.createdAt)} • QR shown, not paid',
                  amount: inv.total,
                  onTap: () => collectInvoice(context, inv),
                ),
              for (final b in uncollected)
                _pendingTile(
                  icon: Icons.spa_outlined,
                  title: b.customer,
                  subtitle:
                      '${b.servicename} • ${formatDate(b.bookingdate)} • completed, not billed',
                  amount: double.tryParse((b.servicePrice ?? '')
                          .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                      0,
                  onTap: () => showCheckoutDialog(context: context, item: b),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pendingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double amount,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (amount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(inr(amount, decimals: false),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              side: const BorderSide(color: _brandDark),
            ),
            icon: const Icon(Icons.qr_code_2, size: 16, color: _brandDark),
            label: const Text('Collect',
                style: TextStyle(color: _brandDark, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }

  //----------------------------------------------------------------- Issues
  Widget _issues(
    BuildContext context,
    PaymentController pay,
    List<BookingsModel> bookings,
    int unbilled,
  ) {
    final now = DateTime.now();
    final s = pay.settings;
    final invoicedBookingIds = pay.invoices
        .where((i) => !i.isVoid)
        .map((i) => i.bookingId)
        .whereType<int>()
        .toSet();

    final overdue = pay.unpaidInvoices
        .where((i) => now.difference(i.createdAt).inHours >= 24)
        .toList();
    final paidNoInvoice = bookings
        .where((b) =>
            (b.paymentStatus ?? '').toLowerCase() == 'paid' &&
            !invoicedBookingIds.contains(b.id))
        .length;
    final monthPaid = pay.invoices.where((i) =>
        i.isPaid &&
        i.revenueDate.year == now.year &&
        i.revenueDate.month == now.month);
    final upiNoRef = monthPaid
        .where((i) => i.paymentMethod == 'UPI' && (i.paymentRef ?? '').isEmpty)
        .length;
    final voided = pay.invoices
        .where((i) =>
            i.isVoid && i.createdAt.year == now.year && i.createdAt.month == now.month)
        .length;
    final gstNoGstin = s != null &&
        !s.hasGstin &&
        pay.invoices.any((i) => i.hasGst && !i.isVoid);

    final items = <Widget>[
      if (!pay.upiReady)
        _issue(Icons.qr_code_2, Colors.red.shade700, 'UPI ID not set up',
            'QR codes cannot be generated', 'Fix',
            () => showBillingSettingsDialog(context)),
      if (overdue.isNotEmpty)
        _issue(
            Icons.schedule,
            Colors.red.shade700,
            '${overdue.length} unpaid for over 24 hours',
            '${inr(overdue.fold(0.0, (a, i) => a + i.total), decimals: false)} overdue',
            'View',
            onViewAll),
      if (unbilled > 0)
        _issue(Icons.receipt_long_outlined, Colors.orange.shade800,
            '$unbilled completed bookings not billed',
            'Services done but no payment recorded', 'View', onViewAll),
      if (paidNoInvoice > 0)
        _issue(Icons.description_outlined, Colors.orange.shade800,
            '$paidNoInvoice paid bookings without invoice',
            'Open the booking payment chip to issue one', null, null),
      if (upiNoRef > 0)
        _issue(Icons.tag, Colors.amber.shade800,
            '$upiNoRef UPI payments without UTR this month',
            'Harder to match with bank statement', null, null),
      if (gstNoGstin)
        _issue(Icons.account_balance_outlined, Colors.amber.shade800,
            'GST charged but no GSTIN set',
            'Add GSTIN in billing settings', 'Fix',
            () => showBillingSettingsDialog(context)),
      if (voided > 0)
        _issue(Icons.block, Colors.grey.shade700,
            '$voided invoices voided this month', 'Excluded from revenue', null, null),
    ];

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text('No payment issues',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return Column(children: items);
  }

  Widget _issue(IconData icon, Color color, String title, String sub,
      String? action, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (action != null && onTap != null)
            TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }

  static Widget _card({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

//==============================================================================
class _WeekChart extends StatelessWidget {
  final List<DayTotal> days;
  const _WeekChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final max = days.fold(0.0, (m, d) => d.amount > m ? d.amount : m);
    final today = DateTime.now();
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Tooltip(
                message: '${DateFormat('EEE, dd MMM').format(d.day)}\n'
                    '${inr(d.amount)} • ${d.count} payments',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        d.amount > 0 ? _short(d.amount) : '',
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        height: max <= 0 ? 4 : 4 + 150 * (d.amount / max),
                        decoration: BoxDecoration(
                          color: _isSame(d.day, today)
                              ? _brandDark
                              : _brand.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSame(d.day, today)
                            ? 'Today'
                            : DateFormat('EEE').format(d.day),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _isSame(d.day, today)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static bool _isSame(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _short(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }
}

class _MethodSplit extends StatelessWidget {
  final Map<String, double> split;
  const _MethodSplit({required this.split});

  static const _colors = {
    'UPI': Color(0xFF665646),
    'Cash': Color(0xFFC9A46A),
    'Card': Color(0xFF6F8A74),
  };

  @override
  Widget build(BuildContext context) {
    final total = split.values.fold(0.0, (s, v) => s + v);
    final entries = split.entries.where((e) => e.value > 0 || _colors.containsKey(e.key)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: total <= 0
                ? Container(color: AppColors.surfaceAlt)
                : Row(
                    children: [
                      for (final e in entries)
                        if (e.value > 0)
                          Expanded(
                            flex: (e.value / total * 1000).round().clamp(1, 1000).toInt(),
                            child: Container(
                                color: _colors[e.key] ?? Colors.grey),
                          ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _colors[e.key] ?? Colors.grey,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(e.key, style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Text(
                  total > 0 ? '${(e.value / total * 100).toStringAsFixed(0)}%' : '0%',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: Text(inr(e.value, decimals: false),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/payment_controller.dart';
import 'package:ira_spa_webapp/models/bookings_model.dart';
import 'package:ira_spa_webapp/models/invoice_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/utils/payment_utils.dart';
import 'package:ira_spa_webapp/views/payments/billing_settings_dialog.dart';
import 'package:ira_spa_webapp/views/payments/ca_report_dialog.dart';
import 'package:ira_spa_webapp/views/payments/checkout_dialog.dart';
import 'package:ira_spa_webapp/views/payments/invoice_actions.dart';
import 'package:provider/provider.dart';

const _brand = Color(0xFF8C7B68);
const _brandDark = Color(0xFF665646);

enum _Period { today, week, month, all }

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  _Period _period = _Period.month;
  String _status = 'All'; // All | Paid | Unpaid
  String _method = 'All';
  String _search = '';

  List<InvoiceModel> _filter(List<InvoiceModel> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return all.where((i) {
      if (i.isVoid && _status != 'All') return false;
      final d = i.revenueDate;
      switch (_period) {
        case _Period.today:
          if (d.isBefore(today)) return false;
        case _Period.week:
          if (d.isBefore(today.subtract(const Duration(days: 6)))) return false;
        case _Period.month:
          if (d.year != now.year || d.month != now.month) return false;
        case _Period.all:
          break;
      }
      if (_status == 'Paid' && !i.isPaid) return false;
      if (_status == 'Unpaid' && i.paymentStatus != 'unpaid') return false;
      if (_method != 'All' && i.paymentMethod != _method) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final hay = '${i.invoiceNumber} ${i.customerName} ${i.customerPhone ?? ''} '
                '${i.items.map((e) => e.description).join(' ')}'
            .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _newBill() async {
    final ref = context.read<AuthController>().businessRef;
    await showCheckoutDialog(context: context, item: walkInBooking(ref));
  }

  @override
  Widget build(BuildContext context) {
    final pay = context.watch<PaymentController>();
    final bookings = context.watch<BookingController>();
    final list = _filter(pay.invoices);
    final paidTotal =
        list.where((i) => i.isPaid).fold(0.0, (s, i) => s + i.total);
    final uncollected = pay.uncollectedBookings(bookings.bookings);
    final wide = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //------------------------------------------------------- Header
            LayoutBuilder(
              builder: (context, headerC) {
                final isCompact = headerC.maxWidth < 800;
                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Payments & Invoices',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 26,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        )),
                    SizedBox(height: 4),
                    Text('Collect via UPI QR, cash or card and issue GST invoices',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        )),
                  ],
                );

                final actionButtons = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => showCaReportDialog(context),
                      icon: const Icon(Icons.account_balance_outlined, size: 18),
                      label: const Text('Export Reports'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF665646),
                        side: const BorderSide(color: Color(0xFF8C7B68)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showBillingSettingsDialog(context),
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Billing settings'),
                    ),
                    ElevatedButton.icon(
                      onPressed: pay.setupMissing ? null : _newBill,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: _brandDark,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New bill'),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleBlock,
                      const SizedBox(height: 14),
                      actionButtons,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 16),
                    actionButtons,
                  ],
                );
              },
            ),
            const SizedBox(height: 15),

            if (pay.setupMissing)
              _notice(
                'Payments database not set up',
                'Open Supabase → SQL Editor and run supabase/migrations/20261119000000_payments_invoices.sql, then reload.',
                Icons.storage_outlined,
                action: TextButton(
                    onPressed: pay.refresh, child: const Text('Reload')),
              )
            else if (!pay.upiReady && !pay.loading)
              _notice(
                'Add your UPI ID to start generating QR codes',
                'Each QR will carry the exact bill amount, so customers can\'t pay the wrong amount.',
                Icons.qr_code_2,
                action: TextButton(
                  onPressed: () => showBillingSettingsDialog(context),
                  child: const Text('Set up now'),
                ),
              ),

            //-------------------------------------------------------- Stats
            LayoutBuilder(
              builder: (context, statsC) {
                final isWide = statsC.maxWidth >= 1050;
                final cards = [
                  _stat('Collected today', inr(pay.todayCollection, decimals: false),
                      '${pay.todayPaidCount} payments', Icons.today_outlined),
                  _stat('This month', inr(pay.monthCollection, decimals: false),
                      'GST ${inr(pay.monthGst, decimals: false)}',
                      Icons.calendar_month_outlined),
                  _stat(
                    'Unpaid dues',
                    inr(pay.unpaidTotal, decimals: false),
                    '${pay.unpaidInvoices.length} inv • ${uncollected.length} bks',
                    Icons.pending_actions_outlined,
                    warn: pay.unpaidInvoices.isNotEmpty || uncollected.isNotEmpty,
                  ),
                  _stat('Avg. bill (month)', inr(pay.averageTicket, decimals: false),
                      'per paid invoice', Icons.trending_up),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 14),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 148,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (_, i) => cards[i],
                );
              },
            ),
            const SizedBox(height: 15),

            //------------------------------------------ Uncollected bookings
            if (uncollected.isNotEmpty) ...[
              _uncollectedStrip(uncollected),
              const SizedBox(height: 15),
            ],

            //-------------------------------------------------------- Table
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _filters(),
                  const Divider(height: 1),
                  LayoutBuilder(
                    builder: (context, tblC) {
                      final isWide = tblC.maxWidth >= 720;
                      final tblContent = SizedBox(
                        width: isWide ? tblC.maxWidth : 720,
                        child: Column(
                          children: [
                            _tableHeader(),
                            const Divider(height: 1),
                            if (pay.loading)
                              const Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(color: _brand),
                              )
                            else if (list.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(48),
                                child: Column(
                                  children: [
                                    Icon(Icons.receipt_long_outlined,
                                        size: 40, color: AppColors.textSecondary),
                                    SizedBox(height: 8),
                                    Text('No invoices for this filter',
                                        style: TextStyle(color: AppColors.textSecondary)),
                                  ],
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: list.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (_, i) => _row(list[i]),
                              ),
                          ],
                        ),
                      );

                      if (isWide) return tblContent;
                      return Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: tblContent,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Text('${list.length} invoices',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        const Spacer(),
                        const Text('Collected: ',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                        Text(inr(paidTotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
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

  //================================ Widgets ===================================
  Widget _notice(String title, String body, IconData icon, {Widget? action}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFB78103)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
            ?action,
          ],
        ),
      );

  Widget _stat(String title, String value, String sub, IconData icon,
      {bool warn = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warn ? AppColors.warning : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.1,
                )),
          ),
          const SizedBox(height: 2),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _uncollectedStrip(List<BookingsModel> list) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Completed but not billed (${list.length})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final b in list.take(12))
                ActionChip(
                  avatar: const Icon(Icons.qr_code_2, size: 16, color: _brandDark),
                  label: Text('${b.customer} • ${b.servicename}',
                      style: const TextStyle(fontSize: 12)),
                  onPressed: () => showCheckoutDialog(context: context, item: b),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    Widget seg(_Period p, String label) {
      final sel = _period == p;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: sel,
          showCheckmark: false,
          selectedColor: _brand.withValues(alpha: 0.18),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: sel ? FontWeight.bold : FontWeight.w500,
            color: sel ? _brandDark : AppColors.textSecondary,
          ),
          onSelected: (_) => setState(() => _period = p),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            seg(_Period.today, 'Today'),
            seg(_Period.week, '7 days'),
            seg(_Period.month, 'This month'),
            seg(_Period.all, 'All'),
          ]),
          _drop('Status', _status, ['All', 'Paid', 'Unpaid'],
              (v) => setState(() => _status = v)),
          _drop('Method', _method, ['All', 'UPI', 'Cash', 'Card'],
              (v) => setState(() => _method = v)),
          SizedBox(
            width: 240,
            child: TextField(
              onChanged: (v) => setState(() => _search = v.trim()),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search invoice, customer, phone',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drop(String label, String value, List<String> opts,
      ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
          items: [
            for (final o in opts)
              DropdownMenuItem(value: o, child: Text('$label: $o')),
          ],
          onChanged: (v) => onChanged(v ?? 'All'),
        ),
      ),
    );
  }

  static const _hStyle = TextStyle(
    fontSize: 11,
    letterSpacing: 1,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  Widget _tableHeader() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text('INVOICE', style: _hStyle)),
            Expanded(flex: 3, child: Text('CUSTOMER', style: _hStyle)),
            Expanded(flex: 4, child: Text('ITEMS', style: _hStyle)),
            Expanded(flex: 2, child: Text('METHOD', style: _hStyle)),
            Expanded(
                flex: 2,
                child: Text('AMOUNT', style: _hStyle, textAlign: TextAlign.right)),
            SizedBox(width: 20),
            Expanded(flex: 2, child: Text('STATUS', style: _hStyle)),
            SizedBox(width: 40),
          ],
        ),
      );

  Widget _row(InvoiceModel i) {
    final (color, label) = i.isPaid
        ? (Colors.green.shade700, 'Paid')
        : i.isVoid
            ? (Colors.grey.shade600, 'Void')
            : (Colors.red.shade700, 'Unpaid');
    return InkWell(
      onTap: () => showInvoiceDetail(context, i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.invoiceNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(formatDateTime(i.revenueDate),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.customerName, style: const TextStyle(fontSize: 13)),
                  if ((i.customerPhone ?? '').isNotEmpty)
                    Text(i.customerPhone!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                i.items.map((e) => e.description).join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(_methodIcon(i.paymentMethod),
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(i.paymentMethod ?? '—', style: const TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(inr(i.total),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    decoration: i.isVoid ? TextDecoration.lineThrough : null,
                  )),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: i.paymentStatus == 'unpaid'
                  ? IconButton(
                      tooltip: 'Collect payment',
                      onPressed: () => collectInvoice(context, i),
                      icon: const Icon(Icons.qr_code_2, size: 20, color: _brandDark),
                    )
                  : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _methodIcon(String? m) => switch (m) {
      'UPI' => Icons.qr_code_2,
      'Cash' => Icons.payments_outlined,
      'Card' => Icons.credit_card,
      _ => Icons.remove,
    };

/// Re-opens checkout for an unpaid invoice (customer paying later).
Future<void> collectInvoice(BuildContext context, InvoiceModel inv) async {
  final bookings = context.read<BookingController>().bookings;
  BookingsModel? booking;
  for (final b in bookings) {
    if (b.id != null && b.id == inv.bookingId) booking = b;
  }
  booking ??= (walkInBooking(inv.businessRef)
    ..id = inv.bookingId
    ..customer = inv.customerName
    ..custphone = inv.customerPhone
    ..therapistname = inv.therapist ?? '');
  await showCheckoutDialog(context: context, item: booking, existing: inv);
}

/// Invoice preview with print / share / collect / void.
Future<void> showInvoiceDetail(BuildContext context, InvoiceModel inv) {
  return showDialog(
    context: context,
    builder: (ctx) {
      final pay = ctx.watch<PaymentController>();
      final s = pay.settings ??
          BillingSettings.empty(inv.businessRef, businessName: 'Spa');
      Widget line(String k, String v, {bool bold = false}) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(k,
                    style: TextStyle(
                        fontSize: 13,
                        color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
                Text(v,
                    style: TextStyle(
                        fontSize: bold ? 16 : 13,
                        fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
              ],
            ),
          );
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inv.invoiceNumber,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(formatDateTime(inv.createdAt),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(inv.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if ((inv.customerPhone ?? '').isNotEmpty)
                  Text(inv.customerPhone!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                if ((inv.therapist ?? '').isNotEmpty)
                  Text('Therapist: ${inv.therapist}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                const Divider(height: 24),
                for (final it in inv.items)
                  line('${it.description}${it.qty > 1 ? ' × ${it.qty}' : ''}',
                      inr(it.amount)),
                const Divider(height: 20),
                line('Subtotal', inr(inv.subtotal)),
                if (inv.discount > 0) line('Discount', '- ${inr(inv.discount)}'),
                if (inv.hasGst) ...[
                  line('CGST', inr(inv.cgst)),
                  line('SGST', inr(inv.sgst)),
                ],
                if (inv.roundOff != 0) line('Round off', inr(inv.roundOff)),
                const SizedBox(height: 4),
                line('Total', inr(inv.total), bold: true),
                const SizedBox(height: 8),
                Text(
                  inv.isPaid
                      ? 'Paid via ${inv.paymentMethod}'
                          '${(inv.paymentRef ?? '').isNotEmpty ? ' • Ref ${inv.paymentRef}' : ''}'
                          '${inv.paidAt != null ? ' • ${formatDateTime(inv.paidAt!)}' : ''}'
                      : inv.isVoid
                          ? 'This invoice was voided'
                          : 'Awaiting payment',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: inv.isPaid ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Center(child: InvoiceActions(invoice: inv, settings: s)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!inv.isVoid)
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: ctx,
                            builder: (c) => AlertDialog(
                              title: const Text('Void this invoice?'),
                              content: Text(
                                inv.isPaid
                                    ? 'It will be excluded from revenue. Refund the customer separately if needed.'
                                    : 'It will be removed from unpaid dues.',
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Void',
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (ok == true && ctx.mounted) {
                            await ctx.read<PaymentController>().voidInvoice(inv);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          }
                        },
                        icon: const Icon(Icons.block, size: 16, color: Colors.red),
                        label: const Text('Void', style: TextStyle(color: Colors.red)),
                      ),
                    const Spacer(),
                    if (inv.paymentStatus == 'unpaid')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          collectInvoice(context, inv);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          backgroundColor: _brandDark,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.qr_code_2, size: 18),
                        label: const Text('Collect payment'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/payment_controller.dart';
import 'package:ira_spa_webapp/models/bookings_model.dart';
import 'package:ira_spa_webapp/models/invoice_model.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/utils/payment_utils.dart';
import 'package:ira_spa_webapp/views/payments/billing_settings_dialog.dart';
import 'package:ira_spa_webapp/views/payments/invoice_actions.dart';
import 'package:ira_spa_webapp/views/service/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _brand = Color(0xFF8C7B68);
const _brandDark = Color(0xFF665646);

/// Opens the checkout: Bill → Collect (dynamic UPI QR / cash / card) → Invoice.
///
/// * If the booking already has a **paid** invoice it opens straight on the
///   invoice screen (reprint / share) — no double charging.
/// * If it has an **unpaid** invoice (QR shown earlier, customer paid later)
///   that invoice is reused with the same number.
Future<InvoiceModel?> showCheckoutDialog({
  required BuildContext context,
  required BookingsModel item,
  ServiceModel? service,
  InvoiceModel? existing,
}) {
  return showDialog<InvoiceModel>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CheckoutDialog(item: item, service: service, existing: existing),
  );
}

/// A blank booking used for walk-in / counter sales from the Payments page.
BookingsModel walkInBooking(int? businessRef) => BookingsModel(
      businessRef: businessRef,
      customer: '',
      servicename: '',
      therapistname: '',
      bookingdate: DateTime.now(),
      timeslot: '',
      bookingdetails: '',
      statusrequired: 'Completed',
    );

class _ItemRow {
  final TextEditingController desc;
  final TextEditingController rate;
  int qty;
  String? sac;
  _ItemRow({required String description, required double price, this.qty = 1, this.sac})
      : desc = TextEditingController(text: description),
        rate = TextEditingController(
          text: price > 0
              ? (price == price.roundToDouble()
                  ? price.toStringAsFixed(0)
                  : price.toStringAsFixed(2))
              : '',
        );

  InvoiceItem toItem() => InvoiceItem(
        description: desc.text.trim().isEmpty ? 'Service' : desc.text.trim(),
        sac: sac,
        qty: qty,
        rate: double.tryParse(rate.text.trim()) ?? 0,
      );

  void dispose() {
    desc.dispose();
    rate.dispose();
  }
}

class CheckoutDialog extends StatefulWidget {
  final BookingsModel item;
  final ServiceModel? service;
  final InvoiceModel? existing;

  const CheckoutDialog({
    super.key,
    required this.item,
    this.service,
    this.existing,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  int _step = 0; // 0 bill, 1 collect, 2 done
  bool _booting = true;
  bool _busy = false;
  String? _error;

  final List<_ItemRow> _rows = [];
  final _discountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _gstOn = false;
  String _method = 'UPI';
  InvoiceModel? _invoice;

  /// Booking was marked paid before invoicing existed → only issue an invoice.
  bool _alreadyPaid = false;

  PaymentController get _pay => context.read<PaymentController>();
  bool get _isWalkIn => widget.item.id == null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.item.customer;
    _phoneCtrl.text = widget.item.custphone ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final settings = _pay.settings;
    _gstOn = settings?.hasGstin ?? false;

    InvoiceModel? inv = widget.existing;
    if (inv == null && !_pay.setupMissing) {
      try {
        inv = await _pay.invoiceForBooking(widget.item.id);
      } on PaymentsSetupMissing {
        inv = null;
      } catch (_) {}
    }

    if (inv != null) {
      _invoice = inv;
      for (final it in inv.items) {
        _rows.add(_ItemRow(
          description: it.description,
          price: it.rate,
          qty: it.qty,
          sac: it.sac,
        ));
      }
      if (inv.discount > 0) _discountCtrl.text = inv.discount.toStringAsFixed(0);
      _gstOn = inv.hasGst;
      if (inv.customerName.isNotEmpty) _nameCtrl.text = inv.customerName;
      if ((inv.customerPhone ?? '').isNotEmpty) _phoneCtrl.text = inv.customerPhone!;
      if (inv.isPaid) _step = 2;
    }

    if (inv == null && (widget.item.paymentStatus ?? '').toLowerCase() == 'paid') {
      _alreadyPaid = true;
      final m = (widget.item.paymentMethod ?? '').toLowerCase();
      _method = m.contains('cash')
          ? 'Cash'
          : m.contains('card')
              ? 'Card'
              : 'UPI';

      final cleanPrice = double.tryParse((widget.item.servicePrice ?? '')
              .replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0.0;
      final serviceName = widget.item.servicename.isEmpty
          ? 'Spa Service'
          : widget.item.servicename;

      _invoice = InvoiceModel(
        businessRef: widget.item.businessRef ?? 0,
        bookingId: widget.item.id,
        invoiceNumber: 'INV-${(widget.item.id ?? 1).toString().padLeft(4, '0')}',
        customerName: widget.item.customer,
        customerPhone: widget.item.custphone,
        therapist: widget.item.therapistname,
        serviceDate: widget.item.bookingdate,
        paidAt: widget.item.bookingdate,
        paymentStatus: 'Paid',
        paymentMethod: widget.item.paymentMethod ?? 'Cash',
        items: [
          InvoiceItem(
            description: serviceName,
            qty: 1,
            rate: cleanPrice,
          ),
        ],
        subtotal: cleanPrice,
        discount: 0,
        taxableAmount: cleanPrice,
        gstRate: 0,
        cgst: 0,
        sgst: 0,
        roundOff: 0,
        total: cleanPrice,
      );
      _step = 2;
    }

    if (_rows.isEmpty) {
      _rows.add(_ItemRow(
        description: _serviceTitle(),
        price: _initialPrice(),
        sac: settings?.sacCode,
      ));
    }
    if (mounted) setState(() => _booting = false);
  }

  String _serviceTitle() {
    final name = widget.item.servicename.trim();
    if (name.isEmpty) return '';
    final dur = widget.item.serviceDuration?.trim();
    if (dur != null && dur.isNotEmpty && dur != '-' && !name.contains('min')) {
      final d = RegExp(r'^\d+$').hasMatch(dur) ? '$dur min' : dur;
      return '$name ($d)';
    }
    return name;
  }

  double _initialPrice() {
    if (widget.service != null && widget.service!.price > 0) {
      return widget.service!.price;
    }
    final raw = widget.item.servicePrice;
    if (raw != null && raw.isNotEmpty) {
      return double.tryParse(raw.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    }
    return 0;
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _discountCtrl.dispose();
    _refCtrl.dispose();
    _cashCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  //================================ Math ======================================
  List<InvoiceItem> get _items =>
      _rows.map((r) => r.toItem()).where((i) => i.rate > 0).toList();

  InvoiceTotals get _totals {
    final s = _pay.settings;
    return InvoiceTotals.compute(
      items: _items,
      discount: double.tryParse(_discountCtrl.text.trim()) ?? 0,
      gstRate: _gstOn ? (s?.defaultGstRate ?? 9) : 0,
      inclusive: s?.gstInclusive ?? false,
    );
  }

  //=============================== Actions ====================================
  void _syncCustomer() {
    widget.item.customer = _nameCtrl.text.trim().isEmpty
        ? 'Walk-in Customer'
        : _nameCtrl.text.trim();
    final p = _phoneCtrl.text.trim();
    widget.item.custphone = p.isEmpty ? null : p;
  }

  Future<void> _proceed() async {
    final totals = _totals;
    if (totals.total <= 0) {
      setState(() => _error = 'Enter an amount greater than zero');
      return;
    }
    if (_isWalkIn) _syncCustomer();
    setState(() => _error = null);

    if (_method == 'UPI') {
      if (!_pay.upiReady) {
        setState(() => _error = 'Add your UPI ID in Billing Settings to generate a QR');
        return;
      }
      // Save as unpaid first: the invoice number goes into the QR (tr=)
      // so the credit can be matched, and if the customer leaves without
      // paying it shows up under "Unpaid" on the Payments page.
      await _run(() async {
        _invoice = await _pay.saveInvoice(
          existing: _invoice,
          booking: widget.item,
          items: _items,
          totals: totals,
        );
        _step = 1;
      });
    } else {
      setState(() {
        _refCtrl.clear();
        _cashCtrl.text = totals.total.toStringAsFixed(0);
        _step = 1;
      });
    }
  }

  Future<void> _confirmPaid() async {
    final totals = _totals;
    if (totals.total <= 0) {
      setState(() => _error = 'Enter an amount greater than zero');
      return;
    }
    if (_isWalkIn) _syncCustomer();
    await _run(() async {
      _invoice = await _pay.saveInvoice(
        existing: _invoice,
        booking: widget.item,
        items: _items,
        totals: totals,
      );
      _invoice = await _pay.markPaid(
        _invoice!,
        method: _method,
        reference: _refCtrl.text,
      );
      await _syncBooking(totals);
      _step = 2;
    });
  }

  /// Keeps the existing Booking columns (payment_status, total_amount …)
  /// in sync so the rest of the app keeps working as before.
  Future<void> _syncBooking(InvoiceTotals t) async {
    final id = widget.item.id;
    if (id == null || !mounted) return;
    try {
      await context.read<BookingController>().completeBookingWithPayment(
            id: id,
            rate: t.taxable,
            totalAmount: t.total,
            paymentMethod: _method,
            withGst: t.gstRate > 0,
            gstAmount: t.gst,
          );
    } catch (e) {
      debugPrint('[Checkout] booking sync failed: $e');
    }
  }

  /// Used only when the payments tables don't exist yet.
  Future<void> _legacyMarkPaid() async {
    await _run(() async {
      await _syncBooking(_totals);
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fn();
    } on PaymentsSetupMissing {
      _error = 'Payments tables are not set up yet. Run the SQL migration in Supabase.';
    } catch (e) {
      _error = 'Something went wrong: $e';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openSettings() async {
    await showBillingSettingsDialog(context);
    if (mounted) setState(() => _error = null);
  }

  //================================= UI =======================================
  @override
  Widget build(BuildContext context) {
    context.watch<PaymentController>();
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
        child: _booting
            ? const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator(color: _brand)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: switch (_step) {
                            0 => _billStep(),
                            1 => _collectStep(),
                            _ => _doneStep(),
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: _banner(_error!, error: true),
                    ),
                  _footer(),
                ],
              ),
      ),
    );
  }

  Widget _header() {
    const labels = ['Bill', 'Payment', 'Invoice'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 12, 14),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            _stepDot(i, labels[i]),
            if (i < 2)
              Expanded(
                child: Container(
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: i < _step ? _brand : AppColors.border,
                ),
              ),
          ],
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Close',
            onPressed: _busy ? null : () => Navigator.of(context).pop(_invoice),
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int i, String label) {
    final done = i < _step;
    final active = i == _step;
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: done || active ? _brand : AppColors.surfaceAlt,
          child: done
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? _brandDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  //------------------------------------------------------------------ Step 0
  Widget _billStep() {
    final s = _pay.settings;
    final t = _totals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pay.setupMissing)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _banner(
              'Invoices are disabled until the payments SQL migration is run in Supabase. '
              'You can still mark this booking as paid.',
            ),
          ),
        if (_alreadyPaid)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _banner(
              'This booking is already marked as paid. Check the amount and method, '
              'then create the invoice for your records — no new payment will be collected.',
            ),
          ),
        if (_invoice != null && !_invoice!.isPaid)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _banner(
              'Invoice ${_invoice!.invoiceNumber} is awaiting payment of ${inr(_invoice!.total)}',
            ),
          ),

        // Customer
        if (_isWalkIn) ...[
          _sectionLabel('Customer'),
          Row(
            children: [
              Expanded(
                child: _field(_nameCtrl, 'Customer name', onChanged: (_) {}),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  _phoneCtrl,
                  'Mobile (for WhatsApp)',
                  keyboard: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ] else
          _bookingSummary(),

        // Items
        Row(
          children: [
            _sectionLabel('Items'),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _rows.add(
                    _ItemRow(description: '', price: 0, sac: s?.sacCode),
                  )),
              icon: const Icon(Icons.add, size: 16, color: _brand),
              label: const Text('Add item', style: TextStyle(color: _brand, fontSize: 12)),
            ),
          ],
        ),
        for (var i = 0; i < _rows.length; i++) _itemRow(i),
        const SizedBox(height: 12),

        // Discount + GST
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              child: _field(
                _discountCtrl,
                'Discount (₹)',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                prefix: '₹ ',
              ),
            ),
            const Spacer(),
            Text(
              'GST ${(s?.defaultGstRate ?? 9).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Switch(
              value: _gstOn,
              activeThumbColor: _brand,
              onChanged: (v) => setState(() => _gstOn = v),
            ),
          ],
        ),
        if (_gstOn && (s?.gstInclusive ?? false))
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('Prices include GST',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
        const SizedBox(height: 12),
        _totalsCard(t),
        const SizedBox(height: 18),

        // Method
        _sectionLabel('Payment method'),
        Row(
          children: [
            _methodTile('UPI', Icons.qr_code_2_rounded, 'Dynamic QR'),
            _methodTile('Cash', Icons.payments_outlined, 'Counter'),
            _methodTile('Card', Icons.credit_card_outlined, 'POS machine'),
          ],
        ),
        if (_method == 'UPI' && !_pay.upiReady && !_pay.setupMissing)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: InkWell(
              onTap: _openSettings,
              child: _banner(
                'Set up your UPI ID once to generate QR codes with the amount pre-filled. Tap to set up →',
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _bookingSummary() {
    final b = widget.item;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _brand.withValues(alpha: 0.15),
            child: Text(
              b.customer.isNotEmpty ? b.customer[0].toUpperCase() : '?',
              style: const TextStyle(color: _brandDark, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.customer,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  [
                    if ((b.custphone ?? '').isNotEmpty) b.custphone!,
                    if (b.therapistname.isNotEmpty) 'with ${b.therapistname}',
                    formatDate(b.bookingdate),
                  ].join('  •  '),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            'BK${(b.id ?? 0).toString().padLeft(3, '0')}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _brand,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(int i) {
    final r = _rows[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _field(r.desc, 'Service / product', onChanged: (_) => setState(() {})),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: _field(
              r.rate,
              'Price',
              prefix: '₹ ',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              align: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 34,
            child: _rows.length > 1
                ? IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    tooltip: 'Remove',
                    onPressed: () => setState(() => _rows.removeAt(i).dispose()),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _totalsCard(InvoiceTotals t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _line('Subtotal', inr(t.subtotal)),
          if (t.discount > 0) _line('Discount', '- ${inr(t.discount)}'),
          if (t.gstRate > 0) ...[
            _line('Taxable value', inr(t.taxable)),
            _line('CGST ${(t.gstRate / 2).toStringAsFixed(1)}%', inr(t.cgst)),
            _line('SGST ${(t.gstRate / 2).toStringAsFixed(1)}%', inr(t.sgst)),
          ],
          if (t.roundOff != 0)
            _line('Round off', '${t.roundOff > 0 ? '+' : '-'} ${inr(t.roundOff.abs())}'),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total payable',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                inr(t.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: _brandDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _methodTile(String m, IconData icon, String sub) {
    final sel = _method == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _method = m;
          _error = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? _brand.withValues(alpha: 0.10) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? _brand : AppColors.border, width: sel ? 1.6 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: sel ? _brandDark : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(m,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.bold : FontWeight.w600,
                    color: sel ? _brandDark : AppColors.textPrimary,
                  )),
              Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  //------------------------------------------------------------------ Step 1
  Widget _collectStep() {
    final t = _totals;
    switch (_method) {
      case 'UPI':
        return _upiCollect();
      case 'Cash':
        final received = double.tryParse(_cashCtrl.text.trim()) ?? 0;
        final change = received - t.total;
        return Column(
          children: [
            _amountHero(t.total, 'Collect cash'),
            const SizedBox(height: 18),
            _field(
              _cashCtrl,
              'Cash received',
              prefix: '₹ ',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final note in _quickNotes(t.total))
                  ActionChip(
                    label: Text(inr(note, decimals: false)),
                    onPressed: () => setState(
                      () => _cashCtrl.text = note.toStringAsFixed(0),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (received > 0)
              _banner(
                change >= 0
                    ? 'Return change: ${inr(change)}'
                    : 'Short by ${inr(-change)}',
                error: change < 0,
              ),
          ],
        );
      default:
        return Column(
          children: [
            _amountHero(t.total, 'Charge on card machine'),
            const SizedBox(height: 18),
            _field(_refCtrl, 'Approval code / last 4 digits (optional)'),
          ],
        );
    }
  }

  List<double> _quickNotes(double total) {
    final out = <double>{total.ceilToDouble()};
    for (final n in [100, 200, 500, 1000, 2000]) {
      final v = (total / n).ceil() * n.toDouble();
      if (v >= total) out.add(v);
    }
    final list = out.toList()..sort();
    return list.take(4).toList();
  }

  Widget _amountHero(double amount, String caption) => Column(
        children: [
          Text(caption,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            inr(amount),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: _brandDark,
            ),
          ),
          if (_invoice != null)
            Text(_invoice!.invoiceNumber,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      );

  Widget _upiCollect() {
    final s = _pay.settings!;
    final inv = _invoice!;
    final uri = buildUpiUri(
      upiId: s.upiId!,
      payeeName: s.upiPayeeName ?? s.businessName,
      amount: inv.total,
      txnRef: inv.invoiceNumber,
      note: '${s.businessName} ${inv.invoiceNumber}',
    );
    return Column(
      children: [
        _amountHero(inv.total, 'Ask the customer to scan & pay'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: QrImageView(
            data: uri,
            size: 230,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _brandDark),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pay to ${s.upiPayeeName ?? s.businessName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(s.upiId!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        const Text(
          'GPay • PhonePe • Paytm • BHIM • any UPI app',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => showCustomerQrView(
                context,
                uri: uri,
                amount: inv.total,
                businessName: s.businessName,
                invoiceNo: inv.invoiceNumber,
              ),
              icon: const Icon(Icons.fullscreen, size: 18),
              label: const Text('Show to customer'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: uri));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('UPI payment link copied')),
                );
              },
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Copy pay link'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _field(_refCtrl, 'UPI reference / UTR (optional)'),
        const SizedBox(height: 10),
        _banner(
          'Confirm the credit on your UPI app or soundbox before tapping "Payment received".',
        ),
      ],
    );
  }

  //------------------------------------------------------------------ Step 2
  Widget _doneStep() {
    final inv = _invoice!;
    final s = _pay.settings ??
        BillingSettings.empty(inv.businessRef, businessName: 'Spa');
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 42, color: Colors.green.shade700),
        ),
        const SizedBox(height: 12),
        Text(
          inv.isPaid ? 'Payment received' : 'Invoice created',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${inr(inv.total)} • ${inv.paymentMethod ?? 'Unpaid'}'
          '${inv.paidAt != null ? ' • ${formatDateTime(inv.paidAt!)}' : ''}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          inv.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _brand),
        ),
        const SizedBox(height: 20),
        InvoiceActions(invoice: inv, settings: s),
        const SizedBox(height: 8),
      ],
    );
  }

  //----------------------------------------------------------------- Footer
  Widget _footer() {
    Widget primary(String label, VoidCallback? onTap, {IconData? icon}) => Expanded(
          child: ElevatedButton.icon(
            onPressed: _busy ? null : onTap,
            style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
              backgroundColor: _brandDark,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(icon ?? Icons.arrow_forward, size: 18),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
    Widget secondary(String label, VoidCallback? onTap) => Expanded(
          child: OutlinedButton(
            onPressed: _busy ? null : onTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
        );

    final children = <Widget>[];
    if (_step == 0) {
      children.add(secondary('Cancel', () => Navigator.of(context).pop(_invoice)));
      children.add(const SizedBox(width: 12));
      if (_pay.setupMissing) {
        children.add(primary('Mark as paid', _legacyMarkPaid, icon: Icons.check));
      } else if (_alreadyPaid) {
        children.add(primary('Create invoice', _confirmPaid, icon: Icons.receipt_long));
      } else {
        children.add(primary(
          _method == 'UPI' ? 'Generate QR' : 'Continue',
          _proceed,
          icon: _method == 'UPI' ? Icons.qr_code_2 : Icons.arrow_forward,
        ));
      }
    } else if (_step == 1) {
      children.add(secondary(
        _method == 'UPI' ? 'Pay later' : 'Back',
        () {
          if (_method == 'UPI') {
            Navigator.of(context).pop(_invoice);
          } else {
            setState(() => _step = 0);
          }
        },
      ));
      children.add(const SizedBox(width: 12));
      children.add(primary(
        _method == 'UPI' ? 'Payment received' : 'Mark as paid',
        _confirmPaid,
        icon: Icons.check_circle_outline,
      ));
    } else {
      children.add(secondary('Edit bill', () => setState(() => _step = 0)));
      children.add(const SizedBox(width: 12));
      children.add(primary('Done', () => Navigator.of(context).pop(_invoice),
          icon: Icons.check));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_step == 1 && _method == 'UPI')
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _busy ? null : () => setState(() => _step = 0),
                child: const Text('← Edit bill', style: TextStyle(color: _brand)),
              ),
            ),
          Row(children: children),
        ],
      ),
    );
  }

  //---------------------------------------------------------------- Helpers
  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
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

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _field(
    TextEditingController c,
    String hint, {
    String? prefix,
    TextInputType? keyboard,
    TextAlign align = TextAlign.left,
    ValueChanged<String>? onChanged,
  }) {
    final numeric = keyboard?.decimal != null;
    return TextField(
      controller: c,
      keyboardType: keyboard,
      textAlign: align,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      onChanged: onChanged ?? (_) => setState(() {}),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        labelText: hint,
        labelStyle: const TextStyle(fontSize: 12),
        prefixText: prefix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _brand, width: 1.4),
        ),
      ),
    );
  }

  Widget _banner(String text, {bool error = false}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFDECEA) : const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: error ? const Color(0xFFF5C2BC) : const Color(0xFFFFE082),
          ),
        ),
        child: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.info_outline,
              size: 18,
              color: error ? Colors.red.shade700 : const Color(0xFFB78103),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: error ? Colors.red.shade900 : Colors.brown.shade900,
                ),
              ),
            ),
          ],
        ),
      );
}

//==============================================================================
// Customer-facing full screen QR (turn the tablet/monitor towards the client)
//==============================================================================
Future<void> showCustomerQrView(
  BuildContext context, {
  required String uri,
  required double amount,
  required String businessName,
  required String invoiceNo,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black87,
    pageBuilder: (ctx, _, _) => Scaffold(
      backgroundColor: _brandDark,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      inr(amount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: QrImageView(
                        data: uri,
                        size: MediaQuery.sizeOf(ctx).shortestSide.clamp(240.0, 420.0).toDouble() * 0.8,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Scan with any UPI app to pay',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ref: $invoiceNo',
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

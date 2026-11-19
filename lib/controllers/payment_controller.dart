import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ira_spa_webapp/models/bookings_model.dart';
import 'package:ira_spa_webapp/models/invoice_model.dart';
import 'package:ira_spa_webapp/views/service/payment_service.dart';

class DayTotal {
  final DateTime day;
  final double amount;
  final int count;
  const DayTotal(this.day, this.amount, this.count);
}

class PaymentController extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  int? _businessRef;
  int? get businessRef => _businessRef;

  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> get invoices => _invoices;

  BillingSettings? _settings;
  BillingSettings? get settings => _settings;

  /// True when settings row exists and UPI is configured.
  bool get upiReady => _settings?.hasUpi ?? false;

  bool _loading = true;
  bool get loading => _loading;

  /// True when the SQL migration hasn't been applied yet.
  bool _setupMissing = false;
  bool get setupMissing => _setupMissing;

  StreamSubscription<List<InvoiceModel>>? _sub;

  //================================ Load ======================================
  Future<void> load(int businessRef, {String? businessName}) async {
    if (_businessRef == businessRef && !_loading) return;
    _businessRef = businessRef;
    _sub?.cancel();
    _loading = true;
    notifyListeners();

    try {
      _settings = await _service.fetchSettings(businessRef) ??
          BillingSettings.empty(businessRef, businessName: businessName);
      if (_settings!.businessName.isEmpty && businessName != null) {
        _settings = _settings!.copyWith(businessName: businessName);
      }
      _invoices = await _service.fetchInvoices(businessRef);
      _setupMissing = false;
    } on PaymentsSetupMissing {
      _setupMissing = true;
      _settings ??=
          BillingSettings.empty(businessRef, businessName: businessName);
    } catch (e) {
      debugPrint('[PaymentCtrl] load error: $e');
    }
    _loading = false;
    notifyListeners();

    if (_setupMissing) return;
    try {
      _sub = _service.watchInvoices(businessRef).listen(
        (list) {
          _invoices = list;
          notifyListeners();
        },
        onError: (e) => debugPrint('[PaymentCtrl] stream error: $e'),
      );
    } catch (e) {
      debugPrint('[PaymentCtrl] stream setup error: $e');
    }
  }

  Future<void> refresh() async {
    final ref = _businessRef;
    if (ref == null) return;
    _loading = false;
    _businessRef = null;
    await load(ref, businessName: _settings?.businessName);
  }

  Future<void> saveSettings(BillingSettings s) async {
    _settings = await _service.saveSettings(s);
    _setupMissing = false;
    notifyListeners();
  }

  //=============================== Checkout ===================================
  Future<InvoiceModel?> invoiceForBooking(int? bookingId) async {
    if (bookingId == null) return null;
    final local = _invoices
        .where((i) => i.bookingId == bookingId && !i.isVoid)
        .toList();
    if (local.isNotEmpty) return local.first;
    return _service.findInvoiceForBooking(bookingId);
  }

  InvoiceModel? cachedInvoiceForBooking(int? bookingId) {
    if (bookingId == null) return null;
    for (final i in _invoices) {
      if (i.bookingId == bookingId && !i.isVoid) return i;
    }
    return null;
  }

  /// Creates the invoice (or updates the existing draft for this booking).
  /// Used both for "Generate QR" (status unpaid) and for direct cash/card.
  Future<InvoiceModel> saveInvoice({
    InvoiceModel? existing,
    required BookingsModel booking,
    required List<InvoiceItem> items,
    required InvoiceTotals totals,
    String? notes,
  }) async {
    final ref = _businessRef ?? booking.businessRef ?? 0;
    if (existing?.id != null && !existing!.isPaid) {
      existing
        ..items = items
        ..notes = notes
        ..customerName = booking.customer
        ..customerPhone = booking.custphone
        ..therapist = booking.therapistname
        ..applyTotals(totals);
      final updated = await _service.updateInvoice(existing);
      _upsertLocal(updated);
      return updated;
    }

    final number = await _service.nextInvoiceNumber(
      ref,
      _settings?.invoicePrefix ?? 'INV',
    );
    final inv = InvoiceModel(
      businessRef: ref,
      bookingId: booking.id,
      invoiceNumber: number,
      customerName: booking.customer,
      customerPhone: booking.custphone,
      therapist: booking.therapistname,
      serviceDate: booking.bookingdate,
      items: items,
      subtotal: 0,
      discount: 0,
      taxableAmount: 0,
      gstRate: 0,
      cgst: 0,
      sgst: 0,
      roundOff: 0,
      total: 0,
      notes: notes,
    )..applyTotals(totals);

    final saved = await _service.insertInvoice(inv);
    if (booking.id != null && saved.id != null) {
      unawaited(_service.linkBooking(booking.id!, saved.id!));
    }
    _upsertLocal(saved);
    return saved;
  }

  Future<InvoiceModel> markPaid(
    InvoiceModel inv, {
    required String method,
    String? reference,
  }) async {
    inv
      ..paymentStatus = 'paid'
      ..paymentMethod = method
      ..paymentRef = (reference?.trim().isEmpty ?? true) ? null : reference
      ..paidAt = DateTime.now();
    final updated = await _service.updateInvoice(inv);
    _upsertLocal(updated);
    return updated;
  }

  Future<void> voidInvoice(InvoiceModel inv) async {
    if (inv.id == null) return;
    await _service.voidInvoice(inv.id!);
    inv.paymentStatus = 'void';
    _upsertLocal(inv);
  }

  void _upsertLocal(InvoiceModel inv) {
    final i = _invoices.indexWhere((e) => e.id == inv.id);
    if (i == -1) {
      _invoices = [inv, ..._invoices];
    } else {
      _invoices[i] = inv;
    }
    notifyListeners();
  }

  //================================ Stats =====================================
  Iterable<InvoiceModel> get _paid => _invoices.where((i) => i.isPaid);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double collectedOn(DateTime day) => _paid
      .where((i) => _sameDay(i.revenueDate, day))
      .fold(0.0, (s, i) => s + i.total);

  double get todayCollection => collectedOn(DateTime.now());

  int get todayPaidCount =>
      _paid.where((i) => _sameDay(i.revenueDate, DateTime.now())).length;

  double get yesterdayCollection =>
      collectedOn(DateTime.now().subtract(const Duration(days: 1)));

  double get monthCollection {
    final now = DateTime.now();
    return _paid
        .where((i) =>
            i.revenueDate.year == now.year && i.revenueDate.month == now.month)
        .fold(0.0, (s, i) => s + i.total);
  }

  double get monthGst {
    final now = DateTime.now();
    return _paid
        .where((i) =>
            i.revenueDate.year == now.year && i.revenueDate.month == now.month)
        .fold(0.0, (s, i) => s + i.gst);
  }

  double get lifetimeCollection => _paid.fold(0.0, (s, i) => s + i.total);

  List<InvoiceModel> get unpaidInvoices =>
      _invoices.where((i) => i.paymentStatus == 'unpaid').toList();

  double get unpaidTotal =>
      unpaidInvoices.fold(0.0, (s, i) => s + i.total);

  double get averageTicket {
    final now = DateTime.now();
    final m = _paid
        .where((i) =>
            i.revenueDate.year == now.year && i.revenueDate.month == now.month)
        .toList();
    if (m.isEmpty) return 0;
    return m.fold(0.0, (s, i) => s + i.total) / m.length;
  }

  /// This month's collection grouped by method (UPI / Cash / Card).
  Map<String, double> get monthByMethod {
    final now = DateTime.now();
    final out = <String, double>{'UPI': 0, 'Cash': 0, 'Card': 0};
    for (final i in _paid) {
      if (i.revenueDate.year != now.year || i.revenueDate.month != now.month) {
        continue;
      }
      final m = i.paymentMethod ?? 'Other';
      out[m] = (out[m] ?? 0) + i.total;
    }
    return out;
  }

  List<DayTotal> lastDays(int n) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: n - 1));
    return List.generate(n, (k) {
      final d = start.add(Duration(days: k));
      final dayInv = _paid.where((i) => _sameDay(i.revenueDate, d));
      return DayTotal(
        d,
        dayInv.fold(0.0, (s, i) => s + i.total),
        dayInv.length,
      );
    });
  }

  List<InvoiceModel> recent([int n = 6]) =>
      _invoices.where((i) => !i.isVoid).take(n).toList();

  /// Completed bookings that have no paid invoice yet — money to collect.
  List<BookingsModel> uncollectedBookings(List<BookingsModel> bookings) {
    final paidBookingIds =
        _paid.map((i) => i.bookingId).whereType<int>().toSet();
    return bookings.where((b) {
      final completed = b.statusrequired.toLowerCase().startsWith('complete');
      final bookingPaid = (b.paymentStatus ?? '').toLowerCase() == 'paid';
      return completed && !bookingPaid && !paidBookingIds.contains(b.id);
    }).toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Payments & invoicing models.
///
/// All money math lives in [InvoiceTotals.compute] so the checkout dialog,
/// the PDF and the database always agree on the numbers.
library;

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.\-]'), '')) ??
      0.0;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString())?.toLocal();
}

double round2(double v) => (v * 100).roundToDouble() / 100;

//==============================================================================
// Line item
//==============================================================================
class InvoiceItem {
  String description;
  String? sac;
  int qty;
  double rate;

  InvoiceItem({
    required this.description,
    this.sac,
    this.qty = 1,
    required this.rate,
  });

  double get amount => round2(rate * qty);

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
        description: m['description']?.toString() ?? '',
        sac: m['sac']?.toString(),
        qty: _toInt(m['qty']) ?? 1,
        rate: _toDouble(m['rate']),
      );

  Map<String, dynamic> toMap() => {
        'description': description,
        if (sac != null && sac!.isNotEmpty) 'sac': sac,
        'qty': qty,
        'rate': rate,
        'amount': amount,
      };

  InvoiceItem copy() =>
      InvoiceItem(description: description, sac: sac, qty: qty, rate: rate);
}

//==============================================================================
// Totals (single source of truth for GST math)
//==============================================================================
class InvoiceTotals {
  final double subtotal;
  final double discount;
  final double taxable;
  final double gstRate;
  final double cgst;
  final double sgst;
  final double roundOff;
  final double total;

  const InvoiceTotals({
    required this.subtotal,
    required this.discount,
    required this.taxable,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
    required this.roundOff,
    required this.total,
  });

  double get gst => round2(cgst + sgst);

  /// [gstRate] in percent (e.g. 18). When [inclusive] is true the item prices
  /// already contain GST and we back-calculate the taxable value.
  /// The final amount is rounded to the nearest rupee (shown as "Round off").
  static InvoiceTotals compute({
    required List<InvoiceItem> items,
    double discount = 0,
    double gstRate = 0,
    bool inclusive = false,
  }) {
    final subtotal = round2(items.fold(0.0, (s, i) => s + i.amount));
    final disc = discount.clamp(0, subtotal).toDouble();
    final afterDiscount = round2(subtotal - disc);

    double taxable;
    double gstTotal;
    if (gstRate <= 0) {
      taxable = afterDiscount;
      gstTotal = 0;
    } else if (inclusive) {
      taxable = round2(afterDiscount / (1 + gstRate / 100));
      gstTotal = round2(afterDiscount - taxable);
    } else {
      taxable = afterDiscount;
      gstTotal = round2(taxable * gstRate / 100);
    }

    final cgst = round2(gstTotal / 2);
    final sgst = round2(gstTotal - cgst);
    final exact = round2(taxable + cgst + sgst);
    final rounded = exact.roundToDouble();

    return InvoiceTotals(
      subtotal: subtotal,
      discount: round2(disc),
      taxable: taxable,
      gstRate: gstRate <= 0 ? 0 : gstRate,
      cgst: cgst,
      sgst: sgst,
      roundOff: round2(rounded - exact),
      total: rounded,
    );
  }
}

//==============================================================================
// Invoice
//==============================================================================
class InvoiceModel {
  int? id;
  int businessRef;
  int? bookingId;
  String invoiceNumber;
  String customerName;
  String? customerPhone;
  String? therapist;
  DateTime? serviceDate;
  List<InvoiceItem> items;
  double subtotal;
  double discount;
  double taxableAmount;
  double gstRate;
  double cgst;
  double sgst;
  double roundOff;
  double total;
  String paymentStatus; // unpaid | paid | void
  String? paymentMethod; // UPI | Cash | Card
  String? paymentRef;
  DateTime? paidAt;
  String? notes;
  DateTime createdAt;

  InvoiceModel({
    this.id,
    required this.businessRef,
    this.bookingId,
    required this.invoiceNumber,
    required this.customerName,
    this.customerPhone,
    this.therapist,
    this.serviceDate,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
    required this.roundOff,
    required this.total,
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.paymentRef,
    this.paidAt,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPaid => paymentStatus == 'paid';
  bool get isVoid => paymentStatus == 'void';
  bool get hasGst => gstRate > 0;
  double get gst => round2(cgst + sgst);

  /// Date used for revenue reporting (when the money came in).
  DateTime get revenueDate => paidAt ?? createdAt;

  InvoiceTotals get totals => InvoiceTotals(
        subtotal: subtotal,
        discount: discount,
        taxable: taxableAmount,
        gstRate: gstRate,
        cgst: cgst,
        sgst: sgst,
        roundOff: roundOff,
        total: total,
      );

  void applyTotals(InvoiceTotals t) {
    subtotal = t.subtotal;
    discount = t.discount;
    taxableAmount = t.taxable;
    gstRate = t.gstRate;
    cgst = t.cgst;
    sgst = t.sgst;
    roundOff = t.roundOff;
    total = t.total;
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> m) {
    final rawItems = m['items'];
    final items = <InvoiceItem>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) items.add(InvoiceItem.fromMap(Map<String, dynamic>.from(e)));
      }
    }
    return InvoiceModel(
      id: _toInt(m['id']),
      businessRef: _toInt(m['business_ref']) ?? 0,
      bookingId: _toInt(m['booking_id']),
      invoiceNumber: m['invoice_number']?.toString() ?? '',
      customerName: m['customer_name']?.toString() ?? '',
      customerPhone: m['customer_phone']?.toString(),
      therapist: m['therapist']?.toString(),
      serviceDate: _toDate(m['service_date']),
      items: items,
      subtotal: _toDouble(m['subtotal']),
      discount: _toDouble(m['discount']),
      taxableAmount: _toDouble(m['taxable_amount']),
      gstRate: _toDouble(m['gst_rate']),
      cgst: _toDouble(m['cgst']),
      sgst: _toDouble(m['sgst']),
      roundOff: _toDouble(m['round_off']),
      total: _toDouble(m['total']),
      paymentStatus: m['payment_status']?.toString() ?? 'unpaid',
      paymentMethod: m['payment_method']?.toString(),
      paymentRef: m['payment_ref']?.toString(),
      paidAt: _toDate(m['paid_at']),
      notes: m['notes']?.toString(),
      createdAt: _toDate(m['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'business_ref': businessRef,
        'booking_id': bookingId,
        'invoice_number': invoiceNumber,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'therapist': therapist,
        'service_date': serviceDate?.toUtc().toIso8601String(),
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'taxable_amount': taxableAmount,
        'gst_rate': gstRate,
        'cgst': cgst,
        'sgst': sgst,
        'round_off': roundOff,
        'total': total,
        'payment_status': paymentStatus,
        'payment_method': paymentMethod,
        'payment_ref': paymentRef,
        'paid_at': paidAt?.toUtc().toIso8601String(),
        'notes': notes,
      };
}

//==============================================================================
// Billing settings (per business)
//==============================================================================
class BillingSettings {
  final int businessRef;
  final String businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? gstin;
  final String? upiId;
  final String? upiPayeeName;
  final String invoicePrefix;
  final double defaultGstRate;
  final bool gstInclusive;
  final String sacCode;
  final String? footerNote;

  const BillingSettings({
    required this.businessRef,
    required this.businessName,
    this.address,
    this.phone,
    this.email,
    this.gstin,
    this.upiId,
    this.upiPayeeName,
    this.invoicePrefix = 'INV',
    this.defaultGstRate = 18,
    this.gstInclusive = false,
    this.sacCode = '999722',
    this.footerNote,
  });

  bool get hasUpi => upiId != null && upiId!.contains('@');
  bool get hasGstin => gstin != null && gstin!.trim().isNotEmpty;

  factory BillingSettings.empty(int businessRef, {String? businessName}) =>
      BillingSettings(
        businessRef: businessRef,
        businessName: businessName ?? '',
        invoicePrefix: _defaultPrefix(businessName),
        footerNote:
            'Thank you for visiting. We look forward to seeing you again!',
      );

  static String _defaultPrefix(String? name) {
    final letters = (name ?? '').replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 3) return 'INV';
    return letters.substring(0, 3).toUpperCase();
  }

  factory BillingSettings.fromMap(Map<String, dynamic> m) => BillingSettings(
        businessRef: _toInt(m['business_ref']) ?? 0,
        businessName: m['business_name']?.toString() ?? '',
        address: m['address']?.toString(),
        phone: m['phone']?.toString(),
        email: m['email']?.toString(),
        gstin: m['gstin']?.toString(),
        upiId: m['upi_id']?.toString(),
        upiPayeeName: m['upi_payee_name']?.toString(),
        invoicePrefix: (m['invoice_prefix']?.toString().trim().isNotEmpty ?? false)
            ? m['invoice_prefix'].toString().trim()
            : 'INV',
        defaultGstRate: m['default_gst_rate'] == null
            ? 18
            : _toDouble(m['default_gst_rate']),
        gstInclusive: m['gst_inclusive'] == true,
        sacCode: m['sac_code']?.toString() ?? '999722',
        footerNote: m['footer_note']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'business_ref': businessRef,
        'business_name': businessName,
        'address': address,
        'phone': phone,
        'email': email,
        'gstin': gstin,
        'upi_id': upiId,
        'upi_payee_name': upiPayeeName,
        'invoice_prefix': invoicePrefix,
        'default_gst_rate': defaultGstRate,
        'gst_inclusive': gstInclusive,
        'sac_code': sacCode,
        'footer_note': footerNote,
      };

  BillingSettings copyWith({String? businessName}) => BillingSettings(
        businessRef: businessRef,
        businessName: businessName ?? this.businessName,
        address: address,
        phone: phone,
        email: email,
        gstin: gstin,
        upiId: upiId,
        upiPayeeName: upiPayeeName,
        invoicePrefix: invoicePrefix,
        defaultGstRate: defaultGstRate,
        gstInclusive: gstInclusive,
        sacCode: sacCode,
        footerNote: footerNote,
      );
}

import 'package:intl/intl.dart';

/// ₹1,23,456.00 style (Indian digit grouping).
final NumberFormat _inr2 =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final NumberFormat _inr0 =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final NumberFormat _plain2 = NumberFormat('#,##,##0.00', 'en_IN');

String inr(double v, {bool decimals = true}) =>
    decimals ? _inr2.format(v) : _inr0.format(v);

/// Without currency symbol, e.g. for PDFs where the font may lack ₹.
String money(double v) => _plain2.format(v);

String formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);
String formatDateTime(DateTime d) =>
    DateFormat('dd MMM yyyy, hh:mm a').format(d);

//==============================================================================
// UPI
//==============================================================================

/// Builds a UPI deep link (NPCI "upi://pay" spec). Any UPI app — GPay,
/// PhonePe, Paytm, BHIM, bank apps — opens it with the amount pre-filled
/// and locked, so the customer can't pay a wrong amount.
///
/// [txnRef] goes in `tr` and shows up in the merchant's statement, which
/// lets the receptionist match the credit to the invoice.
String buildUpiUri({
  required String upiId,
  required String payeeName,
  required double amount,
  String? txnRef,
  String? note,
}) {
  final params = <String, String>{
    'pa': upiId.trim(),
    'pn': payeeName.trim().isEmpty ? 'Merchant' : payeeName.trim(),
    'am': amount.toStringAsFixed(2),
    'cu': 'INR',
    if (txnRef != null && txnRef.isNotEmpty)
      'tr': txnRef.replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '-'),
    if (note != null && note.isNotEmpty)
      'tn': note.length > 50 ? note.substring(0, 50) : note,
  };
  final query = params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return 'upi://pay?$query';
}

bool isValidUpiId(String v) =>
    RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$').hasMatch(v.trim());

/// Normalises an Indian mobile number for wa.me links.
String? whatsappNumber(String? phone) {
  if (phone == null) return null;
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return '91$digits';
  if (digits.length == 12 && digits.startsWith('91')) return digits;
  if (digits.length == 11 && digits.startsWith('0')) {
    return '91${digits.substring(1)}';
  }
  return digits.length >= 10 ? digits : null;
}

//==============================================================================
// Amount in words (Indian system: thousand, lakh, crore)
//==============================================================================
const _ones = [
  '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
  'Seventeen', 'Eighteen', 'Nineteen',
];
const _tens = [
  '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty',
  'Ninety',
];

String _twoDigits(int n) {
  if (n < 20) return _ones[n];
  final t = _tens[n ~/ 10];
  final o = _ones[n % 10];
  return o.isEmpty ? t : '$t $o';
}

String _threeDigits(int n) {
  final h = n ~/ 100;
  final rest = n % 100;
  final parts = <String>[];
  if (h > 0) parts.add('${_ones[h]} Hundred');
  if (rest > 0) parts.add(_twoDigits(rest));
  return parts.join(' ');
}

String _intToWords(int n) {
  if (n == 0) return 'Zero';
  final parts = <String>[];
  final crore = n ~/ 10000000;
  n %= 10000000;
  final lakh = n ~/ 100000;
  n %= 100000;
  final thousand = n ~/ 1000;
  n %= 1000;
  if (crore > 0) parts.add('${_intToWords(crore)} Crore');
  if (lakh > 0) parts.add('${_twoDigits(lakh)} Lakh');
  if (thousand > 0) parts.add('${_twoDigits(thousand)} Thousand');
  if (n > 0) parts.add(_threeDigits(n));
  return parts.join(' ');
}

/// 1180.50 → "Rupees One Thousand One Hundred Eighty and Fifty Paise Only"
String amountInWords(double amount) {
  final rupees = amount.floor();
  final paise = ((amount - rupees) * 100).round();
  final buf = StringBuffer('Rupees ${_intToWords(rupees)}');
  if (paise > 0) buf.write(' and ${_twoDigits(paise)} Paise');
  buf.write(' Only');
  return buf.toString();
}

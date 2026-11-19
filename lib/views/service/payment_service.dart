import 'package:flutter/foundation.dart';
import 'package:ira_spa_webapp/models/invoice_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the payments migration hasn't been run yet.
class PaymentsSetupMissing implements Exception {
  final String message;
  PaymentsSetupMissing([this.message = 'Payments tables are missing']);
  @override
  String toString() => message;
}

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static bool isMissingTable(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('42p01') ||
        s.contains('pgrst205') ||
        s.contains('pgrst202') ||
        (s.contains('relation') && s.contains('does not exist')) ||
        s.contains('could not find the table') ||
        s.contains('could not find the function');
  }

  Never _rethrow(Object e) {
    if (isMissingTable(e)) throw PaymentsSetupMissing();
    throw e;
  }

  //=============================== Settings ===================================
  Future<BillingSettings?> fetchSettings(int businessRef) async {
    try {
      final row = await _supabase
          .from('spa_billing_settings')
          .select()
          .eq('business_ref', businessRef)
          .maybeSingle();
      return row == null ? null : BillingSettings.fromMap(row);
    } catch (e) {
      _rethrow(e);
    }
  }

  Future<BillingSettings> saveSettings(BillingSettings s) async {
    try {
      final row = await _supabase
          .from('spa_billing_settings')
          .upsert(s.toMap(), onConflict: 'business_ref')
          .select()
          .single();
      return BillingSettings.fromMap(row);
    } catch (e) {
      _rethrow(e);
    }
  }

  //=============================== Invoices ===================================
  Future<String> nextInvoiceNumber(int businessRef, String prefix) async {
    try {
      final res = await _supabase.rpc(
        'spa_next_invoice_number',
        params: {'p_business_ref': businessRef, 'p_prefix': prefix},
      );
      final s = res?.toString() ?? '';
      if (s.isNotEmpty) return s;
    } catch (e) {
      debugPrint('[PaymentService] next_invoice_number failed: $e');
      if (isMissingTable(e)) throw PaymentsSetupMissing();
    }
    // Fallback: time based, still unique per business.
    final now = DateTime.now();
    return '$prefix/${now.millisecondsSinceEpoch.toString().substring(5)}';
  }

  Future<List<InvoiceModel>> fetchInvoices(int businessRef) async {
    try {
      final rows = await _supabase
          .from('spa_invoices')
          .select()
          .eq('business_ref', businessRef)
          .order('created_at', ascending: false)
          .limit(2000);
      return (rows as List)
          .map((e) => InvoiceModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _rethrow(e);
    }
  }

  Stream<List<InvoiceModel>> watchInvoices(int businessRef) {
    return _supabase
        .from('spa_invoices')
        .stream(primaryKey: ['id'])
        .eq('business_ref', businessRef)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(InvoiceModel.fromMap).toList());
  }

  Future<InvoiceModel?> findInvoiceForBooking(int bookingId) async {
    try {
      final rows = await _supabase
          .from('spa_invoices')
          .select()
          .eq('booking_id', bookingId)
          .neq('payment_status', 'void')
          .order('created_at', ascending: false)
          .limit(1);
      final list = rows as List;
      if (list.isEmpty) return null;
      return InvoiceModel.fromMap(Map<String, dynamic>.from(list.first));
    } catch (e) {
      _rethrow(e);
    }
  }

  Future<InvoiceModel> insertInvoice(InvoiceModel inv) async {
    try {
      final row = await _supabase
          .from('spa_invoices')
          .insert(inv.toMap())
          .select()
          .single();
      return InvoiceModel.fromMap(row);
    } catch (e) {
      _rethrow(e);
    }
  }

  Future<InvoiceModel> updateInvoice(InvoiceModel inv) async {
    try {
      final payload = inv.toMap()..remove('invoice_number');
      final row = await _supabase
          .from('spa_invoices')
          .update(payload)
          .eq('id', inv.id!)
          .select()
          .single();
      return InvoiceModel.fromMap(row);
    } catch (e) {
      _rethrow(e);
    }
  }

  Future<void> voidInvoice(int id) async {
    try {
      await _supabase
          .from('spa_invoices')
          .update({'payment_status': 'void'})
          .eq('id', id);
    } catch (e) {
      _rethrow(e);
    }
  }

  /// Best-effort link from Booking → invoice (column added by migration).
  Future<void> linkBooking(int bookingId, int invoiceId) async {
    try {
      await _supabase
          .from('Booking')
          .update({'invoice_id': invoiceId})
          .eq('id', bookingId);
    } catch (e) {
      debugPrint('[PaymentService] linkBooking skipped: $e');
    }
  }
}

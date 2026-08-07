import 'package:ira_spa_webapp/models/bookings_model.dart';
import 'package:ira_spa_webapp/models/client_model.dart';
import 'package:ira_spa_webapp/models/customer_model.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/models/staff_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  //====================Service=================================
  Future<void> addService(ServiceModel service) async {
    await _supabase.from('services').insert(service.toJson());
  }

  //Watch Service
  Stream<List<ServiceModel>> watchServices(int businessRef) {
    return _supabase
        .from('services')
        .stream(primaryKey: ['id'])
        .eq('business_ref', businessRef)
        .order('created_at', ascending: false)
        .map((data) {
          return data.map((e) => ServiceModel.fromJson(e)).toList();
        });
  }

  Future<void> deleteService(int id) async {
    await _supabase.from('services').delete().eq('id', id);
  }
    Future<void> updateService(ServiceModel service) async {
    await _supabase
        .from('services')
        .update(service.toJson())
        .eq('id', service.id!);
  }

  //=================================Customer ==========================================

  Future<void> addcustomer(CustomerModel customer) async {
    try {
      final response = await _supabase
          .from('Customers')
          .insert(customer.toJson())
          .select();

      print("Inserted Customer: $response");
    } catch (e) {
      print("Supabase Error: $e");
      rethrow;
    }
  }

  Stream<List<CustomerModel>> watchcustomer(int businessRef) {
    return _supabase
        .from('Customers')
        .stream(primaryKey: ['id'])
        .eq('business_ref', businessRef)
        .order('created_at', ascending: false)
        .map((data) {
          return data.map((e) => CustomerModel.fromJson(e)).toList();
        });
  }
 Future<void> updatecustomer(CustomerModel cust) async {
  try {
    await _supabase
        .from('Customers')
        .update({
          'customer_name': cust.name,
          'customer_email': cust.email,
          'customer_phone': cust.phoneno,
          'customer_dob': cust.dob?.toIso8601String().split('T').first,
          'customer_address': cust.address,
          'customer_note': cust.notes,
        })
        .eq('id', cust.id!);

    print("Customer Updated");
  } catch (e) {
    print(e);
    rethrow;
  }

 

 
}

Future<void> toggleBlacklistCustomer(int id, bool isBlacklisted) async {
  try {
    await _supabase
        .from('Customers')
        .update({'is_blacklisted': isBlacklisted})
        .eq('id', id);

    print("Customer blacklist status updated to: $isBlacklisted");
  } catch (e) {
    print("Error updating blacklist status: $e");
    rethrow;
  }
}
  Future<void> deletecustomer(int id) async {
    await _supabase.from('Customers').delete().eq('id', id);
  }
Future<Map<String, Map<String, dynamic>>> getBookingStatsForBusiness(
  int businessRef,
) async {
  final bookings = await _supabase
      .from('Booking')
      .select()
      .eq('business_ref', businessRef);

  final now = DateTime.now();
  final Map<String, Map<String, dynamic>> statsByName = {};

  for (final booking in bookings) {
    final name = booking['customer_ref'] as String?;
    if (name == null || name.isEmpty) continue;

    final slot = booking['available_slot'] as String?;
    final date = slot != null ? DateTime.parse(slot) : null;

    final entry = statsByName.putIfAbsent(
      name,
      () => {'totalVisits': 0, 'spentThisMonth': 0.0, 'lastVisit': null},
    );

    entry['totalVisits'] = (entry['totalVisits'] as int) + 1;

    if (date != null) {
      final lastVisit = entry['lastVisit'] as DateTime?;
      if (lastVisit == null || date.isAfter(lastVisit)) {
        entry['lastVisit'] = date;
      }

      if (date.year == now.year &&
          date.month == now.month &&
          booking['booking_status'] == 'Completed') {
       
      }
    }
  }

  return statsByName;
}
  //==============================Staff===========================================
  Future<void> addstaff(StaffModel staff) async {
    try {
      final response = await _supabase
          .from('Therapist')
          .insert(staff.toJson())
          .select();
      print("Inserted Customer: $response");
    } on PostgrestException catch (e) {
     
      rethrow;
    }
  }

  Stream<List<StaffModel>> watchStaff(int businessRef) {
    return _supabase
        .from('Therapist')
        .stream(primaryKey: ['id'])
        .eq('business_ref', businessRef)
        .order('created_at', ascending: false)
        .map((data) {
          return data.map((e) => StaffModel.fromJson(e)).toList();
        });
  }
   Future<void> deletestaff(int id) async {
    await _supabase.from('Therapist').delete().eq('id', id);
  }
    Future<void> updatestaff(StaffModel staff) async {
    await _supabase
        .from('Therapist')
        .update(staff.toJson())
        .eq('id', staff.id!);
  }
Future<void> updateStaffJobStatus(int staffId, String status) async {
  await Supabase.instance.client
      .from('Therapist')
      .update({
        'staff_status': status,
      })
      .eq('id', staffId);
}

Stream<Map<int, int>> watchStaffBookingCounts(int businessRef) {
  return _supabase
      .from('Booking')
      .stream(primaryKey: ['id'])
      .eq('business_ref', businessRef)
      .map((rows) {
    final counts = <int, int>{};
    for (final row in rows) {
      final serviceId = row['service_option_id'] as int?;
      if (serviceId != null) {
        counts[serviceId] = (counts[serviceId] ?? 0) + 1;
      }
    }
    return counts;
  });
}

  //==============================Bookings============================================
  Future<void> addBooking(BookingsModel booking) async {
    await _supabase.from('Booking').insert(booking.toMap());
  }

  Stream<List<BookingsModel>> watchBookings(int businessRef) {
    return _supabase
        .from('Booking')
        .stream(primaryKey: ['id'])
        .eq('business_ref', businessRef)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => BookingsModel.fromMap(e)).toList());
  }

  Future<void> updateBooking(BookingsModel booking) async {
    try {
      await _supabase
          .from('Booking')
          .update(booking.toMap())
          .eq('id', booking.id!);

      print("Booking Updated");
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> deleteBooking(int id) async {
    await _supabase.from('Booking').delete().eq('id', id);
  }

  Future<List<String>> getbookedtimeslots(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final data = await _supabase
        .from('Booking')
        .select('confirmed_time')
        .gte('available_slot', start.toIso8601String())
        .lt('available_slot', end.toIso8601String());

    return data.map<String>((e) => e['confirmed_time'] as String).toList();
  }

Stream<Map<int, int>> watchBookingCounts(int businessRef) {
  return _supabase
      .from('Booking')
      .stream(primaryKey: ['id'])
      .eq('business_ref', businessRef)
      .map((rows) {
    final counts = <int, int>{};
    for (final row in rows) {
      final serviceId = row['service_option_id'] as int?;
      if (serviceId != null) {
        counts[serviceId] = (counts[serviceId] ?? 0) + 1;
      }
    }
    return counts;
  });
}

Future<void> updateBookingStatus(int id, String status) async {
  await Supabase.instance.client
      .from('Booking')
      .update({
        'booking_status': status,
      })
      .eq('id', id);
}
  //=================================Service Menu========================================
   Future<ClientModel> insertClient(ClientModel client) async {
    final response = await _supabase
        .from('clients')
        .insert(client.toMap())
        .select()
        .single();
    return ClientModel.fromMap(response);
  }

Future<List<ClientModel>> getAllCustomers() async {
  final response = await _supabase
      .from('Customers')
      .select('id, customer_name, customer_phone, customer_email, customer_address');

  final data = response as List<dynamic>;
  return data.map((json) => ClientModel.fromMap(json)).toList();
}

  // ─── READ ─────────────────────────────────────────────────────────────────
  Future<List<ClientModel>> getAllClients() async {
    final response = await _supabase
        .from('clients')
        .select()
        .order('id', ascending: false);
    return (response as List).map((row) => ClientModel.fromMap(row)).toList();
  }

  Future<ClientModel?> getClientById(int id) async {
    final response = await _supabase
        .from('clients')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return ClientModel.fromMap(response);
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────
  Future<ClientModel> updateClient(ClientModel client) async {
    if (client.id == null) throw ArgumentError('Cannot update without an id.');
    final response = await _supabase
        .from('clients')
        .update(client.toMap())
        .eq('id', client.id!)
        .select()
        .single();
    return ClientModel.fromMap(response);
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────
  Future<void> deleteClient(int id) async {
    await _supabase.from('clients').delete().eq('id', id);
  }
}

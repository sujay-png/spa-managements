import 'package:ira_spa_webapp/models/bookings_model.dart';
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

   Future<void> deletecustomer(int id) async {
    await _supabase.from('Customers').delete().eq('id', id);
  }
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
      print("Message: ${e.message}");
      print("Details: ${e.details}");
      print("Hint: ${e.hint}");
      print("Code: ${e.code}");
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
          .update({
            'customer_ref': booking.customer,
            'services': booking.servicename,
            'therapist': booking.therapistname,
            'available_slot': booking.bookingdate.toIso8601String(),
            'confirmed_time': booking.timeslot,
            'requirements_booking': booking.bookingdetails,
            'booking_status': booking.statusrequired,
          })
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
}

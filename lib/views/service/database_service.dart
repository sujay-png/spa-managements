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

  Future<void> deleteService(String id) async {
    await _supabase.from('services').delete().eq('id', id);
  }
  //   Future<void> updateService(ServiceModel service) async {
  //   await _supabase
  //       .from('services')
  //       .update(service.toJson())
  //       .eq('id', service.id);
  // }

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

  //==============================Staff===========================================
  Future<void> addstaff(StaffModel staff) async {
    try {
      final response = await _supabase
          .from('Therapist')
          .insert(staff.toJson())
          .select();
      print("Inserted Customer: $response");
    }  on PostgrestException catch (e) {
  print("Message: ${e.message}");
  print("Details: ${e.details}");
  print("Hint: ${e.hint}");
  print("Code: ${e.code}");
  rethrow;
}
  }

  Stream<List<StaffModel>> watchStaff(int businessRef){
    return _supabase
    .from('Therapist')
    .stream(primaryKey: ['id'])
    .eq('business_ref', businessRef)
    .order('created_at',ascending: false)
    .map((data){
      return data.map((e)=> StaffModel.fromJson(e)).toList();
    });
  }

  //==============================Bookings============================================
  Future<void> addBooking(BookingsModel booking) async {
  await _supabase
      .from('Booking')
      .insert(booking.toMap());
}

Stream<List<BookingsModel>> watchBookings(int businessRef) {
  return _supabase
      .from('Booking')
      .stream(primaryKey: ['id'])
      .eq('business_ref', businessRef)
      .order('created_at', ascending: false)
      .map(
        (data) => data
            .map((e) => BookingsModel.fromMap(e))
            .toList(),
      );
}

Future<void> updateBooking(BookingsModel booking) async {
  await _supabase
      .from('Booking')
      .update(booking.toMap())
      .eq('id', booking.id!);
}

Future<void> deleteBooking(int id) async {
  await _supabase
      .from('Booking')
      .delete()
      .eq('id', id);
}
}

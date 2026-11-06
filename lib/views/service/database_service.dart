import 'package:flutter/foundation.dart';
import 'package:ira_spa_webapp/models/bookings_model.dart';
import 'package:ira_spa_webapp/models/client_model.dart';
import 'package:ira_spa_webapp/models/customer_model.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/models/staff_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  //====================Service=================================
  bool _isUniqueViolation(dynamic error) {
    final s = error.toString().toLowerCase();
    return s.contains('23505') ||
        s.contains('unique') ||
        s.contains('services_business_name_idx');
  }

  Future<void> _updateByBusinessAndName(
    ServiceModel service,
    Map<String, dynamic> data,
  ) async {
    final updateData = Map<String, dynamic>.from(data)
      ..remove('id')
      ..remove('created_at');
    await _supabase
        .from('services')
        .update(updateData)
        .eq('business_ref', service.businessRef!)
        .eq('service_name', service.serviceName);
  }

  Future<void> addService(ServiceModel service) async {
    try {
      await _supabase.from('services').insert(service.toJson());
    } catch (e) {
      if (e.toString().contains('description') && service.description != null) {
        final fallback =
            Map<String, dynamic>.from(service.toJson())..remove('description');
        try {
          await _supabase.from('services').insert(fallback);
        } catch (e2) {
          if (_isUniqueViolation(e2) && service.businessRef != null) {
            await _updateByBusinessAndName(service, fallback);
            return;
          }
          rethrow;
        }
      } else if (_isUniqueViolation(e) && service.businessRef != null) {
        await _updateByBusinessAndName(service, service.toJson());
      } else {
        rethrow;
      }
    }
  }

  /// Deletes all services matching the given base name for this business
  /// (both exact name and "- [dur] min" variants) to allow clean re-insertion.
  Future<void> deleteServicesByBaseName(int businessRef, String baseName) async {
    try {
      final data = await _supabase
          .from('services')
          .select('id, service_name')
          .eq('business_ref', businessRef);

      final cleanBase = baseName.trim().toLowerCase();
      final idsToDelete = <int>[];

      for (final row in (data as List)) {
        final id = row['id'];
        final sName =
            (row['service_name'] ?? '').toString().trim().toLowerCase();
        final sBase = sName
            .replaceAll(
                RegExp(r'\s*-\s*\d+\s*min.*$', caseSensitive: false), '')
            .replaceAll(
                RegExp(r'\s*\(\s*\d+\s*min.*\)\s*$', caseSensitive: false), '')
            .trim();

        if (sName == cleanBase || sBase == cleanBase) {
          final parsedId = int.tryParse(id.toString());
          if (parsedId != null) {
            idsToDelete.add(parsedId);
          }
        }
      }

      for (final id in idsToDelete) {
        try {
          await _supabase.from('services').delete().eq('id', id);
        } catch (e) {
          if (e.toString().contains('23503') ||
              e.toString().contains('foreign key')) {
            try {
              await _supabase
                  .from('Booking')
                  .update({'service_id': null})
                  .eq('service_id', id);
              await _supabase.from('services').delete().eq('id', id);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('[DatabaseService] deleteServicesByBaseName warning: $e');
    }
  }

  //Watch Service
  Stream<List<ServiceModel>> watchServices(int businessRef) {
    return _supabase
        .from('services')
        .stream(primaryKey: ['id'])
        .eq('business_ref', businessRef)
        .map((data) {
          return data.map((e) => ServiceModel.fromJson(e)).toList();
        });
  }

  Future<void> deleteService(int id) async {
    await _supabase.from('services').delete().eq('id', id);
  }

  Future<void> updateService(ServiceModel service) async {
    try {
      await _supabase
          .from('services')
          .update(service.toJson())
          .eq('id', service.id!);
    } catch (e) {
      if (e.toString().contains('description') && service.description != null) {
        final fallback = Map<String, dynamic>.from(service.toJson())..remove('description');
        await _supabase
            .from('services')
            .update(fallback)
            .eq('id', service.id!);
      } else {
        rethrow;
      }
    }
  }

  //=================================Customer ==========================================

  Future<void> addcustomer(CustomerModel customer) async {
    try {
      final response = await _supabase
          .from('Customers')
          .insert({
            ...customer.toJson(),
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
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
          // stats calculation
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
    } on PostgrestException catch (_) {
      rethrow;
    }
  }

  Stream<List<StaffModel>> watchStaff(int businessRef) {
    return _supabase
        .from('Therapist')
        .stream(primaryKey: ['id'])
        .eq('business_ref', businessRef)
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

  Stream<Map<String, int>> watchStaffBookingCounts(int businessRef) {
    return _supabase
        .from('Booking')
        .stream(primaryKey: ['id'])
        .eq('business_ref', businessRef)
        .map((rows) {
      final counts = <String, int>{};

      for (final row in rows) {
        final therapistName =
            (row['therapist'] as String?)?.trim().toLowerCase();
        final status =
            (row['booking_status'] as String?)?.trim().toLowerCase() ?? '';

        // Ignore completed or cancelled bookings
        if (status == 'completed' || status == 'cancelled') {
          continue;
        }

        if (therapistName != null && therapistName.isNotEmpty) {
          counts[therapistName] = (counts[therapistName] ?? 0) + 1;
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

  Future<Map<String, int>> getSlotBookingCounts(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).subtract(
      const Duration(hours: 12),
    );
    final end = DateTime(date.year, date.month, date.day).add(
      const Duration(hours: 36),
    );
    try {
      final data = await _supabase
          .from('Booking')
          .select('confirmed_time, available_slot, booking_status')
          .gte('available_slot', start.toIso8601String())
          .lt('available_slot', end.toIso8601String());

      final Map<String, int> counts = {};
      for (final row in data) {
        final status = (row['booking_status'] as String?)?.toLowerCase();
        if (status == 'cancelled') continue;

        final slotTimeStr = row['available_slot'] as String?;
        if (slotTimeStr != null) {
          final slotDate = DateTime.tryParse(slotTimeStr)?.toLocal();
          if (slotDate != null &&
              (slotDate.year != date.year ||
                  slotDate.month != date.month ||
                  slotDate.day != date.day)) {
            continue;
          }
        }

        final slot = (row['confirmed_time'] as String?)?.trim();
        if (slot != null && slot.isNotEmpty) {
          final normalized = slot.replaceAll(RegExp(r'\s+'), ' ');
          counts[normalized] = (counts[normalized] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      debugPrint("Error in getSlotBookingCounts: $e");
      return {};
    }
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

  Future<void> completeBookingWithPayment({
    required int id,
    required double rate,
    required double totalAmount,
    required String paymentMethod,
    required bool withGst,
    required double gstAmount,
  }) async {
    debugPrint(
      '[completeBookingWithPayment] ID: $id, rate: $rate, total: $totalAmount, method: $paymentMethod',
    );

    // Build candidates for payment_method to satisfy any DB check constraints
    final methodsToTry = <String>[
      paymentMethod,
      if (paymentMethod.contains('UPI') || paymentMethod.contains('QR')) ...[
        'UPI',
        'QR Code',
        'Online',
        'upi',
      ],
      if (paymentMethod.toLowerCase().contains('cash')) ...['Cash', 'cash'],
      if (paymentMethod.toLowerCase().contains('card')) ...['Card', 'card'],
    ];

    // Build candidates for payment_status
    final statusesToTry = <String>['paid', 'Paid'];

    bool succeeded = false;

    for (final method in methodsToTry.toSet()) {
      for (final status in statusesToTry) {
        try {
          await _supabase
              .from('Booking')
              .update({
                'booking_status': 'Completed',
                'payment_status': status,
                'payment_method': method,
                'rate': rate,
                'total_amount': totalAmount,
                'paid_amount': totalAmount,
              })
              .eq('id', id);

          debugPrint(
            '[completeBookingWithPayment] Succeeded with status="$status", method="$method"',
          );
          succeeded = true;
          break;
        } catch (e) {
          debugPrint(
            '[completeBookingWithPayment] Attempt failed (status="$status", method="$method"): $e',
          );
        }
      }
      if (succeeded) break;
    }

    // If method or amount constraints failed, try updating status & amounts without method
    if (!succeeded) {
      for (final status in statusesToTry) {
        try {
          await _supabase
              .from('Booking')
              .update({
                'booking_status': 'Completed',
                'payment_status': status,
                'rate': rate,
                'total_amount': totalAmount,
                'paid_amount': totalAmount,
              })
              .eq('id', id);

          debugPrint(
            '[completeBookingWithPayment] Succeeded without payment_method constraint (status="$status")',
          );
          succeeded = true;
          break;
        } catch (e) {
          debugPrint(
            '[completeBookingWithPayment] Fallback update failed: $e',
          );
        }
      }
    }

    // Final fallback: at minimum mark Completed
    if (!succeeded) {
      await updateBookingStatus(id, 'Completed');
    }
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
  Future<ClientModel> insertClient(
    ClientModel client, {
    double? rate,
    double? totalAmount,
    double? paidAmount,
    String? paymentStatus,
    String? paymentMethod,
    int? duration,
    String? bookingStatus,
    String? appointmentSlot,
  }) async {
    // Save client
    final clientResponse = await _supabase
        .from('clients')
        .insert(client.toMap())
        .select()
        .single();

    // Save booking with all payment details
    final bookingPayload = <String, dynamic>{
      'business_ref': client.businessRef,
      'customer_ref': client.name,
      'services': client.serviceName,
      'available_slot': appointmentSlot ?? client.appointmentDatetime,
      'confirmed_time': client.time,
      'cust_phno': client.phone,
      'location': client.location,
      'booking_status': bookingStatus ?? 'Confirmed',
      if (rate != null) 'rate': rate,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (duration != null) 'duration': duration,
    };

    await _supabase.from('Booking').insert(bookingPayload);

    return ClientModel.fromMap(clientResponse);
  }

  Future<List<ClientModel>> getAllCustomers() async {
    final response = await _supabase
        .from('Customers')
        .select(
          'id, customer_name, customer_phone, customer_email, customer_address, is_blacklisted',
        );

    final data = response as List<dynamic>;
    return data
        .where((json) => json['is_blacklisted'] != true)
        .map((json) => ClientModel.fromMap(json))
        .toList();
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

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:ira_spa_webapp/models/client_model.dart';

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/bookings_model.dart';
import 'package:ira_spa_webapp/models/repository.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingController extends ChangeNotifier {
  final DatabaseService _service = DatabaseService();

  List<BookingsModel> _bookings = [];
  List<BookingsModel> get bookings => _filteredBookings;

  List<ClientModel> _clients = [];
  List<ClientModel> get clients => _clients;

  bool _loading = true;
  bool get loading => _loading;

  String _search = '';
  String _statusFilter = 'All';

  //===================total bookings============
  int get totalBookings => _bookings.length;

  double _lookupSpaMenuPrice(String serviceName) {
    final clean = serviceName.trim().toLowerCase();
    if (clean.isEmpty) return 0.0;
    for (final list in spaMenuData.values) {
      for (final spa in list) {
        final title = spa.title.trim().toLowerCase();
        if (title == clean || title.contains(clean) || clean.contains(title)) {
          if (spa.options.isNotEmpty) {
            return spa.options.first.price.toDouble();
          }
        }
      }
    }
    return 0.0;
  }

  //================total revenue======================
  double calculateRevenue([List<ServiceModel>? services]) {
    final list = services ?? [];
    return _bookings.fold(0.0, (sum, booking) {
      // 1. If servicePrice is directly on booking (from total_amount or rate)
      if (booking.servicePrice != null && booking.servicePrice!.isNotEmpty) {
        final sanitizedPrice =
            booking.servicePrice!.replaceAll(RegExp(r'[^0-9.]'), '');
        final price = double.tryParse(sanitizedPrice);
        if (price != null && price > 0) {
          return sum + price;
        }
      }

      // 2. Look up matching service in custom services list (by ID or Name)
      final cleanName = booking.servicename.trim().toLowerCase();
      final matched = list.where((s) {
        if (booking.serviceRef != null && s.id == booking.serviceRef) {
          return true;
        }
        if (booking.serviceOptionId != null && s.id == booking.serviceOptionId) {
          return true;
        }
        final sName = s.serviceName.trim().toLowerCase();
        if (sName.isEmpty || cleanName.isEmpty) return false;
        return sName == cleanName ||
            sName.contains(cleanName) ||
            cleanName.contains(sName);
      }).firstOrNull;

      if (matched != null && matched.price > 0) {
        return sum + matched.price;
      }

      // 3. Fallback to spaMenuData (Service Menu default offerings)
      final spaPrice = _lookupSpaMenuPrice(booking.servicename);
      if (spaPrice > 0) {
        return sum + spaPrice;
      }

      return sum;
    });
  }

  double get totalRevenue => calculateRevenue([]);

  //======Average time wait=================
  int get waitingBookings =>
      _bookings.where((b) => b.statusrequired.toLowerCase() == 'pending').length;

  StreamSubscription<List<BookingsModel>>? _sub;
  StreamSubscription<List<ClientModel>>? _clientSub;

  void _enrichBookingsWithClients() {
    if (_clients.isEmpty || _bookings.isEmpty) return;

    for (final booking in _bookings) {
      final cleanCust = booking.customer.trim().toLowerCase();
      if (cleanCust.isEmpty) continue;

      final matchedClient = _clients.firstWhereOrNull((c) {
        final cName = c.name.trim().toLowerCase();
        if (cName.isEmpty) return false;
        return cName == cleanCust ||
            cleanCust.contains(cName) ||
            cName.contains(cleanCust);
      });

      if (matchedClient != null) {
        if ((booking.custphone == null || booking.custphone!.trim().isEmpty) &&
            matchedClient.phone.trim().isNotEmpty) {
          booking.custphone = matchedClient.phone.trim();
        }

        final clientTime = matchedClient.serviceTime ??
            (matchedClient.time.isNotEmpty ? matchedClient.time : null);
        if ((booking.serviceDuration == null ||
                booking.serviceDuration!.trim().isEmpty ||
                booking.serviceDuration == '-') &&
            clientTime != null &&
            clientTime.trim().isNotEmpty) {
          final t = clientTime.trim();
          booking.serviceDuration =
              RegExp(r'^\d+$').hasMatch(t) ? '$t min' : t;
        }
      }
    }
  }

  //======================== Load Bookings ========================

  Future<void> loadBookings(int businessRef) async {
    _sub?.cancel();
    _clientSub?.cancel();

    _loading = true;
    notifyListeners();

    // 1. Fetch immediately via direct REST for instant and reliable load
    try {
      dynamic data;
      try {
        data = await Supabase.instance.client
            .from('Booking')
            .select()
            .or('business_ref.eq.$businessRef,business_ref.is.null')
            .order('id', ascending: false);
      } catch (_) {
        try {
          data = await Supabase.instance.client
              .from('Booking')
              .select()
              .eq('business_ref', businessRef);
        } catch (_) {
          data = [];
        }
      }

      // Fallback: If filtered returned nothing, fetch all bookings
      if (data == null || (data as List).isEmpty) {
        try {
          data = await Supabase.instance.client
              .from('Booking')
              .select()
              .order('id', ascending: false);
        } catch (_) {
          data = await Supabase.instance.client
              .from('Booking')
              .select();
        }
      }

      final rows = List<Map<String, dynamic>>.from(data as List);
      final directList = rows.map((e) => BookingsModel.fromMap(e)).toList();
      _bookings = directList;
      _enrichBookingsWithClients();
      _loading = false;
      debugPrint('[BookingCtrl] Loaded ${_bookings.length} bookings');
      notifyListeners();
    } catch (e) {
      debugPrint('[BookingCtrl] Direct bookings fetch error: $e');
    }

    // 2. Also subscribe to Realtime stream for live changes
    try {
      _sub = _service.watchBookings(businessRef).listen(
        (list) {
          if (list.isNotEmpty || _bookings.isEmpty) {
            _bookings = list;
            _enrichBookingsWithClients();
          }
          _loading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('[BookingCtrl] Bookings stream error: $e');
          _loading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[BookingCtrl] Stream setup error: $e');
    }

    // 3. Load clients from clients table to enrich bookings with mobile number & service minutes
    try {
      _clients = await _service.getAllClients(businessRef);
      _enrichBookingsWithClients();
      notifyListeners();
    } catch (e) {
      debugPrint('[BookingCtrl] Fetch clients error: $e');
    }

    try {
      _clientSub = _service.watchClients(businessRef).listen(
        (clientList) {
          _clients = clientList;
          _enrichBookingsWithClients();
          notifyListeners();
        },
        onError: (e) {
          debugPrint('[BookingCtrl] Clients stream error: $e');
        },
      );
    } catch (_) {}
  }

  Future<void> completeBookingWithPayment({
    required int id,
    required double rate,
    required double totalAmount,
    required String paymentMethod,
    required bool withGst,
    required double gstAmount,
  }) async {
    await _service.completeBookingWithPayment(
      id: id,
      rate: rate,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      withGst: withGst,
      gstAmount: gstAmount,
    );
    final index = _bookings.indexWhere((e) => e.id == id);
    if (index != -1) {
      _bookings[index].statusrequired = 'Completed';
      _bookings[index].servicePrice = totalAmount.toStringAsFixed(2);
      _bookings[index].paymentStatus = 'Paid';
      _bookings[index].paymentMethod = paymentMethod;
      notifyListeners();
    }
  }

  Future<void> updateStatus(int id, String status) async {
    await _service.updateBookingStatus(id, status);
    final index = _bookings.indexWhere((e) => e.id == id);
    if (index != -1) {
      _bookings[index].statusrequired = status;
      notifyListeners();
    }
  }

  //======================== Search ========================

  List<BookingsModel> get _filteredBookings {
    List<BookingsModel> filtered = _bookings;

    // Search
    if (_search.isNotEmpty) {
      filtered = filtered.where((booking) {
        return booking.customer.toLowerCase().contains(_search) ||
            booking.servicename.toLowerCase().contains(_search) ||
            booking.therapistname.toLowerCase().contains(_search);
      }).toList();
    }

    // Status Filter
    if (_statusFilter != 'All') {
      filtered = filtered.where((booking) {
        return booking.statusrequired.toLowerCase() ==
            _statusFilter.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  void filterStatus(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  void search(String value) {
    _search = value.toLowerCase();
    notifyListeners();
  }

  //======================== CRUD ========================

  Future<void> addBooking(BookingsModel booking) async {
    await _service.addBooking(booking);
    if (booking.businessRef != null) {
      await loadBookings(booking.businessRef!);
    }
  }

  Future<void> updateBooking(BookingsModel booking) async {
    await _service.updateBooking(booking);

    final index = _bookings.indexWhere((e) => e.id == booking.id);

    if (index != -1) {
      _bookings[index] = booking;
    }

    notifyListeners();
  }

  Future<void> deleteBooking(int id) async {
    await _service.deleteBooking(id);
    _bookings.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _clientSub?.cancel();
    super.dispose();
  }
}

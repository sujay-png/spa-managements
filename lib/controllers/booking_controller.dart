import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ira_spa_webapp/models/bookings_model.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';

class BookingController extends ChangeNotifier {
  final DatabaseService _service = DatabaseService();

  List<BookingsModel> _bookings = [];
  List<BookingsModel> get bookings => _filteredBookings;

  bool _loading = true;
  bool get loading => _loading;

  String _search = '';
  String _statusFilter = 'All';
  //===================total bookings============
int get totalBookings => _bookings.length;
//================total revenue======================
double get totalRevenue {
  return _bookings.fold(0.0, (sum, booking) {
    final price = double.tryParse(booking.servicePrice ?? '0') ?? 0;
    return sum + price;
  });
}
//======Average time wait=================
int get waitingBookings =>
    _bookings.where((b) => b.statusrequired.toLowerCase() == 'pending').length;
  StreamSubscription<List<BookingsModel>>? _sub;

  

  //======================== Load Bookings ========================

  void loadBookings(int businessRef) {
    _sub?.cancel();

    _loading = false;
    notifyListeners();

  _sub = _service.watchBookings(businessRef).listen(
  (list) {
    print("Bookings fetched: ${list.length}");
    print(list);

    _bookings = list;
    _loading = false;
    notifyListeners();
  },
  onError: (e) {
    print(e);
  },
);
  }


  Future<void> updateStatus(int id, String status) async {
  await _service.updateBookingStatus(id, status);
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
    super.dispose();
  }
}
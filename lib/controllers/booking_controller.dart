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

  StreamSubscription<List<BookingsModel>>? _sub;

  //======================== Load Bookings ========================

  void loadBookings(int businessRef) {
    _sub?.cancel();

    _loading = true;
    notifyListeners();

    _sub = _service.watchBookings(businessRef).listen(
      (list) {
        _bookings = list;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint("Booking Stream Error: $e");
        _loading = false;
        notifyListeners();
      },
    );
  }

  //======================== Search ========================

 List<BookingsModel> get _filteredBookings {
  if (_search.isEmpty) return _bookings;

  return _bookings.where((booking) {
    return booking.customer.toLowerCase().contains(_search) ||
        booking.servicename.toLowerCase().contains(_search) ||
        booking.therapistname.toLowerCase().contains(_search);
  }).toList();
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
  }

  Future<void> deleteBooking(int id) async {
    await _service.deleteBooking(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
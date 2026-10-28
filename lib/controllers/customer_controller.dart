import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/customer_model.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';

class CustomerController extends ChangeNotifier {
  final DatabaseService _customer = DatabaseService();
  List<CustomerModel> _cust = [];
  List<CustomerModel> get customers => _filteredcust;
  bool _loading = true;
  bool get loading => _loading;

  int _totalVisits = 0;
  double _spentThisMonth = 0;
  DateTime? _lastVisit;

  int get totalVisits => _totalVisits;
  double get spentThisMonth => _spentThisMonth;
  DateTime? get lastVisit => _lastVisit;
  String _search = '';

  //=====================Total customer=============================
  int get totalcustomer => _cust.length;

  //=======================Customer new this month========================
  int get newThisMonth {
    final now = DateTime.now();

    return _cust.where((customer) {
      if (customer.dob == null) return false;
      return false;
    }).length;
  }
  //=============================

  StreamSubscription<List<CustomerModel>>? _sub;
 

  List<CustomerModel> get _filteredcust {
    if (_search.isEmpty) return _cust;

    return _cust.where((service) {
      return service.name.toLowerCase().contains(_search) ||
          service.phoneno.contains(_search);
    }).toList();
  }

  void search(String value) {
    _search = value.toLowerCase();
    notifyListeners();
  }

  Future<void> addcustomer(CustomerModel customer) async {
    await _customer.addcustomer(customer);
  }

  Future<void> updatedcustomer(CustomerModel cust) async {
    await _customer.updatecustomer(cust);
    final index = _cust.indexWhere((e) => e.id == cust.id);
    if (index != -1) {
      _cust[index] = cust;
    }
    notifyListeners();
  }

  Future<void> toggleBlacklistCustomer(int id, bool currentStatus) async {
    final newStatus = !currentStatus;

    // 1. Update in Database
    await _customer.toggleBlacklistCustomer(id, newStatus);

    // 2. Update local state
    final index = _cust.indexWhere((e) => e.id == id);
    if (index != -1) {
      _cust[index] = _cust[index].copyWith(isBlacklisted: newStatus);
    }

    notifyListeners();
  }

  Future<void> deletecustomer(int id) async {
    await _customer.deletecustomer(id);
    _cust.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void loadcustomer(int bussinessRef) {
  _sub?.cancel();
  _loading = true;
  notifyListeners();
  _sub = _customer.watchcustomer(bussinessRef).listen((list) async {
    final statsByName = await _customer.getBookingStatsForBusiness(bussinessRef);

    _cust = list.map((c) {
      final stats = statsByName[c.name];
      if (stats == null) return c;
      return c.copyWith(
        totalVisits: stats['totalVisits'] as int,
        spentThisMonth: stats['spentThisMonth'] as double,
        lastVisit: stats['lastVisit'] as DateTime?,
      );
    }).toList();

    _loading = false;
    notifyListeners();
  });
}
}

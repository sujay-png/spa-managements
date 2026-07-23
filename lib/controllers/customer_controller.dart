import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/customer_model.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';

class CustomerController extends ChangeNotifier {
  final DatabaseService _customer =DatabaseService();
  List<CustomerModel> _cust = [];
  List<CustomerModel> get customers=>_filteredcust;
   bool _loading = true;
  bool get loading => _loading;

  String _search = '';

  StreamSubscription<List<CustomerModel>>? _sub;
  //  CustomerController() {
  //   _sub = _service.watchServices().listen((list) {
  //     _services = list;
  //     _loading = false;
  //     notifyListeners();
  //   });
  // }

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

}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';

class 
ServiceController extends ChangeNotifier {
  final DatabaseService _service = DatabaseService();

  List<ServiceModel> _services = [];
  List<ServiceModel> get services => _filteredServices;

  bool _loading = true;
  bool get loading => _loading;

  String _search = '';

  StreamSubscription<List<ServiceModel>>? _sub;

  void loadServices(int businessRef) {
    _sub?.cancel();

    _loading = true;
    notifyListeners();

    _sub = _service.watchServices(businessRef).listen((list) {
      _services = list;
      _loading = false;
      notifyListeners();
    });
  }

  List<ServiceModel> get _filteredServices {
    if (_search.isEmpty) return _services;

    return _services.where((service) {
      return service.serviceName.toLowerCase().contains(_search) ||
          service.designation.toLowerCase().contains(_search);
    }).toList();
  }

  void search(String value) {
    _search = value.toLowerCase();
    notifyListeners();
  }

  Future<void> addService(ServiceModel service) async {
    await _service.addService(service);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
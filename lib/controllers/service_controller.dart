import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';
import '../models/service_model.dart';


class ServiceController extends ChangeNotifier {
  final DatabaseService _service = DatabaseService();

  List<ServiceModel> _services = [];
  List<ServiceModel> get services => _filteredServices;

  bool _loading = false;
  bool get loading => _loading;

  String _search = '';

  List<ServiceModel> get _filteredServices {
    if (_search.isEmpty) return _services;

    return _services.where((service) {
      return service.serviceName.toLowerCase().contains(_search) ||
          service.designation.toLowerCase().contains(_search);
    }).toList();
  }

  /// Fetch all services
  Future<void> fetchServices() async {
    _loading = true;
    notifyListeners();

    try {
      _services = await _service.fetchServices();
    } catch (e) {
      debugPrint(e.toString());
    }

    _loading = false;
    notifyListeners();
  }

  /// Search
  void search(String value) {
    _search = value.toLowerCase();
    notifyListeners();
  }

  /// Add Service
  Future<void> addService(ServiceModel service) async {
    await _service.addService(service);
     await fetchServices();
  }

  // /// Update Service
  // Future<void> updateService(ServiceModel service) async {
  //   await _service.updateService(service);
  //   await fetchServices();
  // }

  // /// Delete Service
  // Future<void> deleteService(String id) async {
  //   await _service.deleteService(id);
  //   await fetchServices();
  // }

  int get totalServices => _services.length;
}
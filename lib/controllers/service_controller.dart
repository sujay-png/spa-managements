import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';

class ServiceController extends ChangeNotifier {
  final DatabaseService _service = DatabaseService();

  List<ServiceModel> _services = [];
  List<ServiceModel> get services => _filteredServices;

  bool _loading = true;
  bool get loading => _loading;

  String _search = '';

  StreamSubscription<List<ServiceModel>>? _sub;

  Map<int, int> _bookingCounts = {};
  Map<int, int> get bookingCounts => _bookingCounts;

  List<Map<String, dynamic>> _rawBookingRows = [];
  StreamSubscription<List<Map<String, dynamic>>>? _countSub;

  /// Returns booking count for a service
  int getBookingCount(int? serviceId) {
    if (serviceId == null) return 0;
    return _bookingCounts[serviceId] ?? 0;
  }

  void _recalculateBookingCounts() {
    final counts = <int, int>{};
    for (final row in _rawBookingRows) {
      int? serviceId;

      // 1. Try from service_option_id or service_id
      final rawId = row['service_option_id'] ?? row['service_id'];
      if (rawId != null) {
        serviceId = int.tryParse(rawId.toString());
      }

      // 2. Fallback: match by service name (case-insensitive) against loaded services
      if (serviceId == null) {
        final serviceName = (row['services'] as String?)?.trim().toLowerCase();
        if (serviceName != null && serviceName.isNotEmpty) {
          final matched = _services.where(
            (s) => s.serviceName.trim().toLowerCase() == serviceName,
          ).firstOrNull;
          serviceId = matched?.id;
        }
      }

      if (serviceId != null) {
        counts[serviceId] = (counts[serviceId] ?? 0) + 1;
      }
    }

    _bookingCounts = counts;
    notifyListeners();
  }

  void loadServices(int businessRef) {
    _sub?.cancel();

    _loading = true;
    notifyListeners();

    _sub = _service.watchServices(businessRef).listen((list) {
      _services = list;
      _loading = false;
      _recalculateBookingCounts();
      notifyListeners();
    });

    // Load booking counts also
    loadBookingCounts(businessRef);
  }

  void loadBookingCounts(int businessRef) {
    _countSub?.cancel();

    _countSub = _service.watchBookingCounts(businessRef).listen((rows) {
      _rawBookingRows = rows;
      _recalculateBookingCounts();
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

  Future<void> updatedservice(ServiceModel service) async {
    await _service.updateService(service);

    final index = _services.indexWhere((e) => e.id == service.id);

    if (index != -1) {
      _services[index] = service;
      notifyListeners();
    }
  }

  Future<void> deleteservice(int id) async {
    await _service.deleteService(id);
    _services.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _countSub?.cancel();
    super.dispose();
  }
}

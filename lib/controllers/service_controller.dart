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

  Map<int, double> _revenueByService = {};
  Map<int, double> get revenueByService => _revenueByService;

  List<Map<String, dynamic>> _rawBookingRows = [];
  StreamSubscription<List<Map<String, dynamic>>>? _countSub;

  /// Returns booking count for a service
  int getBookingCount(int? serviceId) {
    if (serviceId == null) return 0;
    return _bookingCounts[serviceId] ?? 0;
  }

  /// Returns calculated revenue for a service
  double getRevenue(ServiceModel service) {
    if (service.id == null) return 0.0;
    if (_revenueByService.containsKey(service.id)) {
      return _revenueByService[service.id]!;
    }
    return service.price * getBookingCount(service.id);
  }

  void _recalculateBookingCounts() {
    final counts = <int, int>{};
    final revenues = <int, double>{};

    for (final row in _rawBookingRows) {
      int? matchedServiceId;
      ServiceModel? matchedService;

      // 1. First, check if row has a service_option_id or service_id matching a loaded service
      final rawId = row['service_option_id'] ?? row['service_id'];
      if (rawId != null) {
        final parsedId = int.tryParse(rawId.toString());
        if (parsedId != null) {
          matchedService = _services.where((s) => s.id == parsedId).firstOrNull;
          if (matchedService != null) {
            matchedServiceId = matchedService.id;
          }
        }
      }

      // 2. Fallback: match by service name (case-insensitive, trimmed, or partial match)
      if (matchedServiceId == null) {
        final rawServiceName = (row['services'] as String?)?.trim().toLowerCase();
        if (rawServiceName != null && rawServiceName.isNotEmpty) {
          matchedService = _services.where((s) {
            final name = s.serviceName.trim().toLowerCase();
            return name == rawServiceName ||
                rawServiceName.contains(name) ||
                name.contains(rawServiceName);
          }).firstOrNull;

          matchedServiceId = matchedService?.id;
        }
      }

      if (matchedServiceId != null && matchedService != null) {
        counts[matchedServiceId] = (counts[matchedServiceId] ?? 0) + 1;

        // Determine price for this booking
        double price = matchedService.price;
        final rawPrice = row['price'] ?? row['service_price'] ?? row['confirmed_price'];
        if (rawPrice != null) {
          final sanitized = rawPrice.toString().replaceAll(RegExp(r'[^0-9.]'), '');
          final parsed = double.tryParse(sanitized);
          if (parsed != null && parsed > 0) {
            price = parsed;
          }
        }

        revenues[matchedServiceId] = (revenues[matchedServiceId] ?? 0.0) + price;
      }
    }

    _bookingCounts = counts;
    _revenueByService = revenues;
    notifyListeners();
  }

  Future<void> loadServices(int businessRef) async {
    _sub?.cancel();

    _loading = true;
    notifyListeners();

    // 1. Fetch immediately via direct REST call for 100% reliable instant loading
    try {
      final directList = await _service.getServices(businessRef);
      if (directList.isNotEmpty) {
        _services = directList;
        _loading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Direct services fetch error: $e");
    }

    // 2. Also subscribe to Realtime stream for live changes
    _sub = _service.watchServices(businessRef).listen(
      (list) {
        _services = list;
        _loading = false;
        _recalculateBookingCounts();
        notifyListeners();
      },
      onError: (e) {
        debugPrint("Services stream error: $e");
        _loading = false;
        notifyListeners();
      },
    );

    // 3. Load booking counts
    await loadBookingCounts(businessRef);
  }

  Future<void> loadBookingCounts(int businessRef) async {
    _countSub?.cancel();

    // 1. Fetch immediately via direct REST call
    try {
      final rows = await _service.getBookingCounts(businessRef);
      if (rows.isNotEmpty || _rawBookingRows.isEmpty) {
        _rawBookingRows = rows;
        _recalculateBookingCounts();
      }
    } catch (e) {
      debugPrint("Direct booking rows fetch error: $e");
    }

    // 2. Also subscribe to Realtime stream for live changes
    _countSub = _service.watchBookingCounts(businessRef).listen(
      (rows) {
        _rawBookingRows = rows;
        _recalculateBookingCounts();
      },
      onError: (e) {
        debugPrint("Booking stream error (fallback active): $e");
      },
    );
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

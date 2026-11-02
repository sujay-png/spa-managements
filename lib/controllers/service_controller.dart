import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceController extends ChangeNotifier {
  final DatabaseService _service = DatabaseService();

  List<ServiceModel> _services = [];
  List<ServiceModel> get services => _filteredServices;

  bool _loading = true;
  bool get loading => _loading;

  String _search = '';

  StreamSubscription<List<ServiceModel>>? _sub;
  StreamSubscription<List<Map<String, dynamic>>>? _countSub;

  Map<int, int> _bookingCounts = {};
  Map<int, int> get bookingCounts => _bookingCounts;

  Map<int, double> _revenueByService = {};
  Map<int, double> get revenueByService => _revenueByService;

  List<Map<String, dynamic>> _rawBookingRows = [];

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

      // 1. Try service_id or service_option_id direct match
      final rawId = row['service_id'] ?? row['service_option_id'] ?? row['service_ref'];
      if (rawId != null) {
        final parsedId = int.tryParse(rawId.toString());
        if (parsedId != null) {
          matchedService = _services.where((s) => s.id == parsedId).firstOrNull;
          if (matchedService != null) {
            matchedServiceId = matchedService.id;
          }
        }
      }

      // 2. Fallback: match by service name (from 'services' or 'service_name' column)
      if (matchedServiceId == null) {
        final rawServiceName = (row['services'] ?? row['service_name'] ?? row['service'])
            ?.toString()
            .trim()
            .toLowerCase();
        if (rawServiceName != null && rawServiceName.isNotEmpty) {
          matchedService = _services.where((s) {
            final name = s.serviceName.trim().toLowerCase();
            if (name.isEmpty) return false;
            return name == rawServiceName ||
                rawServiceName.contains(name) ||
                name.contains(rawServiceName);
          }).firstOrNull;

          matchedServiceId = matchedService?.id;
        }
      }

      if (matchedServiceId != null && matchedService != null) {
        counts[matchedServiceId] = (counts[matchedServiceId] ?? 0) + 1;

        // Determine price for this booking from total_amount, rate, or service price
        double price = matchedService.price;
        final rawPrice = row['total_amount'] ?? row['rate'] ?? row['paid_amount'] ?? row['price'];
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
    debugPrint('[ServiceCtrl] recalculate: ${_services.length} services, ${_rawBookingRows.length} booking rows -> counts: $counts, revenues: $revenues');
    notifyListeners();
  }

  Future<void> loadServices(int businessRef) async {
    _sub?.cancel();

    _loading = true;
    notifyListeners();

    // 1. Fetch services immediately via direct REST call
    try {
      dynamic data;
      try {
        data = await Supabase.instance.client
            .from('services')
            .select()
            .or('business_ref.eq.$businessRef,business_ref.is.null')
            .order('id', ascending: false);
      } catch (_) {
        try {
          data = await Supabase.instance.client
              .from('services')
              .select()
              .eq('business_ref', businessRef);
        } catch (_) {
          data = [];
        }
      }

      // Fallback: If filtered returned nothing, fetch all services
      if (data == null || (data as List).isEmpty) {
        try {
          data = await Supabase.instance.client
              .from('services')
              .select()
              .order('id', ascending: false);
        } catch (_) {
          data = await Supabase.instance.client
              .from('services')
              .select();
        }
      }

      final directList = (data as List)
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _services = directList;
      _loading = false;
      _recalculateBookingCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('[ServiceCtrl] Direct services fetch error: $e');
    }

    // 2. Also subscribe to Realtime stream for live changes
    try {
      _sub = _service.watchServices(businessRef).listen(
        (list) {
          if (list.isNotEmpty || _services.isEmpty) {
            _services = list;
          }
          _loading = false;
          _recalculateBookingCounts();
          notifyListeners();
        },
        onError: (e) {
          debugPrint('[ServiceCtrl] Services stream error: $e');
          _loading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[ServiceCtrl] Stream setup error: $e');
    }

    // 3. Load booking data for counts/revenue
    await loadBookingCounts(businessRef);
  }

  Future<void> loadBookingCounts(int businessRef) async {
    _countSub?.cancel();

    // 1. Fetch bookings directly via REST
    try {
      dynamic data;
      try {
        data = await Supabase.instance.client
            .from('Booking')
            .select()
            .or('business_ref.eq.$businessRef,business_ref.is.null');
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
        data = await Supabase.instance.client
            .from('Booking')
            .select();
      }

      final rows = List<Map<String, dynamic>>.from(data as List);
      _rawBookingRows = rows;
      debugPrint('[ServiceCtrl] Loaded ${rows.length} booking rows');
      _recalculateBookingCounts();
    } catch (e) {
      debugPrint('[ServiceCtrl] Direct booking rows fetch error: $e');
    }

    // 2. Also subscribe to stream for live updates
    try {
      _countSub = Supabase.instance.client
          .from('Booking')
          .stream(primaryKey: ['id'])
          .eq('business_ref', businessRef)
          .listen(
        (rows) {
          _rawBookingRows = List<Map<String, dynamic>>.from(rows);
          _recalculateBookingCounts();
        },
        onError: (e) {
          debugPrint('[ServiceCtrl] Booking stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('[ServiceCtrl] Booking stream listen error: $e');
    }
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
    if (service.businessRef != null) {
      await loadServices(service.businessRef!);
    }
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

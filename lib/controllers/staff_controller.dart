import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/staff_model.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';

class StaffController extends ChangeNotifier {
  final DatabaseService _staff = DatabaseService();

  List<StaffModel> _staffs = [];
  List<StaffModel> get staffs => _filteredStaff;

  bool _loading = true;
  bool get loading => _loading;

  String _search = '';

  StreamSubscription<List<StaffModel>>? _sub;

  void loadStaff(int businessRef) {
    _sub?.cancel();

    _loading = true;
    notifyListeners();

    _sub = _staff.watchStaff(businessRef).listen((list) {
      _staffs = list;
      _loading = false;
      notifyListeners();
    });
  }

  List<StaffModel> get _filteredStaff {
    if (_search.isEmpty) return _staffs;

    return _staffs.where((staff) {
      return staff.name.toLowerCase().contains(_search) ||
          staff.designation.toLowerCase().contains(_search);
    }).toList();
  }

  void search(String value) {
    _search = value.toLowerCase();
    notifyListeners();
  }

  Future<void> addStaff(StaffModel staff) async {
    await _staff.addstaff(staff);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
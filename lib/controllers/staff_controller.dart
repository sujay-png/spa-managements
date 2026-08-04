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

  StreamSubscription<List<StaffModel>>? _staffSub;
  StreamSubscription<Map<int, int>>? _bookingCountsSub;
  Map<int, int> _bookingCounts = {};
  Map<int, int> get bookingCounts => _bookingCounts;

  int getBookingCount(int? staffId) {
    if (staffId == null) return 0;
    return _bookingCounts[staffId] ?? 0;
  }

  void loadStaff(int businessRef) {
    _staffSub?.cancel();

    _loading = true;
    notifyListeners();

    _staffSub = _staff.watchStaff(businessRef).listen((list) {
      _staffs = list;
      _loading = false;
      notifyListeners();
    });

  }

void loadBookingCounts(int businessRef) {
    _bookingCountsSub?.cancel();

    _bookingCountsSub = _staff.watchStaffBookingCounts(businessRef).listen((counts) {
      _bookingCounts = counts;
      notifyListeners();
    });

    loadStaff(businessRef);
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

  Future<void> updatestaff(StaffModel staff) async{
    await _staff.updatestaff(staff);
    final index =_staffs.indexWhere((e)=>e.id == staff.id);
    if(index !=-1){
      _staffs[index]=staff;
    }
    notifyListeners();
  }
  
Future<void> deletestaff(int id)async{
  await _staff.deletestaff(id);
  _staffs.removeWhere((b)=>b.id==id);
  notifyListeners();

}

Future<void> updateJobStatus(int staffId, String status) async {
  await _staff.updateStaffJobStatus(staffId, status);

  final index = _staffs.indexWhere((e) => e.id == staffId);

  if (index != -1) {
    _staffs[index] = _staffs[index].copyWith(
      jobStatus: status,
    );
    notifyListeners();
  }
}
  @override
  void dispose() {
    _staffSub?.cancel();
    _bookingCountsSub?.cancel();
    super.dispose();
  }
}
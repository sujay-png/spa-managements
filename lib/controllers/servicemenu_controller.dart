import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ira_spa_webapp/models/client_model.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';


class ClientController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // ─── STATE ──────────────────────────────────────────────────
  List<ClientModel> _clients = [];
  List<ClientModel> get clients => _filteredClients;

  bool _loading = true;
  bool get loading => _loading;

  String _search = '';
  String get search => _search;

    StreamSubscription<List<ClientModel>>? _sub;
  // ─── FILTERED LIST (search applied) ────────────────────────
  List<ClientModel> get _filteredClients {
    if (_search.trim().isEmpty) return _clients;
    final query = _search.toLowerCase();
    return _clients
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.phone.toLowerCase().contains(query) ||
            c.email.toLowerCase().contains(query))
        .toList();
  }

  // ─── LOAD / WATCH (READ, realtime) ──────────────────────────
  Future<void> loadClients() async {
    _loading = true;
    notifyListeners();

    try {
      final list = await _db.getAllCustomers();
      _clients = list;
    } catch (e) {
      // ignore errors or handle as needed
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── CREATE ─────────────────────────────────────────────────
  Future<void> addClient(ClientModel client) async {
    try {
      await _db.insertClient(client);
    } catch (e) {
      rethrow;
    }
  }

  // ─── UPDATE ─────────────────────────────────────────────────
  Future<void> updateClient(ClientModel client) async {
    try {
      await _db.updateClient(client);
    } catch (e) {
      rethrow;
    }
  }

  // ─── DELETE ─────────────────────────────────────────────────
  Future<void> deleteClient(int id) async {
    try {
      await _db.deleteClient(id);
    } catch (e) {
      rethrow;
    }
  }

  // ─── SEARCH ─────────────────────────────────────────────────
  void setSearch(String query) {
    _search = query;
    notifyListeners();
  }

  void clearSearch() {
    _search = '';
    notifyListeners();
  }

  // ─── LOOKUP HELPER ──────────────────────────────────────────
  ClientModel? getClientById(int id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── CLEANUP ────────────────────────────────────────────────
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
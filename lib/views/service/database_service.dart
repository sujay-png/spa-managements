import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
//====================Service=================================
  Future<void> addService(ServiceModel service) async {
    await _supabase
        .from('services')
        .insert(service.toJson());
  }

  //Watch Service
  Future<List<ServiceModel>> fetchServices() async {
    final response = await _supabase
        .from('services')
        .select()
        .order('created_at', ascending: false);

    return response
        .map<ServiceModel>((e) => ServiceModel.fromJson(e))
        .toList();
  }
  //   Future<void> updateService(ServiceModel service) async {
  //   await _supabase
  //       .from('services')
  //       .update(service.toJson())
  //       .eq('id', service.id);
  // }

  Future<void> deleteService(String id) async {
    await _supabase
        .from('services')
        .delete()
        .eq('id', id);
  }
}


import 'package:ira_spa_webapp/models/customer_model.dart';
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
  Stream<List<ServiceModel>> watchServices() {
    return _supabase
        .from('services')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .map((e) => ServiceModel.fromJson(e))
            .toList());
  }
    Future<void> deleteService(String id) async {
    await _supabase
        .from('services')
        .delete()
        .eq('id', id);
  }
    //   Future<void> updateService(ServiceModel service) async {
  //   await _supabase
  //       .from('services')
  //       .update(service.toJson())
  //       .eq('id', service.id);
  // }


//=================================Customer ==========================================

 Future<void> addcustomer(CustomerModel customer) async {
    await _supabase
        .from('Customers')
        .insert(customer.toJson());
  }
}



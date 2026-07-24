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
Stream<List<ServiceModel>> watchServices(int businessRef) {
 

  return _supabase
      .from('services')
      .stream(primaryKey: ['id'])
      .eq('business_ref', businessRef)
      .order('created_at', ascending: false)
      .map((data) {
        return data.map((e) => ServiceModel.fromJson(e)).toList();
      });
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
  try {
    final response = await _supabase
        .from('Customers')
        .insert(customer.toJson())
        .select();

    print("Inserted Customer: $response");
  } catch (e) {
    print("Supabase Error: $e");
    rethrow;
  }
}

Stream<List<CustomerModel>> watchcustomer(int businessRef) {
 

  return _supabase
      .from('Customers')
      .stream(primaryKey: ['id'])
      .eq('business_ref', businessRef)
      .order('created_at', ascending: false)
      .map((data) {
        return data.map((e) => CustomerModel.fromJson(e)).toList();
      });
}
}
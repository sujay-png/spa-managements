import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/navigation/shellroute.dart';
import 'package:ira_spa_webapp/views/auth/login_page.dart';


class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const addTenant = '/tenants/add';

  static Map<String, WidgetBuilder> get routes => {
         login: (_) => const LoginPage(),
      home: (_) => const Shellroute(),
        // addTenant: (_) => const AddTenantView(),
      };
}

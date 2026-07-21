import 'package:flutter/material.dart';


class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const addTenant = '/tenants/add';

  static Map<String, WidgetBuilder> get routes => {
        // login: (_) => const LoginView(),
        // home: (_) => const HomeShell(),
        // addTenant: (_) => const AddTenantView(),
      };
}

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/customer_controller.dart';
import 'package:ira_spa_webapp/controllers/service_controller.dart';
import 'package:ira_spa_webapp/controllers/staff_controller.dart';
import 'package:ira_spa_webapp/navigation/approutes.dart';
import 'package:ira_spa_webapp/navigation/shellroute.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/views/auth/login_page.dart';
import 'package:provider/provider.dart';



class IraspaApp extends StatelessWidget {
  const IraspaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
       ChangeNotifierProvider(create: (_) => AuthController()),
     ChangeNotifierProvider(create: (_) => ServiceController()),
   ChangeNotifierProvider(create: (_) => CustomerController()),
 ChangeNotifierProvider(create: (_) => StaffController()),
  ChangeNotifierProvider(create: (_) => BookingController()),
       ],
      child:  MaterialApp(
        title: 'Ira Spa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routes: AppRoutes.routes,
        home: Consumer<AuthController>(
          builder: (context, auth, _) =>
              auth.isLoggedIn ? const Shellroute() : const LoginPage(),
        ),
         
      ),
     );
  }
}

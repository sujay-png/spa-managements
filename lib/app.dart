import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/navigation/approutes.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';



class IraspaApp extends StatelessWidget {
  const IraspaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ChangeNotifierProvider(create: (_) => AuthController()),
        // ChangeNotifierProvider(create: (_) => TenantController()),
        // ChangeNotifierProvider(create: (_) => FeeController()),
        // ChangeNotifierProvider(create: (_) => MaintenanceController()),
        // ChangeNotifierProvider(create: (_) => NoticeController()),
      ],
      child: MaterialApp(
        title: 'Ira Spa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routes: AppRoutes.routes,
        // home: Consumer<AuthController>(
        //   builder: (context, auth, _) =>
        //       auth.isLoggedIn ? const HomeShell() : const LoginView(),
        // ),
      ),
    );
  }
}

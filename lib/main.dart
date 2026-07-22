import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dksyhipjzsppdhnkbcnh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrc3loaXBqenNwcGRobmtiY25oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MjE2MDcsImV4cCI6MjEwMDE5NzYwN30.FYSktXOpumzNIIBne-OfK2DBn3dSAElL6zOKHAen-9A',
  );
  runApp(const IraspaApp());
}
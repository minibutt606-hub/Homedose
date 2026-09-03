import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:homedose/routes/app_routes.dart';
import 'package:homedose/screens/splash/splash_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:http/http.dart' as http;
import 'package:homedose/network/custom_http_client.dart';

void main() {
  http.runWithClient(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await GetStorage.init();
      Stripe.publishableKey = 'pk_test_51TR55UJHyLRo6nDaBwFwPQY8kFpYGP0jwKtnvZXfo6wY7AolE3PvVzV9wDOfxjCOHSIknYQw8c9U4iJQ3QhoXlbj00w3Kx5FaH';
      runApp(const MyApp());
    },
    () => CustomHttpClient(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Home Dose',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF649DAD)),
        useMaterial3: true,
      ),
      getPages: AppRoutes.pages,
      home: const SplashScreen(),
    );
  }
}

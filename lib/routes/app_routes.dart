import 'package:get/get.dart';
import 'package:homedose/screens/auth/forgot_password/forgot_password_screen.dart';
import 'package:homedose/screens/auth/login/login_screen.dart';
import 'package:homedose/screens/auth/signup/signup_screen.dart';
import 'package:homedose/screens/get_started/get_started_screen.dart';
import 'package:homedose/screens/loading/loading_screen.dart';
import 'package:homedose/screens/splash/splash_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String loading = '/loading';
  static const String getStarted = '/get-started';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  static final List<GetPage> pages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: loading, page: () => const LoadingScreen()),
    GetPage(name: getStarted, page: () => const GetStartedScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: signup, page: () => const SignupScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
  ];
}

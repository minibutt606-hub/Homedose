import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'dart:developer' as dev;

class StripeService {
  static const String stripePublishableKey = 'pk_test_51TR55UJHyLRo6nDaBwFwPQY8kFpYGP0jwKtnvZXfo6wY7AolE3PvVzV9wDOfxjCOHSIknYQw8c9U4iJQ3QhoXlbj00w3Kx5FaH';
  static const String stripeSecretKey = 'sk_test_51TR55UJHyLRo6nDaeYeh170L6YHEdp5RHnX6cUeHUbBzeaIZcc0RbfcG2xvVjDJmtGAVIINPYvieE1wvBlEvhfhG00xCuALvF5';

  static void _log(String message) {
    dev.log("💎 [STRIPE SERVICE]: $message");
  }

  static Future<bool> startPayment({
    required int amountInCents,
    required String email,
  }) async {
    try {
      _log("Initializing payment for ${amountInCents / 100} USD...");

      String? clientSecret;

      // Create Payment Intent directly via Stripe API to ensure it always works for testing
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amountInCents.toString(),
          'currency': 'usd',
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        clientSecret = data['client_secret'];
        _log("Payment Intent Created directly via Stripe API.");
      } else {
        throw Exception('Stripe API Error: ${response.body}');
      }

      if (clientSecret == null) {
        throw Exception('Could not retrieve payment client secret.');
      }

      // Initialize & Present Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Home Dose Premium',
          style: ThemeMode.light,
          billingDetails: BillingDetails(email: email),
        ),
      );

      _log("Opening Payment Sheet...");
      await Stripe.instance.presentPaymentSheet();

      _log("✅ Payment Completed Successfully!");
      return true;
    } catch (e) {
      _log("❌ Error: $e");
      if (e is StripeException) {
        if (e.error.code == FailureCode.Canceled) {
          _log("Payment Canceled by user.");
          return false;
        }
        Get.snackbar(
          "Payment Error",
          e.error.localizedMessage ?? "Transaction failed",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          margin: const EdgeInsets.all(15),
        );
      } else {
        Get.snackbar(
          "Error",
          "Payment failed: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          margin: const EdgeInsets.all(15),
        );
      }
      return false;
    }
  }
}

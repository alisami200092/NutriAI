import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

// Initialize Logger
final logger = Logger();

class PaymentService {
  /// The backend URL (reads from .env if available)
  static String get _backendUrl =>
      dotenv.env['STRIPE_BACKEND_URL'] ??
      "http://10.239.138.250:5001/smart-nutrition-app-6d080/us-central1/createPaymentIntent";

  /// Handles the entire payment flow and saves to Firestore on success
  static Future<void> processPayment({
    required int amountInCents,
    required String currency,
    required String userId,
    String description = "Premium Nutrition Plan",
  }) async {
    try {
      // ---------------------------------------------------------
      // Step 1: Request Client Secret from Backend
      // ---------------------------------------------------------
      logger.d("Initiating payment request to backend...");

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"amount": amountInCents, "currency": currency}),
      );

      final data = jsonDecode(response.body);

      if (data['error'] != null) {
        throw Exception("Backend Error: ${data['error']}");
      }
      if (data['clientSecret'] == null) {
        throw Exception("Failed to retrieve client secret from backend.");
      }

      final clientSecret = data['clientSecret'];
      logger.d("Client secret retrieved successfully.");

      // ---------------------------------------------------------
      // Step 2: Initialize Stripe Payment Sheet
      // ---------------------------------------------------------
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'NutriApp Premium',
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF53994B), // Custom Green for Stripe UI
            ),
          ),
        ),
      );

      // ---------------------------------------------------------
      // Step 3: Present the Payment Sheet
      // ---------------------------------------------------------
      // This will throw an exception if the user cancels or payment fails
      await Stripe.instance.presentPaymentSheet();

      // ---------------------------------------------------------
      // Step 4: Retrieve Payment Details (for the ID)
      // ---------------------------------------------------------
      // We retrieve the intent to confirm the status and get the ID
      final paymentIntent = await Stripe.instance.retrievePaymentIntent(
        clientSecret,
      );

      // ---------------------------------------------------------
      // Step 5: Save to Firestore
      // ---------------------------------------------------------
      await FirebaseFirestore.instance.collection('Payments').add({
        'amount': amountInCents,
        'clientSecret': clientSecret,
        'createdAt': FieldValue.serverTimestamp(),
        'currency': currency,
        'description': description,
        'method': 'card', // Stripe Sheet defaults to card usually
        'paymentId': paymentIntent.id, // The Stripe Transaction ID (pi_...)
        'receiptUrl':
            '', // Receipt URLs are usually handled via Stripe Email Webhooks
        'status': 'succeeded',
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': userId,
      });

      // ✅ Replaced print with Logger
      logger.i("✅ Payment saved to Firestore successfully for user: $userId");
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        logger.w("Payment flow cancelled by user.");
        throw "Payment Cancelled";
      } else {
        logger.e("Stripe Error: ${e.error.localizedMessage}");
        throw "Stripe Error: ${e.error.localizedMessage}";
      }
    } catch (e) {
      // Log the full error before throwing
      logger.e("Payment Processing Error: $e");
      throw e.toString();
    }
  }
}

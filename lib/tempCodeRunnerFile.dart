
    print("Start");
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        String sms = message.body ?? "";
        print(sms);

        if (!isFinancialMessage(sms)) return;

        // 🔹 Extract amount
        final RegExp amountRegex = RegExp(
          r'(₹|Rs\.?|INR)\s?([\d,]+(\.\d+)?)',
          caseSensitive: false,
        );

        Match? match = amountRegex.firstMatch(sms);

        int amount =
            int.tryParse(match?.group(2)?.replaceAll(",", "") ?? "0") ?? 0;

        try {
          // 🔥 CALL ML API
          final result = await predictFromApi(sms);

          String category = result["category"] ?? "Others";
          String typeString = result["type"] ?? "debit";

          // 🔹 Convert string → enum
          TransactionStatus type = typeString == "credit"
              ? TransactionStatus.credited
              : TransactionStatus.debited;

          if (mounted) {
            setState(() {
              textReceived = amount;
            });

            TransactionNotifier.instance.addTransaction(
              amount,
              type,
              category,
              purpose: "SMS",
            );

            debugPrint("✅ SMS Added via API: $sms");
          }
        } catch (e) {
          debugPrint("❌ API Error: $e");
        }

        print("📩 Incoming SMS: $sms");
      },
      listenInBackground: false,
    );
  
  /////////////////////////////////////////
  ///
  import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:telephony/telephony.dart';
import 'package:saad_project_2/homePage.dart';
import 'transaction_notifier.dart';

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  debugPrint("📩 Background SMS: ${message.body}");
}

class SmsParsing extends StatefulWidget {
  const SmsParsing({super.key});

  @override
  State<SmsParsing> createState() => _SmsParsingState();
}

class _SmsParsingState extends State<SmsParsing> {
  final Telephony telephony = Telephony.instance;

  int textReceived = 0;

  // 🔹 API URL
  final String apiUrl = "http://172.23.128.1:5000/predict";

  final List<String> financialKeywords = [
    "debited",
    "credited",
    "transaction",
    "payment",
    "paid",
    "received",
    "balance",
    "withdrawn",
    "deposit",
    "upi",
    "account",
    "spent",
    "txn",
  ];

  final RegExp currencyRegex = RegExp(r'(₹|INR|Rs\.?)\s?[\d,]+(\.\d+)?');

  bool isFinancialMessage(String message) {
  final lower = message.toLowerCase();

  final hasAmount = currencyRegex.hasMatch(message);

  final hasKeyword =
      financialKeywords.any((k) => lower.contains(k));

  final isSpam =
      lower.contains("offer") ||
      lower.contains("cashback") ||
      lower.contains("win") ||
      lower.contains("prize");

  return hasAmount && hasKeyword && !isSpam;
}

  // 🔥 API CALL
  Future<Map<String, dynamic>> predictFromApi(String sms) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"sms": sms}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("API Error");
    }
  }

  void requestPermissions() async {
    bool? granted = await telephony.requestPhoneAndSmsPermissions;
    debugPrint("📱 Permission: $granted");
  }

  TransactionStatus detectTransactionType(String sms) {
  final text = sms.toLowerCase();

  if (text.contains("credited") || text.contains("received")) {
    return TransactionStatus.credited;
  }

  if (text.contains("debited") ||
      text.contains("spent") ||
      text.contains("paid") ||
      text.contains("withdrawn")) {
    return TransactionStatus.debited;
  }

  return TransactionStatus.debited; // default
}

String detectCategory(String sms) {
  final text = sms.toLowerCase();

  if (text.contains("zomato") || text.contains("swiggy")) {
    return "Food";
  }

  if (text.contains("uber") || text.contains("ola")) {
    return "Travel";
  }

  if (text.contains("electricity") ||
      text.contains("bill") ||
      text.contains("recharge")) {
    return "Bills";
  }

  if (text.contains("amazon") ||
      text.contains("flipkart") ||
      text.contains("myntra")) {
    return "Shopping";
  }

  return "Others";
}

  void listenSms() {
  debugPrint("🔥 SMS Listener Started");

  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) {
      String sms = message.body ?? "";

      debugPrint("📩 SMS: $sms");

      if (!isFinancialMessage(sms)) return;

      // 🔹 Extract amount
      final RegExp amountRegex = RegExp(
        r'(₹|Rs\.?|INR)\s?([\d,]+(\.\d+)?)',
        caseSensitive: false,
      );

      Match? match = amountRegex.firstMatch(sms);

      int amount =
          double.tryParse(match?.group(2)?.replaceAll(",", "") ?? "0")?.toInt() ?? 0;

      // 🔹 Detect Type (Credit / Debit)
      TransactionStatus type = detectTransactionType(sms);

      // 🔹 Detect Category
      String category = detectCategory(sms);

      if (mounted) {
        setState(() {
          textReceived = amount;
        });

        TransactionNotifier.instance.addTransaction(
          amount,
          type,
          category,
          purpose: "SMS",
        );

        debugPrint("✅ SMS Added Locally: $sms");
      }
    },
    listenInBackground: false,
  );
}

  @override
  void initState() {
    super.initState();
    requestPermissions();
    listenSms();
  }

  @override
  Widget build(BuildContext context) {
    return Homepage();
  }
}

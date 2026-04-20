import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:saad_project_2/homePage.dart';
import 'transaction_notifier.dart';
import 'api_service.dart';

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

  final RegExp currencyRegex = RegExp(
    r'(₹|INR|Rs\.?)\s?[\d,]+(\.\d+)?',
    caseSensitive: false,
  );

  bool isFinancialMessage(String message) {
    final lower = message.toLowerCase();

    final hasAmount = currencyRegex.hasMatch(message);

    final hasKeyword = financialKeywords.any((k) => lower.contains(k));

    final isSpam = lower.contains("offer") ||
        lower.contains("cashback") ||
        lower.contains("win") ||
        lower.contains("prize");

    return hasAmount && hasKeyword && !isSpam;
  }

  void _initSmsListener() async {
    bool? granted = await telephony.requestPhoneAndSmsPermissions;
    debugPrint("📱 Permission: $granted");
    
    if (granted != null && granted) {
      listenSms();
    } else {
      debugPrint("❌ SMS Permission Denied!");
    }
  }

  void listenSms() {
    debugPrint("🔥 SMS Listener Started");
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        String sms = message.body ?? "";
        debugPrint("📩 Raw SMS: $sms");

        if (!isFinancialMessage(sms)) return;

        // 🔹 Extract amount
        final RegExp amountRegex = RegExp(
          r'(₹|Rs\.?|INR)\s?([\d,]+(\.\d+)?)',
          caseSensitive: false,
        );

        Match? match = amountRegex.firstMatch(sms);

        int amount =
            double.tryParse(match?.group(2)?.replaceAll(",", "") ?? "0")?.toInt() ?? 0;

        String category = "Others";
        String typeString = "debit";

        try {
          // 🔥 CALL ML API
          final result = await ApiService.predict(sms);

          category = result["category"] ?? "Others";
          typeString = result["type"] ?? "debit";
          debugPrint("✅ API Success - Category: $category, Type: $typeString");
        } catch (e) {
          debugPrint("❌ API Error (Fallback to default): $e");
        }

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

          debugPrint("✅ SMS Added Locally: $sms");
        }
      },
      listenInBackground: false,
    );
  }

  @override
  void initState() {
    super.initState();
    _initSmsListener();
  }

  @override
  Widget build(BuildContext context) {
    return Homepage();
  }
}

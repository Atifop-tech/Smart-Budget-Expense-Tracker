import 'package:flutter/material.dart';
import 'package:saad_project_2/api_service.dart';
import 'package:saad_project_2/homePage.dart';
import 'package:telephony/telephony.dart';

import 'transaction_notifier.dart';

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  debugPrint('Background SMS: ${message.body}');
}

class SmsParsing extends StatefulWidget {
  const SmsParsing({super.key});

  @override
  State<SmsParsing> createState() => _SmsParsingState();
}

class _SmsParsingState extends State<SmsParsing> {
  final Telephony telephony = Telephony.instance;

  final List<String> financialKeywords = [
    'debited',
    'credited',
    'transaction',
    'payment',
    'paid',
    'received',
    'balance',
    'withdrawn',
    'deposit',
    'upi',
    'account',
    'spent',
    'txn',
  ];

  final RegExp currencyRegex = RegExp(
    r'(₹|INR|Rs\.?)\s?[\d,]+(\.\d+)?',
    caseSensitive: false,
  );

  bool isFinancialMessage(String message) {
    final lower = message.toLowerCase();
    final hasAmount = currencyRegex.hasMatch(message);
    final hasKeyword = financialKeywords.any((keyword) => lower.contains(keyword));
    final isSpam = lower.contains('offer') ||
        lower.contains('cashback') ||
        lower.contains('win') ||
        lower.contains('prize');

    return hasAmount && hasKeyword && !isSpam;
  }

  Future<void> _initSmsListener() async {
    final granted = await telephony.requestPhoneAndSmsPermissions;
    if (granted ?? false) {
      listenSms();
    } else {
      debugPrint('SMS permission denied.');
    }
  }

  void listenSms() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final sms = message.body ?? '';
        if (!isFinancialMessage(sms)) return;

        final amountRegex = RegExp(
          r'(₹|Rs\.?|INR)\s?([\d,]+(\.\d+)?)',
          caseSensitive: false,
        );

        final match = amountRegex.firstMatch(sms);
        final amount =
            double.tryParse(match?.group(2)?.replaceAll(',', '') ?? '0')?.toInt() ?? 0;

        var category = 'Others';
        var typeString = 'debit';

        try {
          final result = await ApiService.predict(sms);
          category = result['category'] ?? 'Others';
          typeString = result['type'] ?? 'debit';
        } catch (_) {
          debugPrint('Prediction API unavailable. Using fallback classification.');
        }

        final type = typeString == 'credit'
            ? TransactionStatus.credited
            : TransactionStatus.debited;

        TransactionNotifier.instance.addTransaction(
          amount,
          type,
          category,
          purpose: _extractPurpose(sms, type),
          source: 'SMS',
        );
      },
      listenInBackground: false,
    );
  }

  String _extractPurpose(String sms, TransactionStatus type) {
    final clean = sms.replaceAll(RegExp(r'\s+'), ' ').trim();
    final merchantMatch = RegExp(
      r'(?:to|from|at)\s+([A-Za-z0-9&\-. ]{3,30})',
      caseSensitive: false,
    ).firstMatch(clean);

    if (merchantMatch != null) {
      final merchant = merchantMatch.group(1)?.trim();
      if (merchant != null && merchant.isNotEmpty) {
        return merchant;
      }
    }

    return type == TransactionStatus.credited ? 'Incoming payment' : 'Card / UPI payment';
  }

  @override
  void initState() {
    super.initState();
    _initSmsListener();
  }

  @override
  Widget build(BuildContext context) {
    return const Homepage();
  }
}

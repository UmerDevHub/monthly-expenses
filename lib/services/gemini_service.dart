import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class GeminiService {
  static Future<List<String>> generateInsights({
    required String apiKey,
    required List<Expense> expenses,
    required List<Category> categories,
    required double totalSpent,
    required String monthName,
  }) async {
    final Map<String, double> categorySpends = {};
    for (var exp in expenses) {
      final cat = categories.firstWhere(
        (c) => c.id == exp.categoryId,
        orElse: () => Category(id: 'other', name: 'Other', iconAsset: '', colorHex: ''),
      );
      categorySpends[cat.name] = (categorySpends[cat.name] ?? 0.0) + exp.amount;
    }

    final StringBuffer dataBuffer = StringBuffer();
    dataBuffer.writeln('Month: $monthName');
    dataBuffer.writeln('Total Spent: Rs. ${totalSpent.toStringAsFixed(0)}');
    dataBuffer.writeln('Category breakdown:');
    categorySpends.forEach((name, amount) {
      final cat = categories.firstWhere(
        (c) => c.name == name,
        orElse: () => Category(id: '', name: '', iconAsset: '', colorHex: ''),
      );
      final limitStr = cat.monthlyLimit != null 
          ? ' (Limit: Rs. ${cat.monthlyLimit!.toStringAsFixed(0)})' 
          : '';
      dataBuffer.writeln('- $name: Rs. ${amount.toStringAsFixed(0)}$limitStr');
    });

    if (expenses.isNotEmpty) {
      dataBuffer.writeln('\nRecent logs (notes/amounts):');
      final recentNotes = expenses
          .where((e) => e.note != null && e.note!.isNotEmpty)
          .take(12)
          .map((e) => '- ${e.note}: Rs. ${e.amount.toStringAsFixed(0)}')
          .join('\n');
      dataBuffer.writeln(recentNotes);
    }

    final prompt = '''
You are "Kharcha AI", a friendly and intelligent personal finance assistant.
Analyze the following expense data for $monthName:

$dataBuffer

Based on this data, provide exactly 3 or 4 short, highly specific, and actionable financial insights.
Focus on:
1. Budget warnings or alerts for categories exceeding or close to limits.
2. Concrete suggestions to save money (e.g. limit specific transaction types).
3. A positive trend if applicable.

Do not use markdown formatting (like bold asterisks or bullet prefixes) inside the text itself. Keep each item simple, friendly, and practical (max 2 sentences).
Provide your response strictly as a JSON array of strings, like this:
[
  "Alert: Dining spend is Rs. 15,000, exceeding your Rs. 12,000 limit.",
  "Tip: Save up to Rs. 2,000 by ordering fewer online deliveries.",
  "Trend: Excellent work keeping Sim Bill within your limit!"
]
Respond ONLY with the raw JSON array. Do not wrap in markdown code blocks.
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List? candidates = responseData['candidates'] as List?;
        final Map? content = candidates?[0]['content'] as Map?;
        final List? parts = content?['parts'] as List?;
        final String? text = parts?[0]['text'] as String?;
        
        if (text != null && text.trim().isNotEmpty) {
          final List parsed = jsonDecode(text.trim());
          return parsed.cast<String>();
        }
      }
      throw Exception('Failed with status: ${response.statusCode}');
    } catch (e) {
      // Return beautiful fallback mock/intelligent local insights if API call fails
      return _generateLocalFallbackInsights(categorySpends, categories, totalSpent);
    }
  }

  static List<String> _generateLocalFallbackInsights(
    Map<String, double> categorySpends,
    List<Category> categories,
    double totalSpent,
  ) {
    final List<String> fallbacks = [];
    
    // Check if any category exceeded budget
    bool foundAlert = false;
    for (var cat in categories) {
      final spent = categorySpends[cat.name] ?? 0.0;
      final limit = cat.monthlyLimit ?? 0.0;
      if (limit > 0 && spent >= limit) {
        fallbacks.add('Alert: Your ${cat.name} spending of Rs. ${spent.toStringAsFixed(0)} has exceeded your set budget limit of Rs. ${limit.toStringAsFixed(0)}.');
        foundAlert = true;
        break;
      }
    }

    if (!foundAlert) {
      fallbacks.add('Tip: Establish monthly limits on your highest spending categories to automate savings.');
    }

    // High spend alert
    String highestCat = 'None';
    double maxSpent = 0.0;
    categorySpends.forEach((name, spent) {
      if (spent > maxSpent) {
        maxSpent = spent;
        highestCat = name;
      }
    });

    if (maxSpent > 0) {
      fallbacks.add('Tip: $highestCat is your highest expense category this month at Rs. ${maxSpent.toStringAsFixed(0)}. Try setting a weekly budget to track it closer.');
    }

    fallbacks.add('Trend: Your total expenses are logged correctly. Keep adding your recurring bills on time to maintain accurate forecasting.');
    
    return fallbacks;
  }
}

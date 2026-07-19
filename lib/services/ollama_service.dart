import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- Added for secure .env reading

class AiService {
  Future<String> getDesignSuggestions(String colorName, String hex) async {
    // Fetch the key lazily inside the method, ensuring dotenv is already loaded
    final String apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      return "API Key missing! Please check your .env file.";
    }

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/Dhvani30/color_picker', 
          'X-Title': 'ChromaPick',
        },
        body: jsonEncode({
          'model': 'qwen/qwen-2.5-7b-instruct', 
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert interior designer. Give me 2 ultra-concise (under 100 characters total), creative interior design tips for using the paint color "$colorName" (HEX: $hex). Format: 1. [Tip 1] ✨ 2. [Tip 2] 🌈 Keep it punchy and visual.'
            }
          ],
          'temperature': 0.7
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return "AI is busy. Please try again!";
      }
    } catch (e) {
      return "Connection error. Check your internet.";
    }
  }
}
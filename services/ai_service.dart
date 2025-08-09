import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final String apiKey;
  final String baseUrl;
  
  AIService(this.apiKey, this.baseUrl);

  Future<String> sendMessage(String message) async {
    try {
      // Determine the provider based on the URL
      if (baseUrl.contains('cohere.ai')) {
        return await _sendCohereMessage(message);
      } else if (baseUrl.contains('openai.com')) {
        return await _sendOpenAIMessage(message);
      } else if (baseUrl.contains('googleapis.com')) {
        return await _sendGoogleAIMessage(message);
      } else {
        // Try Cohere format as default
        return await _sendCohereMessage(message);
      }
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  Future<String> _sendCohereMessage(String message) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'model': 'command-r-plus',
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['text'] ?? 'No response received';
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<String> _sendOpenAIMessage(String message) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': message}
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? 'No response received';
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<String> _sendGoogleAIMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': message}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1000,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] ?? 'No response received';
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
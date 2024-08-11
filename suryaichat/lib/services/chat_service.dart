import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

class ChatService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  late String apiKey;
  late String apiUrl;
  List<Map<String, String>> conversationHistory = [];

  ChatService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadApiKey();
    await initializeSpeech();
  }

  Future<void> loadApiKey() async {
    final loaded = dotenv.env['API_KEY'];
    final url = dotenv.env['API_URL'];

    if (loaded == null || url == null) {
      throw Exception('API_KEY or API_URL is not set in .env file');
    }

    apiKey = loaded;
    apiUrl = url;
  }

  Future<String> sendMessage(String userInput) async {
    conversationHistory.add({"role": "user", "content": userInput});

    try {
      final response = await http.post( 
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(
          <String, dynamic>{
            "model":
                "gpt-3.5-turbo",
            "messages": [
              {
                "role": "system",
                "content": '''
                  Anda adalah asisten AI yang bernama suryaichat yang cerdas, responsif, 
                  dan asik diajak ngobrol.
                  Jawablah pertanyaan dengan gaya santai dan humor ala warga +62 yang random 
                  suka ngomong anjay, anjir,dan serius, dan selalu memberikan informasi yang akurat dan
                  bermanfaat. bisa juga memberikan link website yang dicari oleh user.
                  Jadilah teman curhat yang selalu punya jawaban lengkap dan memadai.
                '''
              },
              ...conversationHistory,
            ],
            'max_tokens': 300, 
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['choices'] != null &&
            responseData['choices'].isNotEmpty) {
          String aiResponse = responseData['choices'][0]['message']['content'];
          String filteredResponse = _filterResponse(aiResponse);

          conversationHistory
              .add({"role": "assistant", "content": aiResponse});
          return filteredResponse;
        } else {
          throw Exception('Invalid response format.');
        }
      } else {
        throw Exception(
            'Failed to get response from server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error occurred while sending message: $e');
    }
  }

  String _filterResponse(String response) {
    return response.replaceAll(
        RegExp(r'[^\w\s.,!?`~@#$%^&*()_+\-=\[\]{};:"\\|,.<>/?]'), '');
  }

  Future<void> initializeSpeech() async {
    await _speech.initialize();
  }

  bool get isSpeechAvailable => _speech.isAvailable;

  bool get isListening => _speech.isListening;

  void startListening(Function(String) onResult) {
    if (_speech.isAvailable) {
      _speech.listen(onResult: (result) {
        onResult(result.recognizedWords);
      });
    }
  }

  void stopListening() {
    _speech.stop();
  }
}

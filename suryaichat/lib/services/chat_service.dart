// ignore_for_file: prefer_final_fields

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

class ChatService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  late String apiKey;
  late String apiUrl;
  List<Map<String, String>> _conversationHistory = [];

  ChatService() {
    loadApiKey();
  }

  Future<void> loadApiKey() async {
    apiKey = dotenv.env['API_KEY']!;
    apiUrl = dotenv.env['API_URL']!;
  }

 Future<String> sendMessage(String userInput, List<String> list) async {
    _conversationHistory.add({"role": "user", "content": userInput});

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json;charset=UTF-8',
          'Charset': 'utf-8',
          'Authorization': 'Bearer $apiKey'
        },
        body: jsonEncode(
          <String, dynamic>{
            "model": "gpt-4o",
            "messages": [
              {
                "role": "system",
                "content":
                    '''Anda adalah asisten AI yang bernama suryaichat yang cerdas, responsif, 
                    dan asik diajak ngobrol.
                    Jawablah pertanyaan dengan gaya santai dan humor ala warga +62 yang random 
                    suka ngomong anjay, anjir,dan serius, dan selalu memberikan informasi yang akurat dan
                    bermanfaat. bisa juga memberikan link website yang dicari oleh user.
                    Jadilah teman curhat yang selalu punya jawaban lengkap dan memadai.'''
              },
              ..._conversationHistory,
            ],
            'max_tokens': 2000,
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String aiResponse = responseData['choices'][0]['message']['content'];
         
        String filteredResponse = '';
        for (int i = 0; i < aiResponse.length; i++) {
          String char = aiResponse[i];
          if (RegExp(r'[a-zA-Z0-9\s.,!?`~@#$%^&*()_+\-=\[\]{};:"\\|,.<>/?]')
              .hasMatch(char)) {
            filteredResponse += char;
          }
        }

        _conversationHistory.add({"role": "assistant", "content": aiResponse});
        return filteredResponse;
      } else {
        throw Exception('Failed to get response from server.');
      }
    } catch (e) {
      throw Exception('Error occurred while sending message: $e');
    }
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

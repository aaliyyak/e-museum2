import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  DateTime? _startTime; // waktu mulai bicara
  DateTime? _endTime; // waktu selesai bicara

  FlutterTts get flutterTts => _tts;

  TtsService() {
    _tts.setLanguage("id-ID");
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.0);

    // 🔹 callback saat TTS mulai bicara
    _tts.setStartHandler(() {
      _startTime = DateTime.now();
      print("🔵 TTS START at $_startTime");
    });

    // 🔹 callback saat selesai bicara
    _tts.setCompletionHandler(() {
      _endTime = DateTime.now();

      if (_startTime != null) {
        final duration = _endTime!.difference(_startTime!);
        print("🟢 TTS FINISHED at $_endTime");
        print("⏱️ Durasi bicara: ${duration.inMilliseconds} ms");
      }
    });
  }

  Future<void> speak(String maleText, String femaleText) async {
    await _tts.stop();

    // --- Suara PRIA ---
    await _tts.setPitch(1.0);
    await _tts.setVoice({"name": "male", "locale": "id-ID"});
    await _tts.speak(maleText);

    // Tunggu jeda sebelum suara wanita
    await Future.delayed(const Duration(milliseconds: 400));

    // --- Suara WANITA ---
    await _tts.setPitch(1.15);
    await _tts.setVoice({"name": "female", "locale": "id-ID"});
    await _tts.speak(femaleText);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}

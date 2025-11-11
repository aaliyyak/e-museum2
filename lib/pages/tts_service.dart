import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _ttsMale = FlutterTts();
  final FlutterTts _ttsFemale = FlutterTts();

  TtsService() {
    // Konfigurasi suara pria
    _ttsMale.setLanguage("id-ID");
    _ttsMale.setVoice({"name": "male", "locale": "id-ID"});
    _ttsMale.setSpeechRate(0.5); // ✅ Lebih lambat & natural
    _ttsMale.setPitch(1.0); // Nada normal

    // Konfigurasi suara wanita
    _ttsFemale.setLanguage("id-ID");
    _ttsFemale.setVoice({"name": "female", "locale": "id-ID"});
    _ttsFemale.setSpeechRate(0.5); // ✅ Sama dengan suara pria
    _ttsFemale.setPitch(1.1); // Sedikit lebih tinggi agar terdengar feminin
  }

  // Fungsi untuk membaca teks
  Future<void> speak(String maleText, String femaleText) async {
    // Pastikan berhenti dulu sebelum memulai
    await _ttsMale.stop();
    await _ttsFemale.stop();

    // Baca teks secara bergantian, bukan bersamaan
    await _ttsMale.speak(maleText);
    await Future.delayed(const Duration(seconds: 1)); // jeda
    await _ttsFemale.speak(femaleText);
  }

  // Fungsi untuk menghentikan pembacaan
  Future<void> stop() async {
    await _ttsMale.stop();
    await _ttsFemale.stop();
  }
}

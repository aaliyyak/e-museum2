import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smb2_museum/pages/output.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/koleksi_models.dart';
import '../data/koleksi_data.dart';

class VoicePopupAuto extends StatefulWidget {
  final VoidCallback onCameraOff;
  final VoidCallback onCameraOn;

  const VoicePopupAuto({
    super.key,
    required this.onCameraOff,
    required this.onCameraOn,
  });

  @override
  State<VoicePopupAuto> createState() => _VoicePopupAutoState();
}

class _VoicePopupAutoState extends State<VoicePopupAuto>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "";
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _requestMicPermission();
  }

  @override
  void dispose() {
    _stopListening(forceDispose: true);
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Izin mikrofon diperlukan.")),
      );
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == "done" && mounted) _stopListening();
      },
      onError: (val) => debugPrint("Error: $val"),
    );

    if (available && mounted) {
      setState(() {
        _isListening = true;
        _text = "";
      });

      _speech.listen(
        onResult: (val) {
          if (mounted) setState(() => _text = val.recognizedWords);
        },
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  Future<void> _stopListening({bool forceDispose = false}) async {
    if (!_isListening && !forceDispose) return;

    await _speech.stop();
    if (!mounted) return;

    setState(() => _isListening = false);
    final recognizedText = _text;
    _text = "";

    widget.onCameraOff();

    if (!forceDispose && recognizedText.isNotEmpty) {
      final result = _findKoleksi(recognizedText.toLowerCase());

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (result != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OutputPage(
                userName: _extractUserName(recognizedText),
                koleksi: result,
                onExit: () {
                  widget.onCameraOn();
                  if (mounted) Navigator.pop(context);
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tidak ditemukan hasil yang cocok.")),
          );
          widget.onCameraOn();
        }
      });
    }
  }

  Koleksi? _findKoleksi(String text) {
    for (var k in koleksiList) {
      for (var keyword in k.keywords) {
        if (text.contains(keyword.toLowerCase())) return k;
      }
    }
    return null;
  }

  String _extractUserName(String text) {
    final words = text.split(' ');
    int idx = words.indexWhere((w) => w == "aku" || w == "saya");
    if (idx != -1 && idx + 1 < words.length) return words[idx + 1].capitalize();
    return "Pengunjung";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      contentPadding: EdgeInsets.zero,
      content: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Silakan berbicara untuk mencari koleksi museum.",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _toggleListening,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isListening)
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: AnimatedBuilder(
                            animation: _waveController,
                            builder: (_, child) {
                              return CustomPaint(
                                painter: _WavePainter(_waveController.value),
                              );
                            },
                          ),
                        ),
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 60,
                        color: _isListening ? Colors.redAccent : Colors.grey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _text.isEmpty
                      ? (_isListening
                          ? "Mendengarkan..."
                          : "Tekan mikrofon untuk mulai")
                      : _text,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                _stopListening();
                widget.onCameraOn();
              },
              child: const Icon(Icons.close, size: 18, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    double radius = 30 + 10 * sin(progress * 2 * pi);
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}

extension StringCap on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/koleksi_models.dart';
import 'tts_service.dart';

class OutputPage extends StatefulWidget {
  final String userName;
  final Koleksi koleksi;
  final VoidCallback? onExit;
  final VoidCallback? onCameraOff;

  const OutputPage({
    super.key,
    required this.userName,
    required this.koleksi,
    this.onExit,
    this.onCameraOff,
  });

  @override
  State<OutputPage> createState() => _OutputPageState();
}

class _OutputPageState extends State<OutputPage> {
  late VideoPlayerController _controller;
  late TtsService _ttsService;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _ttsService = TtsService();
    widget.onCameraOff?.call();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset('assets/videos/viii.mp4');
    await _controller.initialize();
    if (!_isDisposed) setState(() {});
    _controller.setVolume(0);
    await _playVideoAndTtsOnce();
  }

  Future<void> _playVideoAndTtsOnce() async {
    if (_isDisposed) return;
    await _controller.seekTo(Duration.zero);
    await _controller.play();
    await _speakTeks();

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration &&
          !_controller.value.isPlaying &&
          !_isDisposed) {
        setState(() {});
      }
    });
  }

  Future<void> _speakTeks() async {
    final nama = widget.userName.isEmpty ? "Pengunjung" : widget.userName;
    final kalimat =
        "Hai $nama, ${widget.koleksi.title} berada di ${widget.koleksi.lokasi}, silakan ${widget.koleksi.instruksi}.";
    await _ttsService.stop();
    await _ttsService.speak(kalimat, kalimat);
  }

  Future<void> _replayVideoAndTts() async {
    await _playVideoAndTtsOnce();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    _ttsService.stop();
    widget.onExit?.call();
    super.dispose();
  }

  void _handleExit() {
    widget.onExit?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final koleksi = widget.koleksi;
    final nama = widget.userName.isEmpty ? "Pengunjung" : widget.userName;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.elliptical(180, 350),
                    bottomRight: Radius.elliptical(940, 215),
                  ),
                  child: _controller.value.isInitialized
                      ? SizedBox(
                          width: double.infinity,
                          height: 450,
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(height: 10),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  koleksi.imagePath,
                                  width: 100,
                                  height: 130,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -5,
                                right: -5,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.zoom_out_map,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Dialog(
                                          backgroundColor: Colors.black87,
                                          insetPadding:
                                              const EdgeInsets.all(10),
                                          child: Stack(
                                            children: [
                                              InteractiveViewer(
                                                minScale: 1,
                                                maxScale: 4,
                                                child: Image.asset(
                                                  koleksi.imagePath,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              Positioned(
                                                top: 16,
                                                right: 10,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.white,
                                                      size: 30),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hai $nama, ini ${koleksi.title}",
                                  style: GoogleFonts.candal(
                                      fontSize: 13, color: Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 13, color: Colors.redAccent),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        koleksi.lokasi,
                                        style: GoogleFonts.faustina(
                                            fontSize: 13,
                                            color: Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  koleksi.instruksi,
                                  style: GoogleFonts.faustina(
                                      fontSize: 13, color: Colors.black54),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Deskripsi: ",
                                        style: GoogleFonts.candal(
                                            fontSize: 12, color: Colors.black)),
                                    Expanded(
                                      child: Text(
                                        koleksi.deskripsi,
                                        style: GoogleFonts.faustina(
                                            fontSize: 13, color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 60),
                              ],
                            ),
                          ),
                        ],
                      ),

                      /// 🔹 Tombol Play & Exit di bagian bawah kanan & kiri
                      Positioned(
                        bottom: 5,
                        left: 0,
                        child: ElevatedButton.icon(
                          onPressed: _handleExit,
                          icon: const Icon(Icons.exit_to_app,
                              color: Colors.white),
                          label: const Text("Exit",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -10,
                        right: -10,
                        child: IconButton(
                          icon: const Icon(Icons.play_circle_fill,
                              color: Colors.blue, size: 40),
                          tooltip: "Putar ulang video dan suara",
                          onPressed: _replayVideoAndTts,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

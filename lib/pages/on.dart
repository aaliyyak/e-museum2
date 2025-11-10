import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'voice_popup.dart'; // popup disimpan di file terpisah

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  CameraController? _cameraFront;
  Uint8List? _lastFrameFront;
  Uint8List? _lastPersonHash;
  List<CameraDescription>? cameras;

  bool _isMovingFront = false;
  bool _videoPlaying = false;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/videos/onnn.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(false);
      });

    _initCamerasAndFront();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _blinkController.repeat(reverse: true);
  }

  Future<void> _initCamerasAndFront() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      await _initCameraFront();
    }
  }

  Future<void> _initCameraFront() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) return;

    try {
      _cameraFront = CameraController(
        cameras!
            .firstWhere((c) => c.lensDirection == CameraLensDirection.front),
        ResolutionPreset.ultraHigh,
        enableAudio: false,
      );
      await _cameraFront!.initialize();
      await _cameraFront!.startImageStream((image) => _processFrame(image));

      print("📷 Kamera depan siap");
      setState(() {});
    } catch (e) {
      print("❌ Kamera depan gagal: $e");
    }
  }

  Future<void> _stopCameraFront() async {
    if (_cameraFront != null) {
      try {
        if (_cameraFront!.value.isStreamingImages) {
          await _cameraFront!.stopImageStream();
        }
      } catch (e) {
        print("❌ Error stop stream: $e");
      }
      await _cameraFront!.dispose();
      _cameraFront = null;
      print("📷 Kamera depan dimatikan");
    }
  }

  void _processFrame(CameraImage image) {
    Uint8List currentFrame = image.planes[0].bytes;

    if (_lastFrameFront != null) {
      int diffCount = 0;
      for (int i = 0; i < currentFrame.length; i += 100) {
        if ((currentFrame[i] - _lastFrameFront![i]).abs() > 20) diffCount++;
      }

      bool detected = diffCount > 50;
      if (detected != _isMovingFront) {
        _isMovingFront = detected;
        setState(() {});

        if (_isMovingFront) {
          Uint8List frameHash = _computeFrameHash(currentFrame);

          if (!_videoPlaying &&
              (_lastPersonHash == null ||
                  !_compareHash(_lastPersonHash!, frameHash))) {
            _lastPersonHash = frameHash;
            _playVideo();
            _showPersonDetectedSnackbar();
          }
        }
      }
    }

    _lastFrameFront = currentFrame;
  }

  Uint8List _computeFrameHash(Uint8List frame) {
    return Uint8List.fromList(
        [for (int i = 0; i < frame.length; i += 100) frame[i]]);
  }

  bool _compareHash(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _playVideo() async {
    if (!_controller.value.isInitialized || _videoPlaying) return;

    _videoPlaying = true;
    await _controller.seekTo(Duration.zero);
    await _controller.play();

    void listener() {
      if (_controller.value.position >= _controller.value.duration) {
        _videoPlaying = false;
        _controller.removeListener(listener);
      }
    }

    _controller.addListener(listener);
  }

  void _showPersonDetectedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.redAccent.shade400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        content: const Row(
          children: [
            Icon(Icons.person, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Orang terdeteksi di kamera!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔴 Ketika mic ditekan
  Future<void> _onMicPressed() async {
    await _stopCameraFront(); // Matikan kamera sementara

    final result = await showDialog(
      context: context,
      builder: (_) => VoicePopupAuto(
        onCameraOff: () async {
          await _stopCameraFront(); // Pastikan kamera dimatikan sebelum popup
        },
        onCameraOn: () async {
          await _initCamerasAndFront(); // Hidupkan kamera lagi setelah popup ditutup
        },
      ),
    );

    // Jika ada hasil dari popup
    if (result != null && result is Map<String, dynamic>) {
      Navigator.pushNamed(context, '/output', arguments: result);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopCameraFront();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Konten utama
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 180),
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
                            height: 480,
                            child: AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Museum SMB II Palembang',
                    style: GoogleFonts.candal(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Text(
                      'Selamat datang di Museum Sultan Mahmud Badaruddin II Palembang. Mencintai Budaya, Memajukan Peradaban.',
                      style: GoogleFonts.faustina(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Ikon kamera kanan atas
            Positioned(
              top: 8,
              right: 16,
              child: Icon(
                Icons.camera_alt,
                color: _isMovingFront ? Colors.red : Colors.grey,
                size: 25,
              ),
            ),

            // Kamera live kiri bawah
            if (_cameraFront != null && _cameraFront!.value.isInitialized)
              Positioned(
                bottom: 20,
                left: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: CameraPreview(_cameraFront!),
                  ),
                ),
              ),

            // Tombol mic kanan bawah
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: _onMicPressed,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(181, 255, 205, 210),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Color.fromARGB(244, 163, 13, 2),
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<String> images = [
    'assets/icon/img1.png',
    'assets/icon/img2.png',
    'assets/icon/img3.png',
  ];

  final List<String> title = [
    "Hai, Selamat Datang di Technofac!",
    "Gunakan Perintah Suara",
    "Contoh Perintah Pencarian Fasilitas",
  ];

  final List<String> description = [
    "Aplikasi Technofac ini dapat membantu kamu mencari fasilitas kampus dengan menggunakan perintah suara!",
    "Tekan tombol mikrofon lalu beri izin akses. Ucapkan fasilitas yang ingin dicari.",
    "Klik fitur cari fasilitas dan coba perintah ini:\n• Dimana Perpustakaan?\n• Tunjukkan Lab. Komputer",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        images[index],
                        height: 250,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        title[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          description[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ROW: BACK - DOTS - NEXT (Hanya Slide 1 & 2)
            if (_currentIndex != 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button (muncul di slide 2)
                    if (_currentIndex == 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 22),
                        onPressed: () {
                          _controller.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      )
                    else
                      const SizedBox(width: 48),

                    // DOT INDICATOR
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 16 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? const Color(0xFF1DA1F2)
                                : const Color(0xFFD0D0D0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }),
                    ),

                    // Next button (muncul di slide 1 & 2)
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 22),
                      onPressed: () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // BUTTON HANYA UNTUK SLIDE 3
            if (_currentIndex == 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DA1F2),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Navigator.pushReplacement(...)
                  },
                  child: const Text(
                    "Let's Go",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}

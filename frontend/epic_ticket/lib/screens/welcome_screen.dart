import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.5, 0.5),
                radius: 1.24,
                colors: [Color(0x26920703), Colors.black],
              ),
            ),
          ),
          // Decorative circles (sederhana, bisa diimplementasi dengan Positioned)
          ...List.generate(8, (index) => _buildCircle()),
          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Logo dan teks EPIC TICKET
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'EPIC',
                          style: TextStyle(
                            color: const Color(0xFFE2E2E2),
                            fontSize: 28,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.4,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'TICKET',
                          style: TextStyle(
                            color: const Color(0xFFB52619),
                            fontSize: 28,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SMART TICKETING & VENUE NAVIGATION',
                      style: TextStyle(
                        color: const Color(0xCCE3BEB8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Featured event
                Column(
                  children: [
                    const Text(
                      'FEATURED EVENT',
                      style: TextStyle(
                        color: Color(0xFFB52619),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'EPIC 2K26',
                      style: TextStyle(
                        color: Color(0xFFE2E2E2),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B0000),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: Color(0xFFE2E2E2),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5A403C)),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: Color(0xFFE2E2E2),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Dengan melanjutkan, Anda menyetujui Syarat & Ketentuan',
                        style: TextStyle(
                          color: Color(0x99E3BEB8),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk lingkaran dekoratif (sederhana)
  Widget _buildCircle() {
    return Positioned(
      left: 0,
      top: 0,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0x19B52619),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

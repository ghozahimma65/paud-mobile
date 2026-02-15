import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../ui/dashboard_page.dart'; // Dashboard Wali Murid
import '../ui/dashboard_guru_page.dart'; // Dashboard Guru (YANG BARU)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    // Panggil Service Login
    final result = await _authService.login(email, password);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      // Login Berhasil!
      if (!mounted) return;

      // Ambil data user untuk cek Role
      var userData = result['data'];
      String role = userData['role']; // 'guru' atau 'wali_murid'

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login Berhasil! Selamat datang, ${userData['name']}"),
        ),
      );

      // --- LOGIKA PENGARAHAN (ROUTING) ---
      if (role == 'guru') {
        // Kalau Guru -> Ke Dashboard Guru
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardGuruPage()),
        );
      } else {
        // Kalau Wali Murid -> Ke Dashboard Wali
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
      // -----------------------------------
    } else {
      // Login Gagal
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Icon
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, size: 50, color: Colors.green),
              ),
              const SizedBox(height: 20),

              Text(
                "PAUD AISYIYAH",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                "Monitoring & Keamanan Penjemputan",
                style: GoogleFonts.poppins(color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Input Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Input Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            "MASUK",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'kelola_page.dart';
import 'kalender_page.dart';
import 'pomodoro_page.dart';
import 'akun_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // GlobalKey untuk akses method di dalam KelolaPage
  final GlobalKey<State<KelolaPage>> _kelolaKey = GlobalKey();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      KelolaPage(key: _kelolaKey),
      const KalenderPage(),
      const SizedBox.shrink(), // Dummy page for center gap
      const PomodoroPage(),
      const AkunPage(),
    ];
  }

  void _onFabPressed() {
    // Panggil method dialogTambahMisi dari state KelolaPage
    // Note: Kita harus cast state-nya via dynamic atau definisikan interface kalau mau strict
    // Tapi karena State<KelolaPage> defaultnya private type (_KelolaPageState),
    // kita gunakan dynamic call atau pastikan KelolaPage state publik (which is rarely done)
    // ALTERNATIF MUDAH: cast ke dynamic
    final dynamic state = _kelolaKey.currentState;
    if (state != null) {
      // Pindah ke tab Kelola dulu biar dialog muncul di konteks yang benar
      setState(() => _selectedIndex = 0);
      // Tunggu render frame sedikit (opsional) lalu panggil dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.dialogTambahMisi();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),

      // Floating Action Button di Tengah (Timbul)
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Membuat lekukan u/ FAB
        notchMargin: 8.0,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: SizedBox(
          height: 60, // Tinggi NavBar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.check_box_outlined, "Kelola", 0),
              _buildNavItem(Icons.calendar_month_outlined, "Kalender", 1),
              const SizedBox(width: 48), // Spasi kosong di tengah untuk FAB
              _buildNavItem(Icons.timer_outlined, "Fokus", 3),
              _buildNavItem(Icons.person_outline, "Akun", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 24),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

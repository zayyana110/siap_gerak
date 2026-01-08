import 'dart:async';
import 'package:flutter/material.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  double _durasiMenit = 25;
  int _sisaWaktu = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;

  void _mulaiTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_sisaWaktu > 0) {
          _sisaWaktu--;
        } else {
          _stopTimer();
        }
      });
    });
  }

  void _stopTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() => _sisaWaktu = (_durasiMenit * 60).toInt());
  }

  @override
  Widget build(BuildContext context) {
    int menit = _sisaWaktu ~/ 60;
    int detik = _sisaWaktu % 60;

    return Scaffold(
      appBar: AppBar(title: const Text("Mode Fokus"), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: _sisaWaktu / (_durasiMenit * 60),
                    strokeWidth: 10,
                    color: Colors.deepOrange,
                    backgroundColor: Colors.orange[100],
                  ),
                ),
                Text(
                  "${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            if (!_isRunning) ...[
              const Text("Atur Durasi Fokus (Menit)"),
              Slider(
                value: _durasiMenit,
                min: 5,
                max: 120,
                divisions: 23,
                label: "${_durasiMenit.round()} menit",
                activeColor: Colors.deepOrange,
                onChanged: (val) {
                  setState(() {
                    _durasiMenit = val;
                    _sisaWaktu = (val * 60).toInt();
                  });
                },
              ),
              Text(
                "${_durasiMenit.round()} Menit",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _mulaiTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "MULAI",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                OutlinedButton(
                  onPressed: _isRunning ? _stopTimer : _resetTimer,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: Text(_isRunning ? "JEDA" : "RESET"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KalenderPage extends StatefulWidget {
  const KalenderPage({super.key});

  @override
  State<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Tanggal untuk navigasi bulan (Jan, Feb, dst)
  DateTime _focusedDate = DateTime.now();

  // Tanggal yang sedang DIPILIH/DIKLIK (Default hari ini)
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Logika perhitungan kalender
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month + 1,
      0,
    ).day;
    final firstWeekday = firstDayOfMonth.weekday;
    final offset = firstWeekday - 1;

    return Scaffold(
      appBar: AppBar(title: const Text("Kalender"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        // Kita ambil SEMUA data dulu, nanti difilter di UI
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('misi')
            .snapshots(),
        builder: (context, snapshot) {
          // 1. SIAPKAN DATA
          // Set untuk menyimpan tanggal mana saja yang ada tugasnya (biar ada titik oranye)
          Set<int> tanggalAdaTugas = {};
          // List untuk menyimpan tugas khusus tanggal yang DIPILIH
          List<DocumentSnapshot> tugasTerpilih = [];

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              if (data['deadline'] != null) {
                DateTime dt = (data['deadline'] as Timestamp).toDate();

                // Cek untuk titik oranye (di bulan yang sedang dilihat)
                if (dt.month == _focusedDate.month &&
                    dt.year == _focusedDate.year) {
                  tanggalAdaTugas.add(dt.day);
                }

                // Cek untuk List di bawah (sesuai tanggal yang DIKLIK)
                if (dt.day == _selectedDate.day &&
                    dt.month == _selectedDate.month &&
                    dt.year == _selectedDate.year) {
                  tugasTerpilih.add(doc);
                }
              }
            }
          }

          return Column(
            children: [
              // --- BAGIAN 1: HEADER & GRID KALENDER ---
              _buildHeaderKalender(),
              _buildNamaHari(),

              // Grid Kalender (Kita kasih porsi flex lebih besar sedikit)
              Expanded(
                flex: 6,
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: daysInMonth + offset,
                  itemBuilder: (context, index) {
                    if (index < offset) return const SizedBox();

                    final int day = index - offset + 1;
                    // Bikin objek DateTime untuk tanggal kotak ini
                    final DateTime currentDayDate = DateTime(
                      _focusedDate.year,
                      _focusedDate.month,
                      day,
                    );

                    // Cek apakah tanggal ini adalah yang sedang DIPILIH
                    final bool isSelected =
                        day == _selectedDate.day &&
                        _focusedDate.month == _selectedDate.month &&
                        _focusedDate.year == _selectedDate.year;

                    // Cek apakah hari ini (Realtime)
                    final bool isToday =
                        day == DateTime.now().day &&
                        _focusedDate.month == DateTime.now().month &&
                        _focusedDate.year == DateTime.now().year;

                    final bool hasTask = tanggalAdaTugas.contains(day);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDate = currentDayDate;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          // Jika dipilih -> Oranye Penuh
                          // Jika hari ini -> Garis tepi Oranye
                          // Biasa -> Putih
                          color: isSelected ? Colors.deepOrange : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isSelected
                              ? Border.all(color: Colors.deepOrange, width: 2)
                              : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "$day",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasTask)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  // Kalau background oranye (selected), titiknya putih
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.deepOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(thickness: 2),

              // --- BAGIAN 2: LIST TUGAS DI BAWAH ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  "Tugas pada ${_selectedDate.day} ${_namaBulan(_selectedDate.month)} ${_selectedDate.year}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),

              Expanded(
                flex: 4, // Sisa ruang untuk list tugas
                child: tugasTerpilih.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 50,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Tidak ada tugas di tanggal ini",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tugasTerpilih.length,
                        itemBuilder: (context, index) {
                          var data =
                              tugasTerpilih[index].data()
                                  as Map<String, dynamic>;
                          bool selesai = data['sudahSelesai'] ?? false;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 1,
                            child: ListTile(
                              leading: Icon(
                                selesai
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: selesai
                                    ? Colors.green
                                    : Colors.deepOrange,
                              ),
                              title: Text(
                                data['judul'] ?? "-",
                                style: TextStyle(
                                  decoration: selesai
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: selesai ? Colors.grey : Colors.black,
                                ),
                              ),
                              subtitle: Text(data['kategori'] ?? "Umum"),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget Header Bulan (Januari 2026) + Tombol Ganti Bulan
  Widget _buildHeaderKalender() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(
              () => _focusedDate = DateTime(
                _focusedDate.year,
                _focusedDate.month - 1,
              ),
            ),
          ),
          Text(
            "${_namaBulan(_focusedDate.month)} ${_focusedDate.year}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(
              () => _focusedDate = DateTime(
                _focusedDate.year,
                _focusedDate.month + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Nama Hari (SEN - MIN)
  Widget _buildNamaHari() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("SEN", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("SEL", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("RAB", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("KAM", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("JUM", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("SAB", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            "MIN",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      ),
    );
  }

  String _namaBulan(int index) {
    const list = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    return list[index - 1];
  }
}

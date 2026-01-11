import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_model.dart';

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

  // Helper Nama Bulan
  String _namaBulan(int month) {
    const bulan = [
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
    return bulan[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month + 1,
      0,
    ).day;
    final firstWeekday = firstDayOfMonth.weekday;
    final offset = firstWeekday - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kalender"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('misi')
            .snapshots(),
        builder: (context, snapshot) {
          // 1. SIAPKAN DATA
          Map<int, TaskPriority> priorityMap = {};
          List<Task> tugasTerpilih = [];

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              Task task = Task.fromMap(doc.id, data);

              if (task.deadline != null) {
                DateTime dt = task.deadline!.toDate();

                // Cek titik prioritas (untuk bulan yang sedang dilihat)
                if (dt.month == _focusedDate.month &&
                    dt.year == _focusedDate.year) {
                  if (!priorityMap.containsKey(dt.day)) {
                    priorityMap[dt.day] = task.priority;
                  } else {
                    // Update jika prioritas lebih tinggi (index lebih kecil)
                    if (task.priority.index < priorityMap[dt.day]!.index) {
                      priorityMap[dt.day] = task.priority;
                    }
                  }
                }

                // Cek data list (untuk tanggal yang dipilih)
                if (dt.day == _selectedDate.day &&
                    dt.month == _selectedDate.month &&
                    dt.year == _selectedDate.year) {
                  tugasTerpilih.add(task);
                }
              }
            }
            // Urutkan tugas
            tugasTerpilih = urutkanTugas(tugasTerpilih);
          }

          return Column(
            children: [
              // HEADER KALENDER
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() {
                        _focusedDate = DateTime(
                          _focusedDate.year,
                          _focusedDate.month - 1,
                        );
                      }),
                    ),
                    Text(
                      "${_namaBulan(_focusedDate.month)} ${_focusedDate.year}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() {
                        _focusedDate = DateTime(
                          _focusedDate.year,
                          _focusedDate.month + 1,
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // NAMA HARI
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Text("Sen", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Sel", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Rab", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Kam", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Jum", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "Sab",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Min",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // GRID KALENDER
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
                    final DateTime currentDayDate = DateTime(
                      _focusedDate.year,
                      _focusedDate.month,
                      day,
                    );

                    final bool isSelected =
                        day == _selectedDate.day &&
                        _focusedDate.month == _selectedDate.month &&
                        _focusedDate.year == _selectedDate.year;

                    final bool isToday =
                        day == DateTime.now().day &&
                        _focusedDate.month == DateTime.now().month &&
                        _focusedDate.year == DateTime.now().year;

                    return InkWell(
                      onTap: () =>
                          setState(() => _selectedDate = currentDayDate),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue
                              : (Theme.of(context).cardTheme.color ??
                                    Colors.white),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.2),
                                ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "$day",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color ??
                                          Colors.black),
                                fontWeight: isToday || isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (priorityMap.containsKey(day))
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: getPriorityColor(priorityMap[day]!),
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

              const Divider(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  "Tugas tanggal ${_selectedDate.day} ${_namaBulan(_selectedDate.month)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // LIST TUGAS
              Expanded(
                flex: 4,
                child: tugasTerpilih.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.event_available,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Tidak ada tugas",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tugasTerpilih.length,
                        itemBuilder: (context, index) {
                          final task = tugasTerpilih[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  // Strip Prioritas
                                  Container(
                                    width: 4,
                                    decoration: BoxDecoration(
                                      color: getPriorityColor(task.priority),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ListTile(
                                      leading: Icon(
                                        task.sudahSelesai
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: task.sudahSelesai
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                      title: Text(
                                        task.judul,
                                        style: TextStyle(
                                          decoration: task.sudahSelesai
                                              ? TextDecoration.lineThrough
                                              : null,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "${task.kategori} • ${getPriorityText(task.priority)}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
}

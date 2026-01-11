import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String _selectedCategory = 'Semua';
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Silakan login terlebih dahulu.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik'), centerTitle: true),
      body: Column(
        children: [
          // 1. FILTER KATEGORI
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('kategori')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                List<DropdownMenuItem<String>> items = [];
                items.add(
                  const DropdownMenuItem(
                    value: 'Semua',
                    child: Text('Semua Kategori'),
                  ),
                );

                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String nama = data['nama'];
                  items.add(DropdownMenuItem(value: nama, child: Text(nama)));
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.filter_list, color: Colors.blue),
                      items: items,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. CHART & DATA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedCategory == 'Semua'
                  ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('misi')
                        .snapshots()
                  : FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('misi')
                        .where('kategori', isEqualTo: _selectedCategory)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.pie_chart_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Belum ada data di $_selectedCategory",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                int completedCount = 0;
                int pendingCount = 0;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bool isDone = data['sudahSelesai'] ?? false;
                  if (isDone) {
                    completedCount++;
                  } else {
                    pendingCount++;
                  }
                }

                final int total = completedCount + pendingCount;

                if (total == 0) {
                  return const Center(child: Text("Belum ada tugas."));
                }

                final double completedPercentage =
                    (completedCount / total) * 100;
                final double pendingPercentage = (pendingCount / total) * 100;

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      "Progres Misi Anda",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // GRAFIK LINGKARAN (PIE CHART)
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      touchedIndex = -1;
                                      return;
                                    }
                                    touchedIndex = pieTouchResponse
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 0,
                          sections: [
                            // SELESAI
                            PieChartSectionData(
                              color: Colors.blue,
                              value: completedPercentage,
                              title:
                                  '${completedPercentage.toStringAsFixed(1)}%',
                              radius: touchedIndex == 0 ? 110 : 100,
                              titleStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            // BELUM SELESAI
                            PieChartSectionData(
                              color: Colors.grey.shade300,
                              value: pendingPercentage,
                              title: '${pendingPercentage.toStringAsFixed(1)}%',
                              radius: touchedIndex == 1 ? 110 : 100,
                              titleStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // KETERANGAN (LEGEND)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIndicator(
                          color: Colors.blue,
                          text:
                              'Selesai (${completedPercentage.toStringAsFixed(0)}%)',
                          isSquare: false,
                        ),
                        const SizedBox(width: 24),
                        _buildIndicator(
                          color: Colors.grey.shade300,
                          text:
                              'Belum (${pendingPercentage.toStringAsFixed(0)}%)',
                          isSquare: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // MOTIVASI TEXT
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).cardTheme.color ??
                            Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        completedCount == total
                            ? "Luar biasa! Semua tugas selesai."
                            : "Ayo selesaikan $pendingCount tugas lagi!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required Color color,
    required String text,
    required bool isSquare,
    double size = 16,
    Color? textColor,
  }) {
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

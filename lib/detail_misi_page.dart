import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailMisiPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const DetailMisiPage({super.key, required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    // Parse Dates
    Timestamp? deadline = data['deadline'];
    String deadlineStr = "-";
    if (deadline != null) {
      final dt = deadline.toDate();
      deadlineStr =
          "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    // Base64 Image
    final String? fotoBase64 = data['foto_base64'];

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Tugas"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. FOTO BESAR (JIKA ADA)
            if (fotoBase64 != null && fotoBase64.isNotEmpty)
              Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[200],
                child: Image.memory(
                  base64Decode(fotoBase64),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (ctx, err, stack) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. JUDUL & STATUS CHECKBOX
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['judul'] ?? "Tanpa Judul",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Ikon status (Selesai/Belum) - Hanya visual di detail
                      Icon(
                        (data['sudahSelesai'] ?? false)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 3. KATEGORI & DEADLINE
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['kategori'] ?? "Umum",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        deadlineStr,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const Divider(height: 30),

                  // 4. DESKRIPSI
                  const Text(
                    "Deskripsi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (data['deskripsi'] != null &&
                            data['deskripsi'].toString().isNotEmpty)
                        ? data['deskripsi']
                        : "Tidak ada deskripsi tambahan.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

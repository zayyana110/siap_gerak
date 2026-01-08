import 'dart:io';
import 'dart:convert'; // WAJIB: Untuk ubah foto jadi teks
import 'dart:typed_data'; // WAJIB: Untuk menampilkan foto dari teks
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class KelolaPage extends StatefulWidget {
  const KelolaPage({super.key});

  @override
  State<KelolaPage> createState() => _KelolaPageState();
}

class _KelolaPageState extends State<KelolaPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _misiController = TextEditingController();
  final TextEditingController _kategoriBaruController = TextEditingController();

  String _kategoriAktif = '';
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _cekKategoriAwal();
  }

  void _cekKategoriAwal() async {
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('kategori')
        .get();

    if (snapshot.docs.isEmpty) {
      await _tambahKategoriDatabase("Umum");
      if (mounted) setState(() => _kategoriAktif = "Umum");
    } else {
      if (mounted) setState(() => _kategoriAktif = snapshot.docs.first['nama']);
    }
  }

  // --- CRUD MISI (VERSI BASE64 - TANPA STORAGE) ---
  void _tambahMisi() async {
    if (_misiController.text.isNotEmpty &&
        user != null &&
        _kategoriAktif.isNotEmpty) {
      String? imageBase64;

      // 1. Ubah Foto jadi Kode Teks (Base64)
      if (_selectedImage != null) {
        List<int> imageBytes = await _selectedImage!.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

      // 2. Simpan ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('misi')
          .add({
            'judul': _misiController.text,
            'sudahSelesai': false,
            'kategori': _kategoriAktif,
            'createdAt': FieldValue.serverTimestamp(),
            'deadline': Timestamp.fromDate(_selectedDate),
            'foto_base64': imageBase64, // Simpan teks panjang ini
          });

      // Reset
      _misiController.clear();
      _selectedImage = null;

      if (mounted) Navigator.pop(context);
    }
  }

  void _ubahStatus(String id, bool status) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('misi')
          .doc(id)
          .update({'sudahSelesai': status});
    }
  }

  void _hapusMisi(String id) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('misi')
          .doc(id)
          .delete();
    }
  }

  Future<void> _tambahKategoriDatabase(String nama) async {
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('kategori')
          .add({'nama': nama, 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  void _hapusKategori(String id, String namaKategori) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('kategori')
          .doc(id)
          .delete();
      if (_kategoriAktif == namaKategori) {
        _cekKategoriAwal();
      }
    }
  }

  // --- DIALOG TAMBAH MISI ---
  void _dialogTambahMisi() async {
    _selectedDate = DateTime.now();
    _selectedImage = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> pickImage() async {
            final ImagePicker picker = ImagePicker();
            // PENTING: imageQuality diperkecil (20) agar Firestore tidak penuh/error
            final XFile? image = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 20,
            );
            if (image != null) {
              setStateDialog(() {
                _selectedImage = File(image.path);
              });
            }
          }

          return AlertDialog(
            title: Text('Misi di $_kategoriAktif'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _misiController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Apa targetmu?',
                    ),
                  ),
                  const SizedBox(height: 15),

                  // PILIH TANGGAL
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setStateDialog(() => _selectedDate = picked);
                          }
                        },
                        child: Text(
                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  // TOMBOL & PREVIEW FOTO
                  const SizedBox(height: 10),
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () =>
                                setStateDialog(() => _selectedImage = null),
                            child: const CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 12,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              "Foto (Kecil/Opsional)",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 5),
                  const Text(
                    "*Foto akan dikompres agar ringan",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _tambahMisi();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _dialogTambahKategori() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Baru'),
        content: TextField(
          controller: _kategoriBaruController,
          decoration: const InputDecoration(hintText: 'Misal: Olahraga'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_kategoriBaruController.text.isNotEmpty) {
                _tambahKategoriDatabase(_kategoriBaruController.text);
                _kategoriBaruController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text(_kategoriAktif.isEmpty ? "SiapGerak" : _kategoriAktif),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepOrange),
              accountName: Text(user?.displayName ?? "User"),
              accountEmail: Text(user?.email ?? ""),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(user?.photoURL ?? ""),
                backgroundColor: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "KATEGORI SAYA",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.deepOrange,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _dialogTambahKategori();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('kategori')
                    .orderBy('createdAt')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  var cats = snapshot.data!.docs;
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: cats.length,
                    itemBuilder: (context, index) {
                      var data = cats[index].data() as Map<String, dynamic>;
                      var id = cats[index].id;
                      return ListTile(
                        leading: const Icon(Icons.label_outline),
                        title: Text(data['nama']),
                        selected: _kategoriAktif == data['nama'],
                        selectedColor: Colors.deepOrange,
                        onTap: () {
                          setState(() => _kategoriAktif = data['nama']);
                          Navigator.pop(context);
                        },
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onPressed: () => _hapusKategori(id, data['nama']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: _kategoriAktif.isEmpty
          ? const Center(child: Text("Buat kategori dulu di menu samping!"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('misi')
                  .where('kategori', isEqualTo: _kategoriAktif)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Text("Belum ada misi di $_kategoriAktif"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;

                    // Ambil string Base64 (bukan URL)
                    final String? fotoBase64 = data['foto_base64'];

                    Timestamp? deadline = data['deadline'];
                    String tglStr = deadline != null
                        ? "${deadline.toDate().day}/${deadline.toDate().month}"
                        : "";

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. TAMPILKAN FOTO DARI KODE BASE64
                          if (fotoBase64 != null && fotoBase64.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              // Decode Base64 jadi Gambar
                              child: Image.memory(
                                base64Decode(fotoBase64),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            ),

                          // 2. DATA LAINNYA
                          ListTile(
                            leading: Checkbox(
                              value: data['sudahSelesai'] ?? false,
                              activeColor: Colors.deepOrange,
                              onChanged: (val) => _ubahStatus(id, val!),
                            ),
                            title: Text(
                              data['judul'] ?? "",
                              style: TextStyle(
                                decoration: (data['sudahSelesai'] ?? false)
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: (data['sudahSelesai'] ?? false)
                                    ? Colors.grey
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: tglStr.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          tglStr,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () => _hapusMisi(id),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _kategoriAktif.isNotEmpty ? _dialogTambahMisi : null,
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

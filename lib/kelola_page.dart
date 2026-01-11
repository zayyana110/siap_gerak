import 'dart:io';
import 'dart:convert'; // WAJIB: Untuk ubah foto jadi teks
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'statistic_page.dart';
import 'detail_misi_page.dart';
import 'gamification_provider.dart';
import 'gamification_page.dart'; // Import halaman gamifikasi
import 'task_model.dart'; // Import Model Task
import 'notification_service.dart'; // Import NotificationService

class KelolaPage extends StatefulWidget {
  const KelolaPage({super.key});

  @override
  State<KelolaPage> createState() => _KelolaPageState();
}

class _KelolaPageState extends State<KelolaPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _misiController = TextEditingController();
  final TextEditingController _deskripsiController =
      TextEditingController(); // Controller deskripsi
  final TextEditingController _kategoriBaruController = TextEditingController();

  String _kategoriAktif = '';
  String _filterHari = 'Semua'; // Filter Waktu
  DateTime _selectedDate = DateTime.now();
  TaskPriority _selectedPriority = TaskPriority.sedang;
  ReminderOffset? _selectedReminder; // State Filter Pengingat
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
        .get(); // Ambil semua, jangan filter orderBy di query

    if (snapshot.docs.isEmpty) {
      await _tambahKategoriDatabase("Umum");
      if (mounted) setState(() => _kategoriAktif = "Umum");
    } else {
      // Sort manual: CreatedAt ascending (Oldest first)
      final docs = snapshot.docs;
      docs.sort((a, b) {
        final Map<String, dynamic> dataA = a.data();
        final Map<String, dynamic> dataB = b.data();
        Timestamp? tA = dataA['createdAt'];
        Timestamp? tB = dataB['createdAt'];
        if (tA == null) return -1; // Null = Oldest
        if (tB == null) return 1;
        return tA.compareTo(tB);
      });

      if (mounted) setState(() => _kategoriAktif = docs.first['nama']);
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
      try {
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('misi')
            .add({
              'judul': _misiController.text,
              'deskripsi': _deskripsiController.text,
              'sudahSelesai': false,
              'kategori': _kategoriAktif,
              'createdAt': FieldValue.serverTimestamp(),
              'deadline': Timestamp.fromDate(_selectedDate),
              'foto_base64': imageBase64,
              'prioritas': getPriorityText(_selectedPriority),
              'reminderOffset': _selectedReminder?.name, // Simpan Enum Name
            });

        // 3. Jadwalkan Notifikasi (Jika ada reminder)
        if (_selectedReminder != null) {
          Task newTask = Task(
            id: docRef.id,
            judul: _misiController.text,
            deskripsi: _deskripsiController.text,
            sudahSelesai: false,
            kategori: _kategoriAktif,
            deadline: Timestamp.fromDate(_selectedDate),
            priority: _selectedPriority,
            reminderOffset: _selectedReminder,
          );
          await NotificationService().scheduleNotification(newTask);
        }

        // Reset
        _misiController.clear();
        _deskripsiController.clear(); // Reset deskripsi
        _selectedImage = null;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tugas berhasil disimpan!"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menyimpan: $e"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _ubahStatus(String id, bool status) {
    if (user != null) {
      // LOGIKA GAMIFIKASI (XP)
      if (status) {
        // Jika selesai
        final gamification = Provider.of<GamificationProvider>(
          context,
          listen: false,
        );
        bool naikLevel = gamification.completeTask(); // Tambah XP

        if (naikLevel) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selamat! Anda naik ke Level ${gamification.currentLevel}. ${gamification.currentTitle}!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

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
  void dialogTambahMisi() async {
    _selectedDate = DateTime.now();
    _selectedPriority = TaskPriority.sedang;
    _selectedImage = null;
    _misiController.clear();
    _deskripsiController.clear(); // Reset deskripsi
    _selectedReminder = null; // Reset Reminder

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> pickImage() async {
            final ImagePicker picker = ImagePicker();
            // PENTING: imageQuality diperkecil (20) agar Firestore tidak penuh/error
            // Tambahkan maxWidth utk memastikan ukuran file kecil
            final XFile? image = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 20,
              maxWidth: 600,
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
                      labelText: 'Judul Tugas',
                    ),
                  ),
                  const SizedBox(height: 10),
                  // INPUT DESKRIPSI
                  TextField(
                    controller: _deskripsiController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Tambahkan detail (opsional)',
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // PILIH TANGGAL & WAKTU
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              _selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                _selectedDate.hour,
                                _selectedDate.minute,
                              );
                            });
                          }
                        },
                        child: Text(
                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // TIME PICKER
                      const Icon(
                        Icons.access_time_filled,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedDate),
                            builder: (BuildContext context, Widget? child) {
                              return MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null) {
                            setStateDialog(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        },
                        child: Text(
                          "${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // PILIH PRIORITAS
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Prioritas',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                    ),
                    items: TaskPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: getPriorityColor(priority)),
                            const SizedBox(width: 8),
                            Text(getPriorityText(priority)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() => _selectedPriority = val);
                      }
                    },
                  ),
                  const SizedBox(height: 15),

                  // PILIH PENGINGAT (REMINDER)
                  DropdownButtonFormField<ReminderOffset?>(
                    initialValue: _selectedReminder,
                    decoration: const InputDecoration(
                      labelText: 'Pengingat (Opsional)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      prefixIcon: Icon(
                        Icons.notifications_active,
                        color: Colors.blue,
                      ),
                    ),
                    items: [
                      // Opsi Null / Tanpa Pengingat
                      const DropdownMenuItem<ReminderOffset?>(
                        value: null,
                        child: Text("Tanpa Pengingat"),
                      ),
                      ...ReminderOffset.values.map((offset) {
                        return DropdownMenuItem<ReminderOffset?>(
                          value: offset,
                          child: Text(getReminderText(offset)),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setStateDialog(() => _selectedReminder = val);
                    },
                  ),

                  // TOMBOL & PREVIEW FOTO
                  const SizedBox(height: 10),
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                      Text(
                                        "Gagal memuat gambar",
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              accountName: Text(user?.displayName ?? "User"),
              accountEmail: Text(user?.email ?? ""),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(user?.photoURL ?? ""),
                backgroundColor: Colors.white,
              ),
            ),
            // MENU STATISTIK
            ListTile(
              leading: const Icon(Icons.pie_chart_outline, color: Colors.blue),
              title: const Text("Statistik"),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticPage(),
                  ),
                );
              },
            ),
            // MENU GAME / LEVEL
            ListTile(
              leading: const Icon(
                Icons.emoji_events_outlined,
                color: Colors.blue,
              ),
              title: const Text("Level & Rewards"),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GamificationPage(),
                  ),
                );
              },
            ),
            const Divider(),
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
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
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
                    .snapshots(), // Hapus orderBy
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Sort manual
                  var cats = snapshot.data!.docs;
                  cats.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    Timestamp? tA = dataA['createdAt'];
                    Timestamp? tB = dataB['createdAt'];
                    if (tA == null) return -1;
                    if (tB == null) return 1;
                    return tA.compareTo(tB);
                  });

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
                        selectedColor: Colors.blue,
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
                  .snapshots(), // Hapus orderBy di query karena kita sort manual di client
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 1. Convert ke Model Task
                List<Task> tasks = snapshot.data!.docs
                    .map(
                      (doc) => Task.fromMap(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();

                // 2. Urutkan (Sorting)
                tasks = urutkanTugas(tasks);

                // 3. Filter Waktu
                if (_filterHari == 'Hari Ini') {
                  final now = DateTime.now();
                  tasks = tasks.where((t) {
                    if (t.deadline == null) return false;
                    final d = t.deadline!.toDate();
                    return d.day == now.day &&
                        d.month == now.month &&
                        d.year == now.year;
                  }).toList();
                } else if (_filterHari == 'Besok') {
                  final now = DateTime.now().add(const Duration(days: 1));
                  tasks = tasks.where((t) {
                    if (t.deadline == null) return false;
                    final d = t.deadline!.toDate();
                    return d.day == now.day &&
                        d.month == now.month &&
                        d.year == now.year;
                  }).toList();
                }

                // UI LIST
                return Column(
                  children: [
                    // FILTER CHIPS
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _buildFilterChip('Semua'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Hari Ini'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Besok'),
                        ],
                      ),
                    ),

                    if (tasks.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text("Tidak ada tugas ($_filterHari)"),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];

                            // Date Formatting
                            String tglStr = "";
                            if (task.deadline != null) {
                              final dt = task.deadline!.toDate();
                              final datePart = "${dt.day}/${dt.month}";
                              final timePart =
                                  "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                              tglStr = "$datePart $timePart";
                            }

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // Reconstruct Map for Detail Page (Backward Compatibility)
                                  // Or update DetailPage to accept Task object.
                                  // For now, pass Map.
                                  // But we need the original map or reconstruct it.
                                  // Getting data from snapshot directly is safer if we want exact fields,
                                  // but using Task object fields is fine too.
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailMisiPage(
                                        data: {
                                          'judul': task.judul,
                                          'deskripsi': task.deskripsi,
                                          'sudahSelesai': task.sudahSelesai,
                                          'kategori': task.kategori,
                                          'deadline': task.deadline,
                                          'foto_base64': task.fotoBase64,
                                          'prioritas': getPriorityText(
                                            task.priority,
                                          ),
                                        },
                                        docId: task.id,
                                      ),
                                    ),
                                  );
                                },
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      // INDIKATOR PRIORITAS (Garis Warna di Kiri)
                                      Container(
                                        width: 6,
                                        decoration: BoxDecoration(
                                          color: getPriorityColor(
                                            task.priority,
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (task.fotoBase64 != null &&
                                                task.fotoBase64!.isNotEmpty)
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topRight: Radius.circular(
                                                        12,
                                                      ),
                                                    ),
                                                child: Image.memory(
                                                  base64Decode(
                                                    task.fotoBase64!,
                                                  ),
                                                  height: 150,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  gaplessPlayback: true,
                                                ),
                                              ),

                                            ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              leading: Checkbox(
                                                value: task.sudahSelesai,
                                                activeColor: Colors.blue,
                                                onChanged: (val) =>
                                                    _ubahStatus(task.id, val!),
                                              ),
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      task.judul,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        decoration:
                                                            task.sudahSelesai
                                                            ? TextDecoration
                                                                  .lineThrough
                                                            : TextDecoration
                                                                  .none,
                                                        color: task.sudahSelesai
                                                            ? (Theme.of(
                                                                        context,
                                                                      ).brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors
                                                                        .grey
                                                                        .shade400
                                                                  : Colors.grey)
                                                            : (Theme.of(context)
                                                                      .textTheme
                                                                      .bodyLarge
                                                                      ?.color ??
                                                                  Colors.black),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // CHIP PRIORITAS
                                                  if (!task.sudahSelesai)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: getPriorityColor(
                                                          task.priority,
                                                        ).withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              getPriorityColor(
                                                                task.priority,
                                                              ),
                                                          width: 0.5,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        getPriorityText(
                                                          task.priority,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              getPriorityColor(
                                                                task.priority,
                                                              ),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              subtitle: tglStr.isNotEmpty
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 4,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .calendar_today,
                                                            size: 12,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            tglStr,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                ),
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
                                                onPressed: () =>
                                                    _hapusMisi(task.id),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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

  Widget _buildFilterChip(String label) {
    bool isSelected = _filterHari == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterHari = label;
          });
        }
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.blue
            : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

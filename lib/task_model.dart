import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TaskPriority { tinggi, sedang, rendah }

enum ReminderOffset { atDeadline, fiveMinutes, tenMinutes, oneHour, oneDay }

class Task {
  final String id;
  final String judul;
  final String deskripsi;
  final bool sudahSelesai;
  final String kategori;
  final Timestamp? deadline;
  final String? fotoBase64;
  final TaskPriority priority;
  final ReminderOffset? reminderOffset; // Field Baru

  Task({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.sudahSelesai,
    required this.kategori,
    this.deadline,
    this.fotoBase64,
    required this.priority,
    this.reminderOffset,
  });

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    TaskPriority getPriority(String? p) {
      if (p == 'Tinggi') return TaskPriority.tinggi;
      if (p == 'Sedang') return TaskPriority.sedang;
      return TaskPriority.rendah;
    }

    ReminderOffset? getReminderOffset(String? r) {
      if (r == 'atDeadline') return ReminderOffset.atDeadline;
      if (r == 'fiveMinutes') return ReminderOffset.fiveMinutes;
      if (r == 'tenMinutes') return ReminderOffset.tenMinutes;
      if (r == 'oneHour') return ReminderOffset.oneHour;
      if (r == 'oneDay') return ReminderOffset.oneDay;
      return null;
    }

    return Task(
      id: id,
      judul: map['judul'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      sudahSelesai: map['sudahSelesai'] ?? false,
      kategori: map['kategori'] ?? '',
      deadline: map['deadline'],
      fotoBase64: map['foto_base64'],
      priority: getPriority(map['prioritas']),
      reminderOffset: getReminderOffset(map['reminderOffset']),
    );
  }
}

List<Task> urutkanTugas(List<Task> tasks) {
  tasks.sort((a, b) {
    // 1. Selesai di Bawah
    if (a.sudahSelesai != b.sudahSelesai) {
      return a.sudahSelesai ? 1 : -1;
    }

    // 2. Prioritas (Tinggi < Sedang < Rendah) -> index 0 < 1 < 2
    if (a.priority.index != b.priority.index) {
      return a.priority.index.compareTo(b.priority.index);
    }

    // 3. Deadline (Terdekat lebih dulu)
    if (a.deadline != null && b.deadline != null) {
      return a.deadline!.compareTo(b.deadline!);
    } else if (a.deadline != null) {
      return -1; // Ada deadline lebih prioritas dari null
    } else if (b.deadline != null) {
      return 1;
    }

    return 0;
  });
  return tasks;
}

Color getPriorityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.tinggi:
      return Colors.red;
    case TaskPriority.sedang:
      return const Color(0xFFFFCB47); // Golden Pollen
    case TaskPriority.rendah:
      return const Color(0xFF2563EB); // Royal Blue
  }
}

String getPriorityText(TaskPriority p) {
  switch (p) {
    case TaskPriority.tinggi:
      return 'Tinggi';
    case TaskPriority.sedang:
      return 'Sedang';
    case TaskPriority.rendah:
      return 'Rendah';
  }
}

String getReminderText(ReminderOffset r) {
  switch (r) {
    case ReminderOffset.atDeadline:
      return 'Saat Deadline';
    case ReminderOffset.fiveMinutes:
      return '5 Menit Sebelum';
    case ReminderOffset.tenMinutes:
      return '10 Menit Sebelum';
    case ReminderOffset.oneHour:
      return '1 Jam Sebelum';
    case ReminderOffset.oneDay:
      return '1 Hari Sebelum';
  }
}

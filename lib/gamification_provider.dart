import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_constants.dart';

class GamificationProvider extends ChangeNotifier {
  int _currentLevel = 1;
  int _currentXP = 0;

  // XP yang dibutuhkan untuk naik ke level berikutnya
  int get xpTarget => _currentLevel * 200;

  int get currentLevel => _currentLevel;
  int get currentXP => _currentXP;

  String get currentTitle {
    if (_currentLevel <= 5) return 'Productivity Newbie';
    if (_currentLevel <= 10) return 'Task Master';
    return 'Productivity Ninja';
  }

  // PROGRESS THEME
  // Level 1: Light (Default)
  bool get isDarkThemeUnlocked => _currentLevel >= 3;
  // Level 7: Midnight
  bool get isMidnightThemeUnlocked => _currentLevel >= 7;

  ThemeData _currentTheme = AppThemes.lightTheme;
  ThemeData get currentTheme => _currentTheme;

  GamificationProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLevel = prefs.getInt('level') ?? 1;
    _currentXP = prefs.getInt('xp') ?? 0;

    // Load saved theme preference if complex,
    // but for now we default to Light or stick to the unlocked logic.
    // Let's allow users to switch themes only if unlocked,
    // but defaulting to Light on startup is fine for this scope.
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', _currentLevel);
    await prefs.setInt('xp', _currentXP);
  }

  // Returns true if leveled up
  bool completeTask() {
    _currentXP += 20;
    bool leveledUp = false;

    // Cek apakah naik level
    if (_currentXP >= xpTarget) {
      _currentXP -= xpTarget; // Reset XP bucket (sisa XP dibawa ke level baru)
      _currentLevel += 1;
      leveledUp = true;
    }

    _saveData();
    notifyListeners();
    return leveledUp;
  }

  void setTheme(ThemeData theme) {
    _currentTheme = theme;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'gamification_provider.dart';
import 'theme_constants.dart';

class GamificationPage extends StatelessWidget {
  const GamificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Level & Rewards")),
      body: Consumer<GamificationProvider>(
        builder: (context, game, child) {
          // Prevent division by zero just in case
          double progress = game.xpTarget > 0
              ? game.currentXP / game.xpTarget
              : 0.0;
          if (progress > 1.0) progress = 1.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. INFO LEVEL
              Card(
                color: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        "LEVEL SAAT INI",
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${game.currentLevel}",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        game.currentTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.blue.shade800,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${game.currentXP} XP",
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            "${game.xpTarget} XP",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${game.xpTarget - game.currentXP} XP lagi untuk naik level",
                        style: TextStyle(
                          color: Colors.blue.shade100,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. THEMES & REWARDS
              const Text(
                "Tema & Hadiah",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Note: We check reference equality for themes
              _buildThemeItem(
                context,
                game,
                "Light Theme",
                1,
                AppThemes.lightTheme,
              ),
              _buildThemeItem(
                context,
                game,
                "Dark Theme",
                3,
                AppThemes.darkTheme,
              ),
              _buildThemeItem(
                context,
                game,
                "Midnight Blue",
                7,
                AppThemes.midnightBlueTheme,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeItem(
    BuildContext context,
    GamificationProvider game,
    String name,
    int unlockLevel,
    ThemeData theme,
  ) {
    bool isUnlocked = game.currentLevel >= unlockLevel;
    bool isCurrent = game.currentTheme == theme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUnlocked
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isUnlocked ? Icons.palette : Icons.lock,
            color: isUnlocked ? Colors.blue : Colors.grey,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUnlocked ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          isUnlocked ? "Tersedia" : "Buka di Level $unlockLevel",
          style: TextStyle(color: isUnlocked ? Colors.green : Colors.grey),
        ),
        trailing: isUnlocked
            ? ElevatedButton(
                onPressed: isCurrent ? null : () => game.setTheme(theme),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(isCurrent ? "Aktif" : "Pakai"),
              )
            : const SizedBox(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'active_workout_screen.dart';
import 'api_client.dart';
import 'app_theme.dart';
import 'coach_chat_screen.dart';
import 'equipment_screen.dart';
import 'health_screen.dart';
import 'history_screen.dart';
import 'home_dashboard.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'train_screen.dart';
import 'workout_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;

  static const titles = ['', 'Train', '', 'Progress', 'History'];
  static const coachTab = 2;
  static const historyTab = 4;

  void open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> syncNow() async {
    final ok = await WorkoutStore.instance.refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.lime : AppColors.danger,
        content: Text(
          ok ? 'Synced with the server' : WorkoutStore.instance.syncError ?? 'Sync failed',
          style: TextStyle(
            color: ok ? AppColors.onLime : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will return to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ApiClient.instance.logout();
              await WorkoutStore.instance.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget buildSyncButton() {
    return ListenableBuilder(
      listenable: WorkoutStore.instance,
      builder: (context, _) {
        final store = WorkoutStore.instance;
        if (store.isSyncing) {
          return const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final pending = store.unsyncedCount;
        final problem = store.syncError != null;
        return IconButton(
          tooltip: pending > 0 ? '$pending not synced' : 'Sync with server',
          onPressed: syncNow,
          icon: Badge(
            isLabelVisible: pending > 0,
            backgroundColor: AppColors.warning,
            label: Text('$pending'),
            child: Icon(
              problem ? Icons.cloud_off : Icons.cloud_done_outlined,
              color: problem ? AppColors.warning : AppColors.lime,
            ),
          ),
        );
      },
    );
  }

  Widget buildDrawer() {
    final email = ApiClient.instance.email ?? '';
    final name = email.isEmpty ? 'Repify' : email.split('@').first;

    Widget item(IconData icon, String title, VoidCallback onTap) => ListTile(
          leading: Icon(icon, color: AppColors.lime),
          title: Text(title, style: const TextStyle(color: AppColors.text)),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
        );

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: limeCardDecoration(radius: 24),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.onLime,
                    child: Icon(Icons.person, color: AppColors.lime, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.onLime,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.onLime.withAlpha(170), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            item(Icons.person_outline, 'Profile', () => open(const ProfileScreen())),
            item(Icons.photo_camera_outlined, 'Equipment scanner', () => open(const EquipmentScreen())),
            item(Icons.favorite_border, 'Health Connect', () => open(const HealthScreen())),
            item(Icons.settings_outlined, 'Settings', () => open(const SettingsScreen())),
            const Divider(),
            item(Icons.logout, 'Log Out', confirmLogout),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeDashboard(
        onStartWorkout: () => open(const ActiveWorkoutScreen()),
        onSeeAll: () => setState(() => selectedIndex = historyTab),
        onScanEquipment: () => open(const EquipmentScreen()),
        onOpenMenu: () => scaffoldKey.currentState?.openDrawer(),
        onOpenCoach: () => setState(() => selectedIndex = coachTab),
        syncButton: buildSyncButton(),
      ),
      TrainScreen(onOpenHistory: () => setState(() => selectedIndex = historyTab)),
      CoachChatScreen(onOpenMenu: () => scaffoldKey.currentState?.openDrawer()),
      const ProgressScreen(),
      const HistoryScreen(),
    ];

    return Scaffold(
      key: scaffoldKey,
      // Home and Coach draw their own header, the other tabs get a simple title.
      appBar: selectedIndex == 0 || selectedIndex == coachTab
          ? null
          : AppBar(
              title: Text(titles[selectedIndex]),
              actions: [buildSyncButton()],
            ),
      drawer: buildDrawer(),
      body: SafeArea(
        bottom: false,
        child: tabs[selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => setState(() => selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Train',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Coach',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}

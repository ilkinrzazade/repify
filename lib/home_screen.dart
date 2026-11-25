import 'package:flutter/material.dart';

import 'active_workout_screen.dart';
import 'add_workout_screen.dart';
import 'api_client.dart';
import 'history_screen.dart';
import 'home_dashboard.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'workout_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  Future<void> syncNow() async {
    final ok = await WorkoutStore.instance.refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? Colors.green.shade700 : Colors.red,
        content: Text(
          ok ? 'Synced with the server' : WorkoutStore.instance.syncError ?? 'Sync failed',
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

  Widget buildHomeTab() {
    return HomeDashboard(
      onStartWorkout: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
        );
      },
      onSeeAll: () => setState(() => selectedIndex = 3),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          );
        }
        final pending = store.unsyncedCount;
        return IconButton(
          tooltip: pending > 0 ? '$pending not synced' : 'Sync with server',
          onPressed: syncNow,
          icon: Badge(
            isLabelVisible: pending > 0,
            label: Text('$pending'),
            child: Icon(store.syncError != null ? Icons.sync_problem : Icons.cloud_done_outlined),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = ApiClient.instance.email ?? '';
    final List<Widget> tabs = [
      buildHomeTab(),
      AddWorkoutScreen(onSaved: () => setState(() => selectedIndex = 0)),
      const ProgressScreen(),
      const HistoryScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repify'),
        actions: [buildSyncButton()],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(email.isEmpty ? 'Repify' : email.split('@').first),
              accountEmail: Text(email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.deepPurple, size: 40),
              ),
              decoration: const BoxDecoration(color: Colors.deepPurple),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () {
                Navigator.pop(context);
                confirmLogout();
              },
            ),
          ],
        ),
      ),
      body: tabs[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}

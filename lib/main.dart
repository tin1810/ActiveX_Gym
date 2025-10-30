import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/home_page.dart';
import 'screens/workouts_page.dart';
import 'screens/progress_page.dart';
import 'screens/profile_page.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const ActiveXGymApp());
}

class ActiveXGymApp extends StatelessWidget {
  const ActiveXGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ActiveX Gym App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const WorkoutsPage(),
    const ProgressPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 ? const Color(0xFF4CAF50) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home,
                  color: _currentIndex == 0 ? Colors.white : Colors.grey,
                  size: 22,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.fitness_center,
                color: _currentIndex == 1 ? const Color(0xFF4CAF50) : Colors.grey,
              ),
              label: 'Workouts',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.bar_chart,
                color: _currentIndex == 2 ? const Color(0xFF4CAF50) : Colors.grey,
              ),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: _currentIndex == 3 ? const Color(0xFF4CAF50) : Colors.grey,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}


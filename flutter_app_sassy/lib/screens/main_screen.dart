import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sassy/screens/teacher/create_material_screen.dart';
import 'package:sassy/screens/student/student_dashboard_screen.dart';
import 'package:sassy/screens/student/student_notification_screen.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:sassy/widgets/sidebar.dart'; 
import 'package:sassy/screens/teacher/dashboard_screen.dart';
import 'package:sassy/screens/teacher/materials_screen.dart';
import 'package:sassy/screens/teacher/students_screen.dart';
import 'package:sassy/screens/teacher/settings_screen.dart';
import 'package:sassy/screens/admin/teachers_screen.dart';
import 'package:sassy/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final SidebarXController _controller = SidebarXController(selectedIndex: 0);
  String? _userRole;
  String? _userName;
  Timer? _activityTimer;
  late List<Widget> _pages;

  // Pridanie kľúča pre scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _activityTimer?.cancel();
    super.dispose();
  }

  void _startUserActivityLoop() {
    _activityTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final apiService = ApiService();
      await apiService.recordUserActivity();
    });
  }

  Future<void> _loadUserRole() async {
    final apiService = ApiService();
    final userData = await apiService.getCurrentUser();
    if (userData != null && mounted) {
      setState(() {
        _userRole = userData['user']['role'];
        _userName = userData['user']['name'];
        _initPagesBasedOnRole();
      });
    }
  }

  void _initPagesBasedOnRole() {
    // Inicializácia stránok na základe role používateľa
    if (_userRole == 'student') {
      _pages = [
        StudentDashboardScreen(),
        StudentNotificationPage(),
      ];
      _selectedIndex = 0;
      _controller.selectIndex(0);
    } else if (_userRole == 'teacher' || _userRole == 'admin') {
      // Stránky pre učiteľa a admina
      List<Widget> teacherPages = [
        DashboardPage(),
        TemplatesPage(),
        StudentsPage(),
        SettingsPage(),
      ];

      // Pridanie stránky pre admina
      if (_userRole == 'admin') {
        teacherPages.add(TeachersPage());
      }

      // Vytvorenie úlohy na konci zoznamu
      teacherPages.add(CreateTaskScreen(onTaskSubmitted: _onTaskSubmitted));

      _pages = teacherPages;
      _selectedIndex = 0;
      _controller.selectIndex(0);
    }
  }

  void _onItemSelected(int index) {
    final int maxIndex = _pages.length - 1;

    if (_userRole == 'student') {
      if (index <= 1) {
        setState(() {
          _selectedIndex = index;
          _controller.selectIndex(index);
        });
      }
    } else if (_userRole == 'teacher') {
      // Učitelia nemajú prístup k správe učiteľov
      if (index == 4) {
        // Ak sa pokúšajú pristupovať k správe učiteľov, presmerujeme ich na dashboard
        setState(() {
          _selectedIndex = 0;
          _controller.selectIndex(0);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nemáte oprávnenie pre zobrazenie tejto stránky')),
        );
      } else if (index == 5) {
        // Vytvorenie úlohy je posledná stránka
        setState(() {
          _selectedIndex = maxIndex;
          _controller.selectIndex(-1);
        });
      } else if (index < maxIndex) {
        setState(() {
          _selectedIndex = index;
          _controller.selectIndex(index);
        });
      }
    } else if (_userRole == 'admin') {
      if (index == 5) {
        // Vytvorenie úlohy je posledná stránka
        setState(() {
          _selectedIndex = maxIndex;
          _controller.selectIndex(-1);
        });
      } else if (index <= maxIndex) {
        setState(() {
          _selectedIndex = index;
          _controller.selectIndex(index);
        });
      }
    }
  }

  void _onTaskSubmitted() {
    setState(() {
      _selectedIndex = 0;
      _controller.selectIndex(0);
    });
  }

  void _startTokenValidationLoop() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 1));
      final apiService = ApiService();
      final isValid = await apiService.isTokenValid();
      if (!isValid) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return false;
      }
      return true;
    });
  }

  @override
  void initState() {
    super.initState();
    _startTokenValidationLoop();

    _pages = [
      const Center(child: CircularProgressIndicator()),
    ];

    _loadUserRole();
    _startUserActivityLoop();
  }

  @override
  Widget build(BuildContext context) {
    // Získanie šírky obrazovky pre responzívne rozloženie
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktopMode = screenWidth > 768;

    // Kontrola, či sú stránky inicializované
    final contentWidget = _pages.isEmpty || _selectedIndex >= _pages.length
        ? const Center(child: CircularProgressIndicator())
        : _pages[_selectedIndex];

    if (isDesktopMode) {
      // Desktop rozloženie - side-by-side
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 247, 230, 217),
        body: Row(
          children: [
            // Používame ResponsiveSidebar
            ResponsiveSidebar(
              controller: _controller,
              onItemSelected: _onItemSelected,
              userRole: _userRole ?? 'student',
              userName: _userName ?? 'Unknown',
            ),
            const SizedBox(width: 16),
            Expanded(
              child: contentWidget,
            ),
          ],
        ),
      );
    } else {
      // Mobilné rozloženie - obsah s hamburger menu
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color.fromARGB(255, 247, 230, 217),
        body: ResponsiveSidebar(
          controller: _controller,
          onItemSelected: _onItemSelected,
          userRole: _userRole ?? 'student',
          userName: _userName ?? 'Unknown',
          child: contentWidget,
        ),
      );
    }
  }
}
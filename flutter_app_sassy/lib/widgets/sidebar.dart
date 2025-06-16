import 'package:flutter/material.dart';
import 'package:sassy/screens/teacher/login_screen.dart';
import 'package:sassy/screens/teacher/materials_screen.dart';
import 'package:sassy/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebarx/sidebarx.dart';

import '../services/socket_service.dart';

class ResponsiveSidebar extends StatefulWidget {
  final SidebarXController controller;
  final Function(int) onItemSelected;
  final String userRole;
  final String userName;
  final Widget? child;

  const ResponsiveSidebar({
    super.key,
    required this.controller,
    required this.onItemSelected,
    required this.userRole,
    required this.userName,
    this.child,
  });

  @override
  State<ResponsiveSidebar> createState() => _ResponsiveSidebarState();
}

class _ResponsiveSidebarState extends State<ResponsiveSidebar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

  Future<void> logout(BuildContext context) async {
    final apiService = ApiService();
    final socketService = SocketService();

    try {
      // Odhlásenie používateľa na serveri
      final success = await apiService.logoutUser();

      // Odpojenie socketu
      socketService.disconnect();

      // Vymazanie údajov zo SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('userRole');

      // Navigácia na prihlasovaciu obrazovku
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chyba pri odhlasovaní')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Získanie šírky obrazovky
    final screenWidth = MediaQuery.of(context).size.width;
    // Určenie módu zobrazenia (desktop/mobile) - hraničnú hodnotu môžete upraviť
    final bool isDesktopMode = screenWidth > 768;

    // Pre desktopový režim vracajte pôvodný Sidebar
    if (isDesktopMode) {
      return _buildSidebar();
    } 
    // Pre mobilný režim vracajte Drawer a AppBar s hamburger menu
    else {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: const Color(0xffffd3ad),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              setState(() {
                _isDrawerOpen = !_isDrawerOpen;
              });
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: const Text(
            "SASSY",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ),
        drawer: Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffffd3ad), Color(0xfff9dfc8)],
                stops: [0, 1],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerHeader(),
                ..._buildDrawerItems(),
              ],
            ),
          ),
        ),
        body: widget.child ?? Container(),
      );
    }
  }

  Widget _buildSidebar() {
    return SidebarX(
      controller: widget.controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        width: 80, // Nastavíme pevnú šírku pre collapsed stav
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffffd3ad), Color(0xfff9dfc8)],
            stops: [0, 1],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(30, 0, 0, 0),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        hoverColor: const Color.fromARGB(28, 0, 0, 0),
        hoverTextStyle: const TextStyle(color: Colors.black),
        textStyle: const TextStyle(color: Colors.black54, fontSize: 14, fontFamily: 'Inter'),
        selectedTextStyle: const TextStyle(color: Colors.black),

        itemMargin: const EdgeInsets.only(left:5, right: 5, top: 0, bottom: 0),
        itemPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        selectedItemPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        selectedItemMargin: const EdgeInsets.only(left:5, right: 5, top: 0, bottom: 0),
        itemTextPadding: const EdgeInsets.only(left: 30),
        selectedItemTextPadding: const EdgeInsets.only(left: 30),

        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(50, 0, 0, 0),
              Color.fromARGB(75, 2, 2, 2)
            ],
            transform: GradientRotation(1),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black54,
          size: 20,
        ),
        selectedIconTheme: const IconThemeData(
          color: Colors.black,
          size: 20,
        ),
      ),
      extendedTheme: const SidebarXTheme(
        width: 250, // Pevná šírka pre rozbalený stav
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffffd3ad), Color(0xfff9dfc8)],
            stops: [0, 1],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(30, 0, 0, 0),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      headerBuilder: (context, extended) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 20,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 5,),
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 25, color: Color(0xFFF4A261)),
                ),
                if (extended) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child:Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.black,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.userRole == 'teacher' ||  widget.userRole == 'admin' ? "UČITEĽ" : "ŠTUDENT",
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      items: widget.userRole == 'teacher' || widget.userRole == 'admin'
          ? _buildTeacherItems(context, widget.userRole, widget.onItemSelected)
          : _buildStudentItems(context, widget.onItemSelected),
      footerBuilder: (context, extended) {
        if (widget.userRole == 'teacher' || widget.userRole == 'admin') {
          if (extended) {
            // Plne rozbalený stav
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8EDE3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Začnime!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Vytváranie alebo pridávanie nových úloh",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: constraints.maxWidth,
                          child: TextButton.icon(
                            onPressed: () {
                              widget.onItemSelected(widget.userRole == 'admin' ? 5 : 4);
                            },
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                            label: const Text(
                              "Pridať novú úlohu",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 229, 127, 37),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            );
          } else {
            // Zabalený stav
            return Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    elevation: 0,
                    backgroundColor: const Color.fromARGB(255, 229, 127, 37),
                    onPressed: () {
                      widget.onItemSelected(widget.userRole == 'admin' ? 5 : 4);
                    },
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ),
            );
          }
        } else {
          return const SizedBox.shrink();
        }
      }
    );
  }

  // Vytvorenie hlavičky pre drawer
  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffffd3ad), Color(0xfff9dfc8)],
          stops: [0, 1],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: Color(0xFFF4A261)),
          ),
          const SizedBox(height: 10),
          Text(
            widget.userName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.black,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.userRole == 'teacher' || widget.userRole == 'admin' ? "UČITEĽ" : "ŠTUDENT",
            style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.2),
          ),
        ],
      ),
    );
  }

  // Vytvorenie položiek pre drawer
  List<Widget> _buildDrawerItems() {
    List<Widget> items = [];

    // Funkcia pre vytváranie jednotných položiek drawer menu
    Widget buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
      return ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontFamily: 'Inter',
          ),
        ),
        onTap: () {
          // Zavrieť drawer po kliknutí
          Navigator.pop(context);
          onTap();
        },
      );
    }

    // Vytvorenie položiek podľa roly používateľa
    if (widget.userRole == 'teacher' || widget.userRole == 'admin') {
      items.add(buildDrawerItem(Icons.dashboard, 'Dashboard', () => widget.onItemSelected(0)));
      items.add(buildDrawerItem(Icons.folder, 'Materiály', () => widget.onItemSelected(1)));
      items.add(buildDrawerItem(Icons.people, 'Študenti', () => widget.onItemSelected(2)));
      items.add(buildDrawerItem(Icons.settings, 'Nastavenia', () => widget.onItemSelected(3)));
      
      if (widget.userRole == 'admin') {
        items.add(buildDrawerItem(Icons.accessibility_new, 'Učitelia', () => widget.onItemSelected(4)));
      }
      
      // Tlačídlo na pridanie novej úlohy
      items.add(const Divider());
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onItemSelected(widget.userRole == 'admin' ? 5 : 4);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Pridať novú úlohu"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 229, 127, 37),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      );
    } else {
      // Položky pre študenta
      items.add(buildDrawerItem(Icons.dashboard, 'Dashboard', () => widget.onItemSelected(0)));
      items.add(buildDrawerItem(Icons.notification_important, 'Notifikácie', () => widget.onItemSelected(1)));
    }
    
    // Tlačidlo na odhlásenie pre všetky role
    items.add(const Divider());
    items.add(buildDrawerItem(Icons.logout, 'Odhlásiť sa', () => logout(context)));

    return items;
  }

  List<SidebarXItem> _buildTeacherItems(BuildContext context, String userRole, Function(int) onItemSelected) {
    List<SidebarXItem> items = [
      SidebarXItem(
        iconWidget: const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Icon(Icons.dashboard),
        ),
        label: 'Dashboard',
        onTap: () => onItemSelected(0),
      ),
      SidebarXItem(
        iconWidget: const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Icon(Icons.folder),
        ),
        label: 'Materiály',
        onTap: () => onItemSelected(1),
      ),
      SidebarXItem(
        iconWidget: const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Icon(Icons.people),
        ),
        label: 'Študenti',
        onTap: () => onItemSelected(2),
      ),
      SidebarXItem(
        iconWidget: const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Icon(Icons.settings),
        ),
        label: 'Nastavenia',
        onTap: () => onItemSelected(3),
      ),
    ];

    // Len admin má prístup k správe učiteľov
    if (userRole == 'admin') {
      items.add(SidebarXItem(
        iconWidget: const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Icon(Icons.accessibility_new),
        ),
        label: 'Učitelia',
        onTap: () => onItemSelected(4),
      ));
    }

    // Odhlásenie pre obe role
    items.add(SidebarXItem(
      iconWidget: const Padding(
        padding: EdgeInsets.only(left: 2),
        child: Icon(Icons.logout),
      ),
      label: 'Odhlásiť sa',
      onTap: () => logout(context),
    ));

    return items;
  }

  List<SidebarXItem> _buildStudentItems(BuildContext context, Function(int) onItemSelected) {
    return [
      SidebarXItem(
        iconWidget: const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Icon(Icons.dashboard),
        ),
        label: 'Dashboard',
        onTap: () => onItemSelected(0),
      ),
      SidebarXItem(
        iconWidget: const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Icon(Icons.notification_important),
        ),
        label: 'Notifikácie',
        onTap: () => onItemSelected(1),
      ),
      SidebarXItem(
        iconWidget: const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Icon(Icons.logout),
        ),
        label: 'Odhlásiť sa',
        onTap: () => logout(context),
      ),
    ];
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sassy/screens/main_screen.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  bool _isLoading = false;
  bool _isLoadingStudents = false;
  List<Map<String, dynamic>> _students = [];
  String? _selectedStudentId;
  String? _selectedStudentName;

  LoginMode _currentMode = LoginMode.teacher;

  // Pre farebný kód
  List<String> _selectedColors = [];
  final List<String> _availableColors = [
    'red', 'blue', 'green', 'yellow', 'purple', 'orange'
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  // Načítanie zoznamu študentov
  Future<void> _loadStudents() async {
    if (_currentMode == LoginMode.teacher) return;
    
    setState(() {
      _isLoadingStudents = true;
    });

    try {
      final studentsData = await _apiService.getStudentsNames();
      setState(() {
        _students = (studentsData as List).map<Map<String, dynamic>>((item) =>
          Map<String, dynamic>.from(item)
        ).toList();
        _isLoadingStudents = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() {
        _isLoadingStudents = false;
      });
      _showError('Nepodarilo sa načítať zoznam študentov');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDE3),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              width: 340,
              decoration: BoxDecoration(
                color: const Color(0xFFF4D3BA),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo sekcia
                  Container(
                    height: 140,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/img/Sassy.svg',
                        height: 100,
                      ),
                    ),
                  ),

                  // Prepínač typov prihlásenia
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _loginModeButton(
                          icon: Icons.person,
                          label: 'Učiteľ',
                          mode: LoginMode.teacher,
                        ),
                        _loginModeButton(
                          icon: Icons.pin,
                          label: 'PIN',
                          mode: LoginMode.studentPin,
                        ),
                        _loginModeButton(
                          icon: Icons.palette,
                          label: 'Farby',
                          mode: LoginMode.studentColor,
                        ),
                      ],
                    ),
                  ),

                  // Prihlasovací formulár
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: _buildLoginForm(),
                  ),

                  // Tlačidlo na prihlásenie
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _currentMode == LoginMode.studentColor
                        ? _buildLoginButton()
                        : Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF4A261),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(15),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tlačidlo na prepínanie režimu prihlásenia
  Widget _loginModeButton({
    required IconData icon,
    required String label,
    required LoginMode mode,
  }) {
    final isSelected = _currentMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMode = mode;
          if (mode != LoginMode.studentColor) {
            _selectedColors = [];
          }
          
          if (mode != LoginMode.teacher) {
            _loadStudents();
          }
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF4A261) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Dropdown pre výber študenta
  Widget _buildStudentDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _isLoadingStudents
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Vyberte študenta'),
                value: _selectedStudentId,
                items: _students.map((student) {
                  return DropdownMenuItem<String>(
                    value: student['id'],
                    child: Text(student['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStudentId = value;
                    
                    // Uložiť aj meno študenta pre zobrazenie
                    if (value != null) {
                      final selectedStudent = _students.firstWhere(
                        (student) => student['id'] == value,
                        orElse: () => {'name': ''},
                      );
                      _selectedStudentName = selectedStudent['name'];
                    } else {
                      _selectedStudentName = null;
                    }
                  });
                },
              ),
            ),
    );
  }

  // Formulár pre prihlásenie na základe zvoleného módu
  Widget _buildLoginForm() {
    switch (_currentMode) {
      case LoginMode.teacher:
        return Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Email",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Heslo",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );

      case LoginMode.studentPin:
        return Column(
          children: [
            _buildStudentDropdown(),
            if (_selectedStudentName != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Prihlasujete sa ako: $_selectedStudentName',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "PIN kód",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );

      case LoginMode.studentColor:
        return Column(
          children: [
            _buildStudentDropdown(),
            if (_selectedStudentName != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Prihlasujete sa ako: $_selectedStudentName',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Vyberte správne poradie farieb:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _selectedColors.isEmpty
                          ? [const Text('Žiadne vybrané farby')]
                          : _selectedColors.asMap().entries.map((entry) {
                        final index = entry.key;
                        final color = entry.value;
                        return Stack(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _getColorFromString(color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColors.removeAt(index);
                                  });
                                },
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: _availableColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedColors.length < 4) {
                              _selectedColors.add(color);
                            }
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getColorFromString(color),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  // Tlačidlo pre prihlásenie farebným kódom
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || _selectedColors.length < 4 || _selectedStudentId == null
            ? null
            : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF4A261),
          padding: const EdgeInsets.all(15),
          shape: const CircleBorder(),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        child: _isLoading
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : const Icon(Icons.arrow_forward, color: Colors.white),
      ),
    );
  }

  // Spracovanie prihlásenia na základe zvoleného módu
  Future<void> _handleLogin() async {
    if (_currentMode == LoginMode.teacher) {
      if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
        _showError('Vyplňte email a heslo');
        return;
      }
    } else if (_selectedStudentId == null) {
      _showError('Vyberte študenta');
      return;
    } else if (_currentMode == LoginMode.studentPin && _pinController.text.trim().isEmpty) {
      _showError('Zadajte PIN kód');
      return;
    } else if (_currentMode == LoginMode.studentColor && _selectedColors.length < 4) {
      _showError('Vyberte aspoň 4 farby');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic>? userData;

      switch (_currentMode) {
        case LoginMode.teacher:
          // Prihlásenie učiteľa
          final email = _emailController.text.trim();
          final password = _passwordController.text.trim();
          final token = await _apiService.login(email, password);

          if (token != null) {
            userData = await _apiService.getCurrentUser();
          }
          break;

        case LoginMode.studentPin:
          final studentId = _selectedStudentId!;
          final pin = _pinController.text.trim();

          final loginResponse = await _apiService.studentPinLogin(studentId, pin);

          userData = {
            'user': {
              '_id': loginResponse['studentId'],
              'name': loginResponse['name'],
              'role': 'student'
            }
          };
          break;

        case LoginMode.studentColor:
          final studentId = _selectedStudentId!;

          final loginResponse = await _apiService.studentColorCodeLogin(studentId, _selectedColors);

          userData = {
            'user': {
              '_id': loginResponse['studentId'],
              'name': loginResponse['name'],
              'role': 'student'
            }
          };
          break;
      }

      if (userData != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('userId', userData['user']['_id']);
        await prefs.setString('userRole', userData['user']['role']);

        _socketService.initialize(
          dotenv.env['WEB_SOCKET_URL'] as String,
          userData['user']['_id'],
          userData['user']['role']
        );

        // await Future.delayed(const Duration(seconds: 1));

        // if (_socketService.isConnected) {
        //   print('Socket úspešne pripojený: ${_socketService.socket.id}');
        // } else {
        //   print('Upozornenie: Socket sa nepripojil, ale pokračujem v prihlásení');
        // }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        }
      } else {
        _showError('Neplatné prihlasovacie údaje');
      }
    } catch (e) {
      print('Chyba pri prihlasovaní: $e');
      _showError('Chyba pri prihlasovaní');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'purple': return Colors.purple;
      case 'orange': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

enum LoginMode {
  teacher,
  studentPin,
  studentColor,
}
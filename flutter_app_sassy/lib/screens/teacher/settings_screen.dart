import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/screens/teacher/settings_tabs/account_tab.dart';
import 'package:sassy/screens/teacher/settings_tabs/privacy_tab.dart';
import 'package:sassy/screens/teacher/settings_tabs/specialization_tab.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _apiService.getCurrentUser();
      if (userData != null) {
        // Rozdelenie celého mena na meno a priezvisko
        final nameParts = userData['name']?.split(' ') ?? [];
        if (nameParts.isNotEmpty) {
          _nameController.text = nameParts.first;
          if (nameParts.length > 1) {
            _surnameController.text = nameParts.skip(1).join(' ');
          }
        }
        
        _emailController.text = userData['email'] ?? '';
        
        // Správne formátovanie dátumu narodenia
        if (userData['dateOfBirth'] != null) {
          try {
            final DateTime date = DateTime.parse(userData['dateOfBirth']);
            _birthdateController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          } catch (e) {
            _birthdateController.text = '';
          }
        }
        
        _specializationController.text = userData['specialization'] ?? '';
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Nepodarilo sa načítať používateľské údaje: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _birthdateController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  DateTime _parseDateOfBirth(String date) {
    // Kontrola, či je dátum v správnom formáte (DD/MM/YYYY alebo DD.MM.YYYY)
    final separator = date.contains('/') ? '/' : '.';
    final parts = date.split(separator);
    
    if (parts.length == 3) {
      try {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      } catch (e) {
        throw Exception('Neplatný formát dátumu');
      }
    } else {
      throw Exception('Neplatný formát dátumu');
    }
  }

  // Funkcia na spracovanie aktualizácie účtu
  Future<void> _updateUserInformation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Spojenie mena a priezviska
      String? fullName;
      if (_nameController.text.isNotEmpty || _surnameController.text.isNotEmpty) {
        fullName = '${_nameController.text} ${_surnameController.text}'.trim();
      }

      bool success = await _apiService.updateUser(
        name: fullName?.isNotEmpty == true ? fullName : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        specialization: _specializationController.text.isNotEmpty ? _specializationController.text : null,
        dateOfBirth: _birthdateController.text.isNotEmpty 
            ? _parseDateOfBirth(_birthdateController.text)
            : null,
      );

      if (success) {
        setState(() {
          _successMessage = "Profil bol úspešne aktualizovaný";
        });
      } else {
        setState(() {
          _errorMessage = "Nepodarilo sa aktualizovať profil";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Chyba: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Funkcia na zmenu hesla
  Future<void> _updatePassword() async {
    // Kontrola či sa nové heslá zhodujú
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Nové heslá sa nezhodujú";
      });
      return;
    }

    // Kontrola či je zadané aktuálne heslo
    if (_currentPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Zadajte vaše aktuálne heslo";
      });
      return;
    }

    // Kontrola zložitosti hesla
    if (_newPasswordController.text.length < 8) {
      setState(() {
        _errorMessage = "Nové heslo musí mať aspoň 8 znakov";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      bool success = await _apiService.updateUser(
        password: _newPasswordController.text,
      );

      if (success) {
        setState(() {
          _successMessage = "Heslo bolo úspešne zmenené";
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        setState(() {
          _errorMessage = "Nepodarilo sa zmeniť heslo. Skontrolujte aktuálne heslo.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Chyba pri zmene hesla: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
      body: Row(
        children: [
          // Sidebar(controller: _controller),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                color: const Color.fromARGB(0, 244, 163, 97),
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          const TabBar(
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.black45,
                            indicatorColor: Color(0xFFF4A261),
                            indicatorWeight: 3,
                            tabs: [
                              Tab(text: "Môj účet"),
                              Tab(text: "Súkromie a bezpečnosť"),
                              Tab(text: "Špecializácia"),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: TabBarView(
                              children: [
                                AccountTab(
                                  nameController: _nameController,
                                  surnameController: _surnameController,
                                  birthdateController: _birthdateController,
                                  emailController: _emailController,
                                  isLoading: _isLoading,
                                  errorMessage: _errorMessage,
                                  successMessage: _successMessage,
                                  onSave: _updateUserInformation,
                                ),
                                PrivacyTab(
                                  currentPasswordController: _currentPasswordController,
                                  newPasswordController: _newPasswordController,
                                  confirmPasswordController: _confirmPasswordController,
                                  showCurrentPassword: _showCurrentPassword,
                                  showNewPassword: _showNewPassword,
                                  showConfirmPassword: _showConfirmPassword,
                                  isLoading: _isLoading,
                                  errorMessage: _errorMessage,
                                  successMessage: _successMessage,
                                  onToggleCurrentPassword: () {
                                    setState(() {
                                      _showCurrentPassword = !_showCurrentPassword;
                                    });
                                  },
                                  onToggleNewPassword: () {
                                    setState(() {
                                      _showNewPassword = !_showNewPassword;
                                    });
                                  },
                                  onToggleConfirmPassword: () {
                                    setState(() {
                                      _showConfirmPassword = !_showConfirmPassword;
                                    });
                                  },
                                  onSave: _updatePassword,
                                ),
                                SpecializationTab(
                                  specializationController: _specializationController,
                                  isLoading: _isLoading,
                                  errorMessage: _errorMessage,
                                  successMessage: _successMessage,
                                  onSave: _updateUserInformation,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
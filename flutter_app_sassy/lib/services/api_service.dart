import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String baseUrl = dotenv.env['API_URL'] as String;

  // Prihlásenie používateľa
  Future<String?> login(String email, String password) async {
    try {
      final body = jsonEncode({'email': email, 'password': password});

      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        // Uloženie tokenu
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        return token;
      } else {
        return null;
      }
    } catch (e) {
      throw(' Chyba pri prihlasovaní: $e');
    }
  }

  // Získanie materiálov pre študenta
  Future<List<dynamic>> getStudentMaterials(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/materials/student'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa načítať materiály.');
    }
  }

  // Získanie detailov konkrétneho materiálu
  Future<Map<String, dynamic>?> getMaterialDetails(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // print("id: $materialId");

    final response = await http.get(
      Uri.parse('$baseUrl/materials/details/$materialId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // print(response.body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  // Odoslanie odpovedí študenta
  Future<bool> submitMaterial({
    required String studentId,
    required String materialId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/materials/submit-material'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'studentId': studentId,
        'materialId': materialId,
        'answers': answers,
      }),
    );
    // print(response.body);
    return response.statusCode == 201;
  }

  Future<bool> registerStudent({
    required String name,
    required String email,
    required String password,
    required DateTime dateOfBirth,

  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/students/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
        },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'dateOfBirth': dateOfBirth.toIso8601String(),
      }),
    );
    // print(response.body);
    return response.statusCode == 201;
  }

  // Získanie informácií o aktuálnom používateľovi
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    // print(' Status kód: ${response.statusCode}');
    // print(' Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  // Odhlásenie používateľa
  Future<bool> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/users/logout'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      await prefs.remove('token');
      return true;
    } else {
      return false;
    }
  }

  Future<bool> updateUser({
    String? name,
    String? email,
    String? password,
    String? role,
    String? notes,
    String? specialization,
    bool? hasSpecialNeeds,
    DateTime? dateOfBirth,
    String? needsDescription,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    final response = await http.put(
      Uri.parse('$baseUrl/users/update/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (password != null) 'password': password,
        if (role != null) 'role': role,
        if (notes != null) 'notes': notes,
        if (specialization != null) 'specialization': specialization,
        if (hasSpecialNeeds != null) 'hasSpecialNeeds': hasSpecialNeeds,
        if (needsDescription != null) 'needsDescription': needsDescription,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(), // Convert to ISO format
      }),
    );
    
    // print(' Status kód: ${response.statusCode}');
    // print(' Response body: ${response.body}');
    
    return response.statusCode == 200;
  }

  // Aktualizácia používateľa podľa ID
  Future<bool> updateUserById({
    required String userId,
    String? name,
    String? email,
    String? password,
    String? notes,
    String? specialization,
    bool? hasSpecialNeeds,
    DateTime? dateOfBirth,
    String? needsDescription,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    final response = await http.put(
      Uri.parse('$baseUrl/students/update/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (password != null) 'password': password,
        if (notes != null) 'notes': notes,
        if (specialization != null) 'specialization': specialization,
        if (hasSpecialNeeds != null) 'hasSpecialNeeds': hasSpecialNeeds,
        if (needsDescription != null) 'needsDescription': needsDescription,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
      }),
    );
    
    // print('Status kód: ${response.statusCode}');
    // print('Response body: ${response.body}');
    
    return response.statusCode == 200;
  }

  // Vytvorenie novej skupiny
  Future<bool> createGroup({
    required String name,
    required String teacherId,
    required List<String> studentIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/groups/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'teacherId': teacherId,
        'studentIds': studentIds,
      }),
    );
    // print(response.body);

    return response.statusCode == 201;
  }

  // Pridanie študenta do skupiny
  Future<bool> addStudentToGroup({
    required String groupId,
    required String studentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/groups/groups/add-student'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'groupId': groupId,
        'studentId': studentId,
      }),
    );
    // print(response.body);
    return response.statusCode == 200;
  }

  // Odstránenie skupiny
  Future<bool> deleteGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/groups/groups/$groupId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
  
  // Nahrávanie obrázka na server
  Future<String?> uploadImage(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception('Používateľ nie je prihlásený');
      }
      
      // Vytvorenie formData pre multipart request
      final dio = Dio();
      
      // Získanie názvu súboru a typu zo súborového rozšírenia
      String fileName = imageFile.path.split('/').last;
      String fileExtension = fileName.split('.').last.toLowerCase();
      MediaType? contentType;
      
      // Nastavenie správneho typu obsahu podľa prípony súboru
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          contentType = MediaType.parse('image/jpeg');
          break;
        case 'png':
          contentType = MediaType.parse('image/png');
          break;
        case 'gif':
          contentType = MediaType.parse('image/gif');
          break;
        case 'webp':
          contentType = MediaType.parse('image/webp');
          break;
        default:
          contentType = MediaType.parse('image/jpeg');
      }
      
      // Vytvorenie FormData so správnym názvom poľa 'image'
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: contentType,
        ),
      });
      
      // Odoslanie požiadavky na server
      final response = await dio.post(
        '$baseUrl/materials/image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data', // Explicitne nastavenie typu obsahu
          },
          followRedirects: false,
          validateStatus: (status) => true, // Akceptácia akéhokoľvek stavového kódu pre ladenie
        ),
      );
      
      if (response.statusCode == 200) {
        // Vrátime cestu k nahranému obrázku
        return response.data['filePath'];
      } else {
        // print('Chyba pri nahrávaní obrázka: ${response.statusCode}');
        // print('Response data: ${response.data}');
        return null;
      }
    } catch (e) {
      throw('Výnimka pri nahrávaní obrázka: $e');
    }
  }
  
  // 🟢 Získanie obrázka ako bajtov
  Future<Uint8List?> getImageBytes(String fullPath) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
 
    final response = await http.post(
      Uri.parse('$baseUrl/materials/get-image'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'path': fullPath}),
    );
 
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw('Chyba pri získavaní obrázka: ${response.statusCode}');
    }
  }
  
  // Aktualizácia metódy createMaterial pre podporu nahrávania obrázkov
  Future<bool> createMaterial({
    required String title,
    required String type,
    required Map<String, dynamic> content,
    String? description,
    List<String>? assignedTo,
    List<String>? assignedGroups,
    File? imageFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (type == 'puzzle' && imageFile != null) {
      final imagePath = await uploadImage(imageFile);
      if (imagePath != null) {
        content['image'] = imagePath;
      } else {
        return false;
      }
    }
    
    final body = {
      'title': title,
      'type': type,
      'content': content,
      if (description != null) 'description': description,
      if (assignedTo != null && assignedTo.isNotEmpty) 'assignedTo': assignedTo,
      if (assignedGroups != null && assignedGroups.isNotEmpty) 'assignedGroups': assignedGroups,
    };

    // print(body);
        
    final response = await http.post(
      Uri.parse('$baseUrl/materials/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    // print(response.body);
    return response.statusCode == 201;
  }

  // Aktualizácia materiálu s podporou obrázkov
  Future<bool> updateMaterial({
    required String materialId,
    String? title,
    String? description,
    String? type,
    Map<String, dynamic>? content,
    List<String>? assignedTo,
    List<String>? assignedGroups,
    File? imageFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (imageFile != null && content != null && type == 'puzzle') {
      final imagePath = await uploadImage(imageFile);
      if (imagePath != null) {
        content['image'] = imagePath;
      } else {
        return false;
      }
    }

    final body = {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (assignedTo != null && assignedTo.isNotEmpty) 'assignedTo': assignedTo,
      if (assignedGroups != null && assignedGroups.isNotEmpty) 'assignedGroups': assignedGroups,
    };
    // print(assignedTo);
    // print(assignedGroups);
    final response = await http.put(
      Uri.parse('$baseUrl/materials/$materialId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    print(response.body);

    return response.statusCode == 200;
  }



  // Odstránenie materiálu
  Future<bool> deleteMaterial(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/materials/$materialId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Získanie parametrov daného materiálu
  Future<Map<String, dynamic>?> getMaterialParams(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/materials/details/$materialId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['material'];
    } else {
      return null;
    }
  }
  // overenie tokenu
  Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.get(
      Uri.parse('$baseUrl/users/validate-token'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Získanie zoznamu všetkých študentov
  Future<List<dynamic>> getStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/students'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // print(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa načítať študentov');
    }
  }

  // Získanie detailov konkrétneho študenta
  Future<Map<String, dynamic>> getStudentDetails(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/students/$studentId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // print(response.body);


    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa načítať detaily študenta');
    }
  }

  // Získanie skupín študenta
  Future<List<Map<String, dynamic>>> getStudentGroups(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }
    // print(studentId);
    final response = await http.get(
      Uri.parse('$baseUrl/students/$studentId/groups'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // print(response.body);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Nepodarilo sa načítať skupiny študenta');
    }
  }

  // Vyhľadávanie študentov
  Future<List<dynamic>> searchStudents(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/students/search?q=${Uri.encodeComponent(query)}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa vyhľadať študentov');
    }
  }

  // Odstránenie študenta zo skupiny
  Future<bool> removeStudentFromGroup(String groupId, String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }

    // print(studentId);
    final response = await http.delete(
      Uri.parse('$baseUrl/students/groups/$groupId/students/$studentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // print(response.body);

    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getTeacher() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/teacher'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['teacher'];
    } else {
      throw Exception('Nepodarilo sa načítať učiteľa');
    }
  }

// Získanie detailov skupiny vrátane učiteľa a študentov
  Future<Map<String, dynamic>> getGroupDetails(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/groups/group/$groupId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // print(response.body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa načítať detail skupiny');
    }
  }

  // Získanie všetkých skupín s detailmi učiteľa a študentov
  Future<List<Map<String, dynamic>>> getAllGroupsWithDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/groups/groups'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Nepodarilo sa načítať skupiny');
    }
  }

  // ziskanie vestkych materialov
  Future<List<Map<String, dynamic>>> getAllMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/materials/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // print(response.body);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Nepodarilo sa načítať skupiny');
    }
  }

  
  
  // Odstránenie aktuálne prihláseného používateľa
  Future<bool> deleteCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
  
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }
  
    final response = await http.delete(
      Uri.parse('$baseUrl/users/delete'),
      headers: {'Authorization': 'Bearer $token'},
    );
  
    return response.statusCode == 200;
  }
  
  // Odstránenie študenta podľa ID (admin alebo učiteľ)
  Future<bool> deleteStudentById(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
  
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }
  
    final response = await http.delete(
      Uri.parse('$baseUrl/students/delete/$studentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  
    return response.statusCode == 200;
  }
  // ulozit material ako sablonu
  Future<bool> saveMaterialAsTemplate(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/materials/save-as-template'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'materialId': materialId}),
    );

    if (response.statusCode == 201) {

      return true;
    } else {
      return false;
    }
  }

  // Získanie všetkých šablón materiálov
  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/materials/templates'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // print(response.body);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Nepodarilo sa načítať šablóny materiálov');
    }
  }

  // Získanie notifikácií pre aktuálneho používateľa
  Future<List<dynamic>> getNotifications({int page = 1, int limit = 20, bool unreadOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'unreadOnly': unreadOnly.toString(),
    };

    final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['notifications'];
    } else {
      throw Exception('Nepodarilo sa získať notifikácie');
    }
  }

  // Označenie notifikácie ako prečítanej
  Future<bool> markNotificationAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Označenie všetkých notifikácií ako prečítaných
  Future<bool> markAllNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Získanie online stavu študenta
  Future<Map<String, dynamic>> getStudentOnlineStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/activity/status/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa získať online stav študenta');
    }
  }

  // Získanie zoznamu online študentov (pre učiteľov)
  Future<List<dynamic>> getOnlineStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/activity/online-students'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // print(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa získať zoznam online študentov');
    }
  }

  // Získanie zoznamu online študentov (pre učiteľov)
  Future<List<dynamic>> getOfflineStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/activity/offline-students'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa získať zoznam online študentov');
    }
  }

  // Zaznamenanie aktivity používateľa (volané periodicky)
  Future<bool> recordUserActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    // print(token);
    final response = await http.post(
      Uri.parse('$baseUrl/activity/record'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    // print(response.body);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Nepodarilo sa Zaznamenanie aktivity používateľa');
    }
  }
// NastavPIN
  Future<Map<String, dynamic>> setStudentPin(String studentId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/student/$studentId/pin'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'pin': pin}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to set student PIN: ${response.body}');
    }
  }

  // Nastav farebny kod
  Future<Map<String, dynamic>> setStudentColorCode(String studentId, List<String> colorCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/student/$studentId/colorcode'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'colorCode': colorCode}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to set student color code: ${response.body}');
    }
  }

  // generuj nahodny pin
  Future<Map<String, dynamic>> generateRandomPin(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/student/$studentId/generate-pin'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate random PIN: ${response.body}');
    }
  }

  // generuj nahodny farebny kod
  Future<Map<String, dynamic>> generateRandomColorCode(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/student/$studentId/generate-colorcode'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate random color code: ${response.body}');
    }
  }

  // Kontrola spôsobu overovania študentov
  Future<Map<String, dynamic>> checkStudentAuthMethod(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/student/$studentId/auth-method'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check student authentication method: ${response.body}');
    }
  }

  // Prihlásenie študenta pomocou PIN kódu
  Future<Map<String, dynamic>> studentPinLogin(String studentId, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/student/login/pin'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'studentId': studentId,
        'pin': pin
      }),
    );
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Save token if provided in response
      if (responseData['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
      }

      return responseData;
    } else {
      throw Exception('Failed to login with PIN: ${response.body}');
    }
  }

  // Prihlásenie študenta s farebným kódom
  Future<Map<String, dynamic>> studentColorCodeLogin(String studentId, List<String> colorCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/student/login/colorcode'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'studentId': studentId,
        'colorCode': colorCode
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      if (responseData['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
      }

      return responseData;
    } else {
      throw Exception('Failed to login with color code: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getStudentAuth(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/auth/student/$studentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',

      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get student authentication method: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getStudentProgresses(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/materials/progress/$studentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',

      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get student Progrresses: ${response.body}');
    }
  }

  Future<List<dynamic>> getStudentsNames() async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/names'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get student Names: ${response.body}');
    }
  }

    // Získaní zoznamu všetkých učiteľov
  Future<List<dynamic>> getTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/teachers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa načítať učiteľov');
    }
  }

  // Získanie detailov konkrétneho učiteľa
  Future<Map<String, dynamic>> getTeacherDetails(String teacherId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/teachers/$teacherId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa načítať detaily učiteľa');
    }
  }

  // Registrácia nového učiteľa
  Future<Map<String, dynamic>> registerTeacher(Map<String, dynamic> teacherData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/teachers/register'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(teacherData),
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nepodarilo sa zaregistrovať učiteľa: ${response.body}');
    }
  }

  // Vymazanie učiteľa
  Future<bool> deleteTeacher(String teacherId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Používateľ nie je prihlásený');
    }
    final response = await http.delete(
      Uri.parse('$baseUrl/teachers/delete/$teacherId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Nepodarilo sa vymazať učiteľa');
    } else {
      throw Exception('Nepodarilo sa vymazať učiteľa');
    }
  }
}


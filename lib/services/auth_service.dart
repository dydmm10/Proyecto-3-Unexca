import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegisterResponse {
  final bool success;
  final String? message;

  const RegisterResponse({required this.success, this.message});
}

class WorkOrder {
  final int id;
  final String category;
  final String description;
  final String priority;
  final String status;
  final DateTime? createdAt;

  const WorkOrder({
    required this.id,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    this.createdAt,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['created_at'];
    return WorkOrder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      category: (json['category'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      priority: (json['priority'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      createdAt:
          rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null,
    );
  }
}

class EquipmentRecord {
  final int id;
  final String type;
  final String brand;
  final String model;
  final String serial;
  final DateTime? createdAt;

  const EquipmentRecord({
    required this.id,
    required this.type,
    required this.brand,
    required this.model,
    required this.serial,
    this.createdAt,
  });

  String get title => '$brand $model';

  factory EquipmentRecord.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['created_at'];
    return EquipmentRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] as String? ?? '').trim(),
      brand: (json['brand'] as String? ?? '').trim(),
      model: (json['model'] as String? ?? '').trim(),
      serial: (json['serial'] as String? ?? '').trim(),
      createdAt:
          rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null,
    );
  }
}

class AuthService {
  static const Duration _requestTimeout = Duration(seconds: 12);

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:3000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      default:
        return 'http://localhost:3000';
    }
  }

  final String baseUrl;
  AuthService(this.baseUrl);

  Future<String?> login(String email, String password) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_requestTimeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final token = data['token'] as String?;
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt', token);
        }
        return token;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> register(String email, String password) async {
    final result = await registerWithMessage(email, password);
    return result.success;
  }

  Future<bool?> emailExists(String email) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/exists')
          .replace(queryParameters: {'email': email});
      final resp = await http.get(uri).timeout(_requestTimeout);
      if (resp.statusCode != 200) return null;

      final body = jsonDecode(resp.body);
      if (body is Map<String, dynamic> && body['exists'] is bool) {
        return body['exists'] as bool;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<RegisterResponse> registerWithMessage(
    String email,
    String password,
  ) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/api/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_requestTimeout);

      if (resp.statusCode == 200) {
        return const RegisterResponse(success: true);
      }

      String? backendMsg;
      try {
        final body = jsonDecode(resp.body);
        backendMsg =
            body is Map<String, dynamic> ? body['msg'] as String? : null;
      } catch (_) {
        backendMsg = null;
      }

      if (resp.statusCode == 400 &&
          (backendMsg?.toLowerCase().contains('registrado') ?? false)) {
        return const RegisterResponse(
          success: false,
          message: 'Ese email ya está registrado.',
        );
      }

      return RegisterResponse(
        success: false,
        message: backendMsg ?? 'No se pudo crear la cuenta. Intenta de nuevo.',
      );
    } catch (_) {
      return const RegisterResponse(
        success: false,
        message: 'No hay conexión con el servidor. Verifica el backend.',
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<RegisterResponse> createWorkOrder({
    required String category,
    required String description,
    required String priority,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/api/work-orders'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'category': category,
              'description': description,
              'priority': priority,
            }),
          )
          .timeout(_requestTimeout);

      if (resp.statusCode == 201) {
        return const RegisterResponse(success: true, message: 'Orden creada');
      }

      try {
        final data = jsonDecode(resp.body);
        final msg =
            data is Map<String, dynamic> ? data['msg'] as String? : null;
        return RegisterResponse(
          success: false,
          message: msg ?? 'No se pudo crear la orden.',
        );
      } catch (_) {
        return const RegisterResponse(
          success: false,
          message: 'No se pudo crear la orden.',
        );
      }
    } catch (_) {
      return const RegisterResponse(
        success: false,
        message: 'No hay conexión con el servidor.',
      );
    }
  }

  Future<List<WorkOrder>> fetchWorkOrders() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/work-orders'))
          .timeout(_requestTimeout);
      if (resp.statusCode != 200) return const [];

      final data = jsonDecode(resp.body);
      if (data is! List) return const [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(WorkOrder.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<RegisterResponse> deleteWorkOrder(int id) async {
    try {
      final resp = await http
          .delete(Uri.parse('$baseUrl/api/work-orders/$id'))
          .timeout(_requestTimeout);

      if (resp.statusCode == 200) {
        return const RegisterResponse(
            success: true, message: 'Orden eliminada');
      }
      return const RegisterResponse(
          success: false, message: 'No se pudo eliminar la orden.');
    } catch (_) {
      return const RegisterResponse(
          success: false, message: 'No hay conexión con el servidor.');
    }
  }

  Future<RegisterResponse> createEquipment({
    required String type,
    required String brand,
    required String model,
    required String serial,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/api/equipments'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'type': type,
              'brand': brand,
              'model': model,
              'serial': serial,
            }),
          )
          .timeout(_requestTimeout);

      if (resp.statusCode == 201) {
        return const RegisterResponse(success: true, message: 'Equipo creado');
      }
      return const RegisterResponse(
          success: false, message: 'No se pudo crear el equipo.');
    } catch (_) {
      return const RegisterResponse(
          success: false, message: 'No hay conexión con el servidor.');
    }
  }

  Future<List<EquipmentRecord>> fetchEquipments() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/equipments'))
          .timeout(_requestTimeout);
      if (resp.statusCode != 200) return const [];

      final data = jsonDecode(resp.body);
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(EquipmentRecord.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<RegisterResponse> deleteEquipment(int id) async {
    try {
      final resp = await http
          .delete(Uri.parse('$baseUrl/api/equipments/$id'))
          .timeout(_requestTimeout);

      if (resp.statusCode == 200) {
        return const RegisterResponse(
            success: true, message: 'Equipo eliminado');
      }
      return const RegisterResponse(
          success: false, message: 'No se pudo eliminar el equipo.');
    } catch (_) {
      return const RegisterResponse(
          success: false, message: 'No hay conexión con el servidor.');
    }
  }
}

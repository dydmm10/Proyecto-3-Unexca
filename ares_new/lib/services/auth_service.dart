import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:jwt_decoder/jwt_decoder.dart';



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

  final String? nombreCliente;

  final String? usuarioCliente;

  final String? nombreEquipo;

  final int? codCliente;

  final int? codEquipo;

  final int? codTecnico;

  final String? diagnostico;

  final String? costoEstimado;

  final String? costoFinal;

  final DateTime? fechaModificacion;

  final String? correcciones;

  final String? recomendaciones;



  const WorkOrder({

    required this.id,

    required this.category,

    required this.description,

    required this.priority,

    required this.status,

    this.createdAt,

    this.nombreCliente,

    this.usuarioCliente,

    this.nombreEquipo,

    this.codCliente,

    this.codEquipo,

    this.codTecnico,

    this.diagnostico,

    this.costoEstimado,

    this.costoFinal,

    this.fechaModificacion,

    this.correcciones,

    this.recomendaciones,

  });



  factory WorkOrder.fromJson(Map<String, dynamic> json) {

    final rawCreatedAt = json['fecha_creacion'];

    final categoryValue = json['category_name'] ?? json['cod_categoria'];

    String categoryStr = '';

    

    // Manejar category que puede venir como número o como cadena

    if (categoryValue != null) {

      if (categoryValue is num) {

        categoryStr = categoryValue.toString();

      } else if (categoryValue is String) {

        categoryStr = categoryValue.trim();

      }

    }

    

    return WorkOrder(

      id: (json['cod_orden'] as num?)?.toInt() ?? 0,

      category: categoryStr,

      description: (json['descripcion_problema'] as String? ?? '').trim(),

      priority: (json['prioridad'] as String? ?? '').trim(),

      status: (json['estado'] as String? ?? '').trim(),

      createdAt: rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null,

      fechaModificacion: json['fecha_modificacion'] is String ? DateTime.tryParse(json['fecha_modificacion']) : null,

      nombreCliente: json['cliente_nombre'] as String? ?? null,

      usuarioCliente: null, // No viene en el backend

      nombreEquipo: null, // No viene directamente en este endpoint

      codCliente: (json['cod_cliente'] as num?)?.toInt(),

      codEquipo: (json['cod_equipo'] as num?)?.toInt(),

      codTecnico: (json['cod_tecnico'] as num?)?.toInt(),

      diagnostico: json['diagnostico'] as String? ?? null,

      costoEstimado: json['costo_estimado']?.toString() ?? null,

      costoFinal: json['costo_final']?.toString() ?? null,

      correcciones: json['correcciones'] as String? ?? null,

      recomendaciones: json['recomendaciones'] as String? ?? null,

    );

  }

}



class WorkOrderDetail {

  final int id;

  final String category;

  final String description;

  final String priority;

  final String status;

  final DateTime? createdAt;

  final DateTime? modifiedAt;

  final double? costoEstimado;

  final double? costoFinal;

  final String? diagnostico;

  final String? correcciones;

  final String? recomendaciones;

  final int? codTecnico;

  final String? clienteNombre;

  final String? clienteTelefono;

  final String? clienteCorreo;

  final String? clienteDireccion;

  final String? equipoMarca;

  final String? equipoModelo;

  final String? equipoSerial;

  final String? tecnicoNombre;



  const WorkOrderDetail({

    required this.id,

    required this.category,

    required this.description,

    required this.priority,

    required this.status,

    this.createdAt,

    this.modifiedAt,

    this.costoEstimado,

    this.costoFinal,

    this.diagnostico,

    this.correcciones,

    this.recomendaciones,

    this.codTecnico,

    this.clienteNombre,

    this.clienteTelefono,

    this.clienteCorreo,

    this.clienteDireccion,

    this.equipoMarca,

    this.equipoModelo,

    this.equipoSerial,

    this.tecnicoNombre,

  });



  factory WorkOrderDetail.fromJson(Map<String, dynamic> json) {

    final rawCreatedAt = json['fecha_creacion'];

    final rawModifiedAt = json['fecha_modificacion'];

    final categoryValue = json['category_name'] ?? json['cod_categoria'];

    String categoryStr = '';

    

    // Manejar category que puede venir como número o como cadena

    if (categoryValue != null) {

      if (categoryValue is num) {

        categoryStr = categoryValue.toString();

      } else if (categoryValue is String) {

        categoryStr = categoryValue.trim();

      }

    }

    

    return WorkOrderDetail(

      id: (json['cod_orden'] as num?)?.toInt() ?? 0,

      category: categoryStr,

      description: (json['descripcion_problema'] as String? ?? '').trim(),

      priority: (json['prioridad'] as String? ?? '').trim(),

      status: (json['estado'] as String? ?? '').trim(),

      createdAt: rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null,

      modifiedAt: rawModifiedAt is String ? DateTime.tryParse(rawModifiedAt) : null,

      costoEstimado: json['costo_estimado'] != null ? 
        (json['costo_estimado'] is String ? 
          double.tryParse(json['costo_estimado'] as String) : 
          (json['costo_estimado'] as num).toDouble()) : null,

      costoFinal: json['costo_final'] != null ? 
        (json['costo_final'] is String ? 
          double.tryParse(json['costo_final'] as String) : 
          (json['costo_final'] as num).toDouble()) : null,

      diagnostico: json['diagnostico'] as String?,

      correcciones: json['correcciones'] as String?,

      recomendaciones: json['recomendaciones'] as String?,

      codTecnico: json['cod_tecnico'] as int?,

      clienteNombre: json['cliente_nombre'] as String?,

      clienteTelefono: json['cliente_telefono'] as String?,

      clienteCorreo: json['cliente_correo'] as String?,

      clienteDireccion: json['cliente_direccion'] as String?,

      equipoMarca: json['equipo_marca'] as String?,

      equipoModelo: json['equipo_modelo'] as String?,

      equipoSerial: json['equipo_serial'] as String?,

      tecnicoNombre: json['tecnico_nombre'] as String?,

    );

  }

}



class EquipmentRecord {

  final int codEquipos;

  final String tipo;

  final String marca;

  final String modelo;

  final String serial;

  final int? codCliente;

  final String? nombreCliente;

  final String? usuarioCliente;



  const EquipmentRecord({

    required this.codEquipos,

    required this.tipo,

    required this.marca,

    required this.modelo,

    required this.serial,

    this.codCliente,

    this.nombreCliente,

    this.usuarioCliente,

  });



  String get title => '$marca $modelo';



  factory EquipmentRecord.fromJson(Map<String, dynamic> json) {

    return EquipmentRecord(

      codEquipos: (json['cod_equipos'] as num?)?.toInt() ?? 0,

      tipo: (json['tipo'] as String? ?? '').trim(),

      marca: (json['marca'] as String? ?? '').trim(),

      modelo: (json['modelo'] as String? ?? '').trim(),

      serial: (json['serial'] as String? ?? '').trim(),

      codCliente: (json['cod_cliente'] as num?)?.toInt(),

      nombreCliente: json['nombre_cliente'] as String?,

      usuarioCliente: json['usuario_cliente'] as String?,

    );

  }

}



class Cliente {

  final int codCliente;

  final String usuario;

  final String nombre;

  final String correo;

  final String numTelefono;

  final String direccion;

  final String estado;

  final DateTime? createdAt;



  const Cliente({

    required this.codCliente,

    required this.usuario,

    required this.nombre,

    required this.correo,

    required this.numTelefono,

    required this.direccion,

    this.estado = 'Activo',

    this.createdAt,

  });



  factory Cliente.fromJson(Map<String, dynamic> json) {

    final rawCreatedAt = json['fecha_creacion'] ?? json['created_at'];

    return Cliente(

      codCliente: (json['cod_cliente'] as num?)?.toInt() ?? 0,

      usuario: (json['usuario'] as String? ?? '').trim(),

      nombre: (json['nombre'] as String? ?? '').trim(),

      correo: (json['correo'] as String? ?? '').trim(),

      numTelefono: (json['num_telefono'] as String? ?? '').trim(),

      direccion: (json['direccion'] as String? ?? '').trim(),

      estado: (json['estado'] as String? ?? 'Activo').trim(),

      createdAt:

          rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null,

    );

  }

}



class Tecnico {

  final int cod_tecnico;

  final String usuario;

  final String nombre;

  final String correo;

  final String numTelefono;

  final String cod_privilegio;

  final String estado;

  final DateTime? fechaCreacion;



  const Tecnico({

    required this.cod_tecnico,

    required this.usuario,

    required this.nombre,

    required this.correo,

    required this.numTelefono,

    required this.cod_privilegio,

    String? estado,

    this.fechaCreacion,

  }) : estado = estado ?? 'Activo';



  factory Tecnico.fromJson(Map<String, dynamic> json) {

    final rawCreatedAt = json['fecha_creacion'];

    final usuario = (json['usuario'] as String? ?? '').trim();

    

    // Generar ID temporal si cod_tecnico es null

    int codTecnicoValue;

    if (json['cod_tecnico'] != null) {

      codTecnicoValue = (json['cod_tecnico'] as num?)?.toInt() ?? 0;

    } else {

      // Generar ID único basado en el hash del usuario

      codTecnicoValue = usuario.hashCode.abs();

      if (codTecnicoValue <= 0) codTecnicoValue = 1000000 + (usuario.length * 1000);

    }

    

    if (kDebugMode) {

      print('🔍 Mapeando Tecnico desde JSON:');

      print('JSON completo recibido: $json');

      print('Todos los campos del JSON: ${json.keys.toList()}');

      print('cod_tecnico original: ${json['cod_tecnico']}');

      print('Tipo de cod_tecnico original: ${json['cod_tecnico'].runtimeType}');

      print('cod_tecnico después de mapeo: $codTecnicoValue');

      print('cod_tecnico es null?: ${json['cod_tecnico'] == null}');

      print('usuario usado para ID: $usuario');

      print('hash de usuario: ${usuario.hashCode.abs()}');

      

      // Verificar si hay campos similares que podrían ser el ID

      final camposSimilares = json.keys.where((key) => 

        key.toLowerCase().contains('cod') || key.toLowerCase().contains('id')

      ).toList();

      print('Campos similares a código/ID: $camposSimilares');

      camposSimilares.forEach((campo) {

        print('  - $campo: ${json[campo]} (${json[campo].runtimeType})');

      });

      

      // Si cod_tecnico es null, mostrar advertencia

      if (json['cod_tecnico'] == null) {

        print('⚠️ ADVERTENCIA: cod_tecnico es null, se generó ID temporal: $codTecnicoValue');

        print('💡 Esto indica que el campo cod_tecnico no existe en la tabla o no se está seleccionando');

        print('🔧 Se usará el usuario como identificador único para las operaciones');

      }

    }

    

    return Tecnico(

      cod_tecnico: codTecnicoValue,

      usuario: usuario,

      nombre: (json['nombre'] as String? ?? '').trim(),

      correo: (json['correo'] as String? ?? '').trim(),

      numTelefono: (json['num_telefono'] as String? ?? '').trim(),

      cod_privilegio: (json['cod_privilegio'] as String? ?? '').trim(),

      estado: (json['estado'] as String? ?? 'Activo').trim(),

      fechaCreacion:

          rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null,

    );

  }

}



class AuthService {

  static const Duration _requestTimeout = Duration(seconds: 12);

  static String get defaultBaseUrl {
    // URL de Railway para producción
    return 'https://ares-production-20e1.up.railway.app';
  }

  final String baseUrl;

  AuthService(this.baseUrl);



  Future<Map<String, dynamic>?> login(String usuario, String password) async {

    try {

      final resp = await http

          .post(

            Uri.parse('$baseUrl/api/login'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({'usuario': usuario, 'password': password}),

          )

          .timeout(_requestTimeout);



      if (resp.statusCode == 200) {

        final data = jsonDecode(resp.body);

        final token = data['token'] as String?;

        final rol = data['rol'] as String?;

        final tipo = data['tipo'] as String?;

        final nombre = data['nombre'] as String?;

        final userId = data['userId'] as int?;

        final cod_privilegio = data['cod_privilegio'] as String?;

        

        if (token != null) {

          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('jwt', token);

          await prefs.setString('rol', rol ?? '');

          await prefs.setString('tipo', tipo ?? '');

          await prefs.setString('nombre', nombre ?? '');

          await prefs.setInt('userId', userId ?? 0);

          await prefs.setString('codPrivilegio', cod_privilegio ?? '');

        }

        

        return {

          'token': token,

          'rol': rol,

          'tipo': tipo,

          'nombre': nombre,

          'userId': userId,

          'cod_privilegio': cod_privilegio

        };

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

    String password, {

    String? nombre,

    String? num_telefono,

    String? direccion,

    String? usuario,

    String? tipo_usuario,

  }) async {

    try {

      final body = <String, dynamic>{

        'email': email,

        'password': password,

      };

      

      if (nombre != null) body['nombre'] = nombre;

      if (num_telefono != null) body['num_telefono'] = num_telefono;

      if (direccion != null) body['direccion'] = direccion;

      if (usuario != null) body['usuario'] = usuario;

      if (tipo_usuario != null) body['tipo_usuario'] = tipo_usuario;



      final resp = await http

          .post(

            Uri.parse('$baseUrl/api/register'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode(body),

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



  Future<RegisterResponse> registerTecnico({

    required String email,

    required String password,

    required String nombre,

    required String usuario,

    required String num_telefono,

    required String cod_privilegio,

  }) async {

    try {

      final body = <String, dynamic>{

        'nombre': nombre,

        'usuario': usuario,

        'correo': email,

        'password': password,

        'num_telefono': num_telefono,

        'cod_privilegio': cod_privilegio,

      };



      final resp = await http

          .post(

            Uri.parse('$baseUrl/api/tecnicos'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode(body),

          )

          .timeout(_requestTimeout);



      if (resp.statusCode == 201) {

        return const RegisterResponse(success: true);

      }



      String message = 'No se pudo crear el técnico';

      try {

        final bodyDecoded = jsonDecode(resp.body) as Map<String, dynamic>;

        message = bodyDecoded['msg'] ?? message;

      } catch (_) {

        message = resp.body;

      }

      return RegisterResponse(success: false, message: message);

    } catch (e) {

      if (kDebugMode) print('RegisterTecnico error: $e');

      return const RegisterResponse(success: false, message: 'No hay conexión con el servidor');

    }

  }



  Future<RegisterResponse> modificarPrivilegioTecnico(String usuario, String nuevo_privilegio) async {

    try {

      final body = <String, dynamic>{

        'cod_privilegio': nuevo_privilegio,

      };



      if (kDebugMode) {

        print('🔧 Enviando solicitud para modificar privilegio:');

        print('  - Usuario: $usuario');

        print('  - Nuevo privilegio: $nuevo_privilegio');

        print('  - URL: $baseUrl/api/tecnicos/$usuario/privilegio');

      }



      final resp = await http

          .patch(

            Uri.parse('$baseUrl/api/tecnicos/${Uri.encodeComponent(usuario)}/privilegio'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode(body),

          )

          .timeout(_requestTimeout);



      if (kDebugMode) {

        print('📊 Respuesta del servidor:');

        print('  - Status code: ${resp.statusCode}');

        print('  - Body: ${resp.body}');

      }



      if (resp.statusCode == 200) {

        return const RegisterResponse(success: true, message: 'Privilegio modificado exitosamente');

      }



      String message = 'No se pudo modificar el privilegio';

      try {

        final bodyDecoded = jsonDecode(resp.body) as Map<String, dynamic>;

        message = bodyDecoded['msg'] ?? message;

      } catch (_) {

        message = resp.body;

      }

      return RegisterResponse(success: false, message: message);

    } catch (e) {

      if (kDebugMode) print('ModificarPrivilegioTecnico error: $e');

      return const RegisterResponse(success: false, message: 'No hay conexión con el servidor');

    }

  }



  Future<void> logout() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('jwt');

    await prefs.remove('rol');

    await prefs.remove('tipo');

    await prefs.remove('nombre');

    await prefs.remove('userId');

    await prefs.remove('codPrivilegio');

  }



  Future<String?> getToken() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('jwt');

  }



  Future<int?> getCurrentUserId() async {

    final token = await getToken();

    if (token == null) {

      if (kDebugMode) print('No token found');

      return null;

    }

    

    try {

      final decodedToken = JwtDecoder.decode(token);

      if (kDebugMode) print('Decoded token: $decodedToken');

      

      // Intentar con userId primero (nuevo formato), luego con cod_cliente, luego con id (formato antiguo)
      
      int? userId;
      
      if (decodedToken['userId'] != null) {
        userId = int.tryParse(decodedToken['userId'].toString());
      } else if (decodedToken['cod_cliente'] != null) {
        userId = int.tryParse(decodedToken['cod_cliente'].toString());
      } else if (decodedToken['id'] != null) {
        userId = int.tryParse(decodedToken['id'].toString());
      }

      

      if (kDebugMode) print('User ID from token: $userId');

      return userId;

    } catch (e) {

      if (kDebugMode) print('Error decoding token: $e');

      return null;

    }

  }



  // Método para obtener las categorías desde la base de datos

  Future<List<Map<String, dynamic>>> getCategorias() async {

    try {

      final token = await getToken();

      if (token == null) {

        throw Exception('No hay sesión activa');

      }



      final resp = await http

          .get(

            Uri.parse('$baseUrl/api/categorias'),

            headers: {

              'Content-Type': 'application/json',

              'Authorization': 'Bearer $token',

            },

          )

          .timeout(_requestTimeout);



      if (resp.statusCode == 200) {

        final List<dynamic> categoriasList = jsonDecode(resp.body);

        return categoriasList.cast<Map<String, dynamic>>();

      } else {

        throw Exception('Error al obtener categorías: ${resp.statusCode}');

      }

    } catch (e) {

      if (kDebugMode) print('Get categorías error: $e');

      throw Exception('No hay conexión con el servidor');

    }

  }



  Future<RegisterResponse> createWorkOrder({

    required int codCategoria,

    String? tipo,

    required String descripcion_problema,

    required String prioridad,

    required int codCliente,

  }) async {

    try {

      final token = await getToken();

      if (token == null) {

        return const RegisterResponse(

          success: false,

          message: 'No hay sesión activa. Por favor inicia sesión.',

        );

      }



      final resp = await http

          .post(

            Uri.parse('$baseUrl/api/ordenes-reclamos'),

            headers: {

              'Content-Type': 'application/json',

              'Authorization': 'Bearer $token',

            },

            body: jsonEncode({

              'cod_categoria': codCategoria,

              'tipo': tipo ?? 'Reparación',

              'descripcion_problema': descripcion_problema,

              'prioridad': prioridad,

              'cod_cliente': codCliente,

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

      final isClient = await isClientePriv();

      final token = await getToken();
      if (token == null && isClient) {
        print('🔍 fetchWorkOrders - No hay token para cliente, retornando lista vacía');
        return const [];
      }

      // Para clientes, obtener su userId y filtrar por cliente
      String endpoint = '/api/ordenes-trabajo';
      if (isClient) {
        final userId = await getCurrentUserId();
        if (userId != null) {
          endpoint = '/api/ordenes-trabajo?cod_cliente=$userId';
        }
      }

      final resp = await http

          .get(

            Uri.parse('$baseUrl$endpoint'),

            headers: token != null ? {

              'Content-Type': 'application/json',

              'Authorization': 'Bearer $token',

            } : null,

          )

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



  Future<List<WorkOrder>> fetchMaintenanceOrders() async {

    try {

      final isClient = await isClientePriv();

      final endpoint = isClient ? '/api/ordenes-mantenimiento/cliente' : '/api/ordenes-mantenimiento';

      final token = await getToken();
      if (token == null && isClient) {
        print('🔍 fetchMaintenanceOrders - No hay token para cliente, retornando lista vacía');
        return const [];
      }

      final resp = await http

          .get(

            Uri.parse('$baseUrl$endpoint'),

            headers: token != null ? {

              'Content-Type': 'application/json',

              'Authorization': 'Bearer $token',

            } : null,

          )

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



  Future<WorkOrderDetail?> fetchWorkOrderDetail(int id) async {
    try {
      final token = await getToken();
      final resp = await http
          .get(
            Uri.parse('$baseUrl/api/ordenes-reclamos/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_requestTimeout);
      


      if (resp.statusCode != 200) return null;


      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic>) return null;
      


      return WorkOrderDetail.fromJson(data);
    } catch (_) {
      return null;
    }
  }


  Future<List<WorkOrder>> fetchAllOrders() async {

    try {

      final resp = await http

          .get(Uri.parse('$baseUrl/api/ordenes-reclamos'))

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

          .delete(Uri.parse('$baseUrl/api/ordenes-reclamos/$id'))

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

    required String tipo,

    required String marca,

    required String modelo,

    required String serial,

    int? cod_cliente,

  }) async {

    try {

      final body = <String, dynamic>{

        'tipo': tipo,

        'marca': marca,

        'modelo': modelo,

        'serial': serial,

      };

      

      if (cod_cliente != null) {

        body['cod_cliente'] = cod_cliente;

      }



      final resp = await http

          .post(

            Uri.parse('$baseUrl/api/equipos'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode(body),

          )

          .timeout(_requestTimeout);



      if (resp.statusCode == 201) {

        return const RegisterResponse(success: true, message: 'Equipo creado exitosamente');

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

          .get(Uri.parse('$baseUrl/api/equipos'))

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



  Future<RegisterResponse> deleteEquipment(int codEquipos) async {

    try {

      final resp = await http

          .delete(Uri.parse('$baseUrl/api/equipos/$codEquipos'))

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

  // Función combinada: eliminar equipo y actualizar lista automáticamente
  Future<RegisterResponse> deleteEquipmentAndUpdate(int codEquipos) async {

    try {

      // Primero eliminar el equipo
      final deleteResp = await deleteEquipment(codEquipos);

      if (deleteResp.success) {

        // Si la eliminación fue exitosa, obtener la lista actualizada
        try {

          final updatedList = await fetchEquipments();

          if (kDebugMode) {

            print('🔄 Lista de equipos actualizada: ${updatedList.length} equipos');

          }

          return RegisterResponse(

            success: true, 

            message: 'Equipo eliminado y lista actualizada correctamente'

          );

        } catch (e) {

          if (kDebugMode) print('⚠️ Error actualizando lista: $e');

          return RegisterResponse(

            success: true, 

            message: 'Equipo eliminado, pero error al actualizar lista'

          );

        }

      }

      return deleteResp;

    } catch (e) {

      if (kDebugMode) print('❌ Error en deleteEquipmentAndUpdate: $e');

      return const RegisterResponse(

        success: false, 

        message: 'Error al eliminar equipo y actualizar lista'

      );

    }

  }



  // Método para inactivar/activar cliente
  Future<RegisterResponse> inactivarCliente(int codCliente, String estado) async {
    try {
      final token = await getToken();
      if (token == null) {
        return const RegisterResponse(
          success: false,
          message: 'No hay sesión activa. Por favor inicia sesión.',
        );
      }

      final resp = await http
          .patch(
            Uri.parse('$baseUrl/api/clientes/$codCliente/estado'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'estado': estado,
            }),
          )
          .timeout(_requestTimeout);

      if (resp.statusCode == 200) {
        final message = estado == 'Activo' 
          ? 'Cliente activado exitosamente'
          : 'Cliente inactivado exitosamente';
        return RegisterResponse(success: true, message: message);
      }

      return RegisterResponse(
        success: false,
        message: 'No se pudo actualizar el estado del cliente.',
      );
    } catch (e) {
      return RegisterResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }



  // Método para eliminar técnico (solo Master)
  Future<RegisterResponse> deleteTecnico(String usuario) async {
    try {
      final token = await getToken();
      if (token == null) {
        return const RegisterResponse(
          success: false,
          message: 'No hay sesión activa. Por favor inicia sesión.',
        );
      }

      final resp = await http
          .delete(
            Uri.parse('$baseUrl/api/tecnicos/$usuario'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      if (resp.statusCode == 200) {
        return const RegisterResponse(
          success: true,
          message: 'Técnico eliminado exitosamente',
        );
      }

      return RegisterResponse(
        success: false,
        message: 'No se pudo eliminar el técnico.',
      );
    } catch (e) {
      return RegisterResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  // Método para inactivar/activar técnico
  Future<RegisterResponse> inactivarTecnico(String usuario, String estado) async {
    try {
      final token = await getToken();
      if (token == null) {
        return const RegisterResponse(
          success: false,
          message: 'No hay sesión activa. Por favor inicia sesión.',
        );
      }

      final resp = await http
          .patch(
            Uri.parse('$baseUrl/api/tecnicos/$usuario/estado'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'estado': estado,
            }),
          )
          .timeout(_requestTimeout);

      if (resp.statusCode == 200) {
        final message = estado == 'Activo' 
          ? 'Técnico activado exitosamente'
          : 'Técnico inactivado exitosamente';
        return RegisterResponse(success: true, message: message);
      }

      return RegisterResponse(
        success: false,
        message: 'No se pudo actualizar el estado del técnico.',
      );
    } catch (e) {
      return RegisterResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }



  // Método para actualizar orden de trabajo
  Future<Map<String, dynamic>> updateWorkOrder(int id, Map<String, dynamic> updateData) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'msg': 'No hay sesión activa. Por favor inicia sesión.',
        };
      }

      final resp = await http
          .patch(
            Uri.parse('$baseUrl/api/ordenes-reclamos/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(updateData),
          )
          .timeout(_requestTimeout);

      if (resp.statusCode == 200) {
        final responseData = jsonDecode(resp.body);
        return {
          'success': true,
          'msg': responseData['message'] ?? 'Orden actualizada exitosamente',
        };
      }

      return {
        'success': false,
        'msg': 'No se pudo actualizar la orden de trabajo.',
      };
    } catch (e) {
      return {
        'success': false,
        'msg': 'Error de conexión: ${e.toString()}',
      };
    }
  }



  // Métodos para obtener información del usuario logueado

  Future<String> getRol() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('rol') ?? '';

  }



  Future<String> getTipo() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('tipo') ?? '';

  }



  Future<String> getNombre() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('nombre') ?? '';

  }



  Future<String> getCodPrivilegio() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('codPrivilegio') ?? '';

  }



  Future<int> getUserId() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt('userId') ?? 0;

  }



  Future<bool> isCliente() async {

    final tipo = await getTipo();

    return tipo == 'cliente';

  }



  Future<bool> isTecnico() async {

    final tipo = await getTipo();

    return tipo == 'tecnico';

  }



  Future<bool> isMaster() async {

    final codPrivilegio = await getCodPrivilegio();

    return codPrivilegio == '99';

  }



  Future<bool> isAdministrador() async {

    final codPrivilegio = await getCodPrivilegio();

    return codPrivilegio == '92';

  }



  Future<bool> isTecnicoPriv() async {

    final codPrivilegio = await getCodPrivilegio();

    return codPrivilegio == '50';

  }



  Future<bool> isClientePriv() async {

    final codPrivilegio = await getCodPrivilegio();

    return codPrivilegio == '42';

  }



  Future<List<Cliente>> fetchClientes() async {

    try {

      final resp = await http

          .get(Uri.parse('$baseUrl/api/clientes'))

          .timeout(_requestTimeout);

      if (resp.statusCode != 200) return const [];



      final data = jsonDecode(resp.body);

      if (data is! List) return const [];

      

      return data

          .whereType<Map<String, dynamic>>()

          .map(Cliente.fromJson)

          .toList();

    } catch (_) {

      return const [];

    }

  }



  Future<List<Tecnico>> fetchTecnicos() async {

    try {

      final resp = await http

          .get(Uri.parse('$baseUrl/api/tecnicos'))

          .timeout(_requestTimeout);

      if (resp.statusCode != 200) return const [];



      final data = jsonDecode(resp.body);

      if (data is! List) return const [];

      

      if (kDebugMode) {

        print('📊 Datos recibidos del backend:');

        print('Cantidad de técnicos: ${data.length}');

        if (data.isNotEmpty) {

          print('Primer técnico: ${data[0]}');

          print('cod_tecnico del primer técnico: ${data[0]['cod_tecnico']}');

        }

      }

      

      return data

          .whereType<Map<String, dynamic>>()

          .map(Tecnico.fromJson)

          .toList();

    } catch (e) {

      if (kDebugMode) {

        print('Error fetching tecnicos: $e');

      }

      return const [];

    }

  }



  // Método para validar usuario y correo para recuperación de contraseña

  Future<Map<String, dynamic>> validateUserEmail(String usuario, String correo) async {

    try {

      final resp = await http

          .post(

            Uri.parse('$baseUrl/api/validate-user-email'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({

              'usuario': usuario,

              'correo': correo,

            }),

          )

          .timeout(_requestTimeout);



      if (kDebugMode) {

        print('🔍 Validando usuario y correo...');

        print('Usuario: $usuario, Correo: $correo');

        print('Status code: ${resp.statusCode}');

        print('Response body: ${resp.body}');

      }



      if (resp.statusCode == 200) {

        final data = jsonDecode(resp.body);

        return {

          'success': true,

          'user_data': data['user_data'],

          'reset_token': data['reset_token'],

          'msg': data['msg'],

        };

      } else if (resp.statusCode == 404) {

        final data = jsonDecode(resp.body);

        return {

          'success': false,

          'msg': data['msg'] ?? 'Usuario y correo no coinciden',

        };

      } else {

        return {

          'success': false,

          'msg': 'Error en la validación',

        };

      }

    } catch (e) {

      if (kDebugMode) {

        print('Error en validateUserEmail: $e');

      }

      return {

        'success': false,

        'msg': 'Error de conexión: ${e.toString()}',

      };

    }

  }



  // Método para resetear la contraseña

  Future<Map<String, dynamic>> resetPassword(

    String resetToken,

    String newPassword,

    String confirmPassword,

  ) async {

    try {

      final resp = await http

          .post(

            Uri.parse('$baseUrl/api/reset-password'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({

              'reset_token': resetToken,

              'nueva_password': newPassword,

              'confirmar_password': confirmPassword,

            }),

          )

          .timeout(_requestTimeout);



      if (kDebugMode) {

        print('🔧 Resetenado contraseña...');

        print('Status code: ${resp.statusCode}');

        print('Response body: ${resp.body}');

      }



      if (resp.statusCode == 200) {

        final data = jsonDecode(resp.body);

        return {

          'success': true,

          'msg': data['msg'],

          'usuario': data['usuario'],

          'tipo': data['tipo'],

        };

      } else if (resp.statusCode == 400 || resp.statusCode == 401) {

        final data = jsonDecode(resp.body);

        return {

          'success': false,

          'msg': data['msg'] ?? 'Error al actualizar contraseña',

        };

      } else {

        return {

          'success': false,

          'msg': 'Error al actualizar contraseña',

        };

      }

    } catch (e) {

      if (kDebugMode) {

        print('Error en resetPassword: $e');

      }

      return {

        'success': false,

        'msg': 'Error de conexión: ${e.toString()}',

      };

    }
  }

}


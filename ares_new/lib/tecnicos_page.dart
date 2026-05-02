import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'main.dart';

class TecnicosPage extends StatefulWidget {
  const TecnicosPage({Key? key}) : super(key: key);

  @override
  State<TecnicosPage> createState() => _TecnicosPageState();
}

class _TecnicosPageState extends State<TecnicosPage> {
  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);
  List<Tecnico> _tecnicos = [];
  bool _loading = false;
  String? _error;
  bool _isMaster = false;
  bool _isAdministrador = false;
  bool _isTecnico = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadTecnicos();
  }

  Future<void> _loadUserRole() async {
    final isMaster = await _authService.isMaster();
    final isAdministrador = await _authService.isAdministrador();
    final isTecnico = await _authService.isTecnicoPriv();
    
    if (mounted) {
      setState(() {
        _isMaster = isMaster;
        _isAdministrador = isAdministrador;
        _isTecnico = isTecnico;
      });
    }
  }

  Future<void> _loadTecnicos() async {
    setState(() => _loading = true);
    try {
      final tecnicos = await _authService.fetchTecnicos();
      if (mounted) {
        setState(() {
          _tecnicos = tecnicos;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error al cargar técnicos: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: CustomAppBar(
        title: 'Tecnicos',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTecnicos,
            tooltip: 'Actualizar',
            color: Colors.white,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTecnicos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _tecnicos.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay tecnicos registrados',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tecnicos.length,
                      itemBuilder: (context, index) {
                        final tecnico = _tecnicos[index];
                        
                        // Depuración: mostrar datos del técnico en la lista
                        print('📋 Mostrando técnico en lista [$index]:');
                        print('  - cod_tecnico: ${tecnico.cod_tecnico}');
                        print('  - nombre: ${tecnico.nombre}');
                        print('  - usuario: ${tecnico.usuario}');
                        print('  - estado: ${tecnico.estado}');
                        print('  - cod_privilegio: ${tecnico.cod_privilegio}');
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fila principal: Privilegio y acciones
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPrivilegioColor(tecnico.cod_privilegio),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getPrivilegioNombre(tecnico.cod_privilegio),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                                      onSelected: (value) {
                                        // Depuración: mostrar valores del técnico
                                        print('🔍 Técnico seleccionado:');
                                        print('  - usuario: ${tecnico.usuario}');
                                        print('  - cod_tecnico: ${tecnico.cod_tecnico}');
                                        print('  - nombre: ${tecnico.nombre}');
                                        print('  - estado: ${tecnico.estado}');
                                        print('  - cod_privilegio: ${tecnico.cod_privilegio}');
                                        
                                        switch (value) {
                                          case 'estado':
                                            _toggleEstadoTecnico(tecnico);
                                            break;
                                          case 'privilegio':
                                            _modificarPrivilegio(tecnico.usuario, tecnico.nombre, tecnico.cod_privilegio);
                                            break;
                                          case 'eliminar':
                                            _eliminarTecnico(tecnico);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) {
                                          List<PopupMenuEntry<String>> items = [];
                                          
                                          // Solo mostrar opción de estado si es Master o Administrador
                                          if (_isMaster || _isAdministrador) {
                                            items.add(PopupMenuItem(
                                              value: 'estado',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    tecnico.estado == 'Activo' 
                                                      ? Icons.person_off 
                                                      : Icons.person_add,
                                                    color: tecnico.estado == 'Activo' 
                                                      ? Colors.red 
                                                      : Colors.green,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(tecnico.estado == 'Activo' ? 'Inactivar técnico' : 'Activar técnico'),
                                                ],
                                              ),
                                            ));
                                          }
                                          
                                          // Solo mostrar opción de privilegio si es Master o Administrador
                                          if (_isMaster || _isAdministrador) {
                                            items.add(PopupMenuItem(
                                              value: 'privilegio',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.admin_panel_settings, color: Colors.blue, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Modificar privilegio'),
                                                ],
                                              ),
                                            ));
                                          }
                                          
                                          // Solo mostrar opción de eliminar si es Master
                                          if (_isMaster) {
                                            items.add(PopupMenuItem(
                                              value: 'eliminar',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_forever, color: Colors.red, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Eliminar técnico', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                            ));
                                          }
                                          
                                          // Si es técnico, mostrar mensaje de acceso restringido
                                          if (_isTecnico && !(_isMaster || _isAdministrador)) {
                                            items.add(PopupMenuItem(
                                              value: 'info',
                                              enabled: false,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.info_outline, color: Color(0xFF8B0000), size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Acceso Restringido', style: TextStyle(color: Color(0xFF8B0000))),
                                                ],
                                              ),
                                            ));
                                          }
                                          
                                          return items;
                                        },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Nombre y Usuario
                                Text(
                                  tecnico.nombre,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                
                                Text(
                                  '@${tecnico.usuario}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7F8C8D),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Contacto
                                if (tecnico.correo.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        size: 14,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          tecnico.correo,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF7F8C8D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                
                                if (tecnico.numTelefono.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 14,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        tecnico.numTelefono,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7F8C8D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Color _getPrivilegioColor(String cod_privilegio) {
    switch (cod_privilegio) {
      case '99':
        return const Color(0xFFE74C3C); // Rojo para Master
      case '92':
        return const Color(0xFF3498DB); // Azul para Administrador
      case '50':
        return const Color(0xFF27AE60); // Verde para Técnico
      default:
        return const Color(0xFF95A5A6); // Gris para otros
    }
  }

  String _getPrivilegioNombre(String cod_privilegio) {
    switch (cod_privilegio) {
      case '99':
        return 'MASTER';
      case '92':
        return 'ADMINISTRADOR';
      case '50':
        return 'TECNICO';
      default:
        return cod_privilegio;
    }
  }

  Future<void> _toggleEstadoTecnico(Tecnico tecnico) async {
    print('🔍 Iniciando _toggleEstadoTecnico');
    print('  - usuario: ${tecnico.usuario}');
    print('  - cod_tecnico: ${tecnico.cod_tecnico}');
    print('  - nombre: ${tecnico.nombre}');
    
    // Validar permisos: solo Master o Administrador pueden cambiar estados
    if (!(_isMaster || _isAdministrador)) {
      print('❌ ERROR: Permisos insuficientes para cambiar estado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Solo los Administradores y Masters pueden cambiar el estado de los técnicos'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Validar que el usuario sea válido
    if (tecnico.usuario.isEmpty) {
      print('❌ ERROR: usuario está vacío');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: El técnico no tiene un usuario válido'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    print('✅ usuario es válido y permisos suficientes');

    final nuevoEstado = tecnico.estado == 'Activo' ? 'Inactivo' : 'Activo';
    final accion = nuevoEstado == 'Activo' ? 'activar' : 'inactivar';
    
    // Mostrar diálogo de confirmación
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿$accion técnico?'),
        content: Text('¿Estás seguro de que quieres $accion a ${tecnico.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(accion.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      final result = await _authService.inactivarTecnico(tecnico.usuario, nuevoEstado);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Operación completada'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        _loadTecnicos(); // Recargar la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al $accion técnico: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _modificarPrivilegio(String usuario, String nombre, String privilegioActual) async {
    print('🔍 Iniciando _modificarPrivilegio');
    print('  - usuario: $usuario');
    print('  - nombre: $nombre');
    print('  - privilegioActual: $privilegioActual');
    
    // Validar permisos: solo Master o Administrador pueden cambiar privilegios
    if (!(_isMaster || _isAdministrador)) {
      print('❌ ERROR: Permisos insuficientes para cambiar privilegio');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Solo los Administradores y Masters pueden cambiar los privilegios de los técnicos'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Validar que el usuario sea válido
    if (usuario.isEmpty) {
      print('❌ ERROR: usuario está vacío');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: El técnico no tiene un usuario válido'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    print('✅ usuario es válido y permisos suficientes');

    final privilegios = [
      {'codigo': '92', 'nombre': 'Administrador'},
      {'codigo': '50', 'nombre': 'Tecnico'},
    ];

    String? nuevoPrivilegio = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modificar privilegio de $nombre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: privilegios.map((priv) => RadioListTile<String>(
            title: Text(priv['nombre']!),
            value: priv['codigo']!,
            groupValue: privilegioActual,
            onChanged: (value) {
              Navigator.of(context).pop(value);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );

    if (nuevoPrivilegio == null || nuevoPrivilegio == privilegioActual) return;

    try {
      final result = await _authService.modificarPrivilegioTecnico(usuario, nuevoPrivilegio);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Operación finalizada'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        _loadTecnicos(); // Recargar la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarTecnico(Tecnico tecnico) async {
    print('🔍 Iniciando _eliminarTecnico');
    print('  - usuario: ${tecnico.usuario}');
    print('  - nombre: ${tecnico.nombre}');
    
    // Validar permisos: solo Master puede eliminar técnicos
    if (!_isMaster) {
      print('❌ ERROR: Permisos insuficientes para eliminar técnico');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Solo el Master puede eliminar técnicos'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Validar que el usuario sea válido
    if (tecnico.usuario.isEmpty) {
      print('❌ ERROR: usuario está vacío');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: El técnico no tiene un usuario válido'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    print('✅ usuario es válido y permisos suficientes');
    
    // Mostrar diálogo de confirmación
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar técnico?'),
        content: Text('¿Estás seguro de que quieres eliminar a ${tecnico.nombre}?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      final result = await _authService.deleteTecnico(tecnico.usuario);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Operación completada'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        _loadTecnicos(); // Recargar la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar técnico: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

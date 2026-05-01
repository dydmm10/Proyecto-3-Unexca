import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'main.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({Key? key}) : super(key: key);

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);
  List<Cliente> _clientes = [];
  bool _loading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Cliente> _getFilteredClientes() {
    if (_searchController.text.isEmpty) {
      return _clientes;
    }
    
    final query = _searchController.text.toLowerCase();
    return _clientes.where((cliente) {
      return cliente.nombre.toLowerCase().contains(query) ||
             cliente.correo.toLowerCase().contains(query) ||
             cliente.numTelefono.toLowerCase().contains(query) ||
             cliente.usuario.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _loadClientes() async {
    setState(() => _loading = true);
    try {
      final clientes = await _authService.fetchClientes();
      if (mounted) {
        setState(() {
          _clientes = clientes;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error al cargar clientes: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _toggleEstadoCliente(Cliente cliente) async {
    final nuevoEstado = cliente.estado == 'Activo' ? 'Inactivo' : 'Activo';
    final accion = nuevoEstado == 'Activo' ? 'activar' : 'inactivar';
    
    // Mostrar diálogo de confirmación
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿$accion cliente?'),
        content: Text('¿Estás seguro de que quieres $accion a ${cliente.nombre}?'),
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
      final result = await _authService.inactivarCliente(cliente.codCliente, nuevoEstado);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Operación completada'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        _loadClientes(); // Recargar la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al $accion cliente: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: CustomAppBar(
        title: 'Clientes',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClientes,
            tooltip: 'Actualizar',
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          // Cuadro de búsqueda
          Container(
            margin: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo, teléfono o usuario...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF2F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFD2D8DF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFD2D8DF)),
                ),
              ),
            ),
          ),
          // Contenido principal
          Expanded(
            child: _loading
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
                              onPressed: _loadClientes,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _getFilteredClientes().isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron clientes',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _getFilteredClientes().length,
                            itemBuilder: (context, index) {
                              final cliente = _getFilteredClientes()[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: cliente.estado == 'Activo' 
                                                ? const Color(0xFF2F97E5)
                                                : Colors.grey[400],
                                            child: Text(
                                              cliente.nombre.isNotEmpty
                                                  ? cliente.nombre[0].toUpperCase()
                                                  : 'C',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      cliente.nombre.isNotEmpty
                                                          ? cliente.nombre
                                                          : 'Sin nombre',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: cliente.estado == 'Activo' 
                                                            ? const Color(0xFF2F97E5)
                                                            : Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: cliente.estado == 'Activo'
                                                            ? Colors.green[100]
                                                            : Colors.red[100],
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        cliente.estado,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: cliente.estado == 'Activo'
                                                              ? Colors.green[800]
                                                              : Colors.red[800],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'Usuario: ${cliente.usuario}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _toggleEstadoCliente(cliente),
                                            icon: Icon(
                                              cliente.estado == 'Activo' ? Icons.block : Icons.check_circle,
                                              color: cliente.estado == 'Activo' ? Colors.red[600] : Colors.green[600],
                                              size: 20,
                                            ),
                                            tooltip: cliente.estado == 'Activo' ? 'Inactivar cliente' : 'Activar cliente',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(Icons.email, cliente.correo),
                                      if (cliente.numTelefono.isNotEmpty)
                                        _buildInfoRow(Icons.phone, cliente.numTelefono),
                                      if (cliente.direccion.isNotEmpty)
                                        _buildInfoRow(Icons.location_on, cliente.direccion),
                                      if (cliente.createdAt != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Registrado: ${_formatDate(cliente.createdAt!)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

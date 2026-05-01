import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';

class EditWorkOrderPage extends StatefulWidget {
  final WorkOrder workOrder;

  const EditWorkOrderPage({Key? key, required this.workOrder}) : super(key: key);

  @override
  _EditWorkOrderPageState createState() => _EditWorkOrderPageState();
}

class _EditWorkOrderPageState extends State<EditWorkOrderPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers para los campos editables
  late TextEditingController _estadoController;
  late TextEditingController _prioridadController;
  late TextEditingController _descripcionController;
  late TextEditingController _costoEstimadoController;
  late TextEditingController _costoFinalController;
  late TextEditingController _clienteController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late TextEditingController _tipoController;
  late TextEditingController _equipoController;
  late TextEditingController _diagnosticoController;
  late TextEditingController _correccionesController;
  late TextEditingController _recomendacionesController;
  late TextEditingController _fechaCreacionController;
  late TextEditingController _fechaModificacionController;
  
  // Variables de estado
  String? _selectedEstado;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Lista de estados disponibles
  final List<String> _statusOptions = [
    'ABIERTO',
    'ASIGNADO',
    'EN DIAGNOSTICO',
    'EN REPARACIÓN',
    'LISTO',
    'ENTREGADO',
    'CANCELADO'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCurrentUser();
    _loadInitialData();
  }

  void _initializeControllers() {
    _estadoController = TextEditingController(text: widget.workOrder.status);
    _prioridadController = TextEditingController(text: widget.workOrder.priority);
    _descripcionController = TextEditingController(text: widget.workOrder.description);
    _costoEstimadoController = TextEditingController(text: widget.workOrder.costoEstimado?.toString() ?? '');
    _costoFinalController = TextEditingController(text: widget.workOrder.costoFinal?.toString() ?? '');
    _clienteController = TextEditingController(text: widget.workOrder.nombreCliente ?? '');
    _correoController = TextEditingController(); // Se cargará desde tabla clientes
    _telefonoController = TextEditingController(); // Se cargará desde tabla clientes
    _tipoController = TextEditingController(); // Se cargará desde tabla equipos
    _equipoController = TextEditingController(); // Se cargará desde tabla equipos
    _diagnosticoController = TextEditingController(text: widget.workOrder.diagnostico ?? '');
    _correccionesController = TextEditingController(text: widget.workOrder.correcciones ?? '');
    _recomendacionesController = TextEditingController(text: widget.workOrder.recomendaciones ?? '');
    _fechaCreacionController = TextEditingController(text: _formatDate(widget.workOrder.createdAt));
    _fechaModificacionController = TextEditingController(text: widget.workOrder.fechaModificacion != null ? _formatDate(widget.workOrder.fechaModificacion!) : '');
    
    _selectedEstado = widget.workOrder.status;
  }

  Future<void> _loadCurrentUser() async {
    // Método simplificado ya que no se necesita cargar usuario actual
  }

  Future<void> _loadInitialData() async {
    try {
      // Datos cargados directamente desde el WorkOrder
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      print('🔍 EditWorkOrderPage - Error cargando datos iniciales: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _estadoController.dispose();
    _prioridadController.dispose();
    _descripcionController.dispose();
    _costoEstimadoController.dispose();
    _costoFinalController.dispose();
    _clienteController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _tipoController.dispose();
    _equipoController.dispose();
    _diagnosticoController.dispose();
    _correccionesController.dispose();
    _recomendacionesController.dispose();
    _fechaCreacionController.dispose();
    _fechaModificacionController.dispose();
    super.dispose();
  }

  Future<void> _saveTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Nota: WorkOrder no se puede crear sin los métodos necesarios
      // La función de actualización no está implementada en AuthService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Función de actualización no implementada'),
          backgroundColor: Colors.orange,
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el ticket'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('🔍 EditWorkOrderPage - Error guardando ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar ticket'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveTicket,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket # (no editable)
                    _buildTicketHeader(),
                    const SizedBox(height: 24),
                    
                    // Detalles del Ticket
                    _buildDetallesTicketSection(),
                    const SizedBox(height: 24),
                    
                    // Información del Ticket
                    _buildInformacionTicketSection(),
                    const SizedBox(height: 24),
                    
                    // Control del Ticket
                    _buildControlTicketSection(),
                    const SizedBox(height: 24),
                    
                    // Botones
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTicketHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket #',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.workOrder.id.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetallesTicketSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles del Ticket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            
            // Estado del caso
            DropdownButtonFormField<String>(
              initialValue: _selectedEstado,
              decoration: const InputDecoration(
                labelText: 'Estado del caso',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _statusOptions.map((estado) {
                return DropdownMenuItem(
                  value: estado,
                  child: Text(estado),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEstado = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor seleccione un estado';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Prioridad
            TextFormField(
              controller: _prioridadController,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              enabled: false, // No editable
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            
            // Descripción del problema
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción del problema',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 3,
              enabled: false, // No editable
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            
            // Costo estimado
            TextFormField(
              controller: _costoEstimadoController,
              decoration: const InputDecoration(
                labelText: 'Costo estimado',
                border: OutlineInputBorder(),
                prefixText: '\$',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              enabled: false, // No editable
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            
            // Costo final
            TextFormField(
              controller: _costoFinalController,
              decoration: const InputDecoration(
                labelText: 'Costo final',
                border: OutlineInputBorder(),
                prefixText: '\$',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final cost = double.tryParse(value);
                  if (cost == null || cost < 0) {
                    return 'Ingrese un costo válido';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformacionTicketSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Ticket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            
            // Cliente
            TextFormField(
              controller: _clienteController,
              decoration: const InputDecoration(
                labelText: 'Cliente',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              enabled: false, // No editable
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            
            // Correo electrónico
            TextFormField(
              controller: _correoController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              enabled: false, // No editable
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            
            // Contacto
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Contacto',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              enabled: false, // No editable
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            
            // Tipo
            TextFormField(
              controller: _tipoController,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              enabled: false, // No editable
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            
            // Equipo
            TextFormField(
              controller: _equipoController,
              decoration: const InputDecoration(
                labelText: 'Equipo',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              enabled: false, // No editable
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlTicketSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Control del Ticket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            
            // Diagnóstico
            TextFormField(
              controller: _diagnosticoController,
              decoration: const InputDecoration(
                labelText: 'Diagnóstico',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            
            // Correcciones
            TextFormField(
              controller: _correccionesController,
              decoration: const InputDecoration(
                labelText: 'Correcciones',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            
            // Recomendaciones
            TextFormField(
              controller: _recomendacionesController,
              decoration: const InputDecoration(
                labelText: 'Recomendaciones',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            
            // Fecha de creación
            TextFormField(
              controller: _fechaCreacionController,
              decoration: const InputDecoration(
                labelText: 'Fecha de creación',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              enabled: false, // No editable
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            
            // Fecha de modificación
            TextFormField(
              controller: _fechaModificacionController,
              decoration: const InputDecoration(
                labelText: 'Fecha de modificación',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              enabled: false, // No editable
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Guardar Cambios'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

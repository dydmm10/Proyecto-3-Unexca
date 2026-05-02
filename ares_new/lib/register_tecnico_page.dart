import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class RegisterTecnicoPage extends StatefulWidget {
  const RegisterTecnicoPage({Key? key}) : super(key: key);

  @override
  State<RegisterTecnicoPage> createState() => _RegisterTecnicoPageState();
}

class _RegisterTecnicoPageState extends State<RegisterTecnicoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  String _codPrivilegio = '50'; // Por defecto Técnico
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);
  bool _isMaster = false;
  bool _isAdministrador = false;
  bool _hasPermission = false;

  // Lista de privilegios actualizada según la tabla (sin opción Master)
  final List<Map<String, String>> _privilegios = [
    {'codigo': '92', 'nombre': 'Administrador'},
    {'codigo': '50', 'nombre': 'Técnico'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final isMaster = await _authService.isMaster();
    final isAdministrador = await _authService.isAdministrador();
    
    if (mounted) {
      setState(() {
        _isMaster = isMaster;
        _isAdministrador = isAdministrador;
        _hasPermission = isMaster || isAdministrador;
      });
    }
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  String? _validateUsuario(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa un usuario';
    final usuario = v.trim();
    if (usuario.length < 3) return 'El usuario debe tener al menos 3 caracteres';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa un email';
    final email = v.trim();
    final regex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!regex.hasMatch(email)) return 'Email no válido';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa la contraseña';
    if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  String? _validateNombre(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
    return null;
  }

  String? _validateTelefono(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu número de teléfono';
    if (v.trim().length < 8) return 'El teléfono debe tener al menos 8 dígitos';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
    if (v != _passwordController.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _authService.registerTecnico(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nombre: _nombreController.text.trim(),
        usuario: _usuarioController.text.trim(),
        num_telefono: _telefonoController.text.trim(),
        cod_privilegio: _codPrivilegio,
      );

      if (!mounted) return;
      
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Técnico registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        _formKey.currentState?.reset();
        _passwordController.clear();
        _confirmController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Error al registrar técnico'),
            backgroundColor: Colors.red,
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si no tiene permisos, mostrar pantalla de acceso denegado
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A88C6),
          title: const Text(
            'Acceso Denegado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Acceso Restringido',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Solo los Administradores y Masters\npueden agregar nuevos técnicos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A88C6),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'Regresar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A88C6),
        toolbarHeight: 88,
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFAED8F0),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Agregar nuevo tecnico',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Image.asset(
                'assets/logo_unexca.jpg',
                height: 48,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E8EB),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A88C6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'REGISTRAR TECNICO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(text: 'USUARIO'),
                        const SizedBox(height: 6),
                        _DesktopInput(
                          controller: _usuarioController,
                          hint: 'EJ. JSANCHEZ, MRODRIGUEZ...',
                          validator: _validateUsuario,
                        ),
                        const SizedBox(height: 12),
                        
                        const _FieldLabel(text: 'NOMBRE COMPLETO'),
                        const SizedBox(height: 6),
                        _DesktopInput(
                          controller: _nombreController,
                          hint: 'EJ. JUAN SÁNCHEZ',
                          validator: _validateNombre,
                        ),
                        const SizedBox(height: 12),
                        
                        const _FieldLabel(text: 'EMAIL'),
                        const SizedBox(height: 6),
                        _DesktopInput(
                          controller: _emailController,
                          hint: 'Ej. juan@empresa.com',
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        
                        const _FieldLabel(text: 'CONTRASEÑA'),
                        const SizedBox(height: 6),
                        _PasswordInput(
                          controller: _passwordController,
                          hint: 'Mínimo 6 caracteres',
                          obscureText: _obscure,
                          validator: _validatePassword,
                          onToggle: () => setState(() => _obscure = !_obscure),
                        ),
                        const SizedBox(height: 12),
                        
                        const _FieldLabel(text: 'CONFIRMAR CONTRASEÑA'),
                        const SizedBox(height: 6),
                        _PasswordInput(
                          controller: _confirmController,
                          hint: 'Repite la contraseña',
                          obscureText: _obscureConfirm,
                          validator: _validateConfirmPassword,
                          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        const SizedBox(height: 12),
                        
                        const _FieldLabel(text: 'TELÉFONO'),
                        const SizedBox(height: 6),
                        _DesktopInput(
                          controller: _telefonoController,
                          hint: 'Ej. 809-555-1234',
                          validator: _validateTelefono,
                        ),
                        const SizedBox(height: 12),
                        
                        const _FieldLabel(text: 'PRIVILEGIO'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F1F3),
                            border: Border.all(color: const Color(0xFFC4CAD1)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _codPrivilegio,
                              isExpanded: true,
                              items: _privilegios.map((privilegio) {
                                return DropdownMenuItem<String>(
                                  value: privilegio['codigo'],
                                  child: Text(privilegio['nombre']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _codPrivilegio = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A88C6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _loading ? null : _register,
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'GUARDAR TÉCNICO',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF4E5D6C),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class _DesktopInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;

  const _DesktopInput({
    required this.controller,
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA2A9B0)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF0F1F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFC4CAD1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFC4CAD1)),
        ),
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final String? Function(String?)? validator;
  final VoidCallback onToggle;

  const _PasswordInput({
    required this.controller,
    required this.hint,
    required this.obscureText,
    this.validator,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA2A9B0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF0F1F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFC4CAD1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFC4CAD1)),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
          color: const Color(0xFFA2A9B0),
        ),
      ),
    );
  }
}

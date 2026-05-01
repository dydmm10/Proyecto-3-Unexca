import 'package:flutter/material.dart';

import 'register_page.dart';

import 'forgot_password_page.dart';

import 'clientes_page.dart';

import 'tecnicos_page.dart';

import 'services/auth_service.dart';

import 'register_tecnico_page.dart';

import 'edit_work_order_page.dart';



void main() {

  runApp(const MyApp());

}



class MyApp extends StatelessWidget {

  const MyApp({Key? key}) : super(key: key);



  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'Atención de Reclamos y Servicio Técnico (ARES)',

      theme: ThemeData(

        primarySwatch: Colors.blue,

        appBarTheme: const AppBarTheme(

          backgroundColor: Colors.blue,

          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),

          iconTheme: IconThemeData(color: Colors.black),

          toolbarTextStyle: TextStyle(color: Colors.black),

          foregroundColor: Colors.black,

        ),

      ),

      home: const LoginPage(),

      builder: (context, child) {

        return Stack(

          children: [

            if (child != null) child,

            const AuthorsOverlay(),

          ],

        );

      },

    );

  }

}



class LoginPage extends StatefulWidget {

  const LoginPage({Key? key}) : super(key: key);



  @override

  State<LoginPage> createState() => _LoginPageState();

}



class _LoginPageState extends State<LoginPage> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usuarioController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscure = true;

  bool _loading = false;

  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);



  @override

  void dispose() {

    _usuarioController.dispose();

    _passwordController.dispose();

    super.dispose();

  }



  Future<void> _login() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);



    final usuario = _usuarioController.text.trim();

    final password = _passwordController.text;



    try {

      final loginData = await _authService.login(usuario, password);

      if (!mounted) return;



      if (loginData != null) {

        final rol = loginData['rol'] ?? '';

        final nombre = loginData['nombre'] ?? '';

        

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(

              '¡Bienvenido${rol == 'tecnico' ? ' Técnico' : ''} $nombre!',

              style: const TextStyle(fontWeight: FontWeight.bold),

            ),

            backgroundColor: rol == 'tecnico' ? Colors.blue : Colors.green,

          ),

        );

        

        Navigator.of(context).pushReplacement(

          MaterialPageRoute(builder: (_) => const HomePage()),

        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text(

              'No se pudo iniciar sesión. Revisa credenciales o conexión con el servidor.',

            ),

          ),

        );

      }

    } finally {

      if (mounted) {

        setState(() => _loading = false);

      }

    }

  }



  String? _validateUsuario(String? v) {

    if (v == null || v.trim().isEmpty) return 'Ingresa un usuario';

    final usuario = v.trim();

    if (usuario.length < 3) return 'El usuario debe tener al menos 3 caracteres';

    return null;

  }



  String? _validatePassword(String? v) {

    if (v == null || v.isEmpty) return 'Ingresa la contraseña';

    if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres';

    return null;

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        centerTitle: false,

        title: Row(

          mainAxisSize: MainAxisSize.min,

          children: [

            const Text('Atención de Reclamos y Servicio Técnico (ARES)'),

            const SizedBox(width: 8),

            // Logo to the right of the title; place `assets/unexca_logo.png` in project

            Image.asset(

              'assets/logo_unexca.jpg',

              height: 32,

              fit: BoxFit.contain,

            ),

          ],

        ),

      ),

      body: Center(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(16),

          child: Card(

            color: Colors.blue.shade50,

            elevation: 4,

            shape: RoundedRectangleBorder(

              borderRadius: BorderRadius.circular(8),

              side: BorderSide(color: Colors.blue.shade700, width: 2),

            ),

            child: Padding(

              padding: const EdgeInsets.all(16),

              child: Form(

                key: _formKey,

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    TextFormField(

                      controller: _usuarioController,

                      keyboardType: TextInputType.text,

                      decoration: const InputDecoration(

                        labelText: 'Usuario',

                        prefixIcon: Icon(Icons.person),

                      ),

                      validator: _validateUsuario,

                    ),

                    const SizedBox(height: 12),

                    TextFormField(

                      controller: _passwordController,

                      obscureText: _obscure,

                      decoration: InputDecoration(

                        labelText: 'Contraseña',

                        prefixIcon: const Icon(Icons.lock),

                        suffixIcon: IconButton(

                          icon: Icon(_obscure

                              ? Icons.visibility

                              : Icons.visibility_off),

                          onPressed: () => setState(() => _obscure = !_obscure),

                        ),

                      ),

                      validator: _validatePassword,

                    ),

                    const SizedBox(height: 20),

                    SizedBox(

                      width: double.infinity,

                      child: ElevatedButton(

                        onPressed: _loading ? null : _login,

                        child: _loading

                            ? const SizedBox(

                                height: 18,

                                width: 18,

                                child: CircularProgressIndicator(

                                    strokeWidth: 2, color: Colors.white),

                              )

                            : const Text('Ingresar'),

                      ),

                    ),

                    const SizedBox(height: 8),

                    Row(

                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [

                        TextButton(

                          onPressed: () {

                            Navigator.of(context).push(

                              MaterialPageRoute(

                                  builder: (_) => const RegisterPage()),

                            );

                          },

                          child: const Text('Registrarse'),

                        ),

                        TextButton(

                          onPressed: () {

                            Navigator.of(context).push(

                              MaterialPageRoute(

                                  builder: (_) => const ForgotPasswordPage()),

                            );

                          },

                          child: const Text('¿Olvidaste tu contraseña?'),

                        ),

                      ],

                    ),

                  ],

                ),

              ),

            ),

          ),

        ),

      ),

    );

  }

}



class HomePage extends StatefulWidget {

  const HomePage({Key? key}) : super(key: key);



  @override

  State<HomePage> createState() => _HomePageState();

}



class _HomePageState extends State<HomePage> {

  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);

  bool _isCliente = false;

  bool _isTecnico = false;

  bool _isAdministrador = false;

  bool _isMaster = false;

  bool _hasDataMasterAccess = false; // Para controlar acceso a datos maestros

  String _userName = '';

  String _userRole = '';

  Color _roleColor = Colors.grey;



  @override

  void initState() {

    super.initState();

    _loadUserRole();

  }



  Future<void> _loadUserRole() async {

    final isCliente = await _authService.isCliente();

    final isTecnico = await _authService.isTecnicoPriv();

    final isAdministrador = await _authService.isAdministrador();

    final isMaster = await _authService.isMaster();

    final userName = await _authService.getNombre();

    

    String role = '';

    Color roleColor = Colors.grey;

    

    if (isMaster) {

      role = 'Master';

      roleColor = const Color(0xFFE74C3C); // Rojo

    } else if (isAdministrador) {

      role = 'Administrador';

      roleColor = const Color(0xFF3498DB); // Azul

    } else if (isTecnico) {

      role = 'Técnico';

      roleColor = const Color(0xFF27AE60); // Verde

    } else {

      role = 'Cliente';

      roleColor = const Color(0xFF95A5A6); // Gris

    }

    

    if (mounted) {

      setState(() {

        _isCliente = isCliente;

        _isTecnico = isTecnico;

        _isAdministrador = isAdministrador;

        _isMaster = isMaster;

        _hasDataMasterAccess = isTecnico || isAdministrador || isMaster;

        _userName = userName ?? 'Usuario';

        _userRole = role;

        _roleColor = roleColor;

      });

    }

  }



  void _openBlankModule(BuildContext context, String title) {

    Navigator.of(context).push(

      MaterialPageRoute(

        builder: (_) => BlankModulePage(title: title),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF3F4F6),

      body: SafeArea(

        child: SingleChildScrollView(

          child: Column(

            children: [

              Container(

                width: double.infinity,

                padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),

                decoration: const BoxDecoration(

                  color: Color(0xFF2F97E5),

                  borderRadius: BorderRadius.only(

                    bottomLeft: Radius.circular(12),

                    bottomRight: Radius.circular(12),

                  ),

                ),

                child: Column(

                  children: [

                    Row(

                      children: [

                        const Expanded(

                          child: Text(

                            'Atención de Reclamos y Servicio Técnico (ARES)',

                            style: TextStyle(

                              color: Colors.white,

                              fontSize: 20,

                              fontWeight: FontWeight.w700,

                            ),

                          ),

                        ),

                        Image.asset(

                          'assets/logo_unexca.jpg',

                          height: 32,

                          fit: BoxFit.contain,

                        ),

                        const SizedBox(width: 8),

                        IconButton(

                          onPressed: () {

                            Navigator.of(context).pushReplacement(

                              MaterialPageRoute(

                                  builder: (_) => const LoginPage()),

                            );

                          },

                          icon: const Icon(Icons.logout, color: Colors.white),

                          tooltip: 'Cerrar sesión',

                        ),

                      ],

                    ),

                    const SizedBox(height: 8),

                    // Mensaje de bienvenida con nombre y rol

                    Container(

                      width: double.infinity,

                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                      decoration: BoxDecoration(

                        color: Colors.white.withValues(alpha: 0.15),

                        borderRadius: BorderRadius.circular(8),

                        border: Border.all(

                          color: Colors.white.withValues(alpha: 0.3),

                          width: 1,

                        ),

                      ),

                      child: Row(

                        children: [

                          Icon(

                            Icons.person_outline,

                            color: Colors.white,

                            size: 20,

                          ),

                          const SizedBox(width: 8),

                          Expanded(

                            child: Text(

                              _userName,

                              style: TextStyle(

                                color: Colors.white,

                                fontSize: 14,

                                fontWeight: FontWeight.w600,

                              ),

                            ),

                          ),

                          Container(

                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                            decoration: BoxDecoration(

                              color: _roleColor,

                              borderRadius: BorderRadius.circular(12),

                            ),

                            child: Text(

                              _userRole,

                              style: const TextStyle(

                                color: Colors.white,

                                fontSize: 12,

                                fontWeight: FontWeight.w700,

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                    const SizedBox(height: 10),

                  ],

                ),

              ),

              Padding(

                padding: const EdgeInsets.all(12),

                child: Card(

                  color: Colors.white,

                  child: Column(

                    children: [

                      SizedBox(height: 14),

                      Row(

                        children: [

                          Expanded(

                            child: _DashboardActionTile(

                              icon: Icons.assignment,

                              label: 'Ordenes de trabajo',

                              onTap: () => _openBlankModule(

                                context,

                                'Ordenes de trabajo',

                              ),

                            ),

                          ),

                          Expanded(

                            child: _DashboardActionTile(

                              icon: Icons.assignment_add,

                              label: 'Ordenes de mantenimiento',

                              onTap: () => _openBlankModule(

                                context,

                                'Ordenes de mantenimiento',

                              ),

                            ),

                          ),

                        ],

                      ),

                      SizedBox(height: 10),

                      Row(

                        children: [

                          Expanded(

                            child: _DashboardActionTile(

                              icon: Icons.calendar_month,

                              label: 'Horario de servicio',

                              onTap: () => _openBlankModule(

                                context,

                                'Horario de servicio',

                              ),

                            ),

                          ),

                          Expanded(

                            child: _DashboardActionTile(

                              icon: Icons.more_horiz,

                              label: '',

                              onTap: () {},

                            ),

                          ),

                        ],

                      ),

                      SizedBox(height: 12),

                      TextButton.icon(

                        onPressed: () =>

                            _openBlankModule(context, 'Crear orden de trabajo'),

                        icon: const Icon(Icons.add, color: Color(0xFF4A93C9)),

                        label: const Text(

                          'Crear orden de trabajo/mantenimiento',

                          style: TextStyle(

                            color: Color(0xFF4A93C9),

                            fontWeight: FontWeight.w700,

                          ),

                        ),

                      ),

                      SizedBox(height: 12),

                      Divider(height: 1),

                      SizedBox(height: 10),

                      // Solo mostrar datos maestros si tiene acceso

                      if (_hasDataMasterAccess) ...[

                        Text(

                          'Datos maestros',

                          style: TextStyle(

                            fontSize: 16,

                            fontWeight: FontWeight.w600,

                            color: Colors.black54,

                          ),

                        ),

                        SizedBox(height: 8),

                        Row(

                          children: [

                            Expanded(

                              child: _DashboardActionTile(

                                icon: Icons.devices,

                                label: 'Equipos',

                                onTap: () => _openBlankModule(

                                  context,

                                  'Equipos',

                                ),

                              ),

                            ),

                            Expanded(

                              child: _DashboardActionTile(

                                icon: Icons.person,

                                label: 'Tecnicos',

                                onTap: () => _openBlankModule(

                                  context,

                                  'Tecnicos',

                                ),

                              ),

                            ),

                            Expanded(

                              child: _DashboardActionTile(

                                icon: Icons.person_2,

                                label: 'Clientes',

                                onTap: () => Navigator.of(context).push(

                                  MaterialPageRoute(

                                    builder: (_) => const ClientesPage(),

                                  ),

                                ),

                              ),

                            ),

                          ],

                        ),

                        SizedBox(height: 14),

                        TextButton.icon(

                          onPressed: () =>

                              _openBlankModule(context, 'Agregar nuevo equipo'),

                          icon: const Icon(Icons.add, color: Color(0xFF4A93C9)),

                          label: const Text(

                            'Agregar nuevo equipo',

                            style: TextStyle(

                              color: Color(0xFF4A93C9),

                              fontWeight: FontWeight.w700,

                            ),

                          ),

                        ),

                        TextButton.icon(

                          onPressed: () =>

                              _openBlankModule(context, 'Agregar nuevo técnico'),

                          icon: const Icon(Icons.add, color: Color(0xFF4A93C9)),

                          label: const Text(

                            'Agregar nuevo tecnico',

                            style: TextStyle(

                              color: Color(0xFF4A93C9),

                              fontWeight: FontWeight.w700,

                            ),

                          ),

                        ),

                      ],

                      SizedBox(height: 14),

                    ],

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class _TopMenuButton extends StatelessWidget {

  final IconData icon;

  final String label;

  final Color iconColor;

  final Color textColor;

  final VoidCallback onTap;



  const _TopMenuButton({

    required this.icon,

    required this.label,

    required this.iconColor,

    required this.textColor,

    required this.onTap,

  });



  @override

  Widget build(BuildContext context) {

    return InkWell(

      borderRadius: BorderRadius.circular(8),

      onTap: onTap,

      child: Padding(

        padding: const EdgeInsets.symmetric(vertical: 10),

        child: Column(

          children: [

            Icon(icon, color: iconColor),

            const SizedBox(height: 4),

            Text(

              label,

              style: TextStyle(

                color: textColor,

                fontWeight: FontWeight.w600,

              ),

            ),

          ],

        ),

      ),

    );

  }

}



class _DashboardActionTile extends StatelessWidget {

  final IconData icon;

  final String label;

  final VoidCallback onTap;



  const _DashboardActionTile({

    required this.icon,

    required this.label,

    required this.onTap,

  });



  @override

  Widget build(BuildContext context) {

    if (label.isEmpty) {

      return const SizedBox(height: 72);

    }



    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 8),

      child: InkWell(

        borderRadius: BorderRadius.circular(10),

        onTap: onTap,

        child: Padding(

          padding: const EdgeInsets.symmetric(vertical: 4),

          child: Column(

            children: [

              CircleAvatar(

                radius: 24,

                backgroundColor: const Color(0xFF2F97E5),

                child: Icon(icon, color: Colors.white),

              ),

              const SizedBox(height: 8),

              Text(

                label,

                textAlign: TextAlign.center,

                style: const TextStyle(fontSize: 13, color: Colors.black87),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class BlankModulePage extends StatelessWidget {

  final String title;



  const BlankModulePage({Key? key, required this.title}) : super(key: key);



  @override

  Widget build(BuildContext context) {

    if (title == 'Ordenes de trabajo') {

      return const WorkOrdersListPage();

    }



    if (title == 'Ordenes de mantenimiento') {

      return const MaintenanceOrdersListPage();

    }



    if (title == 'Horario de servicio') {

      return const ServiceSchedulePage();

    }



    if (title == 'Crear orden de trabajo') {

      return const CreateWorkOrderPage();

    }



    if (title == 'Equipos') {

      return const EquipmentListPage();

    }



    if (title == 'Agregar nuevo equipo') {

      return const RegisterEquipmentPage();

    }



    if (title == 'Crear orden de trabajo') {

      return const CreateWorkOrderPage();

    }



    if (title == 'Tecnicos') {

      return const TecnicosPage();

    }



    if (title == 'Agregar nuevo técnico') {

      return const RegisterTecnicoPage();

    }



    return Scaffold(

      appBar: CustomAppBar(title: title),

      body: const SizedBox.expand(),

    );

  }

}



class ServiceSchedulePage extends StatelessWidget {

  const ServiceSchedulePage({Key? key}) : super(key: key);



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF2F2F2),

      appBar: const CustomAppBar(

        title: 'Horario de servicio',

      ),

      body: LayoutBuilder(

        builder: (context, constraints) {

          final contentWidth = constraints.maxWidth.clamp(320.0, 760.0);

          final scale = (contentWidth / 760.0).clamp(0.58, 0.82);

          final cardWidth = (300.0 * scale).clamp(210.0, 280.0);



          return Center(

            child: SingleChildScrollView(

              padding: EdgeInsets.symmetric(

                horizontal: 16,

                vertical: 12 * scale,

              ),

              child: ConstrainedBox(

                constraints: BoxConstraints(maxWidth: contentWidth),

                child: Column(

                  children: [

                    SizedBox(height: 6 * scale),

                    ClipPath(

                      clipper: _BottomPointClipper(

                        pointWidth: cardWidth * 0.25,

                        pointHeight: 24 * scale,

                      ),

                      child: Container(

                        width: cardWidth,

                        color: const Color(0xFFAED8F0),

                        padding: EdgeInsets.fromLTRB(

                          14 * scale,

                          18 * scale,

                          14 * scale,

                          58 * scale,

                        ),

                        child: Column(

                          children: [

                            Text(

                              'Lunes a Sabado',

                              textAlign: TextAlign.center,

                              style: TextStyle(

                                fontSize: 32 * scale,

                                fontWeight: FontWeight.w700,

                                color: const Color(0xFF3F4F5D),

                              ),

                            ),

                            SizedBox(height: 14 * scale),

                            Text(

                              '9:00 AM - 5 PM',

                              textAlign: TextAlign.center,

                              style: TextStyle(

                                fontSize: 24 * scale,

                                fontWeight: FontWeight.w700,

                                color: const Color(0xFF2F3A45),

                              ),

                            ),

                            SizedBox(height: 18 * scale),

                            Text(

                              'Domingos',

                              textAlign: TextAlign.center,

                              style: TextStyle(

                                fontSize: 32 * scale,

                                fontWeight: FontWeight.w700,

                                color: const Color(0xFF3F4F5D),

                              ),

                            ),

                            SizedBox(height: 14 * scale),

                            Text(

                              '9:00 AM - 1 PM',

                              textAlign: TextAlign.center,

                              style: TextStyle(

                                fontSize: 24 * scale,

                                fontWeight: FontWeight.w700,

                                color: const Color(0xFF2F3A45),

                              ),

                            ),

                            SizedBox(height: 16 * scale),

                            Icon(

                              Icons.location_on_outlined,

                              size: 42 * scale,

                              color: Colors.white,

                            ),

                            SizedBox(height: 8 * scale),

                            Text(

                              'Final Av. Fuerzas Armadas, mercado de\n'

                              'las flores, san José cotiza, calle real\n'

                              'santa elena.',

                              textAlign: TextAlign.center,

                              style: TextStyle(

                                fontSize: 16 * scale,

                                fontWeight: FontWeight.w700,

                                color: const Color(0xFF4D6575),

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

          );

        },

      ),

    );

  }

}



class _BottomPointClipper extends CustomClipper<Path> {

  final double pointWidth;

  final double pointHeight;



  const _BottomPointClipper({

    required this.pointWidth,

    required this.pointHeight,

  });



  @override

  Path getClip(Size size) {

    final path = Path()

      ..moveTo(0, 0)

      ..lineTo(size.width, 0)

      ..lineTo(size.width, size.height - pointHeight)

      ..lineTo(size.width / 2 + pointWidth, size.height - pointHeight)

      ..lineTo(size.width / 2, size.height)

      ..lineTo(size.width / 2 - pointWidth, size.height - pointHeight)

      ..lineTo(0, size.height - pointHeight)

      ..close();



    return path;

  }



  @override

  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;

}



class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {

  final String title;

  final List<Widget>? actions;

  final double? toolbarHeight;



  const CustomAppBar({

    Key? key,

    required this.title,

    this.actions,

    this.toolbarHeight = 88,

  }) : super(key: key);



  @override

  Size get preferredSize => Size.fromHeight(toolbarHeight ?? 88);



  @override

  Widget build(BuildContext context) {

    return AppBar(

      toolbarHeight: toolbarHeight,

      titleSpacing: 0,

      backgroundColor: const Color(0xFF0A88C6),

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

                    title,

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

      actions: actions,

    );

  }

}



class EquipmentListPage extends StatefulWidget {

  const EquipmentListPage({Key? key}) : super(key: key);



  @override

  State<EquipmentListPage> createState() => _EquipmentListPageState();

}



class _EquipmentListPageState extends State<EquipmentListPage> {

  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);

  final TextEditingController _searchController = TextEditingController();

  late Future<List<EquipmentRecord>> _futureEquipments;



  @override

  void initState() {

    super.initState();

    _futureEquipments = _authService.fetchEquipments();

  }



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  List<EquipmentRecord> _filteredItems(List<EquipmentRecord> all) {

    final q = _searchController.text.trim().toLowerCase();

    if (q.isEmpty) return all;



    return all.where((e) {

      return e.marca.toLowerCase().contains(q) ||

          e.modelo.toLowerCase().contains(q) ||

          e.title.toLowerCase().contains(q) ||

          e.serial.toLowerCase().contains(q) ||

          e.tipo.toLowerCase().contains(q) ||

          (e.nombreCliente?.toLowerCase().contains(q) ?? false) ||

          (e.usuarioCliente?.toLowerCase().contains(q) ?? false);

    }).toList();

  }



  Future<void> _deleteEquipment(int codEquipos, String marca, String modelo, String serial) async {

    // Mostrar diálogo de confirmación

    final confirmado = await showDialog<bool>(

      context: context,

      builder: (context) => AlertDialog(

        title: Text('¿Eliminar equipo?'),

        content: Text('¿Estás seguro de que quieres eliminar el equipo?\n\nMarca: $marca\nModelo: $modelo\nSerial: $serial'),

        actions: [

          TextButton(

            onPressed: () => Navigator.of(context).pop(false),

            child: const Text('Cancelar'),

          ),

          TextButton(

            onPressed: () => Navigator.of(context).pop(true),

            child: Text('Eliminar', style: TextStyle(color: Colors.red)),

          ),

        ],

      ),

    );



    if (confirmado != true) return;



    final result = await _authService.deleteEquipment(codEquipos);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(result.message ?? 'Operación finalizada.')),

    );

    if (result.success) {

      setState(() => _futureEquipments = _authService.fetchEquipments());

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF0F2F5),

      appBar: const CustomAppBar(

        title: 'Equipos',

      ),

      body: Center(

        child: ConstrainedBox(

          constraints: const BoxConstraints(maxWidth: 900),

          child: Padding(

            padding: const EdgeInsets.all(20),

            child: Column(

              children: [

                TextField(

                  controller: _searchController,

                  onChanged: (_) => setState(() {}),

                  decoration: InputDecoration(

                    hintText: 'Buscar serial o marca...',

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

                const SizedBox(height: 14),

                Expanded(

                  child: FutureBuilder<List<EquipmentRecord>>(

                    future: _futureEquipments,

                    builder: (context, snapshot) {

                      if (snapshot.connectionState == ConnectionState.waiting) {

                        return const Center(child: CircularProgressIndicator());

                      }



                      final all = snapshot.data ?? const <EquipmentRecord>[];

                      final items = _filteredItems(all);

                      if (items.isEmpty) {

                        return const Center(

                          child: Text('No hay equipos registrados.'),

                        );

                      }



                      return ListView.separated(

                        itemCount: items.length,

                        separatorBuilder: (_, __) => const SizedBox(height: 10),

                        itemBuilder: (context, index) {

                          final item = items[index];

                          return Container(

                            decoration: BoxDecoration(

                              color: const Color(0xFFF6F7F9),

                              borderRadius: BorderRadius.circular(10),

                              border: Border.all(

                                color: const Color(0xFFDFE4EA),

                              ),

                            ),

                            child: Container(

                              decoration: const BoxDecoration(

                                border: Border(

                                  left: BorderSide(

                                    color: Color(0xFF0A88C6),

                                    width: 4,

                                  ),

                                ),

                              ),

                              child: Padding(

                                padding: const EdgeInsets.all(16),

                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    // Fila principal: Tipo y acciones

                                    Row(

                                      children: [

                                        Container(

                                          padding: const EdgeInsets.symmetric(

                                            horizontal: 8,

                                            vertical: 4,

                                          ),

                                          decoration: BoxDecoration(

                                            color: const Color(0xFF0A88C6),

                                            borderRadius: BorderRadius.circular(4),

                                          ),

                                          child: Text(

                                            item.tipo,

                                            style: const TextStyle(

                                              fontSize: 10,

                                              fontWeight: FontWeight.w700,

                                              color: Colors.white,

                                            ),

                                          ),

                                        ),

                                        const Spacer(),

                                        IconButton(

                                          tooltip: 'Eliminar',

                                          onPressed: () =>

                                              _deleteEquipment(item.codEquipos, item.marca, item.modelo, item.serial),

                                          icon: const Icon(

                                            Icons.delete_outline,

                                            color: Colors.redAccent,

                                            size: 20,

                                          ),

                                        ),

                                      ],

                                    ),

                                    const SizedBox(height: 8),

                                    

                                    // Marca y Modelo

                                    Text(

                                      '${item.marca} ${item.modelo}',

                                      style: const TextStyle(

                                        fontSize: 16,

                                        fontWeight: FontWeight.w700,

                                        color: Color(0xFF2C3E50),

                                      ),

                                    ),

                                    const SizedBox(height: 4),

                                    

                                    // Serial

                                    Text(

                                      'Serial: ${item.serial}',

                                      style: const TextStyle(

                                        fontSize: 13,

                                        color: Color(0xFF7F8C8D),

                                      ),

                                    ),

                                    

                                    // Cliente (si existe)

                                    if (item.nombreCliente != null) ...[

                                      const SizedBox(height: 6),

                                      Container(

                                        padding: const EdgeInsets.symmetric(

                                          horizontal: 8,

                                          vertical: 4,

                                        ),

                                        decoration: BoxDecoration(

                                          color: const Color(0xFFE8F5E8),

                                          borderRadius: BorderRadius.circular(4),

                                          border: Border.all(

                                            color: const Color(0xFF4CAF50),

                                            width: 1,

                                          ),

                                        ),

                                        child: Row(

                                          mainAxisSize: MainAxisSize.min,

                                          children: [

                                            const Icon(

                                              Icons.person_outline,

                                              size: 12,

                                              color: Color(0xFF4CAF50),

                                            ),

                                            const SizedBox(width: 4),

                                            Text(

                                              '${item.nombreCliente} (${item.usuarioCliente})',

                                              style: const TextStyle(

                                                fontSize: 11,

                                                fontWeight: FontWeight.w600,

                                                color: Color(0xFF2E7D32),

                                              ),

                                            ),

                                          ],

                                        ),

                                      ),

                                    ],

                                  ],

                                ),

                              ),

                            ),

                          );

                        },

                      );

                    },

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



class RegisterEquipmentPage extends StatefulWidget {

  const RegisterEquipmentPage({Key? key}) : super(key: key);



  @override

  State<RegisterEquipmentPage> createState() => _RegisterEquipmentPageState();

}



class _RegisterEquipmentPageState extends State<RegisterEquipmentPage> {

  final _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);

  final TextEditingController _brandController = TextEditingController();

  final TextEditingController _modelController = TextEditingController();

  final TextEditingController _serialController = TextEditingController();

  String _equipmentType = 'Laptop';

  bool _saving = false;

  List<Cliente> _clientes = [];

  Cliente? _selectedCliente;

  bool _loadingClientes = false;



  @override

  void initState() {

    super.initState();

    _loadClientes();

  }



  @override

  void dispose() {

    _brandController.dispose();

    _modelController.dispose();

    _serialController.dispose();

    super.dispose();

  }



  Future<void> _loadClientes() async {

    setState(() => _loadingClientes = true);

    try {

      final clientes = await _authService.fetchClientes();

      if (mounted) {

        setState(() {

          _clientes = clientes;

          _loadingClientes = false;

        });

      }

    } catch (e) {

      if (mounted) {

        setState(() => _loadingClientes = false);

      }

    }

  }



  Future<void> _saveEquipment() async {

    if (!_formKey.currentState!.validate()) return;



    setState(() => _saving = true);

    final result = await _authService.createEquipment(

      tipo: _equipmentType,

      marca: _brandController.text.trim(),

      modelo: _modelController.text.trim(),

      serial: _serialController.text.trim(),

      cod_cliente: _selectedCliente?.codCliente,

    );

    if (!mounted) return;

    setState(() => _saving = false);



    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(result.message ?? 'Operación finalizada.'),

      ),

    );



    if (result.success) {

      Navigator.of(context).pushReplacement(

        MaterialPageRoute(builder: (_) => const EquipmentListPage()),

      );

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF0F2F5),

      appBar: const CustomAppBar(

        title: 'Agregar nuevo equipo',

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

                    'REGISTRAR EQUIPO',

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

                        const Text(

                          'CATEGORIA',

                          style: TextStyle(

                            color: Color(0xFF4E5D6C),

                            fontWeight: FontWeight.w700,

                            fontSize: 12,

                          ),

                        ),

                        const SizedBox(height: 8),

                        Row(

                          children: [

                            Expanded(

                              child: _TypeChoiceButton(

                                label: 'Laptop',

                                selected: _equipmentType == 'Laptop',

                                onTap: () {

                                  setState(() => _equipmentType = 'Laptop');

                                },

                              ),

                            ),

                            const SizedBox(width: 10),

                            Expanded(

                              child: _TypeChoiceButton(

                                label: 'PC\nEscritorio',

                                selected: _equipmentType == 'PC Escritorio',

                                onTap: () {

                                  setState(

                                      () => _equipmentType = 'PC Escritorio');

                                },

                              ),

                            ),

                          ],

                        ),

                        const SizedBox(height: 16),

                        const _FieldLabel(text: 'MARCA'),

                        const SizedBox(height: 6),

                        _DesktopInput(

                          controller: _brandController,

                          hint: 'Ej. Dell, HP, Lenovo...',

                          validator: (v) => v == null || v.trim().isEmpty

                              ? 'Ingresa la marca'

                              : null,

                        ),

                        const SizedBox(height: 12),

                        const _FieldLabel(text: 'MODELO'),

                        const SizedBox(height: 6),

                        _DesktopInput(

                          controller: _modelController,

                          hint: 'Ej. Latitude 5420',

                          validator: (v) => v == null || v.trim().isEmpty

                              ? 'Ingresa el modelo'

                              : null,

                        ),

                        const SizedBox(height: 12),

                        const _FieldLabel(text: 'SERIAL'),

                        const SizedBox(height: 6),

                        _DesktopInput(

                          controller: _serialController,

                          hint: 'Ingrese N/S del equipo',

                          validator: (v) => v == null || v.trim().isEmpty

                              ? 'Ingresa el serial'

                              : null,

                        ),

                        const SizedBox(height: 16),

                        const _FieldLabel(text: 'CLIENTE (OPCIONAL)'),

                        const SizedBox(height: 6),

                        Container(

                          padding: const EdgeInsets.symmetric(horizontal: 12),

                          decoration: BoxDecoration(

                            color: const Color(0xFFF0F1F3),

                            border: Border.all(color: const Color(0xFFC4CAD1)),

                            borderRadius: BorderRadius.circular(6),

                          ),

                          child: _loadingClientes

                              ? Row(

                                  children: [

                                    const SizedBox(

                                      width: 16,

                                      height: 16,

                                      child: CircularProgressIndicator(

                                        strokeWidth: 2,

                                        color: Color(0xFF0A88C6),

                                      ),

                                    ),

                                    const SizedBox(width: 12),

                                    Text(

                                      'Cargando clientes...',

                                      style: TextStyle(

                                        color: const Color(0xFF8B95A1),

                                        fontSize: 14,

                                      ),

                                    ),

                                  ],

                                )

                              : DropdownButtonHideUnderline(

                                  child: DropdownButton<Cliente?>(

                                    value: _selectedCliente,

                                    isExpanded: true,

                                    hint: Text(

                                      'Seleccionar cliente (opcional)',

                                      style: TextStyle(

                                        color: const Color(0xFF8B95A1),

                                        fontSize: 14,

                                      ),

                                    ),

                                    items: [

                                      const DropdownMenuItem<Cliente?>(

                                        value: null,

                                        child: Text(

                                          'Sin asignar a cliente',

                                          style: TextStyle(

                                            color: Color(0xFF8B95A1),

                                            fontSize: 14,

                                          ),

                                        ),

                                      ),

                                      ..._clientes.map((cliente) {

                                        return DropdownMenuItem<Cliente>(

                                          value: cliente,

                                          child: Text(

                                            '${cliente.nombre} (${cliente.usuario})',

                                            style: const TextStyle(fontSize: 14),

                                          ),

                                        );

                                      }).toList(),

                                    ],

                                    onChanged: (Cliente? value) {

                                      setState(() {

                                        _selectedCliente = value;

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

                            onPressed: _saving ? null : _saveEquipment,

                            child: _saving

                                ? const SizedBox(

                                    height: 18,

                                    width: 18,

                                    child: CircularProgressIndicator(

                                      strokeWidth: 2,

                                      color: Colors.white,

                                    ),

                                  )

                                : const Text(

                                    'GUARDAR EQUIPO',

                                    style:

                                        TextStyle(fontWeight: FontWeight.w800),

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



class _TypeChoiceButton extends StatelessWidget {

  final String label;

  final bool selected;

  final VoidCallback onTap;



  const _TypeChoiceButton({

    required this.label,

    required this.selected,

    required this.onTap,

  });



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(6),

      child: Container(

        padding: const EdgeInsets.symmetric(vertical: 12),

        decoration: BoxDecoration(

          color: selected ? const Color(0xFFEAF7FD) : const Color(0xFFE6E8EB),

          border: Border.all(

            color: selected ? const Color(0xFF0A88C6) : const Color(0xFFC7CDD4),

          ),

          borderRadius: BorderRadius.circular(6),

        ),

        child: Text(

          label,

          textAlign: TextAlign.center,

          style: TextStyle(

            color: selected ? const Color(0xFF2B3A47) : const Color(0xFF8B95A1),

            fontWeight: FontWeight.w700,

            fontSize: 11,

            height: 1.1,

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



class WorkOrdersListPage extends StatefulWidget {

  const WorkOrdersListPage({Key? key}) : super(key: key);



  @override

  State<WorkOrdersListPage> createState() => _WorkOrdersListPageState();

}



class _WorkOrdersListPageState extends State<WorkOrdersListPage> {

  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);

  final TextEditingController _searchController = TextEditingController();

  late Future<List<WorkOrder>> _futureOrders;

  String _selectedStatusFilter = 'Todos'; // Filtro de estados

  final List<String> _statusOptions = [

    'Todos',

    'Abierto',

    'Asignado', 

    'En diagnostico',

    'En reparación',

    'Listo',

    'Entregado',

    'Cancelado'

  ];



  @override

  void initState() {

    super.initState();

    _futureOrders = _authService.fetchWorkOrders();

  }



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  String _formatDate(DateTime? date) {

    if (date == null) return '-';

    final d = date.toLocal();

    return '${d.day.toString().padLeft(2, '0')}/'

        '${d.month.toString().padLeft(2, '0')}/'

        '${d.year} '

        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  }



  List<WorkOrder> _applyFilter(List<WorkOrder> orders) {

    final q = _searchController.text.trim().toLowerCase();

    if (q.isEmpty) return orders;



    return orders.where((o) {

      return o.category.toLowerCase().contains(q) ||

          o.description.toLowerCase().contains(q) ||

          o.priority.toLowerCase().contains(q) ||

          o.status.toLowerCase().contains(q);

    }).toList();

  }



  Future<void> _openCreateOrder() async {

    await Navigator.of(context).push(

      MaterialPageRoute(builder: (_) => const CreateWorkOrderPage()),

    );

    if (!mounted) return;

    _futureOrders = _authService.fetchWorkOrders();

    setState(() {});

  }



  Color _getStatusColor(String status) {

    switch (status.toLowerCase()) {

      case 'pendiente':

        return const Color(0xFFF59E0B); // Naranja

      case 'en progreso':

        return const Color(0xFF3B82F6); // Azul

      case 'completado':

        return const Color(0xFF10B981); // Verde

      case 'cancelado':

        return const Color(0xFFEF4444); // Rojo

      default:

        return const Color(0xFF6B7280); // Gris

    }

  }



  Color _getPriorityColor(String priority) {

    switch (priority.toLowerCase()) {

      case 'baja':

        return const Color(0xFF10B981); // Verde

      case 'media':

        return const Color(0xFFF59E0B); // Amarillo

      case 'alta':

        return const Color(0xFFEF4444); // Rojo

      default:

        return const Color(0xFF6B7280); // Gris

    }

  }



  void _showOrderDetails(WorkOrder order) {

    showDialog(

      context: context,

      builder: (BuildContext context) {

        return FutureBuilder<WorkOrderDetail?>(

          future: _authService.fetchWorkOrderDetail(order.id),

          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {

              return const AlertDialog(

                content: Center(child: CircularProgressIndicator()),

              );

            }



            if (snapshot.hasError || !snapshot.hasData) {

              return AlertDialog(

                title: Text('Ticket #${order.id}'),

                content: const Text('No se pudo cargar la información completa.'),

                actions: [

                  TextButton(

                    onPressed: () => Navigator.of(context).pop(),

                    child: const Text('Cerrar'),

                  ),

                ],

              );

            }



            final detail = snapshot.data!;

            return AlertDialog(

              title: Text('Ticket #${detail.id}'),

              content: SizedBox(

                width: double.maxFinite,

                child: SingleChildScrollView(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      // Detalles del Ticket

                      _buildSectionTitle('Detalles del Ticket'),

                      _buildDetailRow('Categoria', detail.category),

                      _buildDetailRow('Estado del ticket', detail.status),

                      _buildDetailRow('Prioridad', detail.priority),

                      _buildDetailRow('Descripcion del problema', detail.description),

                      

                      // Costos (condicional)

                      if (detail.costoEstimado != null || detail.costoFinal != null) ...[

                        const SizedBox(height: 8),

                        if (detail.costoFinal != null) 

                          _buildDetailRow('Costo final', '\$${detail.costoFinal!.toStringAsFixed(2)}')

                        else if (detail.costoEstimado != null)

                          _buildDetailRow('Costo estimado', '\$${detail.costoEstimado!.toStringAsFixed(2)}'),

                      ],



                      const SizedBox(height: 16),

                      

                      // Información del Ticket (cliente y equipo)

                      _buildSectionTitle('Información del Ticket'),

                      

                      // Información del Cliente (condicional)

                      if (detail.clienteNombre != null || detail.clienteTelefono != null || 

                          detail.clienteCorreo != null || detail.clienteDireccion != null) ...[

                        if (detail.clienteNombre != null) 

                          _buildDetailRow('Nombre del Cliente', detail.clienteNombre!),

                        if (detail.clienteTelefono != null) 

                          _buildDetailRow('Nro Contacto', detail.clienteTelefono!),

                        if (detail.clienteCorreo != null) 

                          _buildDetailRow('Correo Electronico', detail.clienteCorreo!),

                        if (detail.clienteDireccion != null) 

                          _buildDetailRow('Domicilio', detail.clienteDireccion!),

                      ],



                      // Información del Equipo (condicional)

                      if (detail.equipoMarca != null || detail.equipoModelo != null || detail.equipoSerial != null) ...[

                        if (detail.equipoMarca != null) 

                          _buildDetailRow('Marca', detail.equipoMarca!),

                        if (detail.equipoModelo != null) 

                          _buildDetailRow('Modelo', detail.equipoModelo!),

                        if (detail.equipoSerial != null) 

                          _buildDetailRow('Serial', detail.equipoSerial!),

                      ],



                      const SizedBox(height: 16),

                      

                      // Control del Ticket

                      _buildSectionTitle('Control del Ticket'),

                      if (detail.diagnostico != null) 

                        _buildDetailRow('Registro de diagnostico', detail.diagnostico!),

                      if (detail.correcciones != null) 

                        _buildDetailRow('Registro de correcciones', detail.correcciones!),

                      if (detail.recomendaciones != null) 

                        _buildDetailRow('Registro de recomendaciones', detail.recomendaciones!),

                      if (detail.tecnicoNombre != null) 

                        _buildDetailRow('Persona asignada', detail.tecnicoNombre!),

                      _buildDetailRow('Fecha de creacion', _formatDate(detail.createdAt)),

                      if (detail.modifiedAt != null) 

                        _buildDetailRow('Fecha de modificacion', _formatDate(detail.modifiedAt)),

                    ],

                  ),

                ),

              ),

              actions: [

                TextButton(

                  onPressed: () => Navigator.of(context).pop(),

                  child: const Text('Cerrar'),

                ),

              ],

            );

          },

        );

      },

    );

  }



  Widget _buildSectionTitle(String title) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 12),

      child: Text(

        title,

        style: const TextStyle(

          fontWeight: FontWeight.w700,

          fontSize: 16,

          color: Color(0xFF0A88C6),

        ),

      ),

    );

  }



  Widget _buildDetailRow(String label, String value) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 8),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          SizedBox(

            width: 140,

            child: Text(

              '$label:',

              style: const TextStyle(

                fontWeight: FontWeight.w600,

                fontSize: 14,

              ),

            ),

          ),

          Expanded(

            child: Text(

              value,

              style: const TextStyle(fontSize: 14),

            ),

          ),

        ],

      ),

    );

  }



  Future<void> _deleteOrder(int id) async {

    final result = await _authService.deleteWorkOrder(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(result.message ?? 'Operación finalizada.')),

    );

    if (result.success) {

      setState(() => _futureOrders = _authService.fetchWorkOrders());

    }

  }



  // Verificar si el usuario tiene permisos para editar tickets

  Future<bool> _canEditTicket() async {

    final isMaster = await _authService.isMaster();

    final isAdministrador = await _authService.isAdministrador();

    final isTecnico = await _authService.isTecnicoPriv();

    return isMaster || isAdministrador || isTecnico;

  }



  // Abrir formulario de edición de ticket

  Future<void> _openEditTicket(WorkOrder order) async {

    await Navigator.of(context).push(

      MaterialPageRoute(

        builder: (_) => EditWorkOrderPage(workOrder: order),

      ),

    );

    if (!mounted) return;

    _futureOrders = _authService.fetchWorkOrders();

    setState(() {});

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF0F2F5),

      appBar: CustomAppBar(

        title: 'Ordenes de trabajo',

        actions: [

          // Filtro de estados

          PopupMenuButton<String>(

            icon: const Icon(Icons.filter_list, color: Colors.white),

            tooltip: 'Filtrar por estado',

            onSelected: (String value) {

              setState(() {

                _selectedStatusFilter = value;

              });

            },

            itemBuilder: (BuildContext context) {

              return _statusOptions.map((String status) {

                return PopupMenuItem<String>(

                  value: status,

                  child: Row(

                    children: [

                      Icon(

                        status == _selectedStatusFilter 

                            ? Icons.radio_button_checked 

                            : Icons.radio_button_unchecked,

                        color: const Color(0xFF0A88C6),

                      ),

                      const SizedBox(width: 8),

                      Text(status),

                    ],

                  ),

                );

              }).toList();

            },

          ),

          IconButton(

            tooltip: 'Actualizar',

            onPressed: () {

              _futureOrders = _authService.fetchWorkOrders();

              setState(() {});

            },

            icon: const Icon(Icons.refresh),

            color: Colors.white,

          ),

        ],

      ),

            body: Center(

        child: ConstrainedBox(

          constraints: const BoxConstraints(maxWidth: 980),

          child: Padding(

            padding: const EdgeInsets.all(20),

            child: Column(

              children: [

                TextField(

                  controller: _searchController,

                  onChanged: (_) => setState(() {}),

                  decoration: InputDecoration(

                    hintText: 'Buscar por categoría, prioridad o detalle...',

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

                const SizedBox(height: 14),

                Expanded(

                  child: FutureBuilder<List<WorkOrder>>(

                    future: _futureOrders,

                    builder: (context, snapshot) {

                      if (snapshot.connectionState == ConnectionState.waiting) {

                        return const Center(child: CircularProgressIndicator());

                      }



                      final allOrders = snapshot.data ?? const <WorkOrder>[];

                      final orders = _applyFilter(allOrders);

                      if (orders.isEmpty) {

                        return const Center(

                          child: Column(

                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [

                              Icon(

                                Icons.build_outlined,

                                size: 64,

                                color: Color(0xFFB0BEC5),

                              ),

                              SizedBox(height: 16),

                              Text(

                                'No hay órdenes de trabajo',

                                style: TextStyle(

                                  fontSize: 18,

                                  color: Color(0xFF607D8B),

                                  fontWeight: FontWeight.w500,

                                ),

                              ),

                              SizedBox(height: 8),

                              Text(

                                'Crea una nueva orden de trabajo usando el botón +',

                                style: TextStyle(

                                  fontSize: 14,

                                  color: Color(0xFF90A4AE),

                                ),

                                textAlign: TextAlign.center,

                              ),

                            ],

                          ),

                        );

                      }



                      return ListView.separated(

                        itemCount: orders.length,

                        separatorBuilder: (_, __) => const SizedBox(height: 10),

                        itemBuilder: (context, index) {

                          final order = orders[index];

                          return Container(

                            decoration: BoxDecoration(

                              color: const Color(0xFFF6F7F9),

                              borderRadius: BorderRadius.circular(10),

                              border: Border.all(

                                color: const Color(0xFFDFE4EA),

                              ),

                            ),

                            child: Container(

                              decoration: const BoxDecoration(

                                border: Border(

                                  left: BorderSide(

                                    color: Color(0xFF0A88C6),

                                    width: 4,

                                  ),

                                ),

                              ),

                              child: Padding(

                                padding: const EdgeInsets.all(16),

                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    // Fila principal: ID y botones de acción

                                    Row(

                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                      children: [

                                        Text(

                                          'Ticket #${order.id}',

                                          style: const TextStyle(

                                            fontWeight: FontWeight.w700,

                                            fontSize: 16,

                                            color: Color(0xFF2C3E50),

                                          ),

                                        ),

                                        Row(

                                          children: [

                                            // Botón Editar ticket (solo para roles permitidos)

                                            FutureBuilder<bool>(

                                              future: _canEditTicket(),

                                              builder: (context, snapshot) {

                                                if (snapshot.hasData && snapshot.data == true) {

                                                  return Padding(

                                                    padding: const EdgeInsets.only(right: 8),

                                                    child: ElevatedButton.icon(

                                                      onPressed: () {

                                                        _openEditTicket(order);

                                                      },

                                                      icon: const Icon(

                                                        Icons.edit,

                                                        size: 16,

                                                      ),

                                                      label: const Text(

                                                        'Editar ticket',

                                                        style: TextStyle(fontSize: 12),

                                                      ),

                                                      style: ElevatedButton.styleFrom(

                                                        backgroundColor: const Color(0xFF28A745),

                                                        foregroundColor: Colors.white,

                                                        padding: const EdgeInsets.symmetric(

                                                          horizontal: 12,

                                                          vertical: 6,

                                                        ),

                                                        shape: RoundedRectangleBorder(

                                                          borderRadius: BorderRadius.circular(6),

                                                        ),

                                                      ),

                                                    ),

                                                  );

                                                }

                                                return const SizedBox.shrink();

                                              },

                                            ),

                                            // Botón Ver detalles

                                            ElevatedButton.icon(

                                              onPressed: () {

                                                _showOrderDetails(order);

                                              },

                                              icon: const Icon(

                                                Icons.visibility,

                                                size: 16,

                                              ),

                                              label: const Text(

                                                'Ver detalles',

                                                style: TextStyle(fontSize: 12),

                                              ),

                                              style: ElevatedButton.styleFrom(

                                                backgroundColor: const Color(0xFF0A88C6),

                                                foregroundColor: Colors.white,

                                                padding: const EdgeInsets.symmetric(

                                                  horizontal: 12,

                                                  vertical: 6,

                                                ),

                                                shape: RoundedRectangleBorder(

                                                  borderRadius: BorderRadius.circular(6),

                                                ),

                                              ),

                                            ),

                                          ],

                                        ),

                                      ],

                                    ),

                                    const SizedBox(height: 12),

                                    // Fila de información clave

                                    Row(

                                      children: [

                                        // Estado

                                        Container(

                                          padding: const EdgeInsets.symmetric(

                                            horizontal: 8,

                                            vertical: 4,

                                          ),

                                          decoration: BoxDecoration(

                                            color: _getStatusColor(order.status),

                                            borderRadius: BorderRadius.circular(4),

                                          ),

                                          child: Text(

                                            order.status,

                                            style: const TextStyle(

                                              fontSize: 11,

                                              fontWeight: FontWeight.w600,

                                              color: Colors.white,

                                            ),

                                          ),

                                        ),

                                        const SizedBox(width: 8),

                                        // Prioridad

                                        Container(

                                          padding: const EdgeInsets.symmetric(

                                            horizontal: 8,

                                            vertical: 4,

                                          ),

                                          decoration: BoxDecoration(

                                            color: _getPriorityColor(order.priority),

                                            borderRadius: BorderRadius.circular(4),

                                          ),

                                          child: Text(

                                            order.priority,

                                            style: const TextStyle(

                                              fontSize: 11,

                                              fontWeight: FontWeight.w600,

                                              color: Colors.white,

                                            ),

                                          ),

                                        ),

                                        const Spacer(),

                                        // Fecha

                                        Text(

                                          _formatDate(order.createdAt),

                                          style: const TextStyle(

                                            fontSize: 12,

                                            color: Color(0xFF6B7280),

                                          ),

                                        ),

                                      ],

                                    ),

                                  ],

                                ),

                              ),

                            ),

                          );

                        },

                      );

                    },

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



class MaintenanceOrdersListPage extends StatefulWidget {

  const MaintenanceOrdersListPage({Key? key}) : super(key: key);



  @override

  State<MaintenanceOrdersListPage> createState() => _MaintenanceOrdersListPageState();

}



class _MaintenanceOrdersListPageState extends State<MaintenanceOrdersListPage> {

  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);

  final TextEditingController _searchController = TextEditingController();

  late Future<List<WorkOrder>> _futureOrders;



  @override

  void initState() {

    super.initState();

    _futureOrders = _authService.fetchMaintenanceOrders();

  }



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  String _formatDate(DateTime? date) {

    if (date == null) return '-';

    final d = date.toLocal();

    return '${d.day.toString().padLeft(2, '0')}/'

        '${d.month.toString().padLeft(2, '0')}/'

        '${d.year} '

        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  }



  List<WorkOrder> _applyFilter(List<WorkOrder> orders) {

    final q = _searchController.text.trim().toLowerCase();

    if (q.isEmpty) return orders;



    return orders.where((o) {

      return o.category.toLowerCase().contains(q) ||

          o.description.toLowerCase().contains(q) ||

          o.priority.toLowerCase().contains(q) ||

          o.status.toLowerCase().contains(q);

    }).toList();

  }



  Future<void> _openCreateOrder() async {

    await Navigator.of(context).push(

      MaterialPageRoute(builder: (_) => const CreateWorkOrderPage()),

    );

    if (!mounted) return;

    _futureOrders = _authService.fetchMaintenanceOrders();

    setState(() {});

  }



  Color _getPriorityColor(String priority) {

    switch (priority.toLowerCase()) {

      case 'baja':

        return const Color(0xFF10B981); // Verde

      case 'media':

        return const Color(0xFFF59E0B); // Amarillo

      case 'alta':

        return const Color(0xFFEF4444); // Rojo

      default:

        return const Color(0xFF6B7280); // Gris

    }

  }



  Future<void> _deleteOrder(int id) async {

    final result = await _authService.deleteWorkOrder(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(result.message ?? 'Operación finalizada.')),

    );

    if (result.success) {

      setState(() => _futureOrders = _authService.fetchMaintenanceOrders());

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF0F2F5),

      appBar: CustomAppBar(

        title: 'Ordenes de mantenimiento',

        actions: [

          IconButton(

            tooltip: 'Actualizar',

            onPressed: () {

              _futureOrders = _authService.fetchMaintenanceOrders();

              setState(() {});

            },

            icon: const Icon(Icons.refresh),

            color: Colors.white,

          ),

        ],

      ),

            body: Center(

        child: ConstrainedBox(

          constraints: const BoxConstraints(maxWidth: 980),

          child: Padding(

            padding: const EdgeInsets.all(20),

            child: Column(

              children: [

                TextField(

                  controller: _searchController,

                  onChanged: (_) => setState(() {}),

                  decoration: InputDecoration(

                    hintText: 'Buscar por categoría, prioridad o detalle...',

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

                const SizedBox(height: 14),

                Expanded(

                  child: FutureBuilder<List<WorkOrder>>(

                    future: _futureOrders,

                    builder: (context, snapshot) {

                      if (snapshot.connectionState == ConnectionState.waiting) {

                        return const Center(child: CircularProgressIndicator());

                      }

                      if (snapshot.hasError) {

                        return Center(

                          child: Text(

                            'Error: ${snapshot.error}',

                            style: const TextStyle(color: Colors.red),

                          ),

                        );

                      }

                      final orders = snapshot.data ?? [];

                      final filteredOrders = _applyFilter(orders);



                      if (filteredOrders.isEmpty) {

                        return const Center(

                          child: Column(

                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [

                              Icon(

                                Icons.build_outlined,

                                size: 64,

                                color: Color(0xFFB0BEC5),

                              ),

                              SizedBox(height: 16),

                              Text(

                                'No hay órdenes de mantenimiento',

                                style: TextStyle(

                                  fontSize: 18,

                                  color: Color(0xFF607D8B),

                                  fontWeight: FontWeight.w500,

                                ),

                              ),

                              SizedBox(height: 8),

                              Text(

                                'Crea una nueva orden de mantenimiento usando el botón +',

                                style: TextStyle(

                                  fontSize: 14,

                                  color: Color(0xFF90A4AE),

                                ),

                                textAlign: TextAlign.center,

                              ),

                            ],

                          ),

                        );

                      }



                      return ListView.builder(

                        itemCount: filteredOrders.length,

                        itemBuilder: (context, index) {

                          final order = filteredOrders[index];

                          return Card(

                            margin: const EdgeInsets.only(bottom: 12),

                            elevation: 2,

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(12),

                            ),

                            child: Padding(

                              padding: const EdgeInsets.all(16),

                              child: ListTile(

                                title: Text(

                                  '#${order.id} • ${order.category}',

                                  style: const TextStyle(

                                    fontWeight: FontWeight.w700,

                                  ),

                                ),

                                subtitle: Padding(

                                  padding: const EdgeInsets.only(top: 4),

                                  child: Text(

                                    '${order.description}\n'

                                    'Estado: ${order.status} • ${_formatDate(order.createdAt)}',

                                  ),

                                ),

                                trailing: Row(

                                  mainAxisSize: MainAxisSize.min,

                                  children: [

                                    Container(

                                      padding: const EdgeInsets.symmetric(

                                        horizontal: 10,

                                        vertical: 5,

                                      ),

                                      decoration: BoxDecoration(

                                        color: _getPriorityColor(order.priority),

                                        borderRadius: BorderRadius.circular(6),

                                      ),

                                      child: Text(

                                        order.priority,

                                        style: const TextStyle(

                                          fontSize: 11,

                                          fontWeight: FontWeight.w700,

                                          color: Colors.white,

                                        ),

                                      ),

                                    ),

                                                                      ],

                                ),

                              ),

                            ),

                          );

                        },

                      );

                    },

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



class CreateWorkOrderPage extends StatefulWidget {

  const CreateWorkOrderPage({Key? key}) : super(key: key);



  @override

  State<CreateWorkOrderPage> createState() => _CreateWorkOrderPageState();

}



class _CreateWorkOrderPageState extends State<CreateWorkOrderPage> {

  final _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);

  final TextEditingController _descriptionController = TextEditingController();

  String _categoria = '';

  String _tipo = 'Reparación';

  String _prioridad = 'BAJA';

  bool _saving = false;

  int? _codCliente;

  List<Map<String, dynamic>> _categorias = [];

  bool _loadingCategorias = true;



  @override

  void initState() {

    super.initState();

    _loadUserData();

    _loadCategorias();

  }



  Future<void> _loadUserData() async {

    final codCliente = await _authService.getCurrentUserId();

    if (codCliente != null) {

      setState(() {

        _codCliente = codCliente;

      });

    }

  }



  Future<void> _loadCategorias() async {

    try {

      final categorias = await _authService.getCategorias();

      if (mounted) {

        setState(() {

          _categorias = categorias;

          _loadingCategorias = false;

          // Seleccionar la primera categoría por defecto

          if (categorias.isNotEmpty) {

            _categoria = categorias.first['nombre'] ?? '';

          }

        });

      }

    } catch (e) {

      if (mounted) {

        setState(() {

          _loadingCategorias = false;

        });

      }

      print('Error loading categorías: $e');

    }

  }



  @override

  void dispose() {

    _descriptionController.dispose();

    super.dispose();

  }



  Future<void> _createTicket() async {

    if (!_formKey.currentState!.validate()) return;



    setState(() => _saving = true);

    

    if (mounted) {

      print('Creating order with:');

      print('cod_categoria: $_categoria');

      print('tipo: $_tipo');

      print('descripcion_problema: ${_descriptionController.text.trim()}');

      print('prioridad: $_prioridad');

      print('cod_cliente: $_codCliente');

    }

    

    final result = await _authService.createWorkOrder(

      categoria: _categoria,

      tipo: _tipo,

      descripcion_problema: _descriptionController.text.trim(),

      prioridad: _prioridad,

      cod_cliente: _codCliente,

    );



    if (!mounted) return;

    setState(() => _saving = false);



    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(result.message ?? 'Operación finalizada.'),

      ),

    );



    if (result.success) {

      // Redirigir según el tipo de orden creado

      if (_tipo == 'Reparación') {

        Navigator.of(context).pushReplacement(

          MaterialPageRoute(builder: (_) => const WorkOrdersListPage()),

        );

      } else if (_tipo == 'Mantenimiento') {

        Navigator.of(context).pushReplacement(

          MaterialPageRoute(builder: (_) => const MaintenanceOrdersListPage()),

        );

      } else {

        // Por defecto, redirigir a órdenes de trabajo

        Navigator.of(context).pushReplacement(

          MaterialPageRoute(builder: (_) => const WorkOrdersListPage()),

        );

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF0F2F5),

      appBar: const CustomAppBar(

        title: 'Crear nuevo ticket',

      ),

      body: Center(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(20),

          child: Container(

            width: 560,

            decoration: BoxDecoration(

              color: const Color(0xFFE7E9EC),

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

                    'NUEVO TICKET',

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

                        const _FieldLabel(text: 'CATEGORÍA'),

                        const SizedBox(height: 6),

                        Container(

                          padding: const EdgeInsets.symmetric(horizontal: 12),

                          decoration: BoxDecoration(

                            color: const Color(0xFFF0F1F3),

                            border: Border.all(color: const Color(0xFFC4CAD1)),

                            borderRadius: BorderRadius.circular(6),

                          ),

                          child: DropdownButtonHideUnderline(

                            child: _loadingCategorias

                                ? const Center(

                                    child: Padding(

                                      padding: EdgeInsets.all(16.0),

                                      child: CircularProgressIndicator(),

                                    ),

                                  )

                                : DropdownButton<String>(

                                    value: _categoria.isEmpty ? null : _categoria,

                                    isExpanded: true,

                                    hint: const Text('Selecciona una categoría'),

                                    items: _categorias.map((categoria) {

                                      return DropdownMenuItem<String>(

                                        value: categoria['nombre'] as String,

                                        child: Text(categoria['nombre'] as String),

                                      );

                                    }).toList(),

                                    onChanged: (value) {

                                      if (value == null) return;

                                      setState(() => _categoria = value);

                                    },

                                  ),

                          ),

                        ),

                        const SizedBox(height: 14),

                        const _FieldLabel(text: 'REQUERIMIENTO'),

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

                              value: _tipo,

                              isExpanded: true,

                              items: const [

                                DropdownMenuItem(

                                  value: 'Reparación',

                                  child: Text('Reparación'),

                                ),

                                DropdownMenuItem(

                                  value: 'Mantenimiento',

                                  child: Text('Mantenimiento'),

                                ),

                              ],

                              onChanged: (value) {

                                if (value == null) return;

                                setState(() => _tipo = value);

                              },

                            ),

                          ),

                        ),

                        const SizedBox(height: 14),

                        const _FieldLabel(text: 'DESCRIPCIÓN DEL PROBLEMA'),

                        const SizedBox(height: 6),

                        TextFormField(

                          controller: _descriptionController,

                          minLines: 4,

                          maxLines: 4,

                          validator: (v) => v == null || v.trim().isEmpty

                              ? 'Describe la falla'

                              : null,

                          decoration: InputDecoration(

                            hintText:

                                'Escriba aquí los detalles de\nla falla...',

                            hintStyle:

                                const TextStyle(color: Color(0xFFA2A9B0)),

                            contentPadding: const EdgeInsets.all(12),

                            filled: true,

                            fillColor: const Color(0xFFF0F1F3),

                            border: OutlineInputBorder(

                              borderRadius: BorderRadius.circular(6),

                              borderSide:

                                  const BorderSide(color: Color(0xFFC4CAD1)),

                            ),

                            enabledBorder: OutlineInputBorder(

                              borderRadius: BorderRadius.circular(6),

                              borderSide:

                                  const BorderSide(color: Color(0xFFC4CAD1)),

                            ),

                          ),

                        ),

                        const SizedBox(height: 14),

                        const _FieldLabel(text: 'PRIORIDAD'),

                        const SizedBox(height: 8),

                        Wrap(

                          spacing: 10,

                          children: [

                            _PriorityChip(

                              label: 'BAJA',

                              selected: _prioridad == 'BAJA',

                              selectedColor: const Color(0xFF9FD8A0),

                              onTap: () => setState(() => _prioridad = 'BAJA'),

                            ),

                            _PriorityChip(

                              label: 'MEDIA',

                              selected: _prioridad == 'MEDIA',

                              selectedColor: const Color(0xFFE5D388),

                              onTap: () => setState(() => _prioridad = 'MEDIA'),

                            ),

                            _PriorityChip(

                              label: 'ALTA',

                              selected: _prioridad == 'ALTA',

                              selectedColor: const Color(0xFFE7A4A4),

                              onTap: () => setState(() => _prioridad = 'ALTA'),

                            ),

                          ],

                        ),

                        const SizedBox(height: 24),

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

                            onPressed: _saving ? null : _createTicket,

                            child: _saving

                                ? const SizedBox(

                                    height: 18,

                                    width: 18,

                                    child: CircularProgressIndicator(

                                      strokeWidth: 2,

                                      color: Colors.white,

                                    ),

                                  )

                                : const Text(

                                    'CREAR TICKET',

                                    style:

                                        TextStyle(fontWeight: FontWeight.w800),

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



class _PriorityChip extends StatelessWidget {

  final String label;

  final bool selected;

  final Color selectedColor;

  final VoidCallback onTap;



  const _PriorityChip({

    required this.label,

    required this.selected,

    required this.selectedColor,

    required this.onTap,

  });



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(5),

      child: AnimatedContainer(

        duration: const Duration(milliseconds: 120),

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

        decoration: BoxDecoration(

          color: selected ? selectedColor : const Color(0xFFE0E3E8),

          borderRadius: BorderRadius.circular(5),

          border: Border.all(

            color: selected ? Colors.transparent : const Color(0xFFC4CAD1),

          ),

        ),

        child: Text(

          label,

          style: const TextStyle(

            fontWeight: FontWeight.w700,

            fontSize: 11,

            color: Color(0xFF3E4A55),

          ),

        ),

      ),

    );

  }

}



class AuthorsOverlay extends StatefulWidget {

  const AuthorsOverlay({Key? key}) : super(key: key);



  @override

  State<AuthorsOverlay> createState() => _AuthorsOverlayState();

}



class _AuthorsOverlayState extends State<AuthorsOverlay> {

  String _names = 'Desarrollado por...';



  void _editNames() async {

    final controller = TextEditingController(text: _names);

    final result = await showDialog<String>(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Editar autores'),

        content: TextField(

          controller: controller,

          decoration: const InputDecoration(

            hintText: 'Escribe los nombres separados por comas',

          ),

          maxLines: 3,

        ),

        actions: [

          TextButton(

              onPressed: () => Navigator.of(context).pop(),

              child: const Text('Cancelar')),

          TextButton(

              onPressed: () =>

                  Navigator.of(context).pop(controller.text.trim()),

              child: const Text('Guardar')),

        ],

      ),

    );



    if (result != null && result.isNotEmpty) {

      setState(() => _names = result);

    }

  }



  @override

  Widget build(BuildContext context) {

    return Positioned(

      right: 12,

      bottom: 12,

      child: GestureDetector(

        onTap: _editNames,

        child: ConstrainedBox(

          constraints: const BoxConstraints(maxWidth: 260),

          child: Container(

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

            decoration: BoxDecoration(

              color: Colors.black.withValues(alpha: 0.6),

              borderRadius: BorderRadius.circular(8),

            ),

            child: Row(

              mainAxisSize: MainAxisSize.min,

              children: [

                Flexible(

                  child: Text(

                    _names,

                    style: const TextStyle(color: Colors.white, fontSize: 12),

                    overflow: TextOverflow.ellipsis,

                  ),

                ),

                const SizedBox(width: 8),

                const Icon(Icons.edit, size: 16, color: Colors.white),

              ],

            ),

          ),

        ),

      ),

    );

  }

}


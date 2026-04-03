import 'package:flutter/material.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyecto',
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  final AuthService _authService = AuthService(AuthService.defaultBaseUrl);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final token = await _authService.login(email, password);
      if (!mounted) return;

      if (token != null) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aplicacion Movil'),
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: _validateEmail,
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

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

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
                            'Aplicativo Movil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TopMenuButton(
                              icon: Icons.home,
                              label: 'Hogar',
                              iconColor: Colors.white,
                              textColor: Colors.white,
                              onTap: () => _openBlankModule(context, 'Hogar'),
                            ),
                          ),
                          Expanded(
                            child: _TopMenuButton(
                              icon: Icons.event_note,
                              label: 'Próximo',
                              iconColor: Colors.white70,
                              textColor: Colors.white70,
                              onTap: () => _openBlankModule(context, 'Próximo'),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                              label: 'Orden de trabajo',
                              onTap: () => _openBlankModule(
                                context,
                                'Orden de trabajo',
                              ),
                            ),
                          ),
                          Expanded(
                            child: _DashboardActionTile(
                              icon: Icons.assignment_add,
                              label: 'Solicitud de mantenimiento',
                              onTap: () => _openBlankModule(
                                context,
                                'Solicitud de mantenimiento',
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
                          'Crear orden de trabajo',
                          style: TextStyle(
                            color: Color(0xFF4A93C9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Divider(height: 1),
                      SizedBox(height: 10),
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
                                'Equipo',
                              ),
                            ),
                          ),
                          Expanded(
                            child: _DashboardActionTile(
                              icon: Icons.person,
                              label: 'Usuarios',
                              onTap: () => _openBlankModule(
                                context,
                                'Usuarios',
                              ),
                            ),
                          ),
                          Expanded(
                            child: _DashboardActionTile(
                              icon: Icons.person_2,
                              label: 'Clientes',
                              onTap: () => _openBlankModule(
                                context,
                                'Clientes',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Divider(height: 1),
                      SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () =>
                            _openBlankModule(context, 'Agregar nuevo equipo'),
                        icon: const Icon(Icons.add, color: Color(0xFF5D7E93)),
                        label: const Text(
                          'Agregar nuevo equipo',
                          style: TextStyle(
                            color: Color(0xFF5D7E93),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _openBlankModule(context, 'Agregar nuevo usuario'),
                        icon: const Icon(Icons.add, color: Color(0xFF5D7E93)),
                        label: const Text(
                          'Agregar nuevo usuario',
                          style: TextStyle(
                            color: Color(0xFF5D7E93),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
    if (title == 'Orden de trabajo') {
      return const WorkOrdersListPage();
    }

    if (title == 'Horario de servicio') {
      return const ServiceSchedulePage();
    }

    if (title == 'Equipo') {
      return const EquipmentListPage();
    }

    if (title == 'Agregar nuevo equipo') {
      return const RegisterEquipmentPage();
    }

    if (title == 'Crear orden de trabajo') {
      return const CreateWorkOrderPage();
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
      appBar: AppBar(
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
                  children: const [
                    Text(
                      'Aplicacion Movil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Horario de servicio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
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
      return e.brand.toLowerCase().contains(q) ||
          e.model.toLowerCase().contains(q) ||
          e.title.toLowerCase().contains(q) ||
          e.serial.toLowerCase().contains(q) ||
          e.type.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteEquipment(int id) async {
    final result = await _authService.deleteEquipment(id);
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
      appBar: AppBar(
        title: const Text(
          'EQUIPOS',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
                              child: ListTile(
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text('Serial: ${item.serial}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCE7F8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.type,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5679B6),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      onPressed: () =>
                                          _deleteEquipment(item.id),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
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
  String _equipmentType = 'LAPTOP';
  bool _saving = false;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final result = await _authService.createEquipment(
      type: _equipmentType,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      serial: _serialController.text.trim(),
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
      appBar: AppBar(title: const Text('Agregar nuevo equipo')),
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
                          'TIPO DE EQUIPO',
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
                                label: 'LAPTOP',
                                selected: _equipmentType == 'LAPTOP',
                                onTap: () {
                                  setState(() => _equipmentType = 'LAPTOP');
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TypeChoiceButton(
                                label: 'PC\nESCRITORIO',
                                selected: _equipmentType == 'PC ESCRITORIO',
                                onTap: () {
                                  setState(
                                      () => _equipmentType = 'PC ESCRITORIO');
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
    setState(() => _futureOrders = _authService.fetchWorkOrders());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('ORDEN DE TRABAJO'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              setState(() => _futureOrders = _authService.fetchWorkOrders());
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateOrder,
        icon: const Icon(Icons.add),
        label: const Text('Nueva orden'),
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
                          child: Text('No hay órdenes registradas.'),
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
                                        color: const Color(0xFFDCE7F8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        order.priority,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5679B6),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      onPressed: () => _deleteOrder(order.id),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
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
  String _category = 'Laptop';
  String _priority = 'BAJA';
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final result = await _authService.createWorkOrder(
      category: _category,
      description: _descriptionController.text.trim(),
      priority: _priority,
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
        MaterialPageRoute(builder: (_) => const WorkOrdersListPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(title: const Text('Crear orden de trabajo')),
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
                    'NUEVA ORDEN',
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
                            child: DropdownButton<String>(
                              value: _category,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Laptop',
                                  child: Text('Laptop'),
                                ),
                                DropdownMenuItem(
                                  value: 'pc escritorio',
                                  child: Text('pc escritorio'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _category = value);
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
                              selected: _priority == 'BAJA',
                              selectedColor: const Color(0xFF9FD8A0),
                              onTap: () => setState(() => _priority = 'BAJA'),
                            ),
                            _PriorityChip(
                              label: 'MEDIA',
                              selected: _priority == 'MEDIA',
                              selectedColor: const Color(0xFFE5D388),
                              onTap: () => setState(() => _priority = 'MEDIA'),
                            ),
                            _PriorityChip(
                              label: 'ALTA',
                              selected: _priority == 'ALTA',
                              selectedColor: const Color(0xFFE7A4A4),
                              onTap: () => setState(() => _priority = 'ALTA'),
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
  String _names = 'Autores: Nombre1, Nombre2';

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

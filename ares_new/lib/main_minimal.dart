import 'package:flutter/material.dart';

void main() {
  print('DEBUG: main() iniciado - versión mínima');
  try {
    runApp(const MinimalApp());
    print('DEBUG: runApp() completado - versión mínima');
  } catch (e) {
    print('DEBUG: Error en main() - versión mínima: $e');
    print('DEBUG: Stack trace: ${StackTrace.current}');
  }
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('DEBUG: MinimalApp.build() iniciado');
    try {
      final app = MaterialApp(
        title: 'ARES Minimal',
        home: Scaffold(
          appBar: AppBar(
            title: const Text('ARES - Versión Mínima'),
          ),
          body: const Center(
            child: Text(
              '¡Hola Mundo!\n\nApp funciona correctamente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      );
      print('DEBUG: MaterialApp creado exitosamente - versión mínima');
      return app;
    } catch (e) {
      print('DEBUG: Error en MinimalApp.build(): $e');
      print('DEBUG: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}

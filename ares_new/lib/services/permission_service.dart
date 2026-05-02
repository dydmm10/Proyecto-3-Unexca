import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    try {
      // Solicitar permisos necesarios
      final permissions = [
        Permission.storage,
        Permission.notification,
      ];

      final results = await permissions.request();
      
      // Verificar si todos los permisos fueron concedidos
      bool allGranted = true;
      for (final permission in permissions) {
        if (results[permission] != PermissionStatus.granted) {
          allGranted = false;
          break;
        }
      }

      return allGranted;
    } catch (e) {
      print('Error solicitando permisos: $e');
      return false;
    }
  }

  static Future<bool> checkPermissions() async {
    try {
      final storageStatus = await Permission.storage.status;
      final notificationStatus = await Permission.notification.status;
      
      return storageStatus.isGranted && 
             notificationStatus.isGranted;
    } catch (e) {
      print('Error verificando permisos: $e');
      return false;
    }
  }

  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permisos Requeridos'),
          content: const Text(
            'La aplicación ARES necesita los siguientes permisos para funcionar correctamente:\n\n'
            '• Internet: Para conectar con el servidor\n'
            '• Red: Para verificar conectividad\n'
            '• Almacenamiento: Para guardar datos locales\n'
            '• Notificaciones: Para alertas importantes\n\n'
            'Por favor, concede todos los permisos para continuar.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Configurar Permisos'),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
            TextButton(
              child: const Text('Verificar'),
              onPressed: () async {
                Navigator.of(context).pop();
                final hasPermissions = await checkPermissions();
                if (!hasPermissions) {
                  await requestPermissions();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

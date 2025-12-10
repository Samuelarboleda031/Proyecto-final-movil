import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SideMenu extends StatelessWidget {
  final bool isClient;
  final bool isBarber;

  const SideMenu({
    super.key,
    this.isClient = false,
    this.isBarber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.content_cut,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 10),
                Text(
                  'Barbería',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              if (isClient) {
                Navigator.pushReplacementNamed(context, '/client_home');
              } else if (isBarber) {
                Navigator.pushReplacementNamed(context, '/barber_home');
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {
              if (isClient) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/cliente/perfil');
              } else if (isBarber) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/barbero/perfil');
              } else {
                // Por ahora no hay perfil específico para administrador
                Navigator.pop(context);
              }
            },
          ),
          // Opciones solo administrador
          if (!isClient && !isBarber) ...[
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Ventas'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/ventas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Agendamientos'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/agendamiento');
              },
            ),
          ],
          // Opciones solo cliente
          if (isClient) ...[
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Mis Citas'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.pushReplacementNamed(context, '/cliente/mis-citas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Mis Compras'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.pushReplacementNamed(context, '/cliente/mis-compras');
              },
            ),
          ],
          // Opciones solo barbero
          if (isBarber) ...[
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Mis Citas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/barbero/mis-citas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments),
              title: const Text('Mis Ventas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/barbero/mis-ventas');
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final auth = AuthService();
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
    );
  }
}

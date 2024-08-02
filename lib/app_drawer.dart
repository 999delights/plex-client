import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AppDrawer extends StatelessWidget {
  final User? user;
  final VoidCallback onLogout;

  const AppDrawer({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  dividerTheme: const DividerThemeData(
                    color: Colors.transparent,
                  ),
                ),
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Transform.scale(
                    scale: 0.2,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60.0),
                      child: Image.asset(
                        'lib/images/logo.png',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Divider(color: Colors.grey[800]),
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.white, size: 18),
                title: Text(
                  user?.email ?? 'Email',
                  style: const TextStyle(fontSize: 14.0, color: Colors.white),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 25.0),
                child: ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 18.0,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                    ),
                  ),
                  onTap: onLogout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

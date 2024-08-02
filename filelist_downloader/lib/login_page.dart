import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'custom_textfield.dart';
import 'custom_button.dart';
import 'my_home_page.dart'; // Ensure this points to your main app page

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';

  Future<void> _login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        _message = 'Login successful';
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    } catch (e) {
      setState(() {
        _message = 'Login failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login',   style: TextStyle(
                                  fontSize:18,
                                  color: Colors.white,
                                  fontFamily: 'Revalia',
                                  fontWeight: FontWeight.w300,
                                ),),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _emailController,
              hintText: 'Email',
              obscureText: false,
              suffixIcon: _emailController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _emailController.clear();
                      },
                    )
                  : null,
            ),
            SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              hintText: 'Password',
              obscureText: true,
              suffixIcon: _passwordController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _passwordController.clear();
                      },
                    )
                  : null,
            ),
            SizedBox(height: 20),
            CustomButton(
              text: 'Login',
              isPressed: false,
              isEnabled: true,
              onPressed: _login,
            ),
            SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

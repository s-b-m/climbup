import 'package:climbup/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
            ),
          ),
          TextField(
            controller: passController,
            decoration: InputDecoration(
              labelText: 'Password',
            ),
            enableSuggestions: false,
            autocorrect: false,
            obscureText: true,
          ),
          RaisedButton(
            onPressed: () {
              //sign in code
              context.read<AuthenticationService>().signIn(
                  email: emailController.text.trim(),
                  password: passController.text.trim());
            },
            child: Text('Sign In'),
          ),
          RaisedButton(
            onPressed: () {
              //sign in code
              context.read<AuthenticationService>().signUp(
                  email: emailController.text.trim(),
                  password: passController.text.trim());
            },
            child: Text('Sign Up'),
          )
        ],
      ),
    );
  }
}

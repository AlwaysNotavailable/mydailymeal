import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  String _appLogo = 'assets/images/appLogo.png';

  final TextEditingController _emailCTRL = TextEditingController();
  final TextEditingController _passCTRL = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget> [
              Stack(
                fit: StackFit.loose,
                alignment: AlignmentDirectional.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 1
                      )
                    ),
                    child: Image.asset(
                        _appLogo
                    ),
                  ),
                ],
              ),
              const Text(
                'Welcome!'
              ),
              TextField(
                controller: _emailCTRL,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Enter your email',
                ),
              ),
              TextField(
                controller: _passCTRL,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Enter your password'
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}



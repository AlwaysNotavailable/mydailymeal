import 'package:flutter/material.dart';
import 'login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final TextEditingController _nameCTRL = TextEditingController();
  final TextEditingController _phoneCTRL = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final String _appLogo = 'assets/images/appLogo.png';
  int _selected = 1;
  final _selection = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  bool _yesorno = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(
                width: 300,
                height: 300,
                child: Image.asset(_appLogo, fit: BoxFit.contain),
              ),
              TextFormField(
                controller: _nameCTRL,
                keyboardType: TextInputType.text,
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              TextFormField(
                controller: _phoneCTRL,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(hintText: 'Phone'),
              ),
              DropdownButtonFormField(
                value: _selected,
                items:
                    _selection.map((int item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text('$item (s)'),
                      );
                    }).toList(),
                onChanged: (int? item) {
                  setState(() {
                    _selected = item!;
                  });
                },
              ),
              CheckboxListTile(
                value: _yesorno,
                title: Text('Do you like this apps?'),
                onChanged: (value) {
                  setState(() {
                    _yesorno = value!;
                  });
                },
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                    child: Text('Back'),
                  ),
                  ElevatedButton(
                      onPressed: (){
                        Navigator.pushNamed(context, '/profile');
                      },
                      child: Text('Back2')
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

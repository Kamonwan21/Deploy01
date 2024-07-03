import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'page.dart'; // Ensure to import your PatientDetailsPage file

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _buttonFocusNode = FocusNode();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _buttonFocusNode.addListener(() {
      if (_buttonFocusNode.hasFocus) {
        _buttonFocusNode.consumeKeyboardToken();
      }
    });
  }

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) {
      _showDialog('Validation Error', 'Please fill out all fields.');
      return;
    }

    setState(() => isLoading = true);
    final url = Uri.parse(
        'https://bpk-webapp-prd1.bdms.co.th/ApiPhamacySmartLabel/PatientVerify');
    // Uri.parse('http://10.143.10.37/ApiPhamacySmartLabel/PatientDetails');
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'emplid': _usernameController.text,
      'pass': _passwordController.text,
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
      final response = await http.post(url, headers: headers, body: body);
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userlogin = jsonResponse['userlogin'];
        if (userlogin is List && userlogin.isNotEmpty) {
          final visitId = userlogin[0]['visit_id'];
          if (visitId != null) {
            _navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                  builder: (context) => PatientDetailsPage(visitId: visitId)),
            );
          }
        } else {
          _showDialog('Login Failed!', 'Invalid Username or Password');
        }
      } else {
        _showDialog(
            'Error', 'Unexpected server response: ${response.statusCode}');
      }
    } catch (e) {
      _showDialog('Error', 'An error occurred: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content, style: const TextStyle(fontSize: 20)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (setting) => MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/login.png', width: 200, height: 150),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                          hintText: "กรุณากรอกหมายเลข HN",
                          labelText: 'Username'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your HN' : null,
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Please enter your HN number here.'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          hintText: "กรุณากรอกหมายเลข 4 ตัวท้าย",
                          labelText: 'Password'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your 4 Ids' : null,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: const TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  'กรอกหมายเลข 4 ตัวท้ายหลังบัตรประชาชน หรือ วันเดือนปีเกิด\n',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: 'เช่น ปปปป/ดด/วว\n',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Please enter the last 4 digits of your Passport or your Birthday.\n',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: 'Ex. yyyy/mm/dd',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      focusNode: _buttonFocusNode,
                      onPressed: isLoading ? null : () => _login(),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12)),
                      child: isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  CircularProgressIndicator(
                                      color: Colors.white),
                                  SizedBox(width: 24),
                                  Text('Please Wait...'),
                                ])
                          : const Text('Login',
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 20)),
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

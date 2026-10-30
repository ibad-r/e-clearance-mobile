import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../data/repositories.dart';

class AppState extends ChangeNotifier {
  AppState({AuthRepository? auth}) : _auth = auth ?? MockAuthRepository();

  final AuthRepository _auth;

  Employee? employee;

  Future<void> login(String email, String password) async {
    employee = await _auth.login(email, password);
    notifyListeners();
  }
}
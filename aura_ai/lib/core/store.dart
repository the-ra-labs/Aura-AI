import 'package:shared_preferences/shared_preferences.dart';

class Store {
  static late SharedPreferences _p;
  static Future<void> init() async => _p = await SharedPreferences.getInstance();
  static String? read(String k) => _p.getString(k);
  static Future<void> write(String k, String v) => _p.setString(k, v);
  static Future<void> remove(String k) => _p.remove(k);
}
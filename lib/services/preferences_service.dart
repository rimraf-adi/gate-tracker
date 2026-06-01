import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('preferencesServiceProvider must be overridden in main()');
});

final userNameProvider = StateNotifierProvider<UserNameNotifier, String>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return UserNameNotifier(prefsService);
});

class PreferencesService {
  final SharedPreferences _prefs;
  
  PreferencesService(this._prefs);

  static const _userNameKey = 'user_name';

  String getUserName() {
    return _prefs.getString(_userNameKey) ?? 'Student';
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_userNameKey, name);
  }
}

class UserNameNotifier extends StateNotifier<String> {
  final PreferencesService _prefsService;

  UserNameNotifier(this._prefsService) : super(_prefsService.getUserName());

  Future<void> updateName(String newName) async {
    await _prefsService.setUserName(newName);
    state = newName;
  }
}

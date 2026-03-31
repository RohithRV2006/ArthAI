import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arth/user_model.dart';
import 'package:arth/local_storage.dart';

class ProfileProvider extends ChangeNotifier {
  UserModel? _user;
  List<Map<String, String>> _incomeSources = [];
  bool _isLoading = true;

  String _language = 'english';

  UserModel? get user => _user;
  List<Map<String, String>> get incomeSources => _incomeSources;
  bool get isLoading => _isLoading;
  String get language => _language;

  static const _keyIncomeSources = 'arth_income_sources';

  Future<void> load() async {
    _user = await LocalStorage.loadUser();
    _language = await LocalStorage.getLanguage();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyIncomeSources);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _incomeSources = list.map((e) => Map<String, String>.from(e)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await LocalStorage.setLanguage(lang);
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    if (_user == null) return;
    _user!.name = name;
    await LocalStorage.saveUser(_user!);
    notifyListeners();
  }

  // 🔥 ADDED: Update Phone
  Future<void> updatePhone(String phone) async {
    if (_user == null) return;
    _user!.phone = phone;
    await LocalStorage.saveUser(_user!);
    notifyListeners();
  }

  // 🔥 ADDED: Update Location
  Future<void> updateLocation(String city, String country) async {
    if (_user == null) return;
    _user!.location.city = city;
    _user!.location.country = country;
    await LocalStorage.saveUser(_user!);
    notifyListeners();
  }

  // 🔥 ADDED: Add Family Member
  Future<void> addFamilyMember(FamilyMemberModel member) async {
    if (_user == null) return;
    _user!.members.add(member);
    await LocalStorage.saveUser(_user!);
    notifyListeners();
  }

  // 🔥 ADDED: Remove Family Member
  Future<void> removeFamilyMember(String memberId) async {
    if (_user == null) return;
    _user!.members.removeWhere((m) => m.memberId == memberId);
    await LocalStorage.saveUser(_user!);
    notifyListeners();
  }

  Future<void> updateIncome(double income) async {
    if (_user == null) return;

    final updatedSources = List<IncomeSourceModel>.from(_user!.incomeSources);
    if (updatedSources.isNotEmpty) {
      updatedSources[0].amount = income;
    } else {
      // 🔥 FIX: Changed ownerId -> ownerIds and wrapped the ID in a List []
      updatedSources.add(IncomeSourceModel(
          source: 'Primary', amount: income, ownerIds: [_user!.selfMemberId]));
    }

    _user!.incomeSources = updatedSources;
    await LocalStorage.saveUser(_user!);
    notifyListeners();
  }

  Future<void> toggleFamilyType() async {
    if (_user == null) return;
    final newType = _user!.familyType == 'individual' ? 'family' : 'individual';
    _user!.familyType = newType;
    await LocalStorage.saveUser(_user!);
    notifyListeners();
  }

  Future<void> addIncomeSource(
      {required String name, required String amount}) async {
    _incomeSources.add({'name': name, 'amount': amount});
    await _saveIncomeSources();
    notifyListeners();
  }

  Future<void> removeIncomeSource(Map<String, String> source) async {
    _incomeSources.remove(source);
    await _saveIncomeSources();
    notifyListeners();
  }

  Future<void> _saveIncomeSources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIncomeSources, jsonEncode(_incomeSources));
  }
}
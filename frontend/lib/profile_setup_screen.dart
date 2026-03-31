import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:arth/local_storage.dart';
import 'package:arth/user_model.dart';
import 'package:arth/api_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _professionController = TextEditingController();
  final _incomeAmountController = TextEditingController();
  String _language = 'english';
  String _incomeSourceType = 'salary';

  LocationModel _selectedLocation = LocationModel();

  String _familyType = 'individual';
  int _familyMembersCount = 1;
  final List<Map<String, dynamic>> _familyMembersData = [];

  final _cashInBankController = TextEditingController();
  final _totalAssetsController = TextEditingController();
  final _totalLiabilitiesController = TextEditingController();

  final int _mandatoryPages = 4;
  final int _totalPages = 5;

  final Map<String, String> _en = {
    'step_1': 'Personal Info', 'step_2': 'Location', 'step_3': 'Work & Income', 'step_4': 'Family', 'step_5': 'Balance Sheet',
    'call_you': 'Welcome!', 'name_desc': 'Let\'s set up your core financial profile.', 'full_name': 'Full Name',
    'pref_lang': 'Preferred App Language', 'tell_family': 'Family Details', 'family_desc': 'This helps AI give better household advice.',
    'manage_for': 'Total Number of family members:', 'just_me': 'Individual', 'my_family': 'Family', 'family_size': 'Number of family members:',
    'work': 'Income Source', 'work_desc': 'Tell us about your primary work.', 'profession_lbl': 'Your Profession (e.g. Software Engineer)', 'income': 'Total Monthly Amount',
    'savings_net': 'Current Balance', 'savings_desc': 'Optional — helps AI analyze financial health.',
    'total_assets': 'Est. Total Assets (Property, Gold)', 'total_liabilities': 'Total Debt (Loans, EMIs)', 'cash_bank': 'Current Cash in Bank',
    'continue': 'Continue', 'start_using': 'Finish', 'enter_name': 'Please enter your name', 'step_of': 'Required', 'optional': 'Optional',
    'loc_title': 'Your Location', 'loc_desc': 'This helps Arth adjust to regional financial rules.',
    'pin_loc': 'Pin Current Location', 'repin_loc': 'Repin Location', 'loc_note': 'Note: Only Country and City are saved to MongoDB.'
  };

  final Map<String, String> _ta = {
    'step_1': 'தனிப்பட்ட தகவல்', 'step_2': 'இடம்', 'step_3': 'வருமானம்', 'step_4': 'குடும்பம்', 'step_5': 'இருப்புநிலை',
    'call_you': 'வரவேற்கிறோம்!', 'name_desc': 'உங்கள் அடிப்படை நிதி விவரங்களை அமைப்போம்.', 'full_name': 'முழு பெயர்',
    'pref_lang': 'விருப்பமான செயலி மொழி', 'tell_family': 'குடும்ப விவரங்கள்', 'family_desc': 'இது AI-க்கு சிறந்த ஆலோசனைகளை வழங்க உதவும்.',
    'manage_for': 'குடும்ப உறுப்பினர்களின் மொத்த எண்ணிக்கை:', 'just_me': 'தனிநபர்', 'my_family': 'குடும்பம்', 'family_size': 'குடும்ப உறுப்பினர்கள்:',
    'work': 'வருமான ஆதாரம்', 'work_desc': 'உங்கள் முதன்மை வேலை பற்றி சொல்லுங்கள்.', 'profession_lbl': 'உங்கள் தொழில் (உதா. பொறியாளர்)', 'income': 'மொத்த மாதாந்திர தொகை',
    'savings_net': 'தற்போதைய இருப்பு', 'savings_desc': 'விருப்பத்திற்குரியது - AI நிதி ஆரோக்கியத்தை பகுப்பாய்வு செய்ய உதவும்.',
    'total_assets': 'மொத்த சொத்துக்கள் (நிலம், தங்கம்)', 'total_liabilities': 'மொத்த கடன்கள் (கடன், EMI)', 'cash_bank': 'வங்கியில் உள்ள பணம்',
    'continue': 'தொடரவும்', 'start_using': 'முடிக்க', 'enter_name': 'தயவுசெய்து உங்கள் பெயரை உள்ளிடவும்', 'step_of': 'கட்டாயம்', 'optional': 'விருப்பத்திற்குரியது',
    'loc_title': 'உங்கள் இருப்பிடம்', 'loc_desc': 'பிராந்திய நிதி விதிகளுக்கு ஏற்ப Arth செயல்பட இது உதவும்.',
    'pin_loc': 'தற்போதைய இருப்பிடத்தை பின் செய்யவும்', 'repin_loc': 'மீண்டும் பின் செய்யவும்', 'loc_note': 'குறிப்பு: நாடு மற்றும் நகரம் மட்டுமே MongoDB-யில் சேமிக்கப்படும்.'
  };

  String _t(String key) => _language == 'tamil' ? _ta[key] ?? key : _en[key] ?? key;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    _incomeAmountController.dispose();
    _cashInBankController.dispose();
    _totalAssetsController.dispose();
    _totalLiabilitiesController.dispose();
    super.dispose();
  }

  void _updateFamilyCount(int newCount) {
    setState(() {
      _familyMembersCount = newCount;
      while (_familyMembersData.length < newCount - 1) {
        _familyMembersData.add({
          'name': '',
          'relation': 'child',
          'age': '',
          'profession': '',
          'dependent': true,
        });
      }
      if (_familyMembersData.length > newCount - 1) {
        _familyMembersData.removeRange(newCount - 1, _familyMembersData.length);
      }
    });
  }

  void _nextPage() {
    bool canContinue = false;

    switch (_currentPage) {
      case 0:
        if (_nameController.text.trim().isNotEmpty &&
            _phoneController.text.trim().isNotEmpty) {
          canContinue = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please fill Name, Phone, and Language')));
        }
        break;
      case 1:
        if (_selectedLocation.city.isNotEmpty) {
          canContinue = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please Pin your current location')));
        }
        break;
      case 2:
        if (_professionController.text.trim().isNotEmpty &&
            _incomeAmountController.text.trim().isNotEmpty) {
          canContinue = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter Profession and Income Amount')));
        }
        break;
      case 3:
        if (_familyType == 'family' && _familyMembersData.any((m) => m['name'].toString().trim().isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter a name for all family members')));
        } else {
          canContinue = true;
        }
        break;
      default:
        canContinue = true;
    }

    if (canContinue) {
      if (_currentPage < _totalPages - 1) {
        _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut);
        setState(() => _currentPage++);
      } else {
        _saveProfile(finishOnboarding: true);
      }
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
      setState(() => _currentPage--);
    } else {
      _showGenericSkipDialog();
    }
  }

  void _showGenericSkipDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fill later?'),
        content: const Text(
            'You need to complete basic profile setup to get personalized insights. Do you want to skip for now?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.grey),
              onPressed: () {
                Navigator.pop(ctx);
                _saveProfile(finishOnboarding: false);
              },
              child: const Text('Skip Setup')),
        ],
      ),
    );
  }

  void _skipBalanceSheet() {
    _cashInBankController.clear();
    _totalAssetsController.clear();
    _totalLiabilitiesController.clear();
    _saveProfile(finishOnboarding: true);
  }

  Future<void> _pinCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _selectedLocation = LocationModel(
            country: place.country ?? "India",
            city: place.locality ?? place.subAdministrativeArea ?? "",
            latitude: position.latitude,
            longitude: position.longitude,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _saveProfile({required bool finishOnboarding}) async {
    setState(() => _isSaving = true);

    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) throw 'User not authenticated';

      final selfMember = FamilyMemberModel(
        name: _nameController.text.trim().isEmpty
            ? 'Arth User'
            : _nameController.text.trim(),
        relation: 'self',
        profession: _professionController.text.trim(),
        dependent: false,
      );

      List<FamilyMemberModel> tempFamilyMembers = [selfMember];

      if (_familyType == 'family' && _familyMembersCount > 1) {
        for (var m in _familyMembersData) {
          tempFamilyMembers.add(FamilyMemberModel(
            name: m['name'].toString().trim(),
            relation: m['relation'],
            age: int.tryParse(m['age'].toString()),
            profession: m['profession'].toString().trim(),
            dependent: m['dependent'],
          ));
        }
      }

      double incomeAmount = double.tryParse(_incomeAmountController.text.trim()) ?? 0.0;
      final mainIncome = IncomeSourceModel(
        source: _incomeSourceType,
        amount: incomeAmount,
        ownerIds: [selfMember.memberId],
      );

      final balance = FinancialBalanceModel(
        cashInBank: double.tryParse(_cashInBankController.text.trim()) ?? 0,
        totalAssets: double.tryParse(_totalAssetsController.text.trim()) ?? 0,
        totalLiabilities: double.tryParse(_totalLiabilitiesController.text.trim()) ?? 0,
      );

      final userModel = UserModel(
        userId: fbUser.uid,
        email: fbUser.email ?? '',
        name: selfMember.name,
        phone: '+91${_phoneController.text.trim()}',
        profession: selfMember.profession,
        location: _selectedLocation,
        familyType: _familyType,
        members: tempFamilyMembers,
        incomeSources: [mainIncome],
        onboardingCompleted: finishOnboarding,
      );

      await LocalStorage.saveUser(userModel);
      await LocalStorage.setLanguage(_language);

      try {
        final Map<String, dynamic> payload = userModel.toJson();

        if (balance.cashInBank > 0) {
          (payload['savings'] as List).add({
            "type": "bank",
            "amount": balance.cashInBank,
            "owner_ids": [selfMember.memberId]
          });
        }
        if (balance.totalAssets > 0) {
          (payload['assets'] as List).add({
            "name": "Total Assets",
            "type": "other",
            "value": balance.totalAssets,
            "owner_ids": [selfMember.memberId]
          });
        }
        if (balance.totalLiabilities > 0) {
          (payload['liabilities'] as List).add({
            "name": "Total Liabilities",
            "type": "loan",
            "total_amount": balance.totalLiabilities,
            "outstanding_amount": balance.totalLiabilities,
            "owner_ids": [selfMember.memberId]
          });
        }

        await ApiService.saveUserProfile(payload);
      } catch (e) {
        debugPrint("Pydantic Sync Failed: $e");
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync with Database: $e'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1D9E75);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(themeColor),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _slide1BasicInfo(themeColor),
                  _slide2Location(themeColor),
                  _slide3Income(themeColor),
                  _slide4Family(themeColor),
                  _slide5BalanceSheet(themeColor),
                ],
              ),
            ),
            _buildBottomBar(themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(Color color) {
    bool isMandatory = _currentPage < _mandatoryPages;
    double progress = (_currentPage + 1) / _totalPages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                isMandatory ? _t('step_of') : _t('optional'),
                style: TextStyle(
                    color: isMandatory ? color : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Color color) {
    bool isLastPage = _currentPage == _totalPages - 1;
    bool isOptionalPage = _currentPage >= _mandatoryPages;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (isOptionalPage) ...[
            TextButton(
              onPressed: _skipBalanceSheet,
              child: const Text('Skip', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: GestureDetector(
              onTap: _isSaving ? null : _nextPage,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6))
                    ]),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text(
                    isLastPage ? _t('start_using') : _t('continue'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle(String title, String subtitle, String emoji) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Text(title,
                style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 32),
      ],
    );
  }

  InputDecoration _inputFormat(String label, IconData icon) {
    const color = Color(0xFF1D9E75);
    return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: color, width: 2)));
  }

  Widget _slide1BasicInfo(Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageTitle(
              _t('call_you'), _t('name_desc'), '👋'),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputFormat(_t('full_name'), Icons.person_outline),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _inputFormat('Phone Number', Icons.phone_android).copyWith(
              prefixText: '+91 ',
              prefixStyle: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 32),
          Text(_t('pref_lang'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildLangCard(
                      'English', _language == 'english', color)),
              const SizedBox(width: 12),
              Expanded(
                  child:
                  _buildLangCard('தமிழ்', _language == 'tamil', color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangCard(String label, bool sel, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _language = label == 'தமிழ்' ? 'tamil' : 'english'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: sel ? color : Colors.grey.shade200, width: sel ? 2 : 1)),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: sel ? color : Colors.black87))),
      ),
    );
  }

  Widget _slide2Location(Color color) {
    bool hasLocation = _selectedLocation.city.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageTitle(_t('loc_title'),
              _t('loc_desc'), '📍'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                if (_isLoadingLocation)
                  const CircularProgressIndicator()
                else if (hasLocation) ...[
                  Icon(Icons.location_on, color: color, size: 48),
                  const SizedBox(height: 12),
                  Text(_selectedLocation.city,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_selectedLocation.country,
                      style: TextStyle(color: Colors.grey.shade600)),
                ] else ...[
                  Icon(Icons.location_off_outlined,
                      color: Colors.grey.shade400, size: 48),
                  const SizedBox(height: 12),
                  const Text('Location not pinned yet',
                      style: TextStyle(color: Colors.grey)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingLocation ? null : _pinCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: Text(
                        hasLocation ? _t('repin_loc') : _t('pin_loc')),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            _t('loc_note'),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _slide3Income(Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageTitle(_t('work'), _t('work_desc'), '💼'),
          TextField(
            controller: _professionController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputFormat(_t('profession_lbl'),
                Icons.business_center_outlined),
          ),
          const SizedBox(height: 32),
          const Text('Main Source of Income',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _incomeSourceType,
            decoration: _inputFormat('Income Type', Icons.category_outlined),
            items: ['salary', 'business', 'freelance', 'rental', 'other']
                .map((s) => DropdownMenuItem(
                value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                .toList(),
            onChanged: (v) => setState(() => _incomeSourceType = v!),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _incomeAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputFormat(
                _t('income'), Icons.currency_rupee_outlined),
          ),
        ],
      ),
    );
  }

  Widget _slide4Family(Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageTitle(_t('tell_family'),
              _t('family_desc'), '👨‍👩‍👧‍👦'),
          Row(
            children: [
              _buildFamilyTypeCard(Icons.person, _t('just_me'),
                  _familyType == 'individual', color),
              const SizedBox(width: 12),
              _buildFamilyTypeCard(
                  Icons.people, _t('my_family'), _familyType == 'family', color),
            ],
          ),
          if (_familyType == 'family') ...[
            const SizedBox(height: 32),
            Text(_t('manage_for'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularBtn(Icons.remove, color, () {
                  if (_familyMembersCount > 2) {
                    _updateFamilyCount(_familyMembersCount - 1);
                  }
                }),
                const SizedBox(width: 24),
                Text('$_familyMembersCount',
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                _buildCircularBtn(Icons.add, color, () {
                  if (_familyMembersCount < 10) {
                    _updateFamilyCount(_familyMembersCount + 1);
                  }
                }),
              ],
            ),
            const SizedBox(height: 24),

            ...List.generate(_familyMembersData.length, (index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Member ${index + 2}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: _inputFormat('Name', Icons.person).copyWith(contentPadding: const EdgeInsets.all(12)),
                        onChanged: (v) => _familyMembersData[index]['name'] = v,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _familyMembersData[index]['relation'],
                              decoration: _inputFormat('Relation', Icons.family_restroom).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                              items: ['spouse', 'parent', 'child', 'other'].map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
                              onChanged: (v) => setState(() => _familyMembersData[index]['relation'] = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                              decoration: _inputFormat('Age', Icons.cake).copyWith(contentPadding: const EdgeInsets.all(12)),
                              onChanged: (v) => _familyMembersData[index]['age'] = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: _inputFormat('Profession (Optional)', Icons.work).copyWith(contentPadding: const EdgeInsets.all(12)),
                        onChanged: (v) => _familyMembersData[index]['profession'] = v,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Is Dependent? (Relies on your income)', style: TextStyle(fontSize: 13)),
                        value: _familyMembersData[index]['dependent'],
                        activeThumbColor: color,
                        // 🔥 FIX: 100% foolproof constant padding
                        contentPadding: const EdgeInsets.all(0),
                        onChanged: (v) => setState(() => _familyMembersData[index]['dependent'] = v),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilyTypeCard(IconData icon, String label, bool sel, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _familyType = label == _t('just_me') ? 'individual' : 'family';
            if (_familyType == 'individual') {
              _updateFamilyCount(1);
            } else if (_familyMembersCount < 2) {
              _updateFamilyCount(2);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: sel ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: sel ? color : Colors.grey.shade200, width: sel ? 2 : 1)),
          child: Column(children: [
            Icon(icon, size: 36, color: sel ? color : Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: sel ? color : Colors.black87))
          ]),
        ),
      ),
    );
  }

  Widget _buildCircularBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color)),
          child: Icon(icon, color: color)),
    );
  }

  Widget _slide5BalanceSheet(Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageTitle(_t('savings_net'),
              _t('savings_desc'), '💰'),
          TextField(
            controller: _cashInBankController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputFormat(
                _t('cash_bank'), Icons.account_balance_outlined),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _totalAssetsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputFormat(
                _t('total_assets'), Icons.home_work_outlined),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _totalLiabilitiesController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputFormat(
                _t('total_liabilities'), Icons.money_off_outlined),
          ),
        ],
      ),
    );
  }
}
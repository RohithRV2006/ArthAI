import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arth/profile_provider.dart';
import 'package:arth/local_storage.dart';
import 'package:arth/auth_provider.dart';
import 'package:arth/login_screen.dart';
import 'package:arth/app_localizations.dart';
import 'package:arth/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().load();
    });
  }

  int _calculateCompletion(UserModel? user) {
    if (user == null) return 0;
    int score = 0;
    int total = 6;

    if (user.name.isNotEmpty) {
      score++;
    }
    if (user.phone.isNotEmpty) {
      score++;
    }
    if (user.location.city.isNotEmpty) {
      score++;
    }
    if (user.incomeSources.isNotEmpty) {
      score++;
    }

    if (user.familyType == 'family' && user.members.length > 1) {
      score++;
    } else if (user.familyType == 'individual') {
      score++;
    }

    score++;

    return ((score / total) * 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = context.watch<ProfileProvider>().language;
    final loc = AppLocalizations(currentLanguage);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(loc.profile,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1D9E75)));
          }

          final user = provider.user;
          final completion = _calculateCompletion(user);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (completion < 100)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text('Profile $completion% Complete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: completion / 100,
                            minHeight: 8,
                            backgroundColor: Colors.orange.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade500),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Fill missing details to get better AI insights!', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                      ],
                    ),
                  ),

                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF1D9E75).withValues(alpha: 0.3),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user != null && user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D9E75)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'Arth User',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _SectionHeader(title: loc.personalInfo),
                _PremiumTile(
                  icon: Icons.person_outline,
                  label: loc.name,
                  value: user?.name ?? '—',
                  onEdit: () =>
                      _editField(context, provider, 'name', user?.name ?? '', loc),
                ),

                _PremiumTile(
                  icon: Icons.phone_android,
                  label: 'Phone Number',
                  value: user != null && user.phone.isNotEmpty ? user.phone : 'Tap to add phone',
                  isMissing: user == null || user.phone.isEmpty,
                  onEdit: () => _editField(context, provider, 'phone', user?.phone.replaceAll('+91', '') ?? '', loc),
                ),

                _PremiumTile(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: user != null && user.location.city.isNotEmpty ? '${user.location.city}, ${user.location.country}' : 'Tap to pin location',
                  isMissing: user == null || user.location.city.isEmpty,
                  onEdit: () => _editLocationDialog(context, provider, loc),
                ),

                _PremiumTile(
                  icon: Icons.currency_rupee,
                  label: loc.monthlyIncome,
                  value: '₹${user?.totalMonthlyIncome.toStringAsFixed(0) ?? '0'}',
                  onEdit: () => _editField(
                      context,
                      provider,
                      'income',
                      user?.totalMonthlyIncome.toString() ?? '',
                      loc),
                ),
                const SizedBox(height: 24),

                // 🔥 FIX: Added the 'const' keyword right here!
                const _SectionHeader(title: 'Household'),
                _PremiumTile(
                  icon: Icons.people_outline,
                  label: loc.familyType,
                  value: user?.familyType == 'family' ? loc.family : loc.individual,
                  onEdit: () => provider.toggleFamilyType(),
                ),

                if (user?.familyType == 'family') ...[
                  ...user!.members.where((m) => m.relation != 'self').map((m) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Icon(Icons.face, color: Colors.orange, size: 20)),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text('${m.relation.toUpperCase()} • Age ${m.age ?? '?'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))])),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => provider.removeFamilyMember(m.memberId)),
                      ],
                    ),
                  )),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addFamilyMemberDialog(context, provider, loc),
                      icon: const Icon(Icons.add, color: Color(0xFF1D9E75)),
                      label: const Text('Add Family Member', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D9E75))),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: const Color(0xFF1D9E75).withValues(alpha: 0.5), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                _SectionHeader(title: loc.preferences),
                _PrefTile(
                  icon: Icons.language,
                  label: loc.language,
                  trailing: _LanguageToggle(
                    value: provider.language,
                    onChanged: (lang) =>
                        context.read<ProfileProvider>().setLanguage(lang),
                  ),
                ),
                _PrefTile(
                  icon: Icons.payments_outlined,
                  label: loc.currency,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('₹ INR',
                        style: TextStyle(
                            color: Color(0xFF1D9E75),
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),

                _SectionHeader(title: loc.incomeSources),
                ...provider.incomeSources.map(
                      (src) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.business_center_outlined,
                              color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(src['name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('₹${src['amount']}',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => provider.removeIncomeSource(src),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _addIncomeSource(context, provider, loc),
                    icon: const Icon(Icons.add, color: Color(0xFF1D9E75)),
                    label: Text(loc.addIncomeSource,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D9E75))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                          color: const Color(0xFF1D9E75).withValues(alpha: 0.5),
                          width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _confirmLogout(context, loc),
                    icon: const Icon(Icons.logout),
                    label: Text(loc.signOut,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editField(BuildContext ctx, ProfileProvider provider, String field,
      String current, AppLocalizations loc) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
            field == 'income' ? loc.editMonthlyIncome : (field == 'phone' ? 'Edit Phone' : loc.editName),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          keyboardType:
          field == 'name' ? TextInputType.text : TextInputType.number,
          decoration: InputDecoration(
            labelText: field == 'income' ? loc.amountHint : (field == 'phone' ? '10-digit number' : loc.nameHint),
            prefixIcon: Icon(field == 'income' ? Icons.currency_rupee : (field == 'phone' ? Icons.phone : Icons.person_outline), color: const Color(0xFF1D9E75)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel, style: const TextStyle(color: Colors.grey))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (field == 'income') {
                final val = double.tryParse(ctrl.text);
                if (val != null) provider.updateIncome(val);
              } else if (field == 'phone') {
                provider.updatePhone('+91${ctrl.text}');
              } else {
                provider.updateName(ctrl.text);
              }
              Navigator.pop(ctx);
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  void _editLocationDialog(BuildContext ctx, ProfileProvider provider, AppLocalizations loc) {
    final cityCtrl = TextEditingController(text: provider.user?.location.city);
    final countryCtrl = TextEditingController(text: provider.user?.location.country);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Update Location', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cityCtrl, decoration: InputDecoration(labelText: 'City', prefixIcon: const Icon(Icons.location_city, color: Color(0xFF1D9E75)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
            const SizedBox(height: 16),
            TextField(controller: countryCtrl, decoration: InputDecoration(labelText: 'Country', prefixIcon: const Icon(Icons.map, color: Color(0xFF1D9E75)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel, style: const TextStyle(color: Colors.grey))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { provider.updateLocation(cityCtrl.text, countryCtrl.text); Navigator.pop(ctx); }, child: Text(loc.save)),
        ],
      ),
    );
  }

  void _addFamilyMemberDialog(BuildContext ctx, ProfileProvider provider, AppLocalizations loc) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String relation = 'child';
    bool dependent = true;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add Family Member', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: relation,
                decoration: InputDecoration(labelText: 'Relation', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                items: ['spouse', 'parent', 'child', 'other'].map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
                onChanged: (v) => setDialogState(() => relation = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Age', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              SwitchListTile(
                  title: const Text('Dependent?'),
                  value: dependent,
                  activeThumbColor: const Color(0xFF1D9E75),
                  onChanged: (v) => setDialogState(() => dependent = v)
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(loc.cancel, style: const TextStyle(color: Colors.grey))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D9E75)),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  provider.addFamilyMember(FamilyMemberModel(name: nameCtrl.text, relation: relation, age: int.tryParse(ageCtrl.text), dependent: dependent));
                  Navigator.pop(dialogCtx);
                }
              },
              child: Text(loc.add),
            ),
          ],
        ),
      ),
    );
  }

  void _addIncomeSource(
      BuildContext ctx, ProfileProvider provider, AppLocalizations loc) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.addIncomeSource,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: loc.sourceHint,
                prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF1D9E75)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.monthlyAmountHint,
                prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF1D9E75)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel, style: const TextStyle(color: Colors.grey))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && amtCtrl.text.isNotEmpty) {
                provider.addIncomeSource(
                    name: nameCtrl.text, amount: amtCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: Text(loc.add),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext ctx, AppLocalizations loc) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.signOutTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(loc.signOutBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel, style: const TextStyle(color: Colors.grey))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await LocalStorage.clearUser();
              if (ctx.mounted) {
                await ctx.read<AuthProvider>().signOut();
                if (ctx.mounted) {
                  Navigator.pushAndRemoveUntil(
                      ctx,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (Route<dynamic> route) => false);
                }
              }
            },
            child: Text(loc.signOut),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }
}

class _PremiumTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMissing;
  final VoidCallback onEdit;

  const _PremiumTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isMissing = false,
    required this.onEdit
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMissing ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isMissing ? Colors.orange.shade200 : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: (isMissing ? Colors.orange : const Color(0xFF1D9E75)).withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(icon, color: isMissing ? Colors.orange : const Color(0xFF1D9E75), size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: isMissing ? Colors.orange.shade800 : Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isMissing ? Colors.orange.shade900 : Colors.black87)),
              ],
            ),
          ),
          IconButton(
              icon: Icon(isMissing ? Icons.add_circle : Icons.edit_outlined, color: isMissing ? Colors.orange : Colors.grey),
              onPressed: onEdit),
        ],
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _PrefTile(
      {required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(icon, color: Colors.purple, size: 20)),
          const SizedBox(width: 16),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87))),
          trailing,
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _LanguageToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption('english', 'EN'),
          _buildOption('tamil', 'தமிழ்'),
        ],
      ),
    );
  }

  Widget _buildOption(String id, String label) {
    final isSelected = value == id;
    return GestureDetector(
      onTap: () => onChanged(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1D9E75) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
              BoxShadow(
                  color: const Color(0xFF1D9E75).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]
                : []),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }
}
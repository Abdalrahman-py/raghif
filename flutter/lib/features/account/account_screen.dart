import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../core/i18n/strings.dart';
import '../../core/support/support_contact.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../auth/bloc/auth_bloc.dart';
import '../legal/legal_screens.dart';
import '../queue/confirm_action.dart';
import 'change_pin_sheet.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, this.embedded = false, this.authRepository});
  final bool embedded;

  /// Test seam: the repository the PIN change talks to. Production resolves it
  /// from [sl].
  final AuthRepository? authRepository;

  AuthRepository? get _repository =>
      authRepository ??
      (sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : null);

  Future<void> _changePin(
    BuildContext context,
    AuthRepository repository,
  ) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      builder: (_) => ChangePinSheet(repository: repository),
    );
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تغيير الرمز السري')));
    }
  }

  Future<void> _edit(BuildContext context, UserModel user) async {
    final bloc = context.read<AuthBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _ProfileEditor(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: embedded
          ? null
          : AppBar(
              title: const Text('حسابي'),
              actions: const [AccountMenuButton()],
            ),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is! Authenticated) {
              return const Center(
                child: Text(
                  'سجّل الدخول لعرض حسابك',
                  style: AppTypography.bodyLarge,
                ),
              );
            }
            final user = state.user;
            final scheme = Theme.of(context).colorScheme;
            final busy = state.profileSaving;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Who is signed in: one compact row instead of a hero block.
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.person_outline, color: scheme.primary),
                  ),
                  title: Text(user.name, style: AppTypography.titleLarge),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.phone, style: AppTypography.bodyLarge),
                      const Text(
                        'رقم جوال باي (رقم الدخول)',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('تعديل البيانات'),
                        trailing: const Icon(Icons.chevron_left),
                        enabled: !busy,
                        onTap: () => _edit(context, user),
                      ),
                      if (_repository != null) ...[
                        const Divider(height: 1),
                        ListTile(
                          key: const Key('change-pin'),
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('تغيير الرمز السري'),
                          trailing: const Icon(Icons.chevron_left),
                          enabled: !busy,
                          onTap: () => _changePin(context, _repository!),
                        ),
                      ],
                      const Divider(height: 1),
                      ListTile(
                        key: const Key('account-support-whatsapp'),
                        leading: const Icon(Icons.chat_outlined),
                        title: const Text(Strings.contactSupportWhatsapp),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => openSupportWhatsApp(
                          context,
                          message: Strings.supportMessage,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
                  child: Text(
                    'رقم الجوال ونوع الحساب وحالة التحقق لا تتغير من هذه الصفحة.',
                    style: AppTypography.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Icon(Icons.logout, color: scheme.error),
                    title: Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: scheme.error),
                    ),
                    onTap: () => confirmLogout(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// The three-dots menu of the profile: privacy policy, terms of use and the
/// account-deletion request. They are rarely needed, so they live here instead
/// of taking space on the profile itself.
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  static const _privacy = 'privacy';
  static const _terms = 'terms';
  static const _delete = 'delete';

  void _open(BuildContext context, String value) {
    switch (value) {
      case _privacy:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LegalScreen.privacy()));
      case _terms:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LegalScreen.terms()));
      case _delete:
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(Strings.deleteAccountTitle),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(Strings.deleteAccountBody),
                SizedBox(height: 16),
                SupportWhatsAppButton(
                  message: 'مرحبًا، أرغب بحذف حسابي في تطبيق رغيف.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(Strings.ok),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    key: const Key('account-menu'),
    tooltip: 'المزيد',
    icon: const Icon(Icons.more_vert),
    onSelected: (value) => _open(context, value),
    itemBuilder: (_) => const [
      PopupMenuItem(
        value: _privacy,
        child: ListTile(
          leading: Icon(Icons.privacy_tip_outlined),
          title: Text(Strings.privacyTitle),
        ),
      ),
      PopupMenuItem(
        value: _terms,
        child: ListTile(
          leading: Icon(Icons.description_outlined),
          title: Text(Strings.termsTitle),
        ),
      ),
      PopupMenuItem(
        value: _delete,
        child: ListTile(
          leading: Icon(Icons.delete_outline, color: AppColors.danger),
          title: Text(
            Strings.deleteAccountTitle,
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    ],
  );
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.user});
  final UserModel user;
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);
  bool _submitted = false;
  static final _phonePattern = RegExp(r'^05[69][0-9]{7}$');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_submitted &&
            state is Authenticated &&
            !state.profileSaving &&
            state.profileError == null) {
          Navigator.of(context).pop();
        }
        if (state is Unauthenticated) Navigator.of(context).pop();
      },
      builder: (context, state) {
        final saving = state is Authenticated && state.profileSaving;
        final error = state is Authenticated && _submitted
            ? state.profileError
            : null;
        return PopScope(
          canPop: !saving,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('تعديل البيانات', style: AppTypography.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('profile-name'),
                    controller: _name,
                    enabled: !saving,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'أدخل الاسم'
                        : value!.trim().length > 100
                        ? 'الاسم طويل جداً'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('profile-phone'),
                    controller: _phone,
                    // The phone is what support checks and sends recovery PINs
                    // to, so it cannot be edited here.
                    enabled: false,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'رقم جوال باي',
                    ),
                    validator: (value) =>
                        _phonePattern.hasMatch(value?.trim() ?? '')
                        ? null
                        : 'أدخل رقم جوال صحيحاً من 10 أرقام',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    Strings.phoneChangeViaSupport,
                    key: Key('phone-support-note'),
                    style: AppTypography.bodySmall,
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        error,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.danger,
                        ),
                        semanticsLabel: error,
                      ),
                    ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'حفظ التغييرات',
                    loading: saving,
                    onPressed: () {
                      if (!_form.currentState!.validate()) return;
                      setState(() => _submitted = true);
                      context.read<AuthBloc>().add(
                        UpdateProfileRequestedEvent(name: _name.text),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

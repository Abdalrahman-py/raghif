import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/repositories/auth_repository.dart';

/// Bottom sheet where a bakery owner replaces their own PIN.
///
/// Everything that matters is decided on the server (`change_my_pin`): the
/// current PIN must be right, five misses lock the feature for 15 minutes and
/// trivial PINs are refused. The checks here only save a round trip for typos.
class ChangePinSheet extends StatefulWidget {
  const ChangePinSheet({super.key, required this.repository});

  final AuthRepository repository;

  /// What the person is told for each answer the server can give.
  @visibleForTesting
  static String? messageFor(ChangePinResult result) => switch (result) {
    ChangePinResult.ok => null,
    ChangePinResult.wrongPin => 'الرمز الحالي غير صحيح',
    ChangePinResult.locked =>
      'تم إيقاف تغيير الرمز مؤقتًا بسبب محاولات خاطئة. حاول بعد 15 دقيقة.',
    ChangePinResult.weakPin =>
      'الرمز الجديد سهل التخمين. تجنب الأرقام المتكررة أو المتسلسلة.',
    ChangePinResult.invalidPin => 'الرمز الجديد يجب أن يكون 4 أرقام',
    ChangePinResult.samePin => 'الرمز الجديد يجب أن يختلف عن الحالي',
    ChangePinResult.notAllowed => 'لا يمكن تغيير الرمز لهذا الحساب',
  };

  @override
  State<ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<ChangePinSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  static final _fourDigits = RegExp(r'^[0-9]{4}$');

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.repository.changePin(
        currentPin: _current.text.trim(),
        newPin: _next.text.trim(),
      );
      if (!mounted) return;
      final message = ChangePinSheet.messageFor(result);
      if (message == null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = message);
      }
    } catch (_) {
      // The question never got an answer: say so, and keep what was typed.
      if (mounted) {
        setState(
          () =>
              _error = 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputAction action = TextInputAction.next,
  }) => TextFormField(
    key: key,
    controller: controller,
    enabled: !_busy,
    obscureText: true,
    keyboardType: TextInputType.number,
    textInputAction: action,
    maxLength: 4,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, counterText: ''),
    validator: validator,
    onFieldSubmitted: action == TextInputAction.done ? (_) => _submit() : null,
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: PopScope(
      canPop: !_busy,
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
              const Text('تغيير الرمز السري', style: AppTypography.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'الرمز السري من 4 أرقام تدخل به إلى حسابك.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              _field(
                key: const Key('pin-current'),
                controller: _current,
                label: 'الرمز الحالي',
                validator: (v) => _fourDigits.hasMatch(v ?? '')
                    ? null
                    : 'أدخل الرمز الحالي (4 أرقام)',
              ),
              const SizedBox(height: 16),
              _field(
                key: const Key('pin-new'),
                controller: _next,
                label: 'الرمز الجديد',
                validator: (v) => _fourDigits.hasMatch(v ?? '')
                    ? null
                    : 'الرمز الجديد 4 أرقام',
              ),
              const SizedBox(height: 16),
              _field(
                key: const Key('pin-confirm'),
                controller: _confirm,
                label: 'تأكيد الرمز الجديد',
                action: TextInputAction.done,
                validator: (v) =>
                    v == _next.text ? null : 'الرمزان غير متطابقين',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    key: const Key('pin-error'),
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'حفظ الرمز الجديد',
                loading: _busy,
                onPressed: _submit,
              ),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

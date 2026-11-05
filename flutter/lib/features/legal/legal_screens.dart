import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';

/// A plain, scrollable text page: the privacy policy and the terms of use.
///
/// DRAFT wording for the pilot. It describes what the app actually does today
/// and must be reviewed by someone qualified before a public launch.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.sections});

  final String title;
  final List<LegalSection> sections;

  /// The privacy policy.
  const LegalScreen.privacy({Key? key})
    : this(key: key, title: Strings.privacyTitle, sections: _privacySections);

  /// The terms of use.
  const LegalScreen.terms({Key? key})
    : this(key: key, title: Strings.termsTitle, sections: _termsSections);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (final section in sections) ...[
              Text(
                section.heading,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(section.body, style: textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

const _privacySections = [
  LegalSection(
    'ما الذي نجمعه',
    'اسمك، ورقم هويتك، ورقم جوالك، ورقم محفظة جوال باي إن أدخلته، وحجوزاتك '
        'ومواعيدها وحالتها، ورمزًا يخص جهازك لإرسال الإشعارات. رمزك السري يُحفظ '
        'مشفّرًا ولا يستطيع أحد قراءته، ولا الدعم.',
  ),
  LegalSection(
    'لماذا نجمعه',
    'للتحقق من أن لكل شخص رغيفًا واحدًا في اليوم، ولتنظيم الدور في المخبز، '
        'وإعلامك عندما يحين دورك، والتواصل معك عند الحاجة.',
  ),
  LegalSection(
    'من يرى بياناتك',
    'صاحب المخبز الذي حجزت منه يرى اسمك ورقم هويتك وحالة حجزك ليسلّمك الرغيف. '
        'فريق الإدارة يرى بيانات الحسابات لإدارة الخدمة ومساعدتك. لا نبيع بياناتك '
        'ولا نشاركها مع أي جهة إعلانية.',
  ),
  LegalSection(
    'مدة الحفظ',
    'نحتفظ ببيانات الحجوزات للمراجعة وحل الخلافات، ونحذف أو نخفي بيانات الحساب '
        'عند طلبك.',
  ),
  LegalSection(
    'حقوقك',
    'يمكنك طلب تصحيح بياناتك أو تعطيل حسابك أو حذفه بمراسلة الدعم على واتساب: '
        '${Strings.supportWhatsapp}. لحماية حسابك نتحقق من هويتك قبل أي تغيير.',
  ),
];

const _termsSections = [
  LegalSection(
    'الخدمة',
    'رغيف تتيح لك حجز رغيف واحد في اليوم من مخبز واحد، واستلامه عند إشعارك '
        'بحلول دورك. تعتمد الخدمة على كميات يحددها كل مخبز.',
  ),
  LegalSection(
    'حسابك',
    'أنت مسؤول عن صحة بياناتك وعن سرية رمزك السري، ولا تشاركه مع أحد. '
        'لا تُستعمل هوية غيرك. يجوز للإدارة تعطيل أي حساب يُساء استعماله أو '
        'يتضمن بيانات غير صحيحة.',
  ),
  LegalSection(
    'الحجز والاستلام',
    'الحجز لليوم نفسه فقط، ويمكن تأجيله مرة واحدة. الحجز غير المستلم في يومه '
        'يسقط، وتكرار عدم الاستلام قد يؤدي إلى تقييد حسابك.',
  ),
  LegalSection(
    'الدفع',
    'الدفع عبر جوال باي تجريبي حاليًا ولا يُخصم منه أي مبلغ. وقد يُطلب منك دفع '
        'ثمن الرغيف نقدًا للمخبز عند الاستلام.',
  ),
  LegalSection(
    'الدعم',
    'لأي مشكلة أو لاستعادة رمزك السري، راسل الدعم على واتساب: '
        '${Strings.supportWhatsapp}.',
  ),
];

/// Arabic-only app — no toggle, no second language. Every UI string funnels
/// through this class so there's one place to fix wording instead of
/// scattered literals per screen. Mirrors app/.../i18n/Strings.kt.
class Strings {
  Strings._();

  static const appTitle = 'توزيع الخبز';
  static const appSubtitle = 'احجز خبزك، تجنب الزحام';
  static const phoneLabel = 'رقم الهاتف';
  static const pinLabel = 'الرمز السري المكون من 4 أرقام';
  static const loginButton = 'تسجيل الدخول';
  static const loginError = 'لا يوجد حساب بهذا الرقم والرمز السري';
  static const demoAccountsTitle = 'حسابات تجريبية';
  static const demoBuyerLabel = 'مشتري';
  static const demoOwnerLabel = 'صاحب المخبز';

  static const personalIdLabel = 'رقم الهوية';
  static const nameLabel = 'الاسم';
  static const newAccountNotice = 'رقم جديد، أكمل بيانات التسجيل';
  static const registerButton = 'تسجيل حساب جديد';
  static const registerError = 'يرجى تعبئة جميع الحقول';
  static const demoBadge = 'نموذج تجريبي';
}

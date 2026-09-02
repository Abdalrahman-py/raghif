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
  static const registerButton = 'تسجيل حساب جديد';
  static const registerError = 'يرجى تعبئة جميع الحقول';
  static const demoBadge = 'نموذج تجريبي';
  static const logout = 'تسجيل الخروج';
  static const back = 'رجوع';
  static const createAccountPrompt = 'ليس لديك حساب؟';
  static const createAccountLink = 'إنشاء حساب جديد';

  // Onboarding
  static const onboardingSkip = 'تخطي';
  static const onboardingNext = 'التالي';
  static const onboardingGetStarted = 'إنشاء حساب';
  static const onboardingHaveAccount = 'لدي حساب بالفعل';
  static const onboardingTitle1 = 'احجز خبزك من البيت';
  static const onboardingBody1 =
      'اطلب كيس الخبز اليومي من أي مخبز قريب منك، دون الحاجة للوقوف في طابور طويل.';
  static const onboardingTitle2 = 'استلم إشعارك عند الجاهزية';
  static const onboardingBody2 =
      'بمجرد أن يحين دورك، سنرسل لك إشعاراً لتستلم طلبك من المخبز مباشرة.';
  static const onboardingTitle3 = 'تحقق من حسابك للشراء';
  static const onboardingBody3 =
      'أكمل التسجيل وتحقق من هويتك — كيس واحد لكل بطاقة هوية يومياً.';

  // Registration
  static const registrationTitle = 'إنشاء حساب جديد';
  static const registrationSubtitle = 'المعلومات التالية مطلوبة للتحقق من هويتك وحجز الخبز';
  static const jawwalPayNumberLabel = 'رقم جوال باي';
  static const jawwalPayNumberHint = 'سيُستخدم للدفع عند الشراء';

  // Identity verification
  static const idPhotoTitle = 'صورة بطاقة الهوية';
  static const idPhotoInstructions =
      'التقط صورة واضحة للوجه الأمامي لبطاقة هويتك. تأكد من وضوح الأرقام والصورة.';
  static const selfiePhotoTitle = 'صورة شخصية';
  static const selfiePhotoInstructions =
      'التقط صورة واضحة لوجهك للتأكد من مطابقتها مع بطاقة الهوية.';
  static const capturePrompt = 'اضغط لاختيار صورة';
  static const retakePhoto = 'إعادة الالتقاط';
  static const continueLabel = 'متابعة';
  static const verifyingTitle = 'جاري التحقق من حسابك';
  static const verifyingBody = 'يرجى الانتظار بينما نتحقق من بياناتك. هذا قد يستغرق لحظات.';
  static const verifiedTitle = 'تم التحقق من حسابك!';
  static const verifiedBody = 'يمكنك الآن حجز كيس الخبز اليومي من أي مخبز متاح.';
  static const continueToApp = 'الانتقال إلى التطبيق';

  // Store list
  static const storeListTitle = 'المخابز المتاحة';
  static const todayLabel = 'اليوم';
  static const noStores = 'لا توجد مخابز متاحة حالياً';
  static const available = 'متوفر';
  static const soldOut = 'نفدت الكمية';
  static String bagsRemaining(int remaining, int total) =>
      'المتبقي: $remaining من $total';

  // Purchase
  static const purchaseTitle = 'الشراء';
  static const priceLabel = 'السعر';
  static const priceValue = '3 شيكل';
  static const dailyLimitReached = 'لقد قمت بالحجز من هذا المخبز اليوم';
  static const viewOrder = 'عرض الطلب';
  static const payButton = 'ادفع 3 شيكل';

  // Confirmation
  static const confirmationTitle = 'تأكيد الحجز';
  static const queuePosition = 'الترتيب في الطابور';
  static String batchLabel(int batch) => 'الدفعة رقم $batch';
  static const statusWaiting = 'بانتظار الدور';
  static const estimatedTime = 'الوقت التقديري للجاهزية';
  static const statusNotified = 'خبزك جاهز!';
  static const returnToStores = 'العودة إلى المخابز';

  // Owner dashboard
  static const ownerDashboardTitle = 'لوحة صاحب المخبز';
  static const remainingLabel = 'المتبقي';
  static const purchaseWindowOpen = 'نافذة الشراء مفتوحة';
  static const allocationLabel = 'الكمية اليومية';
  static const batchSizeLabel = 'حجم الدفعة';
  static const decreaseValue = 'إنقاص';
  static const increaseValue = 'زيادة';
  static const saveAllocation = 'حفظ الكمية';
  static const goToQueue = 'عرض طابور المشترين';

  // Owner queue
  static const buyerQueueTitle = 'طابور المشترين';
  static const queueEmpty = 'لا يوجد مشترون بعد اليوم';
  static String notifyNextBatch(int batch) => 'إشعار الدفعة رقم $batch';
  static const statusWaitingShort = 'قيد الانتظار';
  static const statusNotifiedShort = 'تم الإشعار';
  static const statusCollectedShort = 'تم الاستلام';
  static const markReceived = 'تأكيد الاستلام';
  static const undoReceived = 'تراجع عن الاستلام';
}

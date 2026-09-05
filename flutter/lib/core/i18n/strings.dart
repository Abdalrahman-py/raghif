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
  static const loginError = 'الرمز السري غير صحيح';
  static const requestOtpButton = 'إرسال رمز التحقق';
  static const otpLabel = 'رمز التحقق';
  static const verifyOtpButton = 'تأكيد الرمز والدخول';
  static const loginWithPinInstead = 'الدخول باستخدام الرمز السري بدلاً من ذلك';
  static const loginWithOtpInstead = 'الدخول برمز التحقق (OTP) بدلاً من ذلك';
  static const changeNationalId = 'تغيير رقم الهوية';
  static const resendOtp = 'إعادة إرسال الرمز';
  static const otpError = 'رمز التحقق غير صحيح';
  static const nationalIdNotFound = 'رقم الهوية غير مسجل، يرجى إنشاء حساب جديد';
  static String demoOtpBanner(String code) =>
      'رمز تجريبي (لم يتم إرسال رسالة نصية): $code';
  static const otpNotificationTitle = 'رمز التحقق';
  static String otpNotificationBody(String code) => 'رمز التحقق الخاص بك: $code';
  static const demoAccountsTitle = 'حسابات تجريبية';
  static const demoBuyerLabel = 'مشتري';
  static const demoOwnerLabel = 'صاحب المخبز';

  static const personalIdLabel = 'رقم الهوية';
  static const nameLabel = 'الاسم';
  static const registerButton = 'تسجيل حساب جديد';
  static const registerError = 'يرجى تعبئة جميع الحقول';
  static const phoneAlreadyRegistered = 'رقم الهاتف مسجل مسبقاً';
  static const nationalIdAlreadyRegistered = 'رقم الهوية مسجل مسبقاً';
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
  static const registrationSubtitle =
      'المعلومات التالية مطلوبة للتحقق من هويتك وحجز الخبز';
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
  static const verifyingBody =
      'يرجى الانتظار بينما نتحقق من بياناتك. هذا قد يستغرق لحظات.';
  static const verifiedTitle = 'تم التحقق من حسابك!';
  static const verifiedBody =
      'يمكنك الآن حجز كيس الخبز اليومي من أي مخبز متاح.';
  static const continueToApp = 'الانتقال إلى التطبيق';

  // Store list
  static const storeListTitle = 'المخابز المتاحة';
  static const todayLabel = 'اليوم';
  static const noStores = 'لا توجد مخابز متاحة حالياً';
  static const available = 'متوفر';
  static const soldOut = 'نفدت الكمية';
  static String bagsRemaining(int remaining, int total) =>
      'المتبقي: $remaining من $total';
  static String purchaseWindowRange(String openTime, String closeTime) =>
      'وقت الشراء: $openTime - $closeTime';

  // Purchase
  static const purchaseTitle = 'الشراء';
  static const priceLabel = 'السعر';
  static const priceValue = '3 شيكل';
  static const dailyLimitReached = 'لقد قمت بالحجز من هذا المخبز اليوم';
  static String dailyLimitReachedOtherStore(String storeName) {
    final name = storeName.trim();
    if (name.isEmpty) {
      return 'لقد قمت بالحجز من مخبز آخر اليوم بالفعل';
    }
    final prefix = name.startsWith('مخبز') ? '' : 'مخبز ';
    return 'لقد قمت بالحجز من $prefix$name اليوم بالفعل';
  }

  static const viewOrder = 'عرض الطلب';
  static const payButton = 'ادفع 3 شيكل';

  // Confirmation
  static const confirmationTitle = 'تأكيد الحجز';
  static const queuePosition = 'الترتيب في الطابور';
  static String batchLabel(int batch) => 'الدفعة رقم $batch';
  static const statusWaiting = 'بانتظار الدور';
  static const waitingReassurance = 'سيتم إشعارك عندما يحين دورك';
  static const estimatedTime = 'الوقت التقديري للجاهزية';
  static const statusNotified = 'خبزك جاهز!';
  static String batchReadyNotificationTitle(String storeName) =>
      'خبزك جاهز في $storeName';
  static const batchReadyNotificationBody =
      'حان دورك، توجه إلى المخبز لاستلام طلبك';
  static String purchaseConfirmedNotificationTitle(String storeName) =>
      'تم تأكيد حجزك في $storeName';
  static String purchaseConfirmedNotificationBody(int batch) =>
      'أنت الآن في الدفعة رقم $batch، سنشعرك عندما يحين دورك';
  static const returnToStores = 'العودة إلى المخابز';
  static const receiptQrTitle = 'رمز استلام الطلب';
  static const receiptQrSubtitle =
      'أظهر هذا الرمز لصاحب المخبز لتأكيد الاستلام';
  static const shareQrButton = 'مشاركة رمز الاستلام';
  static const saveQrButton = 'حفظ في المعرض';
  static const shareQrText = 'رمز استلام الخبز';
  static const qrSavedSuccess = 'تم حفظ رمز الاستلام في المعرض';
  static const qrSaveFailed = 'تعذر حفظ رمز الاستلام في المعرض';
  static const receiptPurchaseIdLabel = 'رقم الطلب';
  static const receiptDateLabel = 'التاريخ';
  static const receiptBatchLabel = 'الدفعة';
  static const receiptNameLabel = 'الاسم';

  // Owner dashboard
  static const ownerDashboardTitle = 'لوحة صاحب المخبز';
  static const remainingLabel = 'المتبقي';
  static const purchaseWindowTimesLabel = 'أوقات الشراء';
  static const openTimeLabel = 'وقت البدء';
  static const closeTimeLabel = 'وقت الانتهاء';
  static const notSetLabel = 'غير محدد';
  static const allocationLabel = 'الكمية اليومية';
  static const batchSizeLabel = 'حجم الدفعة';
  static const decreaseValue = 'إنقاص';
  static const increaseValue = 'زيادة';
  static const saveAllocation = 'حفظ الكمية';
  static const saveBatchSize = 'حفظ حجم الدفعة';
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

  // Payment (Jawwal Pay mock)
  static const paymentTitle = 'الدفع عبر جوال باي';
  static const confirmJawwalPayNumber = 'تأكيد رقم جوال باي';
  static const jawwalPayPrompt = 'سيتم خصم 3 شيكل من محفظة جوال باي الخاصة بك.';
  static const proceedToOtp = 'إرسال رمز التأكيد';
  static const paymentOtpTitle = 'رمز تأكيد الدفع';
  static const paymentOtpInstructions =
      'أدخل رمز التأكيد المكون من 4 أرقام لتأكيد عملية الدفع.';
  static String demoOtpNotification(String code) =>
      'رمز التحقق (رسالة تجريبية): $code';
  static const paymentOtpLabel = 'رمز التأكيد (OTP)';
  static const confirmPaymentButton = 'تأكيد الدفع';
  static const resendCodeButton = 'إعادة إرسال الرمز';
  static const wrongOtpError = 'رمز التأكيد غير صحيح، يرجى المحاولة مرة أخرى';
  static const paymentSuccessTitle = 'تم الدفع بنجاح';
  static const paymentSuccessMessage =
      'تمت عملية الدفع بنجاح بقيمة 3 شيكل عبر جوال باي.';
  static const completeReservationButton = 'إتمام الحجز';

  // Owner customers
  static const customersTitle = 'سجل الزبائن';
  static const customersButton = 'عرض سجل الزبائن';
  static const customersEmpty = 'لا يوجد زبائن مسجلون بعد';
  static String totalPurchasesCount(int count) => 'إجمالي المشتريات: $count';
  static String lastPurchaseDate(String date) => 'آخر شراء: $date';
}

package com.raghif.app.i18n

// Arabic-only app — no toggle, no second language. Every UI string funnels through here
// so there's one place to fix wording instead of scattered literals per screen.
private val strings: Map<String, String> = mapOf(
    "app_title" to "توزيع الخبز",
    "app_subtitle" to "احجز خبزك، تجنب الزحام",
    "phone_label" to "رقم الهاتف",
    "pin_label" to "الرمز السري المكون من 4 أرقام",
    "login_button" to "تسجيل الدخول",
    "login_error" to "لا يوجد حساب بهذا الرقم والرمز السري",
    "demo_accounts_title" to "حسابات تجريبية",
    "demo_buyer_label" to "مشتري",
    "demo_owner_label" to "صاحب المخبز",

    "personal_id_label" to "رقم الهوية",
    "name_label" to "الاسم",
    "new_account_notice" to "رقم جديد، أكمل بيانات التسجيل",
    "register_button" to "تسجيل حساب جديد",
    "register_error" to "يرجى تعبئة جميع الحقول",
    "demo_badge" to "نموذج تجريبي",

    "search_label" to "ابحث بالاسم أو رقم الهاتف أو رقم الهوية",
    "no_results" to "لا توجد نتائج",
    "queue_empty" to "لا يوجد مشترين بعد",
    "no_stores" to "لا توجد مخابز متاحة حالياً",
    "bags_remaining" to "المتبقي %d / %d",

    "payment_notif_title" to "تم الدفع بنجاح",
    "payment_notif_body" to "لقد دفعت ثمن حزمة الخبز في %s. الوقت المتوقع للجاهزية: %s",

    "store_list_title" to "المخابز المتاحة",
    "menu_label" to "القائمة",
    "orders_count" to "عدد الطلبات",
    "fab_add_allocation" to "إضافة كمية جديدة",
    "available" to "متوفر",
    "sold_out" to "نفدت الكمية",
    "logout" to "تسجيل الخروج",
    "today_label" to "اليوم",
    "simulate_new_day" to "محاكاة يوم جديد (تجريبي)",

    "purchase_title" to "شراء حزمة خبز",
    "balance_label" to "رصيدك",
    "price_label" to "السعر",
    "pay_button" to "ادفع 3 شيكل",
    "back" to "رجوع",
    "insufficient_balance" to "الرصيد غير كافٍ",
    "daily_limit_reached" to "لقد اشتريت خبزًا اليوم، لا يمكنك الشراء مرة أخرى حتى يوم جديد",
    "view_order" to "عرض طلبك",

    "confirmation_title" to "تم تأكيد الطلب",
    "queue_position" to "أنت رقم",
    "estimated_time" to "الوقت المتوقع للجاهزية",
    "status_waiting" to "بانتظار دورك...",
    "status_notified" to "خبزك جاهز!",
    "return_to_stores" to "العودة إلى قائمة المخابز",

    "owner_dashboard_title" to "لوحة صاحب المخبز",
    "remaining_label" to "المتبقي",
    "purchase_window_open" to "نافذة الشراء مفتوحة",
    "allocation_label" to "كمية اليوم (أكياس)",
    "batch_size_label" to "حجم الدفعة",
    "save_allocation" to "حفظ (يعيد ضبط العداد لهذا اليوم)",
    "go_to_queue" to "الذهاب إلى قائمة المشترين",

    "buyer_queue_title" to "قائمة المشترين",
    "notify_next_batch" to "إشعار الدفعة التالية (الدفعة %d)",
    "batch_label" to "الدفعة %d",
    "mark_received" to "تم الاستلام",
    "undo_received" to "تراجع",
    "status_waiting_short" to "قيد الانتظار",
    "status_notified_short" to "تم الإشعار",
    "status_collected_short" to "تم الاستلام",
    "notify_permission_toast" to "تم تحديث الدفعة، لكن إذن الإشعارات غير مفعّل على هذا الجهاز",

    "increase_value" to "زيادة",
    "decrease_value" to "إنقاص"
)

fun t(key: String): String = strings[key] ?: key

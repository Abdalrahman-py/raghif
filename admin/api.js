// Everything the panel asks of the backend, in one place. The Vue app only
// talks to this object, which is also what lets dev-mock.js stand in for it.
(function () {
  class ApiError extends Error {}

  // Plain-Arabic versions of the messages the database and edge functions raise.
  const MESSAGES = {
    'not authorized': 'غير مصرّح لك بهذا الإجراء',
    'missing token': 'انتهت الجلسة، سجّل الدخول من جديد',
    'phone already registered': 'رقم الجوال مسجّل مسبقًا',
    'national id already registered': 'رقم الهوية مسجّل مسبقًا',
    'allocation below existing future bookings': 'الكمية اليومية أقل من الحجوزات المسجّلة ليوم الغد',
    'price cannot be negative': 'السعر لا يمكن أن يكون سالبًا',
    'daily limit cannot be negative': 'الكمية لا يمكن أن تكون سالبة',
    'store not found': 'المخبز غير موجود',
    'user not found': 'المستخدم غير موجود',
    'an administrator cannot be disabled here': 'لا يمكن تعطيل حساب المسؤول',
    'cannot reset an administrator': 'لا يمكن إعادة تعيين رمز المسؤول',
    'owner already has a store': 'لهذا المالك مخبز بالفعل',
    'invalid governorate': 'المحافظة غير صحيحة',
    'phone must be 10 digits starting with 0': 'رقم الجوال: 10 أرقام تبدأ بصفر',
    'nationalId must be 9 digits': 'رقم الهوية: 9 أرقام',
  };

  function translate(message) {
    return MESSAGES[message] || message || 'حدث خطأ غير متوقع';
  }

  window.ApiError = ApiError;

  window.createApi = function (cfg) {
    const sb = window.supabase.createClient(cfg.supabaseUrl, cfg.supabaseKey, {
      auth: { persistSession: true, autoRefreshToken: true },
    });

    async function rpc(name, args) {
      const { data, error } = await sb.rpc(name, args);
      if (error) throw new ApiError(translate(error.message));
      return data;
    }

    // The admin-api edge function. A non-2xx answer carries { error } in its
    // body; surface that instead of the generic "non-2xx status code".
    async function fn(body) {
      const { data, error } = await sb.functions.invoke('admin-api', { body });
      if (error) {
        let message = error.message;
        try {
          const j = await error.context.json();
          if (j && j.error) message = j.error;
        } catch (_) { /* keep the generic message */ }
        throw new ApiError(translate(message));
      }
      return data;
    }

    return {
      // ---- session
      async currentUser() {
        const { data } = await sb.auth.getSession();
        return data.session ? data.session.user : null;
      },
      async signIn(email, password) {
        const { error } = await sb.auth.signInWithPassword({ email, password });
        if (error) throw new ApiError('البريد الإلكتروني أو كلمة المرور غير صحيحة');
        const ok = await sb.rpc('is_admin');
        if (ok.error || ok.data !== true) {
          await sb.auth.signOut();
          throw new ApiError('هذا الحساب ليس حساب مسؤول');
        }
      },
      async isAdmin() {
        const r = await sb.rpc('is_admin');
        return !r.error && r.data === true;
      },
      async signOut() { await sb.auth.signOut(); },

      // ---- statistics
      overview: () => rpc('admin_overview'),
      series: (days) => rpc('admin_daily_series', { p_days: days }),
      scans: (days) => rpc('admin_scan_summary', { p_days: days }),
      notificationStats: (days) => rpc('admin_notification_stats', { p_days: days }),

      // ---- lists
      stores: (idleDays) => rpc('admin_list_stores', { p_idle_days: idleDays }),
      buyers: (search, limit, offset) =>
        rpc('admin_list_buyers', { p_search: search || null, p_limit: limit, p_offset: offset }),

      // ---- changes that need no service key
      updateStore: (id, f) => rpc('admin_update_store', {
        p_store: id,
        p_name: f.name,
        p_area: f.area,
        p_governorate: f.governorate,
        p_daily_bag_limit: f.dailyBagLimit,
        p_bag_price: f.bagPrice,
        p_batch_size: f.batchSize,
        p_open_time: f.openTime || null,
        p_close_time: f.closeTime || null,
      }),
      setVerification: (userId, status) =>
        rpc('admin_set_verification', { p_user: userId, p_status: status }),
      sendNotification: (target, title, body, storeId) =>
        rpc('admin_send_notification', {
          p_target: target, p_title: title, p_body: body, p_store: storeId || null,
        }),

      // ---- changes that go through the admin-api edge function
      createBakery: (f) => fn({ action: 'create-bakery', ...f }),
      resetPin: (userId) => fn({ action: 'reset-pin', userId }),
      setStoreStatus: (storeId, status) => fn({ action: 'set-store-status', storeId, status }),
      setAccountStatus: (userId, status) => fn({ action: 'set-account-status', userId, status }),
    };
  };
})();

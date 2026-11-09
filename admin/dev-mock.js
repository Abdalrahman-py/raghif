// Development only. `?mock=1` on localhost (app.js enforces the hostname) swaps
// the real backend for this in-memory fake so the panel can be looked at and
// clicked through without Supabase. It is sample data, not real people.
(function () {
  const delay = (v) => new Promise((r) => setTimeout(() => r(v), 120));
  const today = new Date();
  const iso = (d) => d.toISOString().slice(0, 10);
  const daysAgo = (n) => { const d = new Date(today); d.setDate(d.getDate() - n); return d; };

  let stores = [
    mk(1, 'مخبز الأمل', 'الرمال', 'غزة', 'active', 220, 140, 3, 9, 'أبو أحمد', '0599111001'),
    mk(2, 'مخبز النور', 'الشجاعية', 'غزة', 'active', 180, 20, 3, 8, 'سليم النجار', '0599111002'),
    mk(3, 'مخبز السلام', 'دير البلح', 'الوسطى', 'paused', 90, 90, 3, 14, 'منى خليل', '0599111003'),
    mk(4, 'مخبز الشروق', 'خانيونس', 'خانيونس', 'active', 40, 12, 3, 0, 'عادل حسن', '0599111004'),
    mk(5, 'مخبز القديم', 'رفح', 'رفح', 'archived', 15, 15, 3, 40, 'يوسف سالم', '0599111005'),
  ];
  function mk(n, name, area, gov, status, total, collected, price, idleDays, owner, phone) {
    return {
      store_id: '00000000-0000-4000-8000-00000000000' + n, name, status,
      is_open: status === 'active', area, governorate: gov, bag_price: price,
      daily_bag_limit: 100, bags_remaining: 100 - n * 11, batch_size: 10,
      open_time: '08:00:00', close_time: '14:00:00',
      owner_id: '10000000-0000-4000-8000-00000000000' + n, owner_name: owner, owner_phone: phone,
      owner_account_status: 'active',
      total_bookings: total, collected, collect_rate: total ? Math.round((collected / total) * 10000) / 10000 : 0,
      bookings_today: status === 'active' ? 12 - n : 0,
      last_booking_date: total ? iso(daysAgo(idleDays)) : null, idle: idleDays > 7,
      revenue_estimate: collected * price, created_at: iso(daysAgo(100 - n)),
    };
  }
  // collect_rate above is bookings collected / total; fix the obviously odd one
  stores[0].collect_rate = 0.64; stores[1].collect_rate = 0.11;

  const names = ['أحمد ناصر', 'محمود سعيد', 'إبراهيم حمدان', 'سارة عبد الرحمن', 'ليلى المصري', 'عمر الخطيب',
    'فاطمة الزهراء', 'يوسف النجار', 'مريم خالد', 'حسن عباس', 'رنا أبو عودة', 'خالد البرغوثي'];
  let buyers = Array.from({ length: 64 }, (_, i) => ({
    id: '20000000-0000-4000-8000-' + String(i).padStart(12, '0'),
    name: names[i % names.length] + (i >= names.length ? ' ' + (Math.floor(i / names.length) + 1) : ''),
    phone: '05991' + String(20000 + i), national_id: '90' + String(1000000 + i),
    verification_status: i % 3 === 0 ? 'pending' : 'verified',
    account_status: i === 7 ? 'disabled' : 'active',
    created_at: iso(daysAgo(i)),
    bookings: 12 - (i % 9), collected: 9 - (i % 9) > 0 ? 9 - (i % 9) : 0,
    missed: i % 11 === 0 ? 4 : i % 5 === 0 ? 2 : 0,
  }));

  const series = Array.from({ length: 30 }, (_, i) => {
    const bookings = 18 + Math.round(10 * Math.sin(i / 3)) + (i % 7);
    return { day: iso(daysAgo(29 - i)), bookings, collected: Math.round(bookings * 0.7), new_buyers: i % 4 };
  });

  const fakePin = () => String(1000 + Math.floor(Math.random() * 8000)).replace(/(\d)\1{3}/, '5726');

  window.createMockApi = function () {
    let signedIn = false;
    return {
      currentUser: () => delay(signedIn ? { email: 'admin@example.com' } : null),
      async signIn(email, password) {
        await delay();
        if (password !== 'demo') throw new window.ApiError('البريد الإلكتروني أو كلمة المرور غير صحيحة');
        signedIn = true;
      },
      isAdmin: () => delay(true),
      signOut: () => { signedIn = false; return delay(); },

      overview: () => delay({
        buyers_total: buyers.length, buyers_new_today: 3, buyers_new_week: 14, buyers_new_month: 47,
        buyers_disabled: 1, buyers_verified: 43, buyers_pending: 21, owners_total: stores.length,
        stores_total: stores.length, stores_active: stores.filter((s) => s.status === 'active').length,
        stores_paused: stores.filter((s) => s.status === 'paused').length,
        stores_archived: stores.filter((s) => s.status === 'archived').length,
        bookings_today: 37, collected_today: 22, not_collected_today: 15,
        bags_sold_total: 2411, bags_collected_total: 1688,
        revenue_estimate_total: 5064, revenue_estimate_today: 66,
      }),
      series: () => delay(series),
      scans: () => delay([{ outcome: 'collected', total: 1688 }, { outcome: 'already_collected', total: 41 }, { outcome: 'wrong_store', total: 6 }]),
      notificationStats: () => delay({
        inbox_total: 912, inbox_unread: 233, devices_registered: 58, users_with_device: 51,
        by_kind: [{ kind: 'confirmed', total: 540 }, { kind: 'ready', total: 360 }, { kind: 'postponed', total: 12 }],
      }),

      stores: () => delay(stores.map((s) => ({ ...s }))),
      buyers(search, limit, offset) {
        const q = (search || '').trim();
        const hit = buyers.filter((b) => !q || [b.name, b.phone, b.national_id].some((v) => v.includes(q)));
        return delay(hit.slice(offset, offset + limit).map((b) => ({ ...b, total_matches: hit.length })));
      },

      async updateStore(id, f) {
        const s = stores.find((x) => x.store_id === id);
        Object.assign(s, {
          name: f.name, area: f.area, governorate: f.governorate, daily_bag_limit: f.dailyBagLimit,
          bag_price: f.bagPrice, batch_size: f.batchSize,
          open_time: f.openTime ? f.openTime + ':00' : s.open_time, close_time: f.closeTime ? f.closeTime + ':00' : s.close_time,
        });
        return delay(s);
      },
      async setVerification(id, status) { buyers.find((b) => b.id === id).verification_status = status; return delay({}); },
      sendNotification: () => delay(51),

      async createBakery(f) {
        if (f.phone === '0599999999') throw new window.ApiError('رقم الجوال مسجّل مسبقًا');
        const n = stores.length + 1;
        const s = mk(n, f.storeName, f.area, f.governorate, 'active', 0, 0, f.bagPrice, 0, f.ownerName, f.phone);
        s.store_id = '00000000-0000-4000-8000-0000000000' + String(n).padStart(2, '0');
        s.owner_id = '10000000-0000-4000-8000-0000000000' + String(n).padStart(2, '0');
        s.daily_bag_limit = f.dailyBagLimit; s.last_booking_date = null; s.idle = true;
        stores.push(s);
        return delay({ ok: true, pin: fakePin() });
      },
      resetPin: () => delay({ ok: true, pin: fakePin() }),
      async setStoreStatus(id, status) {
        stores.find((s) => s.store_id === id).status = status;
        return delay({ ok: true });
      },
      async setAccountStatus(id, status) {
        buyers.find((b) => b.id === id).account_status = status;
        return delay({ ok: true });
      },
    };
  };
})();

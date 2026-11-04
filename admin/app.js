// The admin panel. Vue 3 from a CDN, no build step. All data access goes
// through `api` (api.js), which is the only thing that knows about Supabase.
(function () {
  const cfg = window.RAGHIF_ADMIN;
  const GOVERNORATES = ['شمال غزة', 'غزة', 'الوسطى', 'خانيونس', 'رفح'];
  const WEEKDAYS = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  const STATUS = { active: 'فعّال', paused: 'متوقف مؤقتًا', archived: 'مؤرشف' };

  const emptyForm = () => ({
    storeName: '', area: '', governorate: GOVERNORATES[1],
    ownerName: '', phone: '', nationalId: '',
    dailyBagLimit: 100, bagPrice: 3, batchSize: 10,
  });

  function createPanel(api) {
    return Vue.createApp({
      data() {
        return {
          config: cfg,
          view: 'boot', // boot | login | app
          tab: 'overview',
          tabs: [
            { id: 'overview', label: 'نظرة عامة' },
            { id: 'bakeries', label: 'المخابز' },
            { id: 'buyers', label: 'المشترون' },
            { id: 'stats', label: 'الإحصائيات' },
            { id: 'notifications', label: 'الإشعارات' },
          ],
          userEmail: '',
          loginForm: { email: '', password: '' },
          loginError: '', loginBusy: false,

          banner: null, toast: '', busy: false, modalError: '',
          loading: { overview: false, stores: false, buyers: false, stats: false },

          overview: null, series: [],
          stores: [],
          buyers: { rows: [], total: 0, offset: 0, limit: 50 },
          buyerSearch: '',
          statsLoaded: false, scans: [], notifStats: null,
          missedBuyers: { rows: [], scanned: 0 },

          governorates: GOVERNORATES,
          createOpen: false, form: emptyForm(),
          editing: null, editForm: {},
          reveal: null, copied: false,
          confirm: null,
          notice: { target: 'all', storeId: '', title: '', body: '' },
        };
      },

      computed: {
        chart() {
          const w = 720, h = 210, left = 34, bottom = 26, top = 8;
          const data = this.series;
          const max = Math.max(5, ...data.map((d) => d.bookings));
          const niceMax = Math.ceil(max / 5) * 5;
          const plotH = h - bottom - top;
          const slot = (w - left) / Math.max(data.length, 1);
          const bw = slot * 0.64;
          const y = (v) => top + plotH - (v / niceMax) * plotH;
          const bars = data.map((d, i) => ({
            date: d.day,
            bookings: d.bookings, collected: d.collected,
            x: left + i * slot + (slot - bw) / 2, w: bw,
            y: y(d.bookings), hb: (d.bookings / niceMax) * plotH,
            yc: y(d.collected), hc: (d.collected / niceMax) * plotH,
          }));
          const ticks = [0, 0.5, 1].map((f) => ({ v: Math.round(niceMax * f), y: y(niceMax * f) }));
          const labels = data
            .map((d, i) => ({ x: left + i * slot + slot / 2, text: d.day.slice(5), i }))
            .filter((l) => l.i % 5 === 0 || l.i === data.length - 1);
          return { w, h, left, bars, ticks, labels, total: data.reduce((s, d) => s + d.bookings, 0) };
        },
        topStores() {
          return [...this.stores].filter((s) => Number(s.total_bookings) > 0)
            .sort((a, b) => b.total_bookings - a.total_bookings).slice(0, 5);
        },
        idleStores() {
          return this.stores.filter((s) => s.idle && s.status === 'active');
        },
        storesWithOwner() {
          return this.stores.filter((s) => s.owner_id && s.status !== 'archived');
        },
      },

      methods: {
        // ---------------------------------------------------- formatting
        num(n) { return Number(n || 0).toLocaleString('en-US'); },
        money(n) {
          const v = Number(n || 0);
          return v.toLocaleString('en-US', { maximumFractionDigits: 2 }) + ' ₪';
        },
        pct(r) { return Math.round(Number(r || 0) * 100) + '%'; },
        statusLabel(s) { return STATUS[s] || s; },
        dayName(iso) {
          const d = new Date(iso + 'T00:00:00');
          return isNaN(d) ? '' : WEEKDAYS[d.getDay()];
        },
        dateOnly(ts) { return ts ? String(ts).slice(0, 10) : ''; },
        topWidth(s) {
          const top = this.topStores[0];
          return top ? Math.max(4, Math.round((s.total_bookings / top.total_bookings) * 100)) : 0;
        },

        // ------------------------------------------------------ feedback
        say(text) {
          this.toast = text;
          clearTimeout(this._toast);
          this._toast = setTimeout(() => { this.toast = ''; }, 3500);
        },
        fail(e) {
          if (e && /JWT|token|expired/i.test(e.message || '')) { this.signOut(); return; }
          this.banner = { type: 'error', text: (e && e.message) || 'حدث خطأ غير متوقع' };
        },

        // --------------------------------------------------------- auth
        async boot() {
          try {
            const user = await api.currentUser();
            if (user && (await api.isAdmin())) {
              this.userEmail = user.email || '';
              this.view = 'app';
              this.go('overview');
              return;
            }
          } catch (_) { /* fall through to the login form */ }
          this.view = 'login';
        },
        async signIn() {
          this.loginBusy = true; this.loginError = '';
          try {
            await api.signIn(this.loginForm.email, this.loginForm.password);
            this.loginForm.password = '';
            await this.boot();
          } catch (e) {
            this.loginError = e.message;
          } finally {
            this.loginBusy = false;
          }
        },
        async signOut() {
          try { await api.signOut(); } catch (_) { /* already gone */ }
          this.overview = null; this.stores = []; this.series = [];
          this.buyers = { rows: [], total: 0, offset: 0, limit: 50 };
          this.statsLoaded = false; this.banner = null;
          this.view = 'login';
        },

        // ---------------------------------------------------------- tabs
        go(tab) {
          this.tab = tab; this.banner = null;
          if (tab === 'overview') this.loadOverview();
          if (tab === 'bakeries') this.loadStores();
          if (tab === 'buyers') this.loadBuyers();
          if (tab === 'stats') this.loadStats();
          if (tab === 'notifications' && !this.stores.length) this.loadStores();
        },
        async loadOverview() {
          this.loading.overview = true;
          try {
            const [o, s] = await Promise.all([api.overview(), api.series(30)]);
            this.overview = o; this.series = s;
          } catch (e) { this.fail(e); } finally { this.loading.overview = false; }
        },
        async loadStores() {
          this.loading.stores = true;
          try { this.stores = await api.stores(7); }
          catch (e) { this.fail(e); } finally { this.loading.stores = false; }
        },
        async loadBuyers() {
          this.loading.buyers = true;
          try {
            const rows = await api.buyers(this.buyerSearch, this.buyers.limit, this.buyers.offset);
            this.buyers.rows = rows;
            this.buyers.total = rows.length ? Number(rows[0].total_matches) : 0;
          } catch (e) { this.fail(e); } finally { this.loading.buyers = false; }
        },
        onBuyerSearch() {
          clearTimeout(this._search);
          this._search = setTimeout(() => { this.buyers.offset = 0; this.loadBuyers(); }, 350);
        },
        pageBuyers(dir) {
          this.buyers.offset = Math.max(0, this.buyers.offset + dir * this.buyers.limit);
          this.loadBuyers();
        },
        async loadStats() {
          this.loading.stats = true;
          try {
            const [stores, scans, notif, buyers] = await Promise.all([
              api.stores(7), api.scans(30), api.notificationStats(30), api.buyers(null, 200, 0),
            ]);
            this.stores = stores; this.scans = scans; this.notifStats = notif;
            this.missedBuyers = {
              scanned: buyers.length,
              rows: buyers.filter((b) => Number(b.missed) >= 2)
                .sort((a, b) => b.missed - a.missed).slice(0, 10),
            };
            this.statsLoaded = true;
          } catch (e) { this.fail(e); } finally { this.loading.stats = false; }
        },

        // ------------------------------------------------ create bakery
        openCreate() { this.form = emptyForm(); this.modalError = ''; this.createOpen = true; },
        async submitCreate() {
          this.busy = true; this.modalError = '';
          try {
            const r = await api.createBakery({ ...this.form });
            this.createOpen = false;
            this.reveal = {
              title: 'تم إنشاء المخبز',
              who: `${this.form.storeName} — ${this.form.ownerName} (${this.form.phone})`,
              pin: r.pin,
            };
            this.loadStores();
          } catch (e) { this.modalError = e.message; } finally { this.busy = false; }
        },

        // -------------------------------------------------- edit bakery
        openEdit(s) {
          this.editing = s; this.modalError = '';
          this.editForm = {
            name: s.name, area: s.area || '', governorate: s.governorate || GOVERNORATES[1],
            dailyBagLimit: Number(s.daily_bag_limit), bagPrice: Number(s.bag_price),
            batchSize: Number(s.batch_size),
            openTime: s.open_time ? String(s.open_time).slice(0, 5) : '',
            closeTime: s.close_time ? String(s.close_time).slice(0, 5) : '',
          };
        },
        async submitEdit() {
          this.busy = true; this.modalError = '';
          try {
            await api.updateStore(this.editing.store_id, { ...this.editForm });
            this.editing = null; this.say('تم حفظ التعديلات');
            this.loadStores();
          } catch (e) { this.modalError = e.message; } finally { this.busy = false; }
        },

        // ---------------------------------------- status and PIN actions
        askStoreStatus(s, ev) {
          const status = ev.target.value;
          ev.target.value = s.status; // the list is the source of truth; reload after
          if (status === s.status) return;
          const consequences = {
            active: 'سيعود المخبز للظهور ويستطيع المشترون الحجز عنده.',
            paused: 'سيبقى المخبز ظاهرًا مع شارة «متوقف مؤقتًا» ولن يستطيع المشترون الحجز عنده. يبقى صاحبه قادرًا على الدخول.',
            archived: 'سيختفي المخبز عن المشترين ويُسجَّل خروج صاحبه فورًا ولن يستطيع الدخول. الحجوزات والسجلات تبقى محفوظة.',
          };
          this.ask({
            title: `تغيير حالة «${s.name}» إلى ${STATUS[status]}`,
            body: consequences[status],
            label: 'تأكيد',
            danger: status === 'archived',
            run: async () => {
              await api.setStoreStatus(s.store_id, status);
              this.say('تم تغيير الحالة'); this.loadStores();
            },
          });
        },
        askResetPin(s) {
          this.ask({
            title: `رمز PIN جديد لـ «${s.owner_name}»`,
            body: 'سيتوقف الرمز الحالي عن العمل فورًا ويُسجَّل خروج صاحب المخبز من كل أجهزته. سيظهر الرمز الجديد لك مرة واحدة.',
            label: 'توليد رمز جديد',
            danger: true,
            run: async () => {
              const r = await api.resetPin(s.owner_id);
              this.reveal = { title: 'رمز جديد', who: `${s.name} — ${s.owner_name}`, pin: r.pin };
            },
          });
        },
        askAccountStatus(b) {
          const disabling = b.account_status === 'active';
          this.ask({
            title: `${disabling ? 'تعطيل' : 'تفعيل'} حساب ${b.name || b.phone}`,
            body: disabling
              ? 'لن يستطيع المشتري الدخول أو الحجز، ويُسجَّل خروجه فورًا. بياناته وحجوزاته تبقى محفوظة.'
              : 'سيستطيع المشتري الدخول والحجز من جديد.',
            label: disabling ? 'تعطيل' : 'تفعيل',
            danger: disabling,
            run: async () => {
              await api.setAccountStatus(b.id, disabling ? 'disabled' : 'active');
              this.say('تم تحديث الحساب'); this.loadBuyers();
            },
          });
        },
        async toggleVerification(b) {
          const next = b.verification_status === 'verified' ? 'pending' : 'verified';
          try {
            await api.setVerification(b.id, next);
            b.verification_status = next; this.say('تم تحديث حالة التوثيق');
          } catch (e) { this.fail(e); }
        },

        // ------------------------------------------------------ dialogs
        ask(c) { this.modalError = ''; this.confirm = c; },
        async runConfirm() {
          this.busy = true; this.modalError = '';
          try { await this.confirm.run(); this.confirm = null; }
          catch (e) { this.modalError = e.message; } finally { this.busy = false; }
        },
        async copyPin() {
          try {
            await navigator.clipboard.writeText(this.reveal.pin);
            this.copied = true;
          } catch (_) { this.say('تعذّر النسخ، انسخه يدويًا'); }
        },
        closeReveal() { this.reveal = null; this.copied = false; },

        // ------------------------------------------------ notifications
        askSend() {
          const n = this.notice;
          if (!cfg.announcementsReady) return;
          if (n.target === 'store' && !n.storeId) return;
          const who = {
            all: 'جميع المستخدمين', buyers: 'كل المشترين',
            owners: 'كل أصحاب المخابز', store: 'صاحب المخبز المحدد',
          }[n.target];
          this.ask({
            title: `إرسال إلى ${who}`,
            body: `«${n.title}» — لا يمكن التراجع بعد الإرسال.`,
            label: 'إرسال',
            run: async () => {
              const count = await api.sendNotification(n.target, n.title, n.body, n.storeId);
              this.say(`أُرسل إلى ${this.num(count)} مستخدم`);
              this.notice = { target: 'all', storeId: '', title: '', body: '' };
            },
          });
        },
      },

      mounted() { this.boot(); },
    });
  }

  // Local-only: `?mock=1` on localhost swaps in sample data so the panel can be
  // looked at without a backend. Never active on the published site.
  function loadMock() {
    return new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = 'dev-mock.js'; s.onload = resolve; s.onerror = reject;
      document.head.appendChild(s);
    });
  }

  (async function start() {
    const local = ['localhost', '127.0.0.1'].includes(location.hostname);
    const wantsMock = new URLSearchParams(location.search).get('mock') === '1';
    let api;
    if (local && wantsMock) {
      await loadMock();
      api = window.createMockApi();
    } else {
      api = window.createApi(cfg);
    }
    createPanel(api).mount('#app');
  })();
})();

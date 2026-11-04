// Public configuration for the admin panel.
//
// Both values below are the same ones that ship inside the mobile app's APK
// (the project URL and the *publishable* key). They are not secrets: what keeps
// the data safe is that every admin_* database function and the admin-api edge
// function check that the signed-in user is an administrator. NEVER put the
// service_role key in this file or anywhere under admin/.
window.RAGHIF_ADMIN = {
  supabaseUrl: 'https://mgmerkaokkffsypnkryj.supabase.co',
  supabaseKey: 'sb_publishable_W1krXaSZDx6v4z5Un-BPrg_sa2nJbOc',

  // Announcements write inbox rows with no purchase behind them. The app build
  // that is out today reads purchase_id as non-null and cannot display them.
  // Flip this to true only once the app that tolerates it has shipped
  // (docs/superpowers/plans/2026-11-04-admin-panel.md, phase 6).
  announcementsReady: false,
};

/// Demo sign-in accounts shown on the login screen. They exist on the server
/// only if someone ran the gated `seed-demo` action of the auth-gateway Edge
/// Function (supabase/functions/auth-gateway); the app never creates them.
/// Keep in sync with DEMO_ACCOUNTS there. Never seed them into a project that
/// holds real identities: the PIN is public.
const demoBuyerPhone = '0599111111';
const demoBuyerPin = '1234';
const demoBuyerNationalId = '900111222';
const demoBuyerName = 'أحمد ناصر';

const demoOwnerPhone = '0599222222';
const demoOwnerPin = '1234';
const demoOwnerNationalId = '900333444';
const demoOwnerName = 'صاحب المخبز';

// Second buyer, so two phones can test the queue side by side (one bag per
// account per day).
const demoBuyer2Phone = '0599444555';
const demoBuyer2Pin = '1234';
const demoBuyer2NationalId = '900444555';
const demoBuyer2Name = 'حسن الخليلي';

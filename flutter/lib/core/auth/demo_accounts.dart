/// Demo account constants used to seed the local database on first run
/// (see AuthRepository.ensureSeeded). Mirrors app/.../data/AppDatabase.kt's
/// DEMO_* constants.
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

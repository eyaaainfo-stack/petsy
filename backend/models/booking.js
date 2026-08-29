const mongoose = require('mongoose');

// ============================================================================
// Booking
// ============================================================================
// 🔵 ZID: request_a_book.dart (Flutter) - el owner ye5tar pets + services
// + check-in/check-out, w ybaath talab lel sitter.
// ============================================================================
const bookingServiceSchema = new mongoose.Schema(
  {
    serviceId: { type: String, required: true },
    price: { type: Number, required: true },
  },
  { _id: false }
);

const bookingSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    // 🔴 FIX (kifma tlab: workflow "reject -> broadcast lel sitters
    // okhrin"): "required: true" -> optional (null). Ki el sitter el
    // asli yerfudh W el owner ye5tar y-rebroadcast, el booking twalli
    // "open" (sitter: null) - ay sitter compatible ynajjam ynajjam
    // ychouf/ye5tar ya5ouha.
    sitter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    pets: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Animal', required: true }],
    services: { type: [bookingServiceSchema], required: true },
    checkIn: { type: Date, required: true },
    checkOut: { type: Date, required: true },
    total: { type: Number, required: true },
    // 🔵 ZID (kifma tlab: workflow kaملou):
    // - pending: mab3outha l'sitter mo3ayan, mazel ma jawebch
    // - accepted: mfaslin (sitter = final)
    // - rejected: el sitter el asli rafedh, w el owner 3ADHEL
    //   yerbroadcast (mayet - dead)
    // - open: el owner 9bel el broadcast - sitter=null, ay sitter
    //   compatible ynajjam ychouf/ye5tar ya5ouha (marketplace)
    // - awaiting_confirmation: sitter candidate 9bel ("accept") talab
    //   "open" - mestanniyin confirmation el owner (final say)
    status: { type: String, enum: ['pending', 'accepted', 'rejected', 'open', 'awaiting_confirmation'], default: 'pending' },
    // 🔵 el candidate elli 9bel el talab "open" - mestanni confirmation
    // el owner (booking.sitter ma yetbeddelch 7atta el owner y confirmi).
    pendingCandidateSitter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    // 🔵 sitters elli déjà rafdou (wela el owner declina) - bch ma
    // yban-lhomch NAFS el talab mrra thenya fel "urgent" marketplace.
    rejectedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Booking', bookingSchema);
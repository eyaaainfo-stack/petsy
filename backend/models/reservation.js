// models/reservation.js
const mongoose = require('mongoose');

// ============================================================================
// Reservation
// ============================================================================
// Kifma fel diagramme: Service -- Reservation.
// ============================================================================
const reservationSchema = new mongoose.Schema(
  {
    service: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Service',
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'confirmed', 'completed', 'cancelled'],
      default: 'pending',
    },
    startDate: { type: Date },
    endDate: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Reservation', reservationSchema);
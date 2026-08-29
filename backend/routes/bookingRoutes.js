// routes/bookingRoutes.js
const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const questionnaireController = require('../controllers/checkoutQuestionnaireController');
const { protect } = require('../middleware/auth');

router.post('/', protect, bookingController.createBooking);
router.get('/mine', protect, bookingController.getMyBookings);
router.get('/notifications', protect, bookingController.getMyNotifications);
router.get('/notifications/unread-count', protect, bookingController.getUnreadNotificationsCount);
router.patch('/notifications/mark-read', protect, bookingController.markAllNotificationsRead);
router.patch('/notifications/:id/dismiss', protect, bookingController.dismissNotification);

// 🔵 ZID (kifma tlab: request.dart, workflow accept/reject/broadcast/
// candidate) - "GET /urgent" LEZEM 9BAL "GET /:id" (mnghir Express
// ye5altha b'ID).
// 🔵 ZID (kifma tlab: sitter_calender.dart) - "GET /my-schedule" LEZEM
// 9BAL "GET /:id" (mnghir Express ye5altha b'ID).
// 🔵 ZID (kifma tlab: questionnaire ba3d el checkout) - "GET
// /pending-questionnaires" LEZEM 9BAL "GET /:id" zeda.
router.get('/pending-questionnaires', protect, questionnaireController.getPendingQuestionnaires);
router.get('/my-schedule', protect, bookingController.getMySchedule);
router.get('/urgent', protect, bookingController.getUrgentBookingsForSitter);
router.get('/:id', protect, bookingController.getBookingById);
router.patch('/:id/respond', protect, bookingController.respondToBooking);
router.patch('/:id/broadcast', protect, bookingController.broadcastBooking);
router.patch('/:id/confirm-candidate', protect, bookingController.confirmCandidate);
router.patch('/:id/cancel', protect, bookingController.cancelBooking);

// 🔵 ZID (kifma tlab): questionnaire ba3d el checkout - wizard 4 étapes
// (service/checkout/payment/satisfaction).
router.get('/:id/questionnaire', protect, questionnaireController.getQuestionnaire);
router.patch('/:id/questionnaire/service-done', protect, questionnaireController.answerServiceDone);
router.patch('/:id/questionnaire/checkout-done', protect, questionnaireController.answerCheckoutDone);
router.patch('/:id/questionnaire/payment-done', protect, questionnaireController.answerPaymentDone);
router.patch('/:id/questionnaire/satisfaction', protect, questionnaireController.answerSatisfaction);

module.exports = router;
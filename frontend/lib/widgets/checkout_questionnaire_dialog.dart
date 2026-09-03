import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controllers/checkout_questionnaire_controller.dart';
import 'success_confirmation_dialog.dart';
import 'message_dialog.dart';

// ============================================================================
// CheckoutQuestionnaireDialog
// ============================================================================
// 🔵 ZID (kifma tlab): "fel widgets, mch fel views" (widget mchtarek,
// mch écran kaملou) - "des fenêtres, wa9t yjiw l'écran yولّي flou
// chwaya" (BackdropFilter). 4 étapes (service/checkout/payment/
// satisfaction) - el step yban 7asb el state elli déjà mjawba (backend
// = source of truth, bch el wizard ynajjam "yresumi" lowkan el user
// sakkar w 3awed fata7ha).
//
// 🔵 el "succès" (à la fin) yesta3mel showSuccessConfirmationDialog
// (widgets/success_confirmation_dialog.dart, déjà mawjouda) - mch
// n3awdou nbniw nafs el UI (tick+message+bouton) mel jdid.
// ============================================================================
class _QuestionnaireResult {
  final bool completed;
  final String? message;
  const _QuestionnaireResult({required this.completed, this.message});
}

class CheckoutQuestionnaireDialog extends StatefulWidget {
  final String bookingId;

  const CheckoutQuestionnaireDialog({super.key, required this.bookingId});

  // 🔵 terja3 true lowkan el questionnaire "khlas" (submit sar, mch
  // "Later") - el caller ynajjam ye5tar ychek 3la wa7ed okhor mestani
  // wla le (chain).
  static Future<bool> show(BuildContext context, String bookingId) async {
    final result = await showGeneralDialog<_QuestionnaireResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => CheckoutQuestionnaireDialog(bookingId: bookingId),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6 * anim.value, sigmaY: 6 * anim.value),
          child: FadeTransition(
            opacity: anim,
            child: Container(color: Colors.black.withOpacity(0.15 * anim.value), child: child),
          ),
        );
      },
    );

    if (result?.message != null && context.mounted) {
      await showSuccessConfirmationDialog(context, message: result!.message!);
    }
    return result?.completed ?? false;
  }

  @override
  State<CheckoutQuestionnaireDialog> createState() => _CheckoutQuestionnaireDialogState();
}

class _CheckoutQuestionnaireDialogState extends State<CheckoutQuestionnaireDialog> {
  final CheckoutQuestionnaireController _controller = CheckoutQuestionnaireController();

  QuestionnaireState? _state;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // -------- état "local" (bla ma nebe3thou l'backend 7atta submit) --------
  bool _showServiceReason = false;
  final TextEditingController _serviceReasonController = TextEditingController();

  bool _showCheckoutDelay = false;
  String? _blamedParty; // 'owner' / 'sitter'
  DateTime? _newCheckoutTime;

  bool _showPaymentReason = false;
  final TextEditingController _paymentReasonController = TextEditingController();

  // 🔴 FIX (kifma tlab): "satisfied" (Yes/No) -> 4 catégories (Trust/
  // Service/Communication/Knowledge, 1-5 njoum lel wa7da - kifha kif
  // el mockup).
  bool? _satisfiedChoice;
  final TextEditingController _reviewController = TextEditingController();
  final Map<String, int> _ratings = {'trust': 0, 'service': 0, 'communication': 0, 'knowledge': 0};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _serviceReasonController.dispose();
    _paymentReasonController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final state = await _controller.fetchQuestionnaire(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _state = state;
      _isLoading = false;
    });
  }

  void _closeLater() => Navigator.of(context).pop(const _QuestionnaireResult(completed: false));

  void _closeWithMessage(String message) => Navigator.of(context).pop(_QuestionnaireResult(completed: true, message: message));

  // -------- Étape 1: service done? --------
  Future<void> _onServiceAnswer(bool done) async {
    if (!done) {
      setState(() => _showServiceReason = true);
      return;
    }
    await _submit(() => _controller.answerServiceDone(widget.bookingId, done: true));
  }

  Future<void> _onServiceReasonSubmit() async {
    final ok = await _submit(() => _controller.answerServiceDone(widget.bookingId, done: false, reason: _serviceReasonController.text.trim()));
    if (!ok || !mounted) return;
    _closeWithMessage('questionnaire_closing_service_not_done'.tr());
  }

  // -------- Étape 2: checkout done? --------
  Future<void> _onCheckoutAnswer(bool done) async {
    if (!done) {
      setState(() => _showCheckoutDelay = true);
      return;
    }
    await _submit(() => _controller.answerCheckoutDone(widget.bookingId, done: true));
  }

  Future<void> _pickNewCheckoutTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null || !mounted) return;
    setState(() => _newCheckoutTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _onCheckoutDelaySubmit() async {
    if (_blamedParty == null || _newCheckoutTime == null) return;
    final dateStr =
        '${_newCheckoutTime!.day}/${_newCheckoutTime!.month} ${_newCheckoutTime!.hour.toString().padLeft(2, '0')}:${_newCheckoutTime!.minute.toString().padLeft(2, '0')}';
    final ok = await _submit(() => _controller.answerCheckoutDone(widget.bookingId, done: false, blamedParty: _blamedParty, newCheckoutTime: _newCheckoutTime));
    if (!ok || !mounted) return;
    _closeWithMessage('questionnaire_closing_postponed'.tr(namedArgs: {'date': dateStr}));
  }

  // -------- Étape 3: payment done? --------
  Future<void> _onPaymentAnswer(bool done) async {
    if (!done) {
      setState(() => _showPaymentReason = true);
      return;
    }
    await _submit(() => _controller.answerPaymentDone(widget.bookingId, done: true));
  }

  Future<void> _onPaymentReasonSubmit() async {
    await _submit(() => _controller.answerPaymentDone(widget.bookingId, done: false, reason: _paymentReasonController.text.trim()));
  }

  // -------- Étape 4: satisfaction --------
  Future<void> _onSatisfactionSubmit() async {
    if (_satisfiedChoice == null || _ratings.values.any((v) => v == 0)) return;
    final ok = await _submit(() => _controller.answerSatisfaction(
          widget.bookingId,
          satisfied: _satisfiedChoice!,
          review: _reviewController.text.trim(),
          ratingTrust: _ratings['trust']!,
          ratingService: _ratings['service']!,
          ratingCommunication: _ratings['communication']!,
          ratingKnowledge: _ratings['knowledge']!,
        ));
    if (!ok || !mounted) return;
    _closeWithMessage('questionnaire_closing_thanks'.tr());
  }

  // 🔵 terja3 true lowkan el submit najjah (bch el caller ye3raf ynajjam
  // ykommel wla le).
  Future<bool> _submit(Future<QuestionnaireState?> Function() action) async {
    if (_isSubmitting) return false;
    setState(() => _isSubmitting = true);
    final newState = await action();
    if (!mounted) return false;
    setState(() {
      _isSubmitting = false;
      if (newState != null) _state = newState;
    });
    if (newState == null) {
      showMessageDialog(context, 'profile_submit_error'.tr());
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🔴 FIX (kifma tlab: "el snack bar ma nenajemch nekraha khater el
    // flou") - ScaffoldMessenger.of(context) kan yel9a el Scaffold tel
    // écran EL LI WARA (ta7t el blur/dim, "route" el9dima), fa el
    // SnackBar kan yban TA7T el blur tou3na (ma yen9raٍch). Scaffold
    // MA7ALLI houni (transparent) - el SnackBar tawa jozz men "route"
    // tou3na (FOU9 el blur, wadhe7 100%).
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: sizes.screenWidth * 0.86,
            constraints: BoxConstraints(maxHeight: sizes.screenHeight * 0.75),
            padding: EdgeInsets.all(sizes.screenWidth * 0.055),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: _isLoading
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.06),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : _state == null
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.03),
                        child: Text('no_profile_data_error'.tr(), textAlign: TextAlign.center),
                      )
                    : SingleChildScrollView(child: _buildContent(sizes)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppSizes sizes) {
    final state = _state!;
    if (state.serviceDone == null) return _serviceStep(sizes, state);
    if (state.checkoutDone == null) return _checkoutStep(sizes, state);
    if (state.paymentDone == null) return _paymentStep(sizes, state);
    if (state.satisfied == null) return _satisfactionStep(sizes, state);

    // 🔵 el 4 étapes el kol déjà mjawba - ma lezmou-ch ywalli l'houni
    // 7a9i9atan (el pending-list ma tel9ihech), lakin filet de sécurité.
    return const SizedBox.shrink();
  }

  // ==========================================================================
  Widget _questionHeader(AppSizes sizes, String titleText, {bool showLater = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(titleText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 1.05)),
        ),
        if (showLater)
          TextButton(
            onPressed: _closeLater,
            child: Text('later_label'.tr(), style: TextStyle(color: Colors.grey, fontSize: sizes.myProfileBodyFontSize * 0.75)),
          ),
      ],
    );
  }

  Widget _yesNoRow(AppSizes sizes, {required VoidCallback onYes, required VoidCallback onNo}) {
    return Row(
      children: [
        Expanded(
          child: _pillButton(sizes, label: 'yes_label'.tr(), color: AppColors.vertpetsy, onTap: _isSubmitting ? null : onYes),
        ),
        SizedBox(width: sizes.screenWidth * 0.03),
        Expanded(
          child: _pillButton(sizes, label: 'no_label'.tr(), color: AppColors.pinkpetsy, onTap: _isSubmitting ? null : onNo),
        ),
      ],
    );
  }

  Widget _pillButton(AppSizes sizes, {required String label, required Color color, required VoidCallback? onTap}) {
    return SizedBox(
      height: sizes.screenHeight * 0.055,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0),
        onPressed: onTap,
        child: _isSubmitting
            ? SizedBox(width: sizes.screenWidth * 0.04, height: sizes.screenWidth * 0.04, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.85)),
      ),
    );
  }

  Widget _reasonField(AppSizes sizes, TextEditingController controller, {required String hintKey}) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hintKey.tr(),
        filled: true,
        fillColor: AppColors.pinkpetsy.withOpacity(0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.all(sizes.screenWidth * 0.03),
      ),
    );
  }

  // ==========================================================================
  // Étape 1: service done?
  // ==========================================================================
  Widget _serviceStep(AppSizes sizes, QuestionnaireState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionHeader(sizes, 'questionnaire_service_done_question'.tr(namedArgs: {'name': state.revieweeName})),
        SizedBox(height: sizes.myProfileSectionGap),
        if (!_showServiceReason)
          _yesNoRow(sizes, onYes: () => _onServiceAnswer(true), onNo: () => _onServiceAnswer(false))
        else ...[
          Text('questionnaire_why_not_label'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85)),
          SizedBox(height: sizes.screenHeight * 0.01),
          _reasonField(sizes, _serviceReasonController, hintKey: 'questionnaire_reason_hint'),
          SizedBox(height: sizes.screenHeight * 0.016),
          _pillButton(sizes, label: 'submit_button'.tr(), color: AppColors.pinkpetsy, onTap: _isSubmitting ? null : _onServiceReasonSubmit),
        ],
      ],
    );
  }

  // ==========================================================================
  // Étape 2: checkout done?
  // ==========================================================================
  Widget _checkoutStep(AppSizes sizes, QuestionnaireState state) {
    final String myLabel = 'me_label'.tr();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionHeader(sizes, 'questionnaire_checkout_done_question'.tr()),
        SizedBox(height: sizes.myProfileSectionGap),
        if (!_showCheckoutDelay)
          _yesNoRow(sizes, onYes: () => _onCheckoutAnswer(true), onNo: () => _onCheckoutAnswer(false))
        else ...[
          Text('questionnaire_who_delayed_label'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85, fontWeight: FontWeight.w600)),
          SizedBox(height: sizes.screenHeight * 0.006),
          _radioRow(sizes, label: myLabel, value: state.respondentRole, groupValue: _blamedParty, onChanged: (v) => setState(() => _blamedParty = v)),
          _radioRow(sizes, label: state.revieweeName, value: state.respondentRole == 'owner' ? 'sitter' : 'owner', groupValue: _blamedParty, onChanged: (v) => setState(() => _blamedParty = v)),
          SizedBox(height: sizes.screenHeight * 0.016),
          Text('questionnaire_new_checkout_time_label'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85, fontWeight: FontWeight.w600)),
          SizedBox(height: sizes.screenHeight * 0.008),
          InkWell(
            onTap: _pickNewCheckoutTime,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.014, horizontal: sizes.screenWidth * 0.03),
              decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.event, color: AppColors.pinkpetsy, size: sizes.myProfileBodyFontSize),
                  SizedBox(width: sizes.screenWidth * 0.02),
                  Text(
                    _newCheckoutTime != null
                        ? '${_newCheckoutTime!.day}/${_newCheckoutTime!.month}/${_newCheckoutTime!.year} - ${_newCheckoutTime!.hour.toString().padLeft(2, '0')}:${_newCheckoutTime!.minute.toString().padLeft(2, '0')}'
                        : 'select_label'.tr(),
                    style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sizes.screenHeight * 0.016),
          _pillButton(
            sizes,
            label: 'submit_button'.tr(),
            color: AppColors.pinkpetsy,
            onTap: (_isSubmitting || _blamedParty == null || _newCheckoutTime == null) ? null : _onCheckoutDelaySubmit,
          ),
        ],
      ],
    );
  }

  Widget _radioRow(AppSizes sizes, {required String label, required String value, required String? groupValue, required ValueChanged<String?> onChanged}) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.006),
        child: Row(
          children: [
            Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged, activeColor: AppColors.pinkpetsy),
            Text(label, style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Étape 3: payment done?
  // ==========================================================================
  Widget _paymentStep(AppSizes sizes, QuestionnaireState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionHeader(sizes, 'questionnaire_payment_done_question'.tr()),
        SizedBox(height: sizes.myProfileSectionGap),
        if (!_showPaymentReason)
          _yesNoRow(sizes, onYes: () => _onPaymentAnswer(true), onNo: () => _onPaymentAnswer(false))
        else ...[
          Text('questionnaire_why_not_label'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85)),
          SizedBox(height: sizes.screenHeight * 0.01),
          _reasonField(sizes, _paymentReasonController, hintKey: 'questionnaire_reason_hint'),
          SizedBox(height: sizes.screenHeight * 0.016),
          _pillButton(sizes, label: 'continue_button'.tr(), color: AppColors.pinkpetsy, onTap: _isSubmitting ? null : _onPaymentReasonSubmit),
        ],
      ],
    );
  }

  // ==========================================================================
  // Étape 4: "est-ce que satisfait?" -> "a7kilna 3la l'expérience"
  // (review, text) -> RATING (Trust/Service/Communication/Knowledge)
  // - kifma tlab, hedha el ordre el 7a9i9i.
  // ==========================================================================
  Widget _satisfactionStep(AppSizes sizes, QuestionnaireState state) {
    const List<({String key, String labelKey})> categories = [
      (key: 'trust', labelKey: 'rating_trust_label'),
      (key: 'service', labelKey: 'rating_service_label'),
      (key: 'communication', labelKey: 'rating_communication_label'),
      (key: 'knowledge', labelKey: 'rating_knowledge_label'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -------- 1) Satisfied? --------
        _questionHeader(sizes, 'questionnaire_satisfied_question'.tr(namedArgs: {'name': state.revieweeName}), showLater: false),
        SizedBox(height: sizes.myProfileSectionGap),
        Row(
          children: [
            Expanded(
              child: _pillButton(
                sizes,
                label: 'yes_label'.tr(),
                color: _satisfiedChoice == true ? AppColors.vertpetsy : AppColors.vertpetsy.withOpacity(0.3),
                onTap: () => setState(() => _satisfiedChoice = true),
              ),
            ),
            SizedBox(width: sizes.screenWidth * 0.03),
            Expanded(
              child: _pillButton(
                sizes,
                label: 'no_label'.tr(),
                color: _satisfiedChoice == false ? AppColors.pinkpetsy : AppColors.pinkpetsy.withOpacity(0.3),
                onTap: () => setState(() => _satisfiedChoice = false),
              ),
            ),
          ],
        ),

        // -------- 2) Review (avis mektoub) --------
        SizedBox(height: sizes.screenHeight * 0.02),
        Text('questionnaire_review_label'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85, fontWeight: FontWeight.w600)),
        SizedBox(height: sizes.screenHeight * 0.008),
        _reasonField(sizes, _reviewController, hintKey: 'questionnaire_review_hint'),

        // -------- 3) Rating (4 catégories, njoum) --------
        SizedBox(height: sizes.screenHeight * 0.02),
        for (final cat in categories) ...[
          _ratingRow(sizes, labelKey: cat.labelKey, value: _ratings[cat.key]!, onChanged: (v) => setState(() => _ratings[cat.key] = v)),
          SizedBox(height: sizes.screenHeight * 0.012),
        ],

        SizedBox(height: sizes.screenHeight * 0.008),
        _pillButton(
          sizes,
          label: 'submit_button'.tr(),
          color: AppColors.pinkpetsy,
          onTap: (_isSubmitting || _satisfiedChoice == null || _ratings.values.any((v) => v == 0)) ? null : _onSatisfactionSubmit,
        ),
      ],
    );
  }

  // 🔵 ZID: sef "pill" rose (kifha kif el mockup) - esm el catégorie
  // (chip abyadh) + 5 njoum (tappable, kol nejma tzid/tenna9as el 9ima).
  Widget _ratingRow(AppSizes sizes, {required String labelKey, required int value, required ValueChanged<int> onChanged}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.012),
      decoration: BoxDecoration(color: AppColors.pinkpetsy, borderRadius: BorderRadius.circular(25)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.006),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text(labelKey.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.78)),
          ),
          Row(
            children: [
              for (int star = 1; star <= 5; star++)
                InkWell(
                  onTap: () => onChanged(star),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.006),
                    child: Icon(
                      star <= value ? Icons.star : Icons.star_border,
                      color: Colors.white,
                      size: sizes.myProfileBodyFontSize * 1.05,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
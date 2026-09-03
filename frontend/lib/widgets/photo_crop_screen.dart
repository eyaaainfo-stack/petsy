import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import 'message_dialog.dart';

// ============================================================================
// PhotoCropScreen
// ============================================================================
// 🔵 ZID (kifma tlab): "kima el insta" - ba3d ma el user ye5tar photo
// (image_picker), had écran ywarriha KBIRA, ynajjam "yeddi" (drag/pan)
// w y-zoumi (pinch) bch ye5tar chnou el jozz elli yban fel avatar
// dayra. "Done" yeltaget EXACTEMENT chnou elli yban fel dayra (bytes
// jdad), "Cancel" yerja3 null (el caller yzid yesta3mel el photo el
// 9dima/l'a5ira).
//
// 🔵 Pure Flutter (InteractiveViewer + RepaintBoundary.toImage) - BLA
// package l5arja (image_cropper w chbihou ma ye5demch mlih fel web) -
// ye5dem fel mobile W el web (el app tejri fel Chrome fel testing).
// ============================================================================
class PhotoCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  // 🔵 ZID: true (défaut) = dayra (kifha kif el avatar tel user, CircleAvatar
  // fel app) - false = mrabba3 be zwaya modawra (kifha kif el pets,
  // BorderRadius.circular fel pet_tile.dart/pet_profile.dart - MECH
  // dayra houniki).
  final bool circularMask;

  const PhotoCropScreen({super.key, required this.imageBytes, this.circularMask = true});

  // 🔵 terja3 el bytes el jdad (déjà "cropped") wla null (Cancel).
  static Future<Uint8List?> show(BuildContext context, Uint8List imageBytes, {bool circularMask = true}) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => PhotoCropScreen(imageBytes: imageBytes, circularMask: circularMask), fullscreenDialog: true),
    );
  }

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final TransformationController _transformController = TransformationController();

  bool _isReady = false;
  bool _isSaving = false;
  double _imgWidth = 0;
  double _imgHeight = 0;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _imgWidth = frame.image.width.toDouble();
      _imgHeight = frame.image.height.toDouble();
      _isReady = true;
    });
  }

  // 🔵 el "base scale" - el 9adr elli lezem el image tetkabbar bih bch
  // el jeneb el a9ser mennha ykhabbi el dayra kaملha (kifha kif BoxFit.
  // cover) - hedha "zoom 1x" (el a9all zoom mte5alli, minScale).
  double _baseScale(double cropSize) => cropSize / (_imgWidth < _imgHeight ? _imgWidth : _imgHeight);

  Future<void> _onDone() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      if (!mounted) return;
      Navigator.of(context).pop(bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showMessageDialog(context, 'photo_pick_error'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cropSize = screenWidth * 0.8;
    final double baseScale = _isReady ? _baseScale(cropSize) : 1;
    final double displayW = _imgWidth * baseScale;
    final double displayH = _imgHeight * baseScale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel_button'.tr(), style: const TextStyle(color: Colors.white)),
                  ),
                  Text('move_and_scale_label'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: (_isReady && !_isSaving) ? _onDone : null,
                    child: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('done_button'.tr(), style: TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: !_isReady
                    ? const CircularProgressIndicator(color: Colors.white)
                    : SizedBox(
                        width: cropSize,
                        height: cropSize,
                        child: Stack(
                          children: [
                            RepaintBoundary(
                              key: _repaintKey,
                              child: ClipRect(
                                child: InteractiveViewer(
                                  transformationController: _transformController,
                                  constrained: false,
                                  // 🔵 minScale=1 (baseScale déjà "cover", ma
                                  // yenajjamch yzoumi le5arej mennha - bch
                                  // ma yban-ch fragh transparent fel zwaya).
                                  minScale: 1,
                                  maxScale: 4,
                                  boundaryMargin: const EdgeInsets.all(400),
                                  child: SizedBox(
                                    width: displayW,
                                    height: displayH,
                                    child: Image.memory(widget.imageBytes, fit: BoxFit.fill),
                                  ),
                                ),
                              ),
                            ),
                            IgnorePointer(
                              child: CustomPaint(size: Size(cropSize, cropSize), painter: _CropMaskPainter(circular: widget.circularMask)),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.03),
              child: Text('drag_to_reposition_label'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _CircleMaskPainter - ye3tem el kol 5arej el dayra el west (guide
// visuel bark, MA yed5elch fel RepaintBoundary - foug el image mch
// jouwaha).
// ============================================================================
// ============================================================================
// _CropMaskPainter - ye3tem el kol 5arej el chekel (dayra WALA mrabba3
// bzwaya modawra) - guide visuel bark (MA yed5elch fel RepaintBoundary -
// foug el image mch jouwaha).
// ============================================================================
class _CropMaskPainter extends CustomPainter {
  final bool circular;

  const _CropMaskPainter({required this.circular});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect roundedRect = RRect.fromRectAndRadius(bounds, const Radius.circular(24));

    final Path outer = Path()..addRect(bounds);
    final Path shape = circular ? (Path()..addOval(Rect.fromCircle(center: bounds.center, radius: size.width / 2))) : (Path()..addRRect(roundedRect));
    final Path mask = Path.combine(PathOperation.difference, outer, shape);

    canvas.drawPath(mask, Paint()..color = Colors.black.withOpacity(0.55));

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (circular) {
      canvas.drawCircle(bounds.center, size.width / 2, borderPaint);
    } else {
      canvas.drawRRect(roundedRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropMaskPainter oldDelegate) => oldDelegate.circular != circular;
}
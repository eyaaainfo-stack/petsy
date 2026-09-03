import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

// ============================================================================
// LineChartSeries: 7ijja/série wa7da fel graphique (esm + loun + valeurs)
// ============================================================================
class LineChartSeries {
  final String label;
  final Color color;
  final List<double> values;

  const LineChartSeries({required this.label, required this.color, required this.values});
}

// ============================================================================
// LineChartWidget
// ============================================================================
// 🔵 ZID: "Graphique linéaire (Line Chart) standard" (kifma tlab) - béni
// mel A-Z b'CustomPainter (bla package 5arej/fl_chart) bch ma nel7a9ouch
// b flutter pub get + risque compatibilité, w bch tab9a khfifa/behya.
//
// xLabels: label ta7t kol point ("08/26", "09/26"...) - lezmha ykoun
// nefs tarti9/3adad el valeurs fel series el kol.
//
// 🔴 FIX (rappel: "ma staamlech el AppSizes eli fi constants") - kanet
// el sizes el kol (height, fonts, paddings, épaisseur lignes...) mel
// MediaQuery direct - tawa AppSizes.of(context) (sizes.lineChartXxx),
// nafs mant9 el app el kol. el CustomPainter (barra el widget tree,
// ma3andouch BuildContext) yakhod el valeurs déjà m7soubin (pixels)
// mel build() - mch magic numbers dakhlou.
// ============================================================================
class LineChartWidget extends StatelessWidget {
  final List<String> xLabels;
  final List<LineChartSeries> series;
  // 🔵 optionnel - ken el caller ma yb3athech height, nesta3mlou
  // sizes.lineChartHeight (proportionnelle, mch fixe) b'default.
  final double? height;

  const LineChartWidget({
    super.key,
    required this.xLabels,
    required this.series,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color gridColor = (isDark ? Colors.white : Colors.black).withOpacity(0.08);
    final Color labelColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.55) ?? Colors.grey;

    final double resolvedHeight = height ?? sizes.lineChartHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: resolvedHeight,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              xLabels: xLabels,
              series: series,
              gridColor: gridColor,
              labelColor: labelColor,
              axisFontSize: sizes.lineChartAxisFontSize,
              leftPad: sizes.lineChartLeftPad,
              bottomPad: sizes.lineChartBottomPad,
              topPad: sizes.lineChartTopPad,
              rightPad: sizes.lineChartRightPad,
              axisLabelGap: sizes.lineChartAxisLabelGap,
              strokeWidth: sizes.lineChartStrokeWidth,
              dotRadius: sizes.lineChartDotRadius,
            ),
          ),
        ),
        SizedBox(height: sizes.lineChartLegendGap),
        // ----------------------------------------------------------
        // Légende: point loun + esm el série (users/owners/sitters/
        // couriers) - bch el user yefreq beynethom.
        // ----------------------------------------------------------
        Wrap(
          spacing: sizes.lineChartLegendSpacing,
          runSpacing: sizes.lineChartLegendRunSpacing,
          children: series
              .map(
                (s) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: sizes.lineChartLegendDotSize, height: sizes.lineChartLegendDotSize, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    SizedBox(width: sizes.lineChartLegendDotTextGap),
                    Text(s.label, style: TextStyle(fontSize: sizes.lineChartLegendFontSize, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<String> xLabels;
  final List<LineChartSeries> series;
  final Color gridColor;
  final Color labelColor;
  final double axisFontSize;
  final double leftPad;
  final double bottomPad;
  final double topPad;
  final double rightPad;
  final double axisLabelGap;
  final double strokeWidth;
  final double dotRadius;

  _LineChartPainter({
    required this.xLabels,
    required this.series,
    required this.gridColor,
    required this.labelColor,
    required this.axisFontSize,
    required this.leftPad,
    required this.bottomPad,
    required this.topPad,
    required this.rightPad,
    required this.axisLabelGap,
    required this.strokeWidth,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double chartWidth = size.width - leftPad - rightPad;
    final double chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    // ------------------------------------------------------------
    // el max valeur (el 4 séries kol) - bch nna7iw "échelle" (axe Y)
    // ------------------------------------------------------------
    double maxValue = 0;
    for (final s in series) {
      for (final v in s.values) {
        if (v > maxValue) maxValue = v;
      }
    }
    final double niceMax = _niceCeil(maxValue <= 0 ? 1 : maxValue);

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final TextStyle labelStyle = TextStyle(color: labelColor, fontSize: axisFontSize);

    // ------------------------------------------------------------
    // 4 lignes horizontales (grid) + labels el axe Y (0, 25%, 50%...)
    // ------------------------------------------------------------
    const int steps = 4;
    for (int i = 0; i <= steps; i++) {
      final double y = topPad + chartHeight - (chartHeight * i / steps);
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + chartWidth, y), gridPaint);

      final double value = niceMax * i / steps;
      final TextPainter tp = TextPainter(
        text: TextSpan(text: _formatAxisValue(value), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - axisLabelGap, y - tp.height / 2));
    }

    // ------------------------------------------------------------
    // labels el axe X (echhour)
    // ------------------------------------------------------------
    final int n = xLabels.length;
    if (n > 0) {
      for (int i = 0; i < n; i++) {
        final double x = n == 1 ? leftPad + chartWidth / 2 : leftPad + chartWidth * i / (n - 1);
        final TextPainter tp = TextPainter(
          text: TextSpan(text: xLabels[i], style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, topPad + chartHeight + axisLabelGap));
      }
    }

    // ------------------------------------------------------------
    // el 4 lignes (séries) + points
    // ------------------------------------------------------------
    for (final s in series) {
      final int count = s.values.length;
      if (count == 0) continue;

      final Path path = Path();
      for (int i = 0; i < count; i++) {
        final double x = count == 1 ? leftPad + chartWidth / 2 : leftPad + chartWidth * i / (count - 1);
        final double y = topPad + chartHeight - (chartHeight * (s.values[i] / niceMax));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final Paint linePaint = Paint()
        ..color = s.color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);

      final Paint dotPaint = Paint()..color = s.color;
      for (int i = 0; i < count; i++) {
        final double x = count == 1 ? leftPad + chartWidth / 2 : leftPad + chartWidth * i / (count - 1);
        final double y = topPad + chartHeight - (chartHeight * (s.values[i] / niceMax));
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
  }

  // 🔵 "échelle jmila" (0, 5, 10, 20, 50, 100, mba3d mضاعفات 50) - bch
  // el labels el axe Y ykounou ar9am ronds, mch 3.7 / 8.9...
  double _niceCeil(double value) {
    if (value <= 5) return 5;
    if (value <= 10) return 10;
    if (value <= 20) return 20;
    if (value <= 50) return 50;
    if (value <= 100) return 100;
    return (value / 50).ceil() * 50;
  }

  String _formatAxisValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.xLabels != xLabels ||
        oldDelegate.leftPad != leftPad;
  }
}
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Decodes a `data:image/...;base64,...` URI into raw bytes if valid.
Uint8List? tryDecodeAvatarDataUri(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final trimmed = raw.trim();
  if (!trimmed.startsWith('data:image/')) return null;
  final comma = trimmed.indexOf(',');
  if (comma <= 0 || comma + 1 >= trimmed.length) return null;
  try {
    return base64Decode(trimmed.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

/// Interactive circular avatar crop & edit modal working identically on Android and Web.
Future<String?> showFinoraAvatarCropSheet({
  required BuildContext context,
  required Uint8List imageBytes,
  required String roleLabel,
  required Color accentColor,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AvatarCropDialogSheet(
      imageBytes: imageBytes,
      roleLabel: roleLabel,
      accentColor: accentColor,
    ),
  );
}

class _AvatarCropDialogSheet extends StatefulWidget {
  final Uint8List imageBytes;
  final String roleLabel;
  final Color accentColor;

  const _AvatarCropDialogSheet({
    required this.imageBytes,
    required this.roleLabel,
    required this.accentColor,
  });

  @override
  State<_AvatarCropDialogSheet> createState() => _AvatarCropDialogSheetState();
}

class _AvatarCropDialogSheetState extends State<_AvatarCropDialogSheet> {
  static const double _stageSize = 272;
  static const double _circleRatio = 0.88;
  static const int _exportSize = 280;

  ui.Image? _decoded;
  String? _loadError;
  bool _saving = false;

  double _zoom = 1.0;
  double _zoomStart = 1.0;
  Offset _pan = Offset.zero;
  int _quarterTurns = 0; // 0..3
  bool _flipX = false;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _decoded = frame.image);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Không đọc được định dạng ảnh này.');
    }
  }

  @override
  void dispose() {
    _decoded?.dispose();
    super.dispose();
  }

  Offset _clampPan(Offset raw) {
    final maxPan = _stageSize * 0.70 * _zoom;
    return Offset(
      raw.dx.clamp(-maxPan, maxPan),
      raw.dy.clamp(-maxPan, maxPan),
    );
  }

  Future<void> _exportAndReturn() async {
    final image = _decoded;
    if (image == null || _saving) return;
    setState(() => _saving = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, _exportSize * 1.0, _exportSize * 1.0),
      );
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, _exportSize * 1.0, _exportSize * 1.0),
        Paint()..color = Colors.white,
      );

      final rotatedOdd = _quarterTurns.isOdd;
      final effW = rotatedOdd ? image.height.toDouble() : image.width.toDouble();
      final effH = rotatedOdd ? image.width.toDouble() : image.height.toDouble();
      final apertureDiameter = _stageSize * _circleRatio;
      final coverScale = math.max(apertureDiameter / effW, apertureDiameter / effH);
      final totalScale = (_exportSize / apertureDiameter) * coverScale * _zoom;
      final offsetRatio = _exportSize / apertureDiameter;

      canvas.save();
      canvas.translate(
        _exportSize / 2 + _pan.dx * offsetRatio,
        _exportSize / 2 + _pan.dy * offsetRatio,
      );
      canvas.rotate(_quarterTurns * (math.pi / 2));
      canvas.scale((_flipX ? -1.0 : 1.0) * totalScale, totalScale);

      final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: image.width.toDouble(),
        height: image.height.toDouble(),
      );
      canvas.drawImageRect(
        image,
        src,
        dst,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();

      final picture = recorder.endRecording();
      final rendered = await picture.toImage(_exportSize, _exportSize);
      final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      picture.dispose();
      if (byteData == null) throw StateError('Không xuất được ảnh.');

      final pngBytes = byteData.buffer.asUint8List();
      final dataUri = 'data:image/png;base64,${base64Encode(pngBytes)}';
      if (!mounted) return;
      Navigator.of(context).pop(dataUri);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _loadError = 'Không thể lưu ảnh đã cắt. Vui lòng thử ảnh khác.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderCol =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final pillBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderCol, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cắt & chỉnh sửa ảnh (${widget.roleLabel})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kéo ảnh để căn giữa, phóng to hoặc xoay cho vừa khung tròn.',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent && _decoded != null) {
                  setState(() {
                    _zoom = (_zoom - event.scrollDelta.dy * 0.0015).clamp(1.0, 4.0);
                    _pan = _clampPan(_pan);
                  });
                }
              },
              child: GestureDetector(
                onScaleStart: (_) => _zoomStart = _zoom,
                onScaleUpdate: (details) {
                  if (_decoded == null) return;
                  setState(() {
                    if (details.scale != 1.0) {
                      _zoom = (_zoomStart * details.scale).clamp(1.0, 4.0);
                    }
                    _pan = _clampPan(_pan + details.focalPointDelta);
                  });
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: _stageSize,
                    height: _stageSize,
                    child: _decoded != null
                        ? CustomPaint(
                            painter: _AvatarCropStagePainter(
                              image: _decoded!,
                              zoom: _zoom,
                              pan: _pan,
                              quarterTurns: _quarterTurns,
                              flipX: _flipX,
                              circleRatio: _circleRatio,
                            ),
                          )
                        : Container(
                            color: const Color(0xFF0F172A),
                            alignment: Alignment.center,
                            child: _loadError != null
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      _loadError!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFFDA4AF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : const CircularProgressIndicator(),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton(
                  onPressed: _decoded == null
                      ? null
                      : () => setState(() {
                            _zoom = (_zoom - 0.2).clamp(1.0, 4.0);
                            _pan = _clampPan(_pan);
                          }),
                  icon: Icon(Icons.zoom_out_rounded, color: muted),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: widget.accentColor,
                      thumbColor: widget.accentColor,
                      inactiveTrackColor: borderCol,
                    ),
                    child: Slider(
                      min: 1.0,
                      max: 4.0,
                      value: _zoom,
                      onChanged: _decoded == null
                          ? null
                          : (val) => setState(() {
                                _zoom = val;
                                _pan = _clampPan(_pan);
                              }),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _decoded == null
                      ? null
                      : () => setState(() {
                            _zoom = (_zoom + 0.2).clamp(1.0, 4.0);
                            _pan = _clampPan(_pan);
                          }),
                  icon: Icon(Icons.zoom_in_rounded, color: muted),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _ToolPill(
                  icon: Icons.rotate_right_rounded,
                  label: 'Xoay 90°',
                  bg: pillBg,
                  fg: isDark ? Colors.white : const Color(0xFF0F172A),
                  border: borderCol,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _quarterTurns = (_quarterTurns + 1) % 4);
                  },
                ),
                _ToolPill(
                  icon: Icons.flip_rounded,
                  label: 'Lật ngang',
                  bg: pillBg,
                  fg: isDark ? Colors.white : const Color(0xFF0F172A),
                  border: borderCol,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _flipX = !_flipX);
                  },
                ),
                _ToolPill(
                  icon: Icons.refresh_rounded,
                  label: 'Đặt lại',
                  bg: pillBg,
                  fg: muted,
                  border: borderCol,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _zoom = 1.0;
                      _pan = Offset.zero;
                      _quarterTurns = 0;
                      _flipX = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: borderCol),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Huỷ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: muted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        (_decoded == null || _saving) ? null : _exportAndReturn,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _saving ? 'Đang xử lý...' : 'Lưu ảnh đã cắt',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  final VoidCallback onTap;

  const _ToolPill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 0.9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarCropStagePainter extends CustomPainter {
  final ui.Image image;
  final double zoom;
  final Offset pan;
  final int quarterTurns;
  final bool flipX;
  final double circleRatio;

  const _AvatarCropStagePainter({
    required this.image,
    required this.zoom,
    required this.pan,
    required this.quarterTurns,
    required this.flipX,
    required this.circleRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0F172A),
    );

    final aperture = size.width * circleRatio;
    final rotatedOdd = quarterTurns.isOdd;
    final effW = rotatedOdd ? image.height.toDouble() : image.width.toDouble();
    final effH = rotatedOdd ? image.width.toDouble() : image.height.toDouble();
    final coverScale = math.max(aperture / effW, aperture / effH);
    final totalScale = coverScale * zoom;

    canvas.save();
    canvas.translate(size.width / 2 + pan.dx, size.height / 2 + pan.dy);
    canvas.rotate(quarterTurns * (math.pi / 2));
    canvas.scale((flipX ? -1.0 : 1.0) * totalScale, totalScale);

    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: image.width.toDouble(),
      height: image.height.toDouble(),
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();

    final radius = aperture / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final scrim = Path()
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      scrim,
      Paint()..color = const Color(0xFF020617).withValues(alpha: 0.58),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarCropStagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.zoom != zoom ||
        oldDelegate.pan != pan ||
        oldDelegate.quarterTurns != quarterTurns ||
        oldDelegate.flipX != flipX ||
        oldDelegate.circleRatio != circleRatio;
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../utils/app_notification.dart';
import 'blueprint_grid_painter.dart';
import 'cloud_network_image.dart';

/// Full-screen viewer for every file and photo in the app with granular zoom
/// (pinch, double-tap, +/- buttons, and continuous zoom slider up to 800%),
/// native PDF page rendering via [Printing.raster], image rendering, and
/// "Open in Gallery" / external app launch support.
class FullScreenMediaViewer extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? filePath;
  final String? fileUrl;
  final String? base64Data;
  final String? fileName;
  final String? format;
  final IconData fallbackIcon;
  final Color accentColor;

  const FullScreenMediaViewer({
    super.key,
    required this.title,
    this.subtitle,
    this.filePath,
    this.fileUrl,
    this.base64Data,
    this.fileName,
    this.format,
    this.fallbackIcon = Icons.insert_drive_file_rounded,
    this.accentColor = AppColors.brandPeach,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? filePath,
    String? fileUrl,
    String? base64Data,
    String? fileName,
    String? format,
    IconData fallbackIcon = Icons.insert_drive_file_rounded,
    Color accentColor = AppColors.brandPeach,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullScreenMediaViewer(
          title: title,
          subtitle: subtitle,
          filePath: filePath,
          fileUrl: fileUrl,
          base64Data: base64Data,
          fileName: fileName,
          format: format,
          fallbackIcon: fallbackIcon,
          accentColor: accentColor,
        ),
      ),
    );
  }

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  static const double _minScale = 1.0;
  static const double _maxScale = 8.0;

  final TransformationController _transformController =
      TransformationController();
  bool _showControls = true;
  Uint8List? _decodedBase64Bytes;

  bool _isLoadingPdf = false;
  String? _pdfError;
  List<Uint8List> _pdfPageImages = [];

  bool get _hasLocalFile =>
      widget.filePath != null &&
      widget.filePath!.isNotEmpty &&
      !widget.filePath!.startsWith('http') &&
      !kIsWeb &&
      File(widget.filePath!).existsSync();

  bool get _hasRemoteUrl =>
      widget.fileUrl != null && widget.fileUrl!.trim().isNotEmpty;

  bool get _hasBase64 =>
      widget.base64Data != null && widget.base64Data!.trim().isNotEmpty;

  String get _extension {
    final candidates = [
      widget.format ?? '',
      widget.fileName ?? '',
      widget.filePath ?? '',
      widget.fileUrl ?? '',
    ];
    for (final raw in candidates) {
      final clean = raw.split('?').first.trim().toLowerCase();
      if (clean.startsWith('.') && clean.length <= 6) {
        return clean.substring(1);
      }
      final dot = clean.lastIndexOf('.');
      if (dot != -1 && dot < clean.length - 1) {
        final ext = clean.substring(dot + 1);
        if (ext.length <= 6) return ext;
      }
    }
    return '';
  }

  bool get _isPdf => _extension == 'pdf';

  bool get _isImage {
    const imgExts = {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'heic'};
    if (imgExts.contains(_extension)) return true;
    if (_isPdf) return false;
    // If no non-image extension was specified and we have image data/fallback photo icon
    if (_extension.isEmpty &&
        (_hasLocalFile || _hasRemoteUrl || _hasBase64)) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _decodeBase64IfNeeded();
    if (_isPdf) {
      _loadAndRasterizePdf();
    }
  }

  @override
  void didUpdateWidget(covariant FullScreenMediaViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64Data != widget.base64Data) {
      _decodeBase64IfNeeded();
    }
  }

  void _decodeBase64IfNeeded() {
    if (_hasBase64) {
      try {
        _decodedBase64Bytes = base64Decode(widget.base64Data!);
      } catch (_) {
        _decodedBase64Bytes = null;
      }
    } else {
      _decodedBase64Bytes = null;
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  double _scaleFromMatrix(Matrix4 matrix) {
    return matrix.getMaxScaleOnAxis().clamp(_minScale, _maxScale);
  }

  void _setZoomScale(double targetScale) {
    final clamped = targetScale.clamp(_minScale, _maxScale);
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final matrix = Matrix4.identity()
      ..translateByDouble(cx, cy, 0.0, 1.0)
      ..scaleByDouble(clamped, clamped, 1.0, 1.0)
      ..translateByDouble(-cx, -cy, 0.0, 1.0);
    _transformController.value = matrix;
  }

  void _handleDoubleTap() {
    final current = _scaleFromMatrix(_transformController.value);
    if (current > 1.2) {
      _transformController.value = Matrix4.identity();
    } else {
      _setZoomScale(2.5);
    }
  }

  Future<void> _loadAndRasterizePdf() async {
    setState(() {
      _isLoadingPdf = true;
      _pdfError = null;
    });
    try {
      Uint8List? pdfBytes;
      if (_hasLocalFile) {
        pdfBytes = await File(widget.filePath!).readAsBytes();
      } else if (_hasBase64) {
        pdfBytes = base64Decode(widget.base64Data!);
      } else if (_hasRemoteUrl && !kIsWeb) {
        final client = HttpClient();
        try {
          final req = await client.getUrl(Uri.parse(widget.fileUrl!));
          final resp = await req.close();
          if (resp.statusCode == 200) {
            final builder = BytesBuilder();
            await for (final chunk in resp) {
              builder.add(chunk);
            }
            pdfBytes = builder.takeBytes();
          }
        } finally {
          client.close();
        }
      }

      if (pdfBytes == null || pdfBytes.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingPdf = false;
            _pdfError = 'PDF file bytes not available locally.';
          });
        }
        return;
      }

      final pages = <Uint8List>[];
      await for (final page in Printing.raster(pdfBytes, dpi: 150)) {
        pages.add(await page.toPng());
      }
      if (mounted) {
        setState(() {
          _pdfPageImages = pages;
          _isLoadingPdf = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPdf = false;
          _pdfError = 'Could not render PDF pages: $e';
        });
      }
    }
  }

  Future<void> _openInGalleryOrExternal() async {
    try {
      if (_hasLocalFile) {
        final uri = Uri.file(widget.filePath!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      if (_hasRemoteUrl) {
        final uri = Uri.parse(widget.fileUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      if (mounted) {
        AppNotification.show(
          context,
          message: 'No external gallery or app handler available for this file.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          message: 'Could not open externally: $e',
        );
      }
    }
  }

  Widget _buildMediaContent(BuildContext context) {
    if (_isPdf) {
      if (_isLoadingPdf) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.brandPeach),
              SizedBox(height: 12),
              Text(
                'Rendering PDF...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      }
      if (_pdfPageImages.isNotEmpty) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 72),
          itemCount: _pdfPageImages.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, idx) => Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Image.memory(
                _pdfPageImages[idx],
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      }
      return _buildNonImageFallback(
        subtitleOverride: _pdfError ?? 'PDF document preview',
      );
    }

    if (_isImage) {
      if (_hasLocalFile) {
        return Center(
          child: Image.file(
            File(widget.filePath!),
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        );
      }
      if (_decodedBase64Bytes != null) {
        return Center(
          child: Image.memory(
            _decodedBase64Bytes!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        );
      }
      if (_hasRemoteUrl) {
        return Center(
          child: CloudNetworkImage(
            url: widget.fileUrl!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _buildNonImageFallback(),
          ),
        );
      }
    }

    return _buildNonImageFallback();
  }

  Widget _buildNonImageFallback({String? subtitleOverride}) {
    final extLabel = _extension.isNotEmpty
        ? '.${_extension.toUpperCase()}'
        : (widget.format ?? 'FILE');
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: widget.accentColor.withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BlueprintGridPainter(
                  step: 22.0,
                  gridColor: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.fallbackIcon,
                    size: 46,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.fileName ?? widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitleOverride ??
                      '$extLabel • Pinch or use slider to zoom',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                key: const Key('fullscreen_interactive_viewer'),
                transformationController: _transformController,
                clipBehavior: Clip.none,
                minScale: _minScale,
                maxScale: _maxScale,
                panEnabled: true,
                scaleEnabled: true,
                child: SizedBox.expand(child: _buildMediaContent(context)),
              ),
            ),
          ),

          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  12,
                  MediaQuery.of(context).padding.top + 8,
                  12,
                  12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('fullscreen_close_btn'),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      tooltip: 'Close Full Screen',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.subtitle != null &&
                              widget.subtitle!.isNotEmpty)
                            Text(
                              widget.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<Matrix4>(
                      valueListenable: _transformController,
                      builder: (_, matrix, _) {
                        final zoomPct = (_scaleFromMatrix(matrix) * 100)
                            .round();
                        return Container(
                          key: const Key('fullscreen_zoom_badge'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            '$zoomPct%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  14,
                  12,
                  14,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.88),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<Matrix4>(
                      valueListenable: _transformController,
                      builder: (_, matrix, _) {
                        final currentScale = _scaleFromMatrix(matrix);
                        return Row(
                          children: [
                            IconButton(
                              key: const Key('fullscreen_zoom_out_btn'),
                              icon: const Icon(
                                Icons.zoom_out_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _setZoomScale(currentScale - 0.5),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppColors.brandPeach,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: AppColors.brandPeach,
                                  trackHeight: 2.5,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                  ),
                                ),
                                child: Slider(
                                  key: const Key('fullscreen_zoom_slider'),
                                  min: _minScale,
                                  max: _maxScale,
                                  value: currentScale.clamp(
                                    _minScale,
                                    _maxScale,
                                  ),
                                  onChanged: _setZoomScale,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const Key('fullscreen_zoom_in_btn'),
                              icon: const Icon(
                                Icons.zoom_in_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _setZoomScale(currentScale + 0.5),
                            ),
                            TextButton(
                              key: const Key('fullscreen_zoom_reset_btn'),
                              onPressed: () {
                                _transformController.value =
                                    Matrix4.identity();
                              },
                              child: const Text(
                                '1x',
                                style: TextStyle(
                                  color: AppColors.brandPeach,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (_hasLocalFile || _hasRemoteUrl) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('fullscreen_open_gallery_btn'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                          ),
                          icon: Icon(
                            _isImage
                                ? Icons.photo_library_rounded
                                : Icons.open_in_new_rounded,
                            size: 16,
                            color: AppColors.brandPeach,
                          ),
                          label: Text(
                            _isImage ? 'Open in Gallery' : 'Open Externally',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: _openInGalleryOrExternal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

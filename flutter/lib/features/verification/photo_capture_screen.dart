import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/status_chip.dart';

enum PhotoCaptureKind { id, selfie }

/// Which camera request a capture step should make.
///
/// Camera-only on purpose: the ID photo and the selfie are identity evidence,
/// so the app must never accept a gallery upload — a stored photo of a photo,
/// or of someone else, would defeat the check. The selfie uses the front
/// camera; the ID uses the rear one. On Android the camera intent requests the
/// CAMERA permission itself, since the manifest declares it (for the QR
/// scanner).
@visibleForTesting
({ImageSource source, CameraDevice device}) photoCaptureRequestFor(
  PhotoCaptureKind kind,
) =>
    (
      source: ImageSource.camera,
      device: kind == PhotoCaptureKind.id
          ? CameraDevice.rear
          : CameraDevice.front,
    );

/// ID-photo and selfie capture — same layout, different copy. Mock-only:
/// nothing here is verified or matched, it's a demo of what the real KYC
/// flow will look like. Photos aren't persisted past this session.
class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key, required this.kind, required this.onContinue});

  final PhotoCaptureKind kind;
  final VoidCallback onContinue;

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  Uint8List? _imageBytes;
  bool _picking = false;
  String? _error;

  bool get _isId => widget.kind == PhotoCaptureKind.id;
  String get _title => _isId ? Strings.idPhotoTitle : Strings.selfiePhotoTitle;
  String get _instructions =>
      _isId ? Strings.idPhotoInstructions : Strings.selfiePhotoInstructions;
  IconData get _icon => _isId ? Icons.badge_outlined : Icons.face_outlined;

  Future<void> _captureImage() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final request = photoCaptureRequestFor(widget.kind);
      final file = await ImagePicker().pickImage(
        source: request.source,
        preferredCameraDevice: request.device,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (_) {
      // Permission refused, no camera app, camera in use — all land here.
      if (mounted) setState(() => _error = Strings.captureError);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _instructions,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GestureDetector(
                  onTap: _picking ? null : _captureImage,
                  child: AspectRatio(
                    aspectRatio: _isId ? 16 / 10 : 3 / 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: AppShapes.large,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: AppShapes.large,
                              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _icon,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    Strings.capturePrompt,
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const Spacer(),
                if (_error != null) ...[
                  StatusChip(text: _error!, tone: StatusTone.danger),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (_imageBytes != null) ...[
                  SecondaryButton(text: Strings.retakePhoto, onPressed: _captureImage),
                  const SizedBox(height: AppSpacing.sm),
                ],
                PrimaryButton(
                  text: Strings.continueLabel,
                  onPressed: _imageBytes != null ? widget.onContinue : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

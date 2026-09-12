import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raghif/features/verification/photo_capture_screen.dart';

void main() {
  group('photoCaptureRequestFor', () {
    test('ID photo is a live rear-camera capture — never the gallery', () {
      final request = photoCaptureRequestFor(PhotoCaptureKind.id);

      expect(request.source, ImageSource.camera);
      expect(request.device, CameraDevice.rear);
    });

    test('selfie is a live front-camera capture — never the gallery', () {
      final request = photoCaptureRequestFor(PhotoCaptureKind.selfie);

      expect(request.source, ImageSource.camera);
      expect(request.device, CameraDevice.front);
    });
  });
}

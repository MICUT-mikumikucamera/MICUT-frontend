import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:image/image.dart' as img;
import '../../data/jobs/job.dart';

/// Full field of view for depth analysis, separate from the displayed crop.
class CaptureDraft {
  const CaptureDraft(
      {required this.originalBytes,
      required this.previewBytes,
      required this.capture});
  final Uint8List originalBytes;
  final Uint8List previewBytes;
  final CaptureInfo capture;
  XFile get original => XFile.fromData(originalBytes,
      mimeType: 'image/jpeg', name: 'micut-original.jpg');
}

CaptureDraft prepareCaptureRequest((Uint8List, double?) request) =>
    prepareCapture(request.$1, request.$2);

CaptureDraft prepareCapture(Uint8List bytes, double? aspectRatio) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('지원하지 않는 사진 형식이에요.');
  final source = img.bakeOrientation(decoded);
  final crop = centeredCrop(
      source.width, source.height, aspectRatio ?? source.width / source.height);
  final original = Uint8List.fromList(img.encodeJpg(source, quality: 95));
  return CaptureDraft(
    originalBytes: original,
    previewBytes: applyCaptureCrop(original, crop),
    capture:
        CaptureInfo(w: source.width, h: source.height, rotation: 0, crop: crop),
  );
}

CropRegion centeredCrop(int sourceWidth, int sourceHeight, double aspectRatio) {
  if (sourceWidth <= 0 ||
      sourceHeight <= 0 ||
      !aspectRatio.isFinite ||
      aspectRatio <= 0) {
    throw ArgumentError('Invalid capture dimensions');
  }
  final int width, height;
  if (sourceWidth / sourceHeight > aspectRatio) {
    height = sourceHeight;
    width = (height * aspectRatio).round().clamp(1, sourceWidth);
  } else {
    width = sourceWidth;
    height = (width / aspectRatio).round().clamp(1, sourceHeight);
  }
  return CropRegion(
      x: (sourceWidth - width) ~/ 2,
      y: (sourceHeight - height) ~/ 2,
      width: width,
      height: height);
}

Uint8List applyCaptureCrop(Uint8List bytes, CropRegion crop) {
  final source = img.decodeImage(bytes);
  if (source == null) throw const FormatException('Invalid photo');
  if (crop.x < 0 ||
      crop.y < 0 ||
      crop.width <= 0 ||
      crop.height <= 0 ||
      crop.x + crop.width > source.width ||
      crop.y + crop.height > source.height) {
    throw ArgumentError('Crop outside original image');
  }
  return Uint8List.fromList(img.encodeJpg(
      img.copyCrop(source,
          x: crop.x, y: crop.y, width: crop.width, height: crop.height),
      quality: 95));
}

// Retained for callers that only need an output image.
Uint8List cropCameraRequest((Uint8List, double) request) =>
    cropCameraJpeg(request.$1, request.$2);
Uint8List cropCameraJpeg(Uint8List bytes, double aspectRatio) =>
    prepareCapture(bytes, aspectRatio).previewBytes;

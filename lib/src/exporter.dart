import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui show ImageByteFormat, Image;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:screen_record/src/screen_recorder.dart';
import 'create_video.dart';
import 'frame.dart';

class Exporter {
  Exporter(this.skipFramesBetweenCaptures);

  final int skipFramesBetweenCaptures;

  static final List<Frame> _frames = [];
  int _maxWidthFrame = 0;
  int _maxHeightFrame = 0;

  static List<Frame> get frames => _frames;

  void onNewFrame(Frame frame) {
    _frames.add(frame);
  }

  void clear() {
    _frames.clear();

    _maxWidthFrame = 0;
    _maxHeightFrame = 0;
  }

  bool get hasFrames => _frames.isNotEmpty;

  Future<List<RawFrame>?> exportFrames() async {
    if (_frames.isEmpty) {
      return null;
    }
    final bytesImages = <RawFrame>[];
    for (final frame in _frames) {
      const format = ui.ImageByteFormat.png;
      final bytesImage = await frame.image.toByteData(format: format);

      if (frame.image.width >= _maxWidthFrame) {
        _maxWidthFrame = frame.image.width;
      }

      if (frame.image.height >= _maxHeightFrame) {
        _maxHeightFrame = frame.image.height;
      }

      if (bytesImage != null) {
        bytesImages.add(RawFrame(16, bytesImage));
      } else {
        debugPrint('Skipped frame while enconding');
      }
    }
    return bytesImages;
  }

  static Future<image.Image> convertUiImageToImage(ui.Image uiImage) async {
    // Convert ui.Image to ByteData
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert ui.Image to ByteData');
    }

    // Convert ByteData to Uint8List
    final uint8List = byteData.buffer.asUint8List();

    // Decode Uint8List to image.Image
    final _image = image.decodeImage(uint8List);
    if (_image == null) {
      throw Exception('Failed to decode Uint8List to image.Image');
    }

    return _image;
  }

  Future<File?> exportVideo({ValueChanged<ExportResult>? onProgress}) async {
    return await createVideoFromImages(

    );
  }

  Future<List<int>?> exportGif({ValueChanged<ExportResult>? onProgress}) async {
    ExportResult exportStatus = ExportResult(status: ExportStatus.exporting, percent: 0);
    onProgress?.call(exportStatus);
    debugPrint('Exporting gif ${DateTime.now()}');
    final frames = await exportFrames();

    debugPrint('End Exporting gif ${DateTime.now()}');
    if (frames == null) {
      return null;
    }
    exportStatus = ExportResult(status: ExportStatus.exported, percent: 0);
    onProgress?.call(exportStatus);

    return await _exportGif(DataHolder(frames, _maxWidthFrame, _maxHeightFrame), onProgress: onProgress);
  }

  static Future<List<int>?> _exportGif(DataHolder data, {ValueChanged<ExportResult>? onProgress}) async {
    List<RawFrame> frames = data.frames;
    int width = data.width;
    int height = data.height;

    image.Image mainImage = image.Image.empty();
    int i = 1;
    int max = frames.length;

    DateTime start = DateTime.now();

    for (final frame in frames) {
      double percent = double.parse((i / max).toStringAsFixed(4));
      ExportResult exportStatus = ExportResult(status: ExportStatus.encoding, percent: percent);

      onProgress?.call(exportStatus);
      i += 1;

      DataFrame dataFrame = DataFrame(frame: frame, mainImage: mainImage, width: width, height: height);

      var newFrame = await _handelFrame(dataFrame);

      if (newFrame == null) {
        continue;
      }

      mainImage.frames.add(newFrame);
    }

    DateTime endAddFrame = DateTime.now();
    debugPrint('End Exporting gif v1 ${endAddFrame.difference(start).inSeconds}');

    var resul = image.encodeGif(
      mainImage,
    );

    debugPrint('encodeGif ${DateTime.now().difference(endAddFrame).inSeconds}');
    ExportResult exportStatus = ExportResult(status: ExportStatus.encoded);
    onProgress?.call(exportStatus);
    return resul;
  }

  static image.PaletteUint8 _convertPalette(image.Palette palette) {
    final newPalette = image.PaletteUint8(palette.numColors, 4);
    for (var i = 0; i < palette.numColors; i++) {
      newPalette.setRgba(i, palette.getRed(i), palette.getGreen(i), palette.getBlue(i), 255);
    }
    return newPalette;
  }

  static image.Image encodeGifWIthTransparency(
    image.Image srcImage, {
    int transparencyThreshold = 1,
  }) {
    var format = srcImage.format;
    image.Image image32;
    if (format != image.Format.int8) {
      image32 = srcImage.convert(format: image.Format.uint8);
    } else {
      image32 = srcImage;
    }
    final newImage = image.quantize(image32);

    // GifEncoder will use palette colors with a 0 alpha as transparent. Look at the pixels
    // of the original image and set the alpha of the palette color to 0 if the pixel is below
    // a transparency threshold.
    final numFrames = srcImage.frames.length;
    for (var frameIndex = 0; frameIndex < numFrames; frameIndex++) {
      final srcFrame = srcImage.frames[frameIndex];
      final newFrame = newImage.frames[frameIndex];

      final palette = _convertPalette(newImage.palette!);

      for (final srcPixel in srcFrame) {
        if (srcPixel.a < transparencyThreshold) {
          final newPixel = newFrame.getPixel(srcPixel.x, srcPixel.y);
          palette.setAlpha(newPixel.index.toInt(), 0); // Set the palette color alpha to 0
        }
      }

      newFrame.data!.palette = palette;
    }

    return newImage;
  }

  static Future<image.Image?> _handelFrame(DataFrame data) async {
    final iAsBytes = data.frame.image.buffer.asUint8List();
    final decodedImage = image.decodePng(iAsBytes);

    if (decodedImage == null) {
      debugPrint('Skipped frame while enconding');
      return null;
    }
    decodedImage.frameDuration = data.frame.durationInMillis;

    var imageFrame = encodeGifWIthTransparency(
      image.copyExpandCanvas(
        decodedImage,
        newWidth: data.width,
        newHeight: data.height,
        toImage: image.Image(
          width: data.width,
          height: data.height,
          format: decodedImage.format,
          numChannels: 4,
        ),
      ),
    );
    return imageFrame;
  }
}

class DataFrame {
  final RawFrame frame;
  final image.Image mainImage;
  final int width;
  final int height;

  DataFrame({required this.frame, required this.mainImage, required this.width, required this.height});
}

class RawFrame {
  RawFrame(this.durationInMillis, this.image);

  final int durationInMillis;
  final ByteData image;
}

class DataHolder {
  DataHolder(this.frames, this.width, this.height);

  List<RawFrame> frames;

  int width;
  int height;
}

enum ExportStatus {
  exporting,
  encoding,
  encoded,
  exported,
  failed,
}

class ExportResult {
  final ExportStatus status;
  final File? file;
  final double? percent;

  ExportResult({required this.status, this.file, this.percent});

  //to String
  @override
  String toString() {
    return 'ExportResult(status: $status,  percent: $percent)';
  }
}

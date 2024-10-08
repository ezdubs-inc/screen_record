
import 'dart:io';
import 'dart:ui' as ui show Image, ImageByteFormat;


import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:image/image.dart' as imagelib;
import 'package:path_provider/path_provider.dart';
import 'exporter.dart';
import 'frame.dart';

class ScreenRecorderController {
  ScreenRecorderController({
    Exporter? exporter,
    this.pixelRatio = 0.5,
    this.skipFramesBetweenCaptures = 2,
    SchedulerBinding? binding,
  })  : _containerKey = GlobalKey(),
        _binding = binding ?? SchedulerBinding.instance,
        _exporter = exporter ?? Exporter(skipFramesBetweenCaptures);

  final GlobalKey _containerKey;
  final SchedulerBinding _binding;
  final Exporter _exporter;

  Exporter get exporter => _exporter;

  /// The pixelRatio describes the scale between the logical pixels and the size
  /// of the output image. Specifying 1.0 will give you a 1:1 mapping between
  /// logical pixels and the output pixels in the image. The default is a pixel
  /// ration of 3 and a value below 1 is not recommended.
  ///
  /// See [RenderRepaintBoundary](https://api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html)
  /// for the underlying implementation.
  final double pixelRatio;

  /// Describes how many frames are skipped between caputerd frames.
  /// For example if it's `skipFramesBetweenCaptures = 2` screen_recorder
  /// captures a frame, skips the next two frames and then captures the next
  /// frame again.
  final int skipFramesBetweenCaptures;

  int skipped = 0;

  bool _record = false;

  void start() {
    // only start a video, if no recording is in progress
    if (_record == true) {
      return;
    }
    _record = true;
    _binding.addPostFrameCallback(postFrameCallback);
  }

  void stop() {
    _record = false;
  }

  void postFrameCallback(Duration timestamp) {
    if (_record == false) {
      return;
    }
    if (skipped > 0) {
      // count down frames which should be skipped
      skipped = skipped - 1;
      // add a new PostFrameCallback to know about the next frame
      _binding.addPostFrameCallback(postFrameCallback);
      // but we do nothing, because we skip this frame
      return;
    }
    if (skipped == 0) {
      // reset skipped frame counter
      skipped = skipped + skipFramesBetweenCaptures;
    }
    try {
      final image = capture();
      if (image == null) {
        debugPrint('capture returned null');
        return;
      }
      _handleSaveImage(image);
      _exporter.onNewFrame(Frame(timestamp, image));
    } catch (e) {
      debugPrint(e.toString());
    }
    _binding.addPostFrameCallback(postFrameCallback);
  }

  ui.Image? capture() {
    final renderObject = _containerKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;

    return renderObject.toImageSync(pixelRatio: pixelRatio);
  }
  int  indexTest =0;
  void _handleSaveImage(ui.Image image) async{
    try{
      print('save image ${indexTest++} : ${image.width} ${image.height}');
      // DateTime now = DateTime.now();
      String path = (await getApplicationDocumentsDirectory()).path;
      // debugPrint('getApplicationDocumentsDirectory: ${DateTime.now().difference(now).inMilliseconds}');
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      // var decodePng = await  imagelib.decodePng(byteData!.buffer.asUint8List());

      final buffer = byteData!.buffer.asUint8List();
      // DateTime end = DateTime.now();
      // debugPrint('covertImage: ${DateTime.now().difference(now).inMilliseconds}');
      int time = DateTime.now().millisecondsSinceEpoch;
      String fullPath = '$path/$time.png';
      await File(fullPath).writeAsBytes(buffer);
      data.add(time);
      // debugPrint('save image: ${DateTime.now().difference(end).inMilliseconds}');
    }
    catch(e){
      print(e);
    }

  }
}
List<int> data = [];

class ScreenRecorder extends StatelessWidget {
  const ScreenRecorder({
    super.key,
    required this.child,
    required this.controller,
    required this.width,
    required this.height,
    this.background = Colors.transparent,
  });

  /// The child which should be recorded.
  final Widget child;

  /// This controller starts and stops the recording.
  final ScreenRecorderController controller;

  /// Width of the recording.
  /// This should not change during recording as it could lead to
  /// undefined behavior.
  final double width;

  /// Height of the recording
  /// This should not change during recording as it could lead to
  /// undefined behavior.
  final double height;

  /// The background color of the recording.
  /// Transparency is currently not supported.
  final Color background;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: controller._containerKey,
      child: Container(
        width: width,
        height: height,
        color: background,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

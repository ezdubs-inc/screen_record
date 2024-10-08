import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

import '../screen_record.dart';

Future<File?> createVideoFromImages(List<int> imagePaths, int skipFramesBetweenCaptures,
    {ValueChanged<ExportResult>? onProgress}) async {
  try {
    var frame = 60 ~/ ((skipFramesBetweenCaptures != 0) ? skipFramesBetweenCaptures : 1);
    int estimateTime = calculateVideoDuration(imagePaths.length, frame) * 10000;
    String outputPath = await getOutputPath();
    final directory = await getApplicationDocumentsDirectory();
    final command = '-framerate $frame -pattern_type glob -i ${directory.path}/*.png $outputPath';

    if (onProgress != null) {
      FFmpegKitConfig.enableStatisticsCallback(
        (Statistics statistics) {
          double timeInMilliseconds = statistics.getTime();
          // print('timeInMilliseconds $timeInMilliseconds');
          double progress = timeInMilliseconds / 10000;
          if (progress <= 1) {
            ExportResult exportResult = ExportResult(status: ExportStatus.exporting, percent: progress);
            onProgress.call(exportResult);
          }
        },
      );
    }
    var session = await FFmpegKit.execute(command);

    var a = await session.getReturnCode();

    if (a?.isValueSuccess() ?? false) {
      /// kiểm tra đã ghi xuống local chưa
      await waitForFile(file: File(outputPath), timeout: const Duration(seconds: 10));
      ExportResult exportResult = ExportResult(
        status: ExportStatus.exported,
        file: File(outputPath),
        percent: 1,
      );
      onProgress?.call(exportResult);
      session.cancel();
      return File(outputPath);
    }
    session.cancel();
    return null;
  } catch (e, s) {
    print(e);
  }
  return null;
}

Future<File> waitForFile({
  required final File file,
  required final Duration timeout,
}) async {
  final expiryTime = DateTime.now().add(timeout);

  while (!file.existsSync()) {
    if (DateTime.now().isAfter(expiryTime)) {
      throw TimeoutException("File not found after waiting for the specified duration.");
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
  return file;
}

Future<String> getOutputPath() async {
  final directory = await getApplicationDocumentsDirectory();
  String date = DateTime.now().millisecondsSinceEpoch.toString();
  final outputPath = '${directory.path}/$date.mp4';
  return outputPath;
}

int calculateVideoDuration(int numFrames, int fps) {
  if (fps <= 0) {
    throw ArgumentError('FPS must be greater than zero');
  }
  return (numFrames / fps).toInt();
}

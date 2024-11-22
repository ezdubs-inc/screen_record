import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'exporter.dart';
import 'package:path/path.dart';

Future<File?> createVideoFromImages({
  required Duration duration,
  ValueChanged<ExportResult>? onProgress,
  double speed = 1,
}) async {
  try {
    /// tinh toan: estimation time de xac dinh % progress
    String cacheDir = (await getApplicationDocumentsDirectory()).path;
    final input = join(cacheDir, 'rendering');

    String outputName = DateTime.now().millisecondsSinceEpoch.toString();
    final outputPath = join(cacheDir, '$outputName.mp4');

    final Directory directory = Directory(input);

    String temp = '${directory.path}/frame_%04d.bmp';

    String command = '-i $temp -threads 8  $outputPath';

    if (onProgress != null) {
      FFmpegKitConfig.enableStatisticsCallback(
            (statistics) {
          final time = statistics.getTime();
          double percent = time / duration.inMilliseconds;
          if (percent > 1) {
            percent = 1;
          }
          ExportResult exportResult = ExportResult(status: ExportStatus.exporting, percent: percent);
          onProgress.call(exportResult);
        },
      );
    }

    var session = await FFmpegKit.execute(command);

    var a = await session.getReturnCode();

    if (a?.isValueSuccess() ?? false) {
      /// kiểm tra đã ghi xuống local chưa
      await waitForFile(
          file: File(outputPath), timeout: const Duration(seconds: 10));
      ExportResult exportResult = ExportResult(
        status: ExportStatus.exported,
        file: File(outputPath),
        percent: 1,
      );
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
      throw TimeoutException(
          "File not found after waiting for the specified duration.");
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
  return file;
}

Future<String> getOutputPath() async {
  final directory = await getApplicationDocumentsDirectory();
  String date = DateTime.now().millisecondsSinceEpoch.toString();
  final outputPath = '${directory.path}/temp/$date.mp4';
  return outputPath;
}

int calculateVideoDuration(int numFrames, int fps) {
  if (fps <= 0) {
    throw ArgumentError('FPS must be greater than zero');
  }
  return numFrames * 1000 ~/ fps;
}

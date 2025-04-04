import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'exporter.dart';

Future<File?> createVideoFromImagesAndAudio({
  required Duration duration,
  ValueChanged<ExportResult>? onProgress,
  double speed = 1,
  required bool multiCache,
  required String cacheFolder,
  Uint8List? audioData,
}) async {
  try {
    /// tinh toan: estimation time de xac dinh % progress
    String cacheDir = (await getApplicationDocumentsDirectory()).path;
    final input = join(cacheDir, 'rendering');

    String outputName = DateTime.now().millisecondsSinceEpoch.toString();

    if (multiCache == false) {
      outputName = "ScreenRecord";
    }

    // check cacheFolder exists
    final Directory cacheFolderDir = Directory(join(cacheDir, cacheFolder));
    if (!cacheFolderDir.existsSync()) {
      cacheFolderDir.createSync();
    }
    cacheDir = cacheFolderDir.path;
    final outputPath = join(cacheDir, '$outputName.mp4');

    // if output file exists, delete it
    if (File(outputPath).existsSync()) {
      File(outputPath).deleteSync();
    }

    final Directory directory = Directory(input);

    String temp = '${directory.path}/frame_%04d.bmp';

    // If audio data is provided, save it to a temporary file
    String? audioPath;
    if (audioData != null) {
      audioPath = join(cacheDir, '${outputName}_audio.wav');
      await File(audioPath).writeAsBytes(audioData);
    }

    // Build FFmpeg command based on whether audio is present
    String command;
    if (audioPath != null) {
      command = '-i $temp -i "$audioPath" -c:v libx264 -crf 18 '
          '-c:a aac -b:a 192k -pix_fmt yuv420p -movflags +faststart -threads 8 '
          '-shortest $outputPath';
    } else {
      command = '-i $temp -c:v libx264 -crf 18 -pix_fmt yuv420p '
          '-movflags +faststart -threads 8 $outputPath';
    }

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

    var returnCode = await session.getReturnCode();
    
    // Add detailed error logging
    final logs = await session.getOutput();
    final errorLogs = await session.getLogsAsString();
    print('FFmpeg Command: $command');
    print('FFmpeg Output: $logs');
    print('FFmpeg Error Logs: $errorLogs');

    if (returnCode?.isValueSuccess() ?? false) {
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
  } catch (e) {
    throw Exception('Create Video Failed: $e');
  }
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
  final outputPath = '${directory.path}/temp/$date.mp4';
  return outputPath;
}

int calculateVideoDuration(int numFrames, int fps) {
  if (fps <= 0) {
    throw ArgumentError('FPS must be greater than zero');
  }
  return numFrames * 1000 ~/ fps;
}

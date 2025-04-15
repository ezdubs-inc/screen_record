import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit_config.dart';
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
  int skipFramesBetweenCaptures = 2,
  int audioSampleRate = 48000,
  int audioBitrate = 128000,
}) async {
  try {
    // Calculate the effective frame rate based on skipped frames
    // Assuming base Flutter frame rate of 60fps
    final effectiveFrameRate = 60 ~/ (skipFramesBetweenCaptures + 1);

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
      // First save raw audio data
      String rawAudioPath = join(cacheDir, '${outputName}_raw_audio.raw');
      await File(rawAudioPath).writeAsBytes(audioData);
      
      // Convert raw audio directly to AAC
      String aacPath = join(cacheDir, '${outputName}_temp.aac');
      
      // Basic audio conversion with configurable sample rate and bitrate
      String audioCommand = '-y -f s16le -ar $audioSampleRate -ac 1 -i "$rawAudioPath" '
          '-c:a aac -b:a ${audioBitrate ~/ 1000}k "$aacPath"';
      
      var audioSession = await FFmpegKit.execute(audioCommand);
      var audioReturnCode = await audioSession.getReturnCode();
      
      if (!(audioReturnCode?.isValueSuccess() ?? false)) {
        final logs = await audioSession.getLogsAsString();
        throw Exception('Audio conversion failed: $logs');
      }

      // Clean up raw audio file
      try {
        File(rawAudioPath).deleteSync();
      } catch (e) {
        // Ignore cleanup errors
      }

      audioPath = aacPath;
    }

    // Build FFmpeg command based on whether audio is present
    String command;

    if (audioPath != null) {
      // Now combine video and audio without modifying either
      if (Platform.isAndroid) {
        command = '-framerate $effectiveFrameRate -i $temp -i "$audioPath" '
            '-c:v mpeg4 -b:v 2M '
            '-c:a copy ' // Copy the audio as-is
            '-pix_fmt yuv420p '
            '-movflags +faststart '
            '-vsync 1 ' // Ensure proper video sync
            '-threads 8 '
            '-y ' // Overwrite output file if exists
            '$outputPath';
      } else {
        command = '-framerate $effectiveFrameRate -i $temp -i "$audioPath" '
            '-c:v h264_videotoolbox -b:v 2M '
            '-c:a copy ' // Copy the audio as-is
            '-pix_fmt yuv420p -movflags +faststart '
            '-vsync 1 ' // Ensure proper video sync
            '-threads 8 $outputPath';
      }
      
      // Clean up temp audio file after processing
      Future.delayed(const Duration(seconds: 1), () {
        try {
          if (audioPath != null) {
            File(audioPath).deleteSync();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      });
    } else {
      if (Platform.isAndroid) {
        command = '-framerate $effectiveFrameRate -i $temp '
            '-c:v mpeg4 -b:v 2M '
            '-pix_fmt yuv420p '
            '-movflags +faststart '
            '-vsync 1 '
            '-threads 8 '
            '-y ' // Overwrite output file if exists
            '$outputPath';
      } else {
        command = '-framerate $effectiveFrameRate -i $temp '
            '-c:v h264_videotoolbox -b:v 2M '
            '-pix_fmt yuv420p -movflags +faststart -vsync 1 -threads 8 $outputPath';
      }
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
    final logs = await session.getLogsAsString();

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
    } else {
      print('FFmpeg Logs: $logs');
      throw Exception('Create Video Failed: $logs');
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

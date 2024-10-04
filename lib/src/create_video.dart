import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

Future<File?> createVideoFromImages(List<int> imagePaths) async {
  try{
    final directory = await getApplicationDocumentsDirectory();
    String date = DateTime.now().millisecondsSinceEpoch.toString();
    final outputPath = '${directory.path}/$date.mp4';
    final command = '-framerate 60 -pattern_type glob -i "${directory.path}/*.png" $outputPath';
    var session = await FFmpegKit.execute(command);
     var a = await session.getReturnCode();
    if( a?.isValueSuccess()??false){
      return File(outputPath);
    }
    return null;

  }
  catch(e){
    print(e);
  }
  return null;


}
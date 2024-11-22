import 'dart:io';


import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:screen_record_plus/screen_record.dart';

import 'animated_screen.dart';
import 'sample_animation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // FFmpegKitConfig.enableLogCallback((log) {
  //   final message = log.getMessage();
  //   print(message);
  // });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

enum RecordStatus { none, recording, stop, exporting }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  RecordStatus status = RecordStatus.none;

  ScreenRecorderController controller = ScreenRecorderController(
    binding: WidgetsFlutterBinding.ensureInitialized(),
    skipFramesBetweenCaptures: 0,
    pixelRatio: 3,
  );

  bool get canExport => controller.exporter.hasFrames;
  double percentExport = 0;

  Duration duration = const Duration(seconds: 3);

  File? testFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ScreenRecorder(
                height: MediaQuery.of(context).size.height - 300,
                width: MediaQuery.of(context).size.width,
                controller: controller,
                child: const UnconstrainedBox(
                  child: SizedBox(
                    height: 300,
                    width: 300,
                    child: SampleAnimation(),
                  ),
                ),
              ),
              if (status == RecordStatus.none)
                ElevatedButton(
                  onPressed: () async {
                    await controller.start();
                    setState(() {
                      status = RecordStatus.recording;
                    });
                  },
                  child: const Text('Start Recording'),
                ),
              if (status == RecordStatus.recording)
                ElevatedButton(
                  onPressed: () async {
                    controller.stop();
                    setState(() {
                      status = RecordStatus.stop;
                    });
                  },
                  child: const Text('Stop Recording'),
                ),

              if (status == RecordStatus.stop)
                ElevatedButton(
                  onPressed: () async {
                    File? file = await controller.exporter.exportVideo(onProgress: (value){
                      print(value);
                    });
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AnimatedScreen(
                          file: file!,
                        );
                      },
                    );
                    setState(() {
                      status = RecordStatus.none;
                    });
                  },
                  child: const Text('Stop Recording'),
                )
            ],
          ),
        ),
      ),
    );
  }
}

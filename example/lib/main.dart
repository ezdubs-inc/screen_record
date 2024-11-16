import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_record/screen_record.dart';

import 'animated_screen.dart';
import 'sample_animation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FFmpegKitConfig.enableLogCallback((log) {
    final message = log.getMessage();
    print(message);
  });
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _recording = false;
  bool _exporting = false;
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
    // TODO: implement initState
    _getList();
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
              if(!_recording)
              ElevatedButton(
                onPressed: () async {
                  await controller.start();
                  Future.delayed(Duration(seconds: 10)).then((_)async{
                     controller.stop();

                  });
                },
                child: const Text('Start Recording'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _getList() async {
    // final directory = await getApplicationDocumentsDirectory();
    // var list = await Directory('${directory.path}/temp').listSync();
    // String path = list.first.path;
    // testFile = File(path);
    // setState(() {});
  }
}

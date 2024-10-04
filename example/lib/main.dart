import 'dart:async';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
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
    pixelRatio: 2,
  );

  bool get canExport => controller.exporter.hasFrames;
  double percentExport = 0;
  late PercentanceCallBack percentanceCallBack;

  Timer? _timer;

  Duration duration = const Duration(seconds: 3);

  startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) async {
        duration = duration - oneSec;
        if (duration == Duration.zero) {
          controller.stop();

          timer.cancel();
          DateTime now = DateTime.now();
          try {
            var gif = await controller.exporter.exportVideo();

            await showDialog(
              context: context as dynamic,
              builder: (context) {
                return Dialog(
                  child: AnimatedScreen(file: gif!),
                );
              },
            );
          } catch (e) {
            debugPrint(e.toString());
          }

          DateTime end = DateTime.now();
          debugPrint('Time taken: ${end.difference(now).inSeconds}');
        }
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    percentanceCallBack = PercentanceCallBack(percentCallBack: (value) {
      // renderPercent.value = value;
      print(value);
      // percentExport = value;
      // setState(() {});
    });
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
              if (_exporting)
                Center(
                  child: CircularProgressIndicator(
                    value: percentExport,
                    // value: 0.5,
                  ),
                )
              else ...[
                ScreenRecorder(
                  height: 500,
                  width: 500,
                  controller: controller,
                  child: const SampleAnimation(),
                ),
                if (!_recording && !_exporting)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        controller.start();
                        controller.exporter.clear();
                        startTimer();
                        setState(() {
                          _recording = true;
                        });
                      },
                      child: const Text('Start'),
                    ),
                  ),
                if (_recording && !_exporting)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        controller.stop();
                        setState(() {
                          _recording = false;
                        });
                      },
                      child: const Text('Stop'),
                    ),
                  ),
                if (canExport && !_exporting)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _exporting = true;
                        });
                        var frames = await controller.exporter.exportFrames();
                        if (frames == null) {
                          throw Exception();
                        }
                        setState(() => _exporting = false);
                        showDialog(
                          context: context as dynamic,
                          builder: (context) {
                            return AlertDialog(
                              content: SizedBox(
                                height: 500,
                                width: 500,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  itemCount: frames.length,
                                  itemBuilder: (context, index) {
                                    final image = frames[index].image;
                                    return SizedBox(
                                      height: 150,
                                      child: Image.memory(
                                        image.buffer.asUint8List(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: const Text('Export as frames'),
                    ),
                  ),
                if (canExport && !_exporting) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _exporting = true;
                        });
                        var gif = await controller.exporter.exportGif(
                          onProgress: (value) {
                            print(value);
                          },
                        );
                        if (gif == null) {
                          throw Exception();
                        }
                        setState(() => _exporting = false);
                        showDialog(
                          context: context as dynamic,
                          builder: (context) {
                            return AlertDialog(
                              content: Image.memory(Uint8List.fromList(gif)),
                            );
                          },
                        );
                      },
                      child: const Text('Export as GIF'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          controller.exporter.clear();
                        });
                      },
                      child: const Text('Clear recorded data'),
                    ),
                  )
                ]
              ]
            ],
          ),
        ),
      ),
    );
  }
}

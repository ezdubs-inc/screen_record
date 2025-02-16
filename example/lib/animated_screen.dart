import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class AnimatedScreen extends StatefulWidget {
  const AnimatedScreen({super.key, required this.file});

  final File file;

  @override
  State<AnimatedScreen> createState() => _AnimatedScreenState();
}

class _AnimatedScreenState extends State<AnimatedScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
  
    _controller = VideoPlayerController.file(
      widget.file,
      videoPlayerOptions: VideoPlayerOptions(),
    )..initialize().then((value) => _controller.play());

    _controller.addListener(() {
      if (_controller.value.isPlaying) {
        print('Playing ${_controller.value.duration.inSeconds}');
      } else {
        print('Pause');
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.value.isPlaying ? _controller.pause() : _controller.play();
      },
      child: SafeArea(
        child: Padding(padding: const EdgeInsets.all(20), child: AspectRatio(aspectRatio: 9 / 16, child: VideoPlayer(_controller))),
      ),
    );
  }

  void init() async {
    final bytes = await rootBundle.load('assets/images/test.jpeg');
    final bytesBackground = await rootBundle.load('assets/images/background.png');
    String path = (await getApplicationDocumentsDirectory()).path;
    File('$path/noise.png').writeAsBytesSync(bytes.buffer.asUint8List());
    File('$path/background.png').writeAsBytesSync(bytesBackground.buffer.asUint8List());
  }

  saveImageToPath(Image image, String s) {}
}

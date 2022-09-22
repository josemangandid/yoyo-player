import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_wake/flutter_screen_wake.dart';
import 'package:orientation/orientation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import 'package:http/http.dart' as http;
import 'package:yoyo_player/src/utils/utils.dart';
import 'package:yoyo_player/src/widget/widget_bottombar.dart';
import 'package:yoyo_player/yoyo_player.dart';
import 'model/audio.dart';
import 'model/m3u8.dart';
import 'model/m3u8s.dart';
import 'responses/play_response.dart';
import 'responses/regex_response.dart';
import 'widget/top_chip.dart';

class YoYoPlayer extends StatefulWidget {
  ///Video[source],
  ///```dart
  ///url:"https://example.com/index.m3u8";
  ///```

  ///Video Player  style
  ///```dart
  ///videoStyle : VideoStyle(
  ///     play =  Icon(Icons.play_arrow),
  ///     pause = Icon(Icons.pause),
  ///     fullScreen =  Icon(Icons.fullScreen),
  ///     forward =  Icon(Icons.skip_next),
  ///     backward =  Icon(Icons.skip_previous),
  ///     playedColor = Colors.green,
  ///     qualitystyle = const TextStyle(
  ///     color: Colors.white,),
  ///      qaShowStyle = const TextStyle(
  ///      color: Colors.white,
  ///    ),
  ///   );
  ///```
  final VideoStyle? videoStyle;

  /// Video Loading Style
  final VideoLoadingStyle? videoLoadingStyle;

  /// Video AspectRatio [aspectRatio : 16 / 9 ]
  final double aspectRatio;

  /// video state fullScreen
  final void Function(bool fullScreenTurnedOn)? onFullScreen;

  /// video Type
  final void Function(String videoType)? onPlayingVideo;

  final Function(int position)? position;

  final Duration? startAt;

  final List<M3U8pass> yoyo;

  ///
  /// ```dart
  /// YoYoPlayer(
  /// //url = (m3u8[hls],.mp4,.mkv,)
  ///   url : "",
  /// //video style
  ///   videoStyle : VideoStyle(),
  /// //video loading style
  ///   videoLoadingStyle : VideoLoadingStyle(),
  /// //video aspect ratio
  ///   aspectRatio : 16/9,
  /// )
  /// ```
  YoYoPlayer({
    Key? key,
    required this.yoyo,
    required this.aspectRatio,
    this.startAt,
    this.position,
    this.videoStyle,
    this.videoLoadingStyle,
    this.onFullScreen,
    this.onPlayingVideo,
  }) : super(key: key);

  @override
  _YoYoPlayerState createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer>
    with SingleTickerProviderStateMixin {
  //video play type (hls,mp4,mkv,offline)
  String? playType;

  // Animation Controller
  late AnimationController controlBarAnimationController;

  // Video Top Bar Animation
  Animation<double>? controlTopBarAnimation;

  // Video Bottom Bar Animation
  Animation<double>? controlBottomBarAnimation;

  // Video Player Controller
  VideoPlayerController? controller;

  // Video init error default :false
  bool hasInitError = false;

  // Video Total Time duration
  String? videoDuration;

  // Video Seed to
  String? videoSeek;

  // Video duration 1
  Duration? duration;

  // video seek second by user
  double? videoSeekSecond;

  // video duration second
  double? videoDurationSecond;

  //m3u8 data video list for user choice
  List<M3U8pass> yoyo = [];

  // m3u8 audio list
  List<AUDIO> audioList = [];

  // m3u8 temp data
  String? m3u8Content;

  // subtitle temp data
  String? subtitleContent;

  // menu show m3u8 list
  bool m3u8show = false;

  // video full screen
  bool fullScreen = false;

  // menu show
  bool showMenu = false;

  // auto show subtitle
  bool showSubtitles = false;

  final _position = 0;

  // video status
  bool? offline;

  // video auto quality
  String? m3u8quality = "Auto";

  // time for duration
  Timer? showTime;

  //Current ScreenSize
  Size get screenSize => MediaQuery.of(context).size;

  VideoPlayerValue? _latestValue;

  bool _wasLoading = true;

  bool controlsNotVisible = true;

  bool _fullscreen = false;

  Timer? _hideTimer;
  Timer? _initTimer;
  bool _displayTapped = false;

  bool isChangedQuality = false;

  int currentPosition = 0;

  Duration _startAt = Duration(seconds: 0);

  //
  @override
  void initState() {
    getM3U8();
    if(widget.startAt != null ) {
      _startAt = widget.startAt!;
    }
    // getSub();
    urlCheck(yoyo[0].dataURL!);
    super.initState();

    /// Control bar animation
    controlBarAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    controlTopBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    controlBottomBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    var widgetsBinding = WidgetsBinding.instance!;

    widgetsBinding.addPostFrameCallback((callback) {
      widgetsBinding.addPersistentFrameCallback((callback) {
        if (!mounted) return;
        if (_fullscreen != fullScreen) {
          setState(() {
            fullScreen = !fullScreen;
            _navigateLocally(context);
            if (widget.onFullScreen != null) {
              widget.onFullScreen!(fullScreen);
            }
          });
        }
        //
        widgetsBinding.scheduleFrame();
      });
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    FlutterScreenWake.keepOn(true);
  }

  @override
  void dispose() {
    m3u8clean();
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _wasLoading = (isLoading(_latestValue) || !controller!.value.isInitialized);
    final videoChildren = <Widget>[
      GestureDetector(
        onTap: () {
          toggleControls();
        },
        onDoubleTap: () {
          togglePlay();
        },
        child: ClipRect(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
                child: AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: VideoPlayer(controller!),
            )),
          ),
        ),
      ),
    ];
    videoChildren.addAll(videoBuiltInChildren());
    return AspectRatio(
        aspectRatio: fullScreen
            ? calculateAspectRatio(context, screenSize)
            : widget.aspectRatio,
        child: Stack(children: videoChildren));
  }

  /// Video Player ActionBar
  Widget actionBar() {
    return showMenu
        ? Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 40,
              width: double.infinity,
              // color: Colors.yellow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 5,
                  ),
                  if(yoyo.length> 1 )topChip(
                    Text(m3u8quality!, style: widget.videoStyle!.qualitystyle),
                    () {
                      // quality function
                      m3u8show = true;
                    },
                  ),
                  if(yoyo.length >1)Container(
                    width: 5,
                  ),
                  InkWell(
                    onTap: () => toggleFullScreen(),
                    child: Padding(
                      padding: EdgeInsets.all(fullScreen ? 20.0 : 10.0),
                      child: Icon(
                        fullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white,
                        size: fullScreen ? 35 : 25,
                      ),
                    ),
                  ),
                  Container(
                    width: 5,
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  Widget m3u8list() {
    return m3u8show == true
        ? Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0, right: 5),
              child: SingleChildScrollView(
                child: Column(
                  children: yoyo
                      .map((e) => InkWell(
                            onTap: () {
                              m3u8quality = e.dataQuality;
                              m3u8show = false;
                              onSelectQuality(e);
                              print(
                                  "--- quality select ---\nquality : ${e.dataQuality}\nlink : ${e.dataURL}");
                            },
                            child: Container(
                                width: 90,
                                color: Colors.grey,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${e.dataQuality}",
                                    style: widget.videoStyle!.qaShowStyle,
                                  ),
                                )),
                          ))
                      .toList(),
                ),
              ),
            ),
          )
        : Container();
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(milliseconds: 3000), () {
      changePlayerControlsNotVisible(true);
    });
  }

  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    changePlayerControlsNotVisible(false);
    _displayTapped = true;
  }

  List<Widget> videoBuiltInChildren() {
    return [
      shadow(),
      _wasLoading ? widget.videoLoadingStyle!.loading : Container(),
      _wasLoading ? Container() : actionBar(),
      _wasLoading
          ? Container()
          : bottomBar(
              controller: controller,
              videoSeek: "$videoSeek",
              videoDuration: "$videoDuration",
              showMenu: showMenu,
              isFullScreen: fullScreen,
              onDragStart: () {
                _hideTimer?.cancel();
              },
              onDragEnd: () {
                _startHideTimer();
              },
              onTapDown: () {
                cancelAndRestartTimer();
              },
            ),
      _wasLoading
          ? Container()
          : playPauseAndBackForward(
              controller: controller,
              forwardIcon: widget.videoStyle!.forward,
              backwardIcon: widget.videoStyle!.backward,
              play: () => togglePlay()),
      _wasLoading ? Container() : m3u8list(),
    ];
  }

  Widget shadow() {
    return showMenu
        ? GestureDetector(
            onTap: () {
              toggleControls();
            },
            onDoubleTap: () {
              togglePlay();
            },
            child: Align(
              alignment: Alignment.center,
              child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black54),
            ),
          )
        : Container();
  }

  Widget playPauseAndBackForward({
    VideoPlayerController? controller,
    Widget? backwardIcon,
    Widget? forwardIcon,
    Function? play,
  }) {
    return showMenu
        ? Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        rewind(controller!);
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: (fullScreen ? 40 : 20), vertical: 5),
                        child: Icon(
                          Icons.replay_10,
                          color: Colors.white,
                          size: fullScreen ? 50 : 30,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: play as void Function()?,
                    child: Icon(
                      controller!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: fullScreen ? 55 : 35,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        fastForward(controller: controller);
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: (fullScreen ? 40 : 20), vertical: 5),
                        child: Icon(
                          Icons.forward_10,
                          color: Colors.white,
                          size: fullScreen ? 50 : 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  void urlCheck(String url) {
    final netRegex = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
    final isNetwork = netRegex.hasMatch(url);
    final a = Uri.parse(url);

    print("parse url data end : ${a.pathSegments.last}");
    if (isNetwork) {
      setState(() {
        offline = false;
      });
      if (a.pathSegments.last.endsWith("mkv")) {
        setState(() {
          playType = "MKV";
        });
        print("urlEnd : mkv");
        if (widget.onPlayingVideo != null) widget.onPlayingVideo!("MKV");

        videoControlSetup(url);
      } else if (a.pathSegments.last.endsWith("mp4")) {
        setState(() {
          playType = "MP4";
        });
        print("urlEnd : mp4 $playType");
        if (widget.onPlayingVideo != null) widget.onPlayingVideo!("MP4");

        print("urlEnd : mp4");
        videoControlSetup(url);
      } else if (a.pathSegments.last.endsWith("m3u8")) {
        setState(() {
          playType = "HLS";
        });
        if (widget.onPlayingVideo != null) widget.onPlayingVideo!("M3U8");

        print("urlEnd : m3u8");
        videoControlSetup(url);
      } else {
        print("urlEnd : null");
        videoControlSetup(url);
      }
      print("--- Current Video Status ---\noffline : $offline");
    } else {
      setState(() {
        offline = true;
        print(
            "--- Current Video Status ---\noffline : $offline \n --- :3 done url check ---");
      });
      videoControlSetup(url);
    }
  }

// M3U8 Data Setup
  void getM3U8() {
    if (yoyo.length > 0) {
      print("${yoyo.length} : data start clean");
      m3u8clean();
    }
    m3u8video();
  }

  Future<M3U8s> m3u8video() async {
    for(M3U8pass video in widget.yoyo){
      yoyo.add(video);
    }
    M3U8s m3u8s = M3U8s(m3u8s: yoyo);
    print(
        "--- m3u8 file write ---\n${yoyo.map((e) => e.dataQuality == e.dataURL).toList()}\nlength : ${yoyo.length}\nSuccess");
    return m3u8s;
  }

// Video controller
  void videoControlSetup(String? url) async {
    await videoInit(url);
    controller!.addListener(listener);
    controller!.play();
  }

// video Listener
  void listener() async {
    _updateState();
    if (controller!.value.isInitialized && controller!.value.isPlaying) {
      if (!await Wakelock.enabled) {
        await Wakelock.enable();
      }
      setState(() {
        videoDuration = convertDurationToString(controller!.value.duration);
        videoSeek = convertDurationToString(controller!.value.position);
        videoSeekSecond = controller!.value.position.inSeconds.toDouble();
        videoDurationSecond = controller!.value.duration.inSeconds.toDouble();
      });
    } else {
      if (await Wakelock.enabled) {
        await Wakelock.disable();
        setState(() {});
      }
    }
  }

  void createHideControlBarTimer() {
    clearHideControlBarTimer();
    showTime = Timer(Duration(milliseconds: 5000), () {
      if (controller != null && controller!.value.isPlaying) {
        if (showMenu) {
          setState(() {
            showMenu = false;
            m3u8show = false;
            controlBarAnimationController.reverse();
          });
        }
      }
    });
  }

  void clearHideControlBarTimer() {
    showTime?.cancel();
  }

  void toggleControls() {
    clearHideControlBarTimer();

    if (!showMenu) {
      showMenu = true;
      createHideControlBarTimer();
    } else {
      m3u8show = false;
      showMenu = false;
    }
    setState(() {
      if (showMenu) {
        controlBarAnimationController.forward();
      } else {
        controlBarAnimationController.reverse();
      }
    });
  }

  void togglePlay() {
    createHideControlBarTimer();
    if (controller!.value.isPlaying) {
      controller!.pause();
    } else {
      controller!.play();
    }
    setState(() {});
  }

  Future<void> videoInit(String? url) async {
    if (offline == false) {
      print(
          "--- Player Status ---\nplay url : $url\noffline : $offline\n--- start playing –––");

      if (playType == "MP4") {
        // Play MP4
        controller =
            VideoPlayerController.network(url!, formatHint: VideoFormat.other)
              ..initialize().then((value) {
                startAt();
                setState(() => hasInitError = false);
              }).catchError((e) => setState(() => hasInitError = true));
      } else if (playType == "MKV") {
        controller =
            VideoPlayerController.network(url!, formatHint: VideoFormat.dash)
              ..initialize().then((value) {
                startAt();
                setState(() => hasInitError = false);
              }).catchError((e) => setState(() => hasInitError = true));
      } else if (playType == "HLS") {
        controller =
            VideoPlayerController.network(url!, formatHint: VideoFormat.hls)
              ..initialize().then((value) {
                startAt();
                setState(() => hasInitError = false);
              }).catchError((e) => setState(() => hasInitError = true));
      } else if (playType == null) {
        controller = VideoPlayerController.network(url!, formatHint: VideoFormat.other)
          ..initialize().then((value) {
            startAt();
            setState(() => hasInitError = false);
          }).catchError((e) => setState(() => hasInitError = true));
      }
    } else {
      print(
          "--- Player Status ---\nplay url : $url\noffline : $offline\n--- start playing –––");

      controller = VideoPlayerController.file(File(url!))
        ..initialize().then((value) {
          startAt();
          setState(() => hasInitError = false);
        }).catchError((e) {
          log(e.toString(), name: "Error al reproducir Archivo local");
          setState(() => hasInitError = true);
        });
    }
  }

  void startAt() async {
      await controller!.seekTo(_startAt);
  }

  String convertDurationToString(Duration duration) {
    var minutes = duration.inMinutes.toString();
    if (minutes.length == 1) {
      minutes = '0' + minutes;
    }
    var seconds = (duration.inSeconds % 60).toString();
    if (seconds.length == 1) {
      seconds = '0' + seconds;
    }
    return "$minutes:$seconds";
  }

  void _navigateLocally(context) async {
    if (!fullScreen) {
      if (ModalRoute.of(context)!.willHandlePopInternally) {
        Navigator.of(context).pop();
      }
      return;
    }
    ModalRoute.of(context)!
        .addLocalHistoryEntry(LocalHistoryEntry(onRemove: () {
      if (fullScreen) toggleFullScreen();
    }));
  }

  void onSelectQuality(M3U8pass data) async {
    if(!isChangedQuality){
      isChangedQuality = true;
      currentPosition = controller!.value.position.inSeconds;
      _startAt = Duration(seconds: currentPosition);
      isChangedQuality = !isChangedQuality;
    }
    controller!.value.isPlaying ? controller!.pause() : controller!.pause();
    if (data.dataQuality == "Auto") {
      videoControlSetup(data.dataURL);
    } else {
      try {
        String text;
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file =
            File('${directory.path}/yoyo${data.dataQuality}.m3u8');
        print("read file success");
        text = await file.readAsString();
        print("data : $text  :: data");
        localM3U8play(file);
        // videoControlSetup(file);
      } catch (e) {
        print("Couldn't read file ${data.dataQuality} e: $e");
      }
      print("data : ${data.dataQuality}");
    }
  }

  void localM3U8play(File file) {
    controller = VideoPlayerController.file(
      file,
    )..initialize().then((value) {
        startAt();
        setState(() => hasInitError = false);
      }).catchError((e) => setState(() => hasInitError = true));
    controller!.addListener(listener);
    controller!.play();
  }

  void m3u8clean() async {
    print(yoyo.length);
    for (int i = 2; i < yoyo.length; i++) {
      try {
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file = File('${directory.path}/${yoyo[i].dataQuality}.m3u8');
        file.delete();
        print("delete success $file");
      } catch (e) {
        print("Couldn't delete file $e");
      }
    }
    try {
      print("Audio m3u8 list clean");
      audioList.clear();
    } catch (e) {
      print("Audio list clean error $e");
    }
    audioList.clear();
    try {
      print("m3u8 data list clean");
      yoyo.clear();
    } catch (e) {
      print("m3u8 video list clean error $e");
    }
  }

  void toggleFullScreen() {
    if (fullScreen) {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    } else {
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }
    _fullscreen = !_fullscreen;
  }

  static const int _bufferingInterval = 20000;

  bool isLoading(VideoPlayerValue? latestValue) {
    if (latestValue != null) {
      if (!latestValue.isPlaying && latestValue.duration == null) {
        return true;
      }

      final Duration position = latestValue.position;

      Duration? bufferedEndPosition;
      if (latestValue.buffered.isNotEmpty == true) {
        bufferedEndPosition = latestValue.buffered.last.end;
      }

      if (bufferedEndPosition != null) {
        final difference = bufferedEndPosition - position;

        if (latestValue.isPlaying &&
            latestValue.isBuffering &&
            difference.inMilliseconds < _bufferingInterval) {
          return true;
        }
      }
    }
    return false;
  }

  void _updateState() {
    if (mounted) {
      if (controller!.value.position.inSeconds != _position &&
          widget.position != null) {
        widget.position!(controller!.value.position.inSeconds);
      }
      if (isVideoFinished(controller!.value) ||
          _wasLoading ||
          isLoading(controller!.value)) {
        setState(() {
          _latestValue = controller!.value;
          //if (isVideoFinished(_latestValue) &&
          //    controller!.value.isPlaying == false) {
          //  changePlayerControlsNotVisible(false);
          //}
        });
      }
    }
  }

  bool isVideoFinished(VideoPlayerValue? videoPlayerValue) {
    return videoPlayerValue?.position != null &&
        videoPlayerValue?.duration != null &&
        videoPlayerValue!.position.inMilliseconds != 0 &&
        videoPlayerValue.duration.inMilliseconds != 0 &&
        videoPlayerValue.position >= videoPlayerValue.duration;
  }

  void changePlayerControlsNotVisible(bool notVisible) {
    setState(() {
      controlsNotVisible = notVisible;
    });
  }
}

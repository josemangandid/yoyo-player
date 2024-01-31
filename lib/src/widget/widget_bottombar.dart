import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:yoyo_player/src/widget/progress_bar.dart';
import 'package:yoyo_player/src/widget/progress_colors.dart';

Color progressBarPlayedColor = Colors.white;
Color progressBarHandleColor = Colors.white;
Color progressBarBufferedColor = Colors.white70;
Color progressBarBackgroundColor = Colors.white60;

Widget bottomBar({
  VideoPlayerController? controller,
  String? videoSeek,
  String? videoDuration,
  required bool isFullScreen,
  required bool showMenu,
  Function()? onDragStart,
  Function()? onDragEnd,
  Function()? onDragUpdate,
  Function()? onTapDown,
  Function()? onToNextVideo,
}) {
  return showMenu
      ? Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Text(
                      videoSeek! + " / " + videoDuration!,
                      style: TextStyle(
                          fontSize: isFullScreen ? 16 : 12, color: Colors.white),
                    ),
                  ),
                  Spacer(),
                  if(onToNextVideo != null)Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: ElevatedButton(
                      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Color(0xff303030))
                      ),
                      onPressed: (){},
                      child: Row(mainAxisSize: MainAxisSize.min,
                      children: [Text("Siguiente", style: TextStyle(
                          fontSize: isFullScreen ? 16 : 12, color: Colors.white)), Icon(Icons.arrow_forward_ios,
                        size: isFullScreen ? 20 : 16,
                      )],), ),
                  )
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Container(
                  height: 30,
                  child: ProgressBar(
                    controller,
                    onDragStart: onDragStart,
                    onDragEnd: onDragEnd,
                    onTapDown: onTapDown,
                    colors: ProgressColors(
                      playedColor: progressBarPlayedColor,
                      handleColor: progressBarHandleColor,
                      bufferedColor: progressBarBufferedColor,
                      backgroundColor: progressBarBackgroundColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      : Container();
}

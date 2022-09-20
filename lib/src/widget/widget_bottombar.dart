import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

Widget bottomBar({
  VideoPlayerController? controller,
  String? videoSeek,
  String? videoDuration,
  required bool isFullScreen,
  required bool showMenu,
}) {
  return showMenu
      ? Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Text(
                  videoSeek! + " / " + videoDuration!,
                  style: TextStyle(fontSize: isFullScreen ? 16 : 12, color: Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: VideoProgressIndicator(
                  controller!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                      playedColor: Colors.black45,
                      bufferedColor: Colors.black12,
                      backgroundColor: Colors.white),
                  padding: EdgeInsets.only(left: 5.0, right: 5),
                ),
              ),
              isFullScreen
                  ? SizedBox(
                      height: 20.0,
                    )
                  : SizedBox(),
            ],
          ),
        )
      : Container();
}

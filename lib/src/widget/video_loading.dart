import 'package:flutter/material.dart';

class VideoLoading extends StatelessWidget {
  const VideoLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: new AlwaysStoppedAnimation<Color>(Color(0xffff9d00)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:developer';

import 'package:example/provider.dart';
import 'package:flutter/material.dart';
import 'package:yoyo_player/yoyo_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool fullscreen = false;
  bool isLoaded = false;
  List urls = [];
  String _url = 'https://embedsito.com/v/ryq6gueq4j1-nj5';

  @override
  void initState() {
    super.initState();
    loadUrl();
  }

  loadUrl() async {
    urls = await Provider.resolveFembedUrl(_url);

    setState(() {
      isLoaded = true;
    });
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      home: Scaffold(
        appBar: fullscreen == false
            ? AppBar(
                backgroundColor: Colors.blue,
                title: Image(
                  image: AssetImage('image/yoyo_logo.png'),
                  fit: BoxFit.fitHeight,
                  height: 50,
                ),
                centerTitle: true,
              )
            : null,
        body: Column(
          children: [
            isLoaded ? YoYoPlayer(
              position: (int position){
                print(position.toString());
              },
              startAt: Duration(seconds: 60),
              aspectRatio: 16 / 9,
              yoyo: [
                M3U8pass(
                  dataQuality: urls[0]["label"],
                  dataURL: urls[0]["file"]
                ),
                /*M3U8pass(
                    dataQuality: urls[1]["label"],
                    dataURL: urls[1]["file"]
                )*/
              ],
                  // "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
                  // "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
                  // "https://player.vimeo.com/external/440218055.m3u8?s=7ec886b4db9c3a52e0e7f5f917ba7287685ef67f&oauth2_token_id=1360367101",
                  //"https://sfux-ext.sfux.info/hls/chapter/105/1588724110/1588724110.m3u8",
              videoStyle: VideoStyle(),
              videoLoadingStyle: VideoLoadingStyle(/*
                loading: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image(
                        image: AssetImage('image/yoyo_logo.png'),
                        fit: BoxFit.fitHeight,
                        height: 50,
                      ),
                      Text("Loading video"),
                    ],
                  ),
                ),*/
              ),
              onFullScreen: (t) {
                setState(() {
                  fullscreen = t;
                });
              },
            ): CircularProgressIndicator()
          ],
        ),
      ),
    );
  }
}

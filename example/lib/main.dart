import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];
  String? _sharedText;

  @override
  void initState() {
    super.initState();

    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      _processSharedData(value);
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _processSharedData(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _processSharedData(List<SharedMediaFile> value) {
    setState(() {
      _sharedFiles.clear();
      _sharedText = null;
      if (value.isEmpty) return;

      _sharedFiles.addAll(value.where((f) => f.type != SharedMediaType.text));
      var textFile = value.firstWhere(
        (f) => f.type == SharedMediaType.text,
      );
      if (textFile.path.isNotEmpty) {
        _sharedText = textFile.path;
      }
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF15202B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF15202B),
          elevation: 0,
        ),
      ),
      home: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ReceiveSharingIntent.instance.reset();
                // In a real app, you'd likely pop the navigator.
                // For this example, we do nothing.
              },
            ),
            actions: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Tweet action
                  },
                  child: const Text("Tweet"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      // In a real app, you'd load the user's profile picture
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: Key(_sharedText ?? ''), // To update with new text
                        initialValue: _sharedText,
                        maxLines: null,
                        minLines: 1,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          hintText: "What's happening?",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_sharedFiles.isNotEmpty)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _sharedFiles.first.type == SharedMediaType.image
                            ? Image.file(
                                File(_sharedFiles.first.path),
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.movie,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

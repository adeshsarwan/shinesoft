import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class LocalVideoPlayerScreen extends StatefulWidget {
  final String videoPath; // Can be file path OR content:// URI
  const LocalVideoPlayerScreen({super.key, required this.videoPath});
  @override
  State<LocalVideoPlayerScreen> createState() => _LocalVideoPlayerScreenState();
}

class _LocalVideoPlayerScreenState extends State<LocalVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }
  // ============================
  // 🌟 UNIVERSAL VIDEO LOADER
  // Works on ALL Android versions
  // Supports:
  //   ✔ /storage/emulated/0/... (old Android)
  //   ✔ content://media/... (Android 10+)
  // ============================
  Future<void> _initVideo() async {
    print("📥 Original videoPath: ${widget.videoPath}");
    
    // Clean and parse the path
    String path = widget.videoPath.trim();
    
    // Extract content:// URI if present (handle corrupted database entries)
    if (path.contains('content://')) {
      // Find the content:// URI in the string
      final uriMatch = RegExp(r'content://[^\s]+').firstMatch(path);
      if (uriMatch != null) {
        path = uriMatch.group(0)!;
        print("➡ Extracted content URI: $path");
      }
    }
    // Check if it's a full file path starting with /storage
    else if (path.startsWith('/storage')) {
      // It's already a full file path
      print("➡ Using full file path: $path");
    }
    // Check if it's just a filename (no slashes, might have .mp4 extension)
    else if (!path.contains('/') && !path.startsWith('content://')) {
      // It's just a filename, construct the full path
      // Remove .mp4 extension if present, we'll add it
      String fileName = path.replaceAll('.mp4', '');
      path = "/storage/emulated/0/Download/${fileName}.mp4";
      print("➡ Constructed path from filename: $path");
    }
    // App-specific path (e.g. Android 11+ cache dir) — use as-is
    else if (path.startsWith('/') && !path.startsWith('/storage')) {
      print("➡ Using app path: $path");
    }

    print("📥 Final Path: $path");

    try {
      // CASE 1: Android 10+ MediaStore URI
      if (path.startsWith("content://")) {
        print("➡ Using MediaStore URI");
        _controller = VideoPlayerController.contentUri(Uri.parse(path));
      }
      // CASE 2: File system path (/storage/emulated/0/… or app path e.g. /data/…/cache/…)
      else if (path.startsWith("/")) {
        File? videoFile;
        final file = File(path);
        print("➡ Checking file: ${file.path}");

        if (await file.exists()) {
          print("✔ File exists at provided path");
          videoFile = file;
        } else if (path.startsWith("/storage")) {
          // Try alternative locations only for legacy storage paths
          final fileName = path.split('/').last;
          final possiblePaths = [
            "/storage/emulated/0/Movies/VideoDownloader/$fileName",
            "/storage/emulated/0/Download/$fileName",
            path.replaceAll('/Movies/VideoDownloader/', '/Download/'),
            path.replaceAll('/Download/', '/Movies/VideoDownloader/'),
          ];
          for (String altPath in possiblePaths) {
            File altFile = File(altPath);
            if (await altFile.exists()) {
              print("✔ Found file at alternative location: $altPath");
              videoFile = altFile;
              break;
            }
          }
        }
        if (videoFile != null) {
          _controller = VideoPlayerController.file(videoFile);
        } else {
          print("❌ File not found at any location");
          return;
        }
      }
      // CASE 3: Fallback - try as content URI
      else {
        print("⚠ Unknown path type — trying contentUri");
        _controller = VideoPlayerController.contentUri(Uri.parse(path));
      }

      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play();

      setState(() => isReady = true);
    } catch (e) {
      print("❌ Video load error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: isReady
            ? AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

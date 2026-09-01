import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:videodownloader/screens/downloads/local_video_player_screen.dart';
import 'package:videodownloader/core/storage/local_database/database_helper.dart';

class WhatsappStatusSaverScreen extends StatefulWidget {
  const WhatsappStatusSaverScreen({super.key});

  @override
  State<WhatsappStatusSaverScreen> createState() =>
      _WhatsappStatusSaverScreenState();
}

class _WhatsappStatusSaverScreenState
    extends State<WhatsappStatusSaverScreen> {
  List<File> statusFiles = [];
  bool loading = true;
  Set<String> downloadedFiles = {};
  bool hasFolderAccess = false;
  String? selectedFolderUri;
  static const platform = MethodChannel('com.snapdock.videodownloader/folder');

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Check if we already have folder access
    final prefs = await SharedPreferences.getInstance();
    final savedUri = prefs.getString('whatsapp_folder_uri');
    
    if (savedUri != null && savedUri.isNotEmpty) {
      // We have saved URI, try to load files
      setState(() {
        selectedFolderUri = savedUri;
        hasFolderAccess = true;
        loading = true;
      });
      await _loadFilesFromUri(savedUri);
    } else {
      // No saved URI, show access request screen
      setState(() {
        loading = false;
        hasFolderAccess = false;
      });
    }
  }

  Future<void> _requestFolderAccess() async {
    try {
      setState(() {
        loading = true;
      });
      
      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening file manager to WhatsApp Status folder...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Open folder picker
      final String? uri = await platform.invokeMethod('openWhatsAppFolderPicker');
      
      if (uri != null && uri.isNotEmpty) {
        // Save the URI for future use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('whatsapp_folder_uri', uri);
        
        setState(() {
          selectedFolderUri = uri;
          hasFolderAccess = true;
        });
        
        // Load files from the granted URI
        await _loadFilesFromUri(uri);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ WhatsApp Status folder access granted!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Folder access not granted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      print("Failed to get folder access: ${e.message}");
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadFilesFromUri(String uri) async {
    try {
      final List<dynamic>? files = await platform.invokeMethod('listFilesInFolder', {'uri': uri});
      
      if (files != null && files.isNotEmpty) {
        setState(() {
          statusFiles = files.map((filePath) => File(filePath as String)).toList();
          loading = false;
        });
        
        // Check which files are already downloaded
        await _checkDownloadedFiles();
      } else {
        setState(() {
          statusFiles = [];
          loading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No status files found in the selected folder'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } on PlatformException catch (e) {
      print("Failed to load files: ${e.message}");
      setState(() {
        loading = false;
        statusFiles = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load files: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkDownloadedFiles() async {
    try {
      // Use the shared downloads database as the single source of truth
      // so that deletions from `downloadVideoScreen` are reflected here.
      final allDownloads = await LocalDB.instance.getAllDownloads();

      // Collect all file names that exist in the downloads table
      final Set<String> downloadedFileNames = {};
      for (final download in allDownloads) {
        final String videoPath = (download['videoPath'] ?? '') as String;
        final String imageUrl = (download['imageUrl'] ?? '') as String;

        if (videoPath.isNotEmpty) {
          downloadedFileNames.add(path.basename(videoPath));
        }
        if (imageUrl.isNotEmpty) {
          downloadedFileNames.add(path.basename(imageUrl));
        }
      }

      // Only keep entries that correspond to current WhatsApp status files
      final currentStatusNames =
          statusFiles.map((f) => path.basename(f.path)).toSet();
      final Set<String> downloaded = downloadedFileNames
          .intersection(currentStatusNames)
          .toSet();

      setState(() {
        downloadedFiles = downloaded;
      });
    } catch (e) {
      print("Error checking downloaded files: $e");
      // In case of error, don't modify existing UI state
    }
  }

  bool isVideo(String filePath) {
    String ext = path.extension(filePath).toLowerCase();
    return ext == '.mp4' || ext == '.mov' || ext == '.avi' || ext == '.mkv';
  }

  bool isImage(String filePath) {
    String ext = path.extension(filePath).toLowerCase();
    return ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.gif' || ext == '.webp';
  }

  Future<Directory> _getDownloadedDirectory() async {
    if (Platform.isAndroid) {
      final androidDir = Directory('/storage/emulated/0/Download');
      if (!await androidDir.exists()) {
        await androidDir.create(recursive: true);
      }
      return androidDir;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${documentsDir.path}/WhatsAppStatusDownloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  Future<String> _getDownloadedFilePath(String fileName) async {
    final downloadDir = await _getDownloadedDirectory();
    return '${downloadDir.path}/$fileName';
  }

  Future<void> _shareFile(File file) async {
    try {
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (isVideo(file.path)) {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'video/mp4')],
          text: 'Check out this WhatsApp status!',
        );
      } else if (isImage(file.path)) {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/jpeg')],
          text: 'Check out this WhatsApp status!',
        );
      } else {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out this WhatsApp status!',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFile(File file, int index) async {
    try {
      final fileName = path.basename(file.path);
      final downloadPath = await _getDownloadedFilePath(fileName);
      final downloadedFile = File(downloadPath);
      final isDownloaded = await downloadedFile.exists();

      bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Status'),
          content: Text(isDownloaded
              ? 'This will delete the downloaded copy from Downloads folder. The original WhatsApp status will remain.'
              : 'No downloaded copy found in Downloads folder.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            if (isDownloaded)
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      );

      if (confirm != true) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting downloaded copy...'),
          backgroundColor: Colors.blue,
        ),
      );

      if (await downloadedFile.exists()) {
        await downloadedFile.delete();
        
        try {
          final allDownloads = await LocalDB.instance.getAllDownloads();
          for (var download in allDownloads) {
            if (download['videoPath'] == downloadPath || 
                download['imageUrl'] == downloadPath) {
              await LocalDB.instance.deleteDownload(download['id']);
              break;
            }
          }
        } catch (e) {
          print('Error removing from database: $e');
        }
        
        // Update downloaded files set - REMOVE from downloadedFiles
        setState(() {
          downloadedFiles.remove(fileName);
        });
        
        // Show success message
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status deleted from Downloads successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No downloaded copy found to delete'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadFile(File file) async {
    try {
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final fileName = path.basename(file.path);
      final destinationPath = await _getDownloadedFilePath(fileName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading...'),
          backgroundColor: Colors.blue,
        ),
      );

      await file.copy(destinationPath);
      print("✅ Copied file to: $destinationPath");

      if (Platform.isAndroid) {
        if (isVideo(file.path)) {
          try {
            await MediaStore.ensureInitialized();
            MediaStore.appFolder = "VideoDownloader";
            final mediaStore = MediaStore();
            await mediaStore.saveFile(
              tempFilePath: destinationPath,
              dirType: DirType.video,
              dirName: DirName.movies,
            );
            print("✅ Saved video to MediaStore");
          } catch (mediaStoreError) {
            print("⚠️ MediaStore save error (file still saved): $mediaStoreError");
          }
        } else if (isImage(file.path)) {
          try {
            await MediaStore.ensureInitialized();
            MediaStore.appFolder = "VideoDownloader";
            final mediaStore = MediaStore();
            await mediaStore.saveFile(
              tempFilePath: destinationPath,
              dirType: DirType.photo,
              dirName: DirName.pictures,
            );
            print("✅ Saved image to MediaStore");
          } catch (mediaStoreError) {
            print("⚠️ MediaStore save error (file still saved): $mediaStoreError");
          }
        }
      }

      String imageUrl = '';
      if (isImage(file.path)) {
        imageUrl = destinationPath;
      }
      
      await LocalDB.instance.insertDownload(imageUrl, destinationPath);
      
      print("✅ Saved to DB - imageUrl: $imageUrl, videoPath: $destinationPath");

      // Update downloaded files set - ADD to downloadedFiles
      setState(() {
        downloadedFiles.add(fileName);
      });
      
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Platform.isAndroid
                ? '✅ Downloaded to Downloads/$fileName'
                : '✅ Downloaded to app storage/$fileName',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAccessRequestScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_open,
              size: 100,
              color: Color(0xFF25D366),
            ),
            const SizedBox(height: 30),
            const Text(
              'Access WhatsApp Status Folder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'To save WhatsApp statuses, please grant access to the WhatsApp status folder.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFF25D366).withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Text(
                    '📁 Folder Location:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF25D366),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF075E54),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '⚠️ Tap "Use this folder" button in file manager',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _requestFolderAccess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF25D366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Grant Folder Access',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              '🔍 The file manager will open automatically',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '👉 Navigate to WhatsApp/.Statuses folder\n👉 Tap "Use this folder" button',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Status Saver'),
        centerTitle: true,
        backgroundColor: Color(0xFF25D366),
        actions: [
          if (hasFolderAccess && statusFiles.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  loading = true;
                });
                if (selectedFolderUri != null) {
                  _loadFilesFromUri(selectedFolderUri!);
                } else {
                  _initialize();
                }
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
            ),
          if (hasFolderAccess)
            IconButton(
              onPressed: _requestFolderAccess,
              icon: const Icon(Icons.folder_open, color: Colors.white),
              tooltip: 'Change Folder',
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF25D366)),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading WhatsApp statuses...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : !hasFolderAccess
              ? _buildAccessRequestScreen()
              : statusFiles.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.folder_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No WhatsApp statuses found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Make sure you have WhatsApp statuses saved.\nThey appear here only for 24 hours.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _requestFolderAccess,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF25D366),
                              ),
                              child: const Text('Open WhatsApp Folder Again'),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                // Clear saved URI and show access screen again
                                SharedPreferences.getInstance().then((prefs) {
                                  prefs.remove('whatsapp_folder_uri');
                                  setState(() {
                                    hasFolderAccess = false;
                                  });
                                });
                              },
                              child: const Text('Change Folder Location'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Color(0xFF25D366).withOpacity(0.1),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF25D366), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '✅ WhatsApp Status Access Granted',
                                      style: TextStyle(
                                        color: Color(0xFF075E54),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Found ${statusFiles.length} statuses',
                                      style: const TextStyle(
                                        color: Color(0xFF128C7E),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _requestFolderAccess,
                                icon: const Icon(Icons.edit, size: 20),
                                color: Color(0xFF25D366),
                                tooltip: 'Change Folder',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: statusFiles.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.8,
                            ),
                            itemBuilder: (context, index) {
                              final file = statusFiles[index];
                              final fileName = path.basename(file.path);
                              final isDownloaded = downloadedFiles.contains(fileName);
                              final bool isVideoFile = isVideo(file.path);

                              return GestureDetector(
                                onTap: () {
                                  // Always open the original file from WhatsApp folder
                                  if (isVideoFile) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LocalVideoPlayerScreen(videoPath: file.path),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Scaffold(
                                          appBar: AppBar(
                                            backgroundColor: Color(0xFF25D366),
                                            title: const Text('WhatsApp Status'),
                                          ),
                                          body: Center(
                                            child: Image.file(
                                              file,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 40,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                onLongPress: () {
                                  // Show options on long press
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.share, color: Color(0xFF25D366)),
                                              title: const Text('Share'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _shareFile(file);
                                              },
                                            ),
                                            if (isDownloaded)
                                              ListTile(
                                                leading: const Icon(Icons.delete, color: Colors.red),
                                                title: const Text('Delete Downloaded'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _deleteFile(file, index);
                                                },
                                              ),
                                            const SizedBox(height: 10),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.grey[200],
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        isVideoFile
                                            ? _VideoThumbnailWidget(videoPath: file.path)
                                            : Image.file(
                                                file,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                        size: 40,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                        if (!isDownloaded)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => _downloadFile(file),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF25D366).withOpacity(0.8),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.download,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (isVideoFile)
                                          const Positioned.fill(
                                            child: Center(
                                              child: Icon(
                                                Icons.play_circle_fill,
                                                color: Colors.white,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                        // Removed the bottom action buttons as requested
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;

  const _VideoThumbnailWidget({required this.videoPath});

  @override
  State<_VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<_VideoThumbnailWidget> {
  String? _thumbnailPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: widget.videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );

      if (mounted && thumbnail != null) {
        setState(() {
          _thumbnailPath = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black26,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_thumbnailPath == null) {
      return Container(
        color: Colors.black26,
        child: const Center(
          child: Icon(
            Icons.videocam,
            color: Colors.white,
            size: 40,
          ),
        ),
      );
    }

    return Image.file(
      File(_thumbnailPath!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.black26,
          child: const Center(
            child: Icon(
              Icons.videocam,
              color: Colors.white,
              size: 40,
            ),
          ),
        );
      },
    );
  }
}


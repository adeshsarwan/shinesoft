import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:videodownloader/l10n/app_localizations.dart';
import 'package:videodownloader/screens/downloads/local_video_player_screen.dart';
import 'package:videodownloader/core/storage/local_database/database_helper.dart';
import 'package:videodownloader/services/models/download_video_model/download_video_model.dart';

class DownloadedVideoScreen extends StatefulWidget {
  DownloadedVideoScreen({super.key});
  @override
  State<DownloadedVideoScreen> createState() => _DownloadedVideoScreenState();
}

class _DownloadedVideoScreenState extends State<DownloadedVideoScreen> {
  int selectedTab = 0;
  List<DownloadVideoItem> items = [];
  List<DownloadVideoItem> favoriteItems = [];
  bool isLoading = true;
  bool hasError = false;
  bool showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (kReleaseMode) {
      debugPrint('Running in RELEASE mode');
    } else {
      debugPrint('Running in DEBUG mode');
    }
    
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });
      
      await _getAllVideoDownloads();
      await _getFavoriteVideos();
      
      setState(() {
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error fetching downloads: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _getAllVideoDownloads() async {
    try {
      List<Map<String, dynamic>> records = await LocalDB.instance.getAllDownloads();
      
      debugPrint("Fetched ${records.length} records from database");
      
      setState(() {
        items.clear();
        for (var row in records) {
          try {
            final model = DownloadVideoItem.fromJson(row);
            items.add(model);
            debugPrint("Parsed item - ID: ${model.id}, Favorite: ${model.isFavorite}");
          } catch (e) {
            debugPrint('Error parsing record: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching all downloads: $e');
      rethrow;
    }
  }

  Future<void> _getFavoriteVideos() async {
    try {
      List<Map<String, dynamic>> records = await LocalDB.instance.getFavoriteDownloads();
      
      debugPrint("Fetched ${records.length} favorite records from database");
      
      setState(() {
        favoriteItems.clear();
        for (var row in records) {
          try {
            final model = DownloadVideoItem.fromJson(row);
            favoriteItems.add(model);
          } catch (e) {
            debugPrint('Error parsing favorite record: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(DownloadVideoItem item, int index) async {
    try {
      bool newFavoriteStatus = !item.isFavorite;
      
      // Update in database
      int result = await LocalDB.instance.toggleFavorite(item.id, newFavoriteStatus);
      debugPrint("Toggled favorite status, result: $result");
      
      if (result > 0) {
        // Update local state
        setState(() {
          // Update in main items list
          items[index] = items[index].copyWith(isFavorite: newFavoriteStatus);
          
          // Update in favorite list
          if (newFavoriteStatus) {
            favoriteItems.add(item.copyWith(isFavorite: true));
          } else {
            favoriteItems.removeWhere((favItem) => favItem.id == item.id);
          }
        });
        
        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newFavoriteStatus ? 
              'Added to favorites' : 
              'Removed from favorites'),
            backgroundColor: newFavoriteStatus ? Colors.green : Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error toggling favorite: $e');
      debugPrint('Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> deleteVideo(DownloadVideoItem item, int index) async {
    try {
      bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Video'),
          content: Text('Are you sure you want to delete this video?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleting video...'),
          backgroundColor: Colors.blue,
        ),
      );

      int result = await LocalDB.instance.deleteDownload(item.id);
      debugPrint("Deleted from DB, result: $result");

      bool fileDeleted = await deleteVideoFile(item.videoPath);
      
      if (!fileDeleted) {
        debugPrint("Warning: Could not delete video file from storage");
      }

      setState(() {
        items.removeAt(index);
        favoriteItems.removeWhere((favItem) => favItem.id == item.id);
      });

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e, stackTrace) {
      debugPrint('Error deleting video: $e');
      debugPrint('Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete video: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> deleteVideoFile(String videoPath) async {
    try {
      debugPrint("🗑️ Attempting to delete video file: $videoPath");
      
      // Use the same path finding logic as share functionality
      String? actualVideoPath = await _findActualVideoPath(videoPath);
      
      if (actualVideoPath == null) {
        debugPrint("❌ Could not find video file to delete");
        return false;
      }
      
      debugPrint("📍 Found video file at: $actualVideoPath");
      
      // For content:// URIs, we need to use MediaStore to delete
      if (actualVideoPath.startsWith('content://')) {
        debugPrint("⚠️ Cannot delete content:// URI directly, skipping file deletion");
        // Content URIs are managed by MediaStore, deletion might require special handling
        return false;
      }
      
      // Delete the actual file
      try {
        File file = File(actualVideoPath);
        if (await file.exists()) {
          await file.delete();
          debugPrint("✅ Successfully deleted file at: $actualVideoPath");
          return true;
        } else {
          debugPrint("❌ File does not exist at: $actualVideoPath");
          return false;
        }
      } catch (e) {
        debugPrint("❌ Error deleting file: $e");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error in deleteVideoFile: $e");
      return false;
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(),
              const SizedBox(height: 32),
              // Collection Grid
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 50),
            SizedBox(height: 16),
            Text(
              'Failed to load videos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    List<DownloadVideoItem> currentList = showFavoritesOnly ? favoriteItems : items;
    
    if (currentList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showFavoritesOnly ? 
                Icons.favorite_border : 
                Icons.video_library_outlined, 
              size: 60, 
              color: Colors.grey[300]
            ),
            SizedBox(height: 16),
            Text(
              showFavoritesOnly ? 
                'No favorite videos yet' : 
                'No downloaded videos yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return _buildCollectionGrid(currentList);
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        customTabs()
      ],
    );
  }

  Widget customTabs() {
    List<String> tabs = ["download", "video", "photo", "collection"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ...List.generate(tabs.length, (index) {
              bool isSelected = selectedTab == index;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTab = index;
                      showFavoritesOnly = (index == 3);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [
                                Color(0xff6553A3),
                                Color(0xff9451A0),
                                Color(0xffC94B9B),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected ? null : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.black38,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate(tabs[index]),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(width: 12),

            // Add button with subtle border
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Container(
                height: 32,
                width: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xffC94B9B),
                      Color(0xffEE346B),
                      Color(0xffF15C22),
                    ],
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionGrid(List<DownloadVideoItem> itemList) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: itemList.length,
      itemBuilder: (context, index) {
        final item = itemList[index];
        return _CollectionItem(
          key: ValueKey(item.id),
          index: index,
          isSelected: index % 3 == 0,
          item: item,
          onTap: () async {
            final videoPath = item.videoPath;
            if (videoPath.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File not found'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            final actualPath = await _findActualVideoPath(videoPath) ?? videoPath;
            final isImage = actualPath.toLowerCase().endsWith('.jpg') ||
                actualPath.toLowerCase().endsWith('.jpeg') ||
                actualPath.toLowerCase().endsWith('.png') ||
                actualPath.toLowerCase().endsWith('.gif') ||
                actualPath.toLowerCase().endsWith('.webp');
            if (isImage) {
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewerScreen(imagePath: actualPath),
                ),
              );
            } else {
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocalVideoPlayerScreen(videoPath: actualPath),
                ),
              );
            }
          },
          onFavorite: () {
            int mainIndex = items.indexWhere((i) => i.id == item.id);
            if (mainIndex != -1) {
              toggleFavorite(item, mainIndex);
            }
          },
          onDelete: () {
            int mainIndex = items.indexWhere((i) => i.id == item.id);
            if (mainIndex != -1) {
              deleteVideo(item, mainIndex);
            } else {
              deleteVideo(item, index);
            }
          },
          showFavoritesOnly: showFavoritesOnly,
          findVideoPath: _findActualVideoPath,
        );
      },
    );
  }

  Future<String?> _findActualVideoPath(String storedPath) async {
    try {
      print("🔍 Looking for video with stored path: $storedPath");
      
      // Clean the path - remove any extra content:// URI or SaveInfo text if present
      String cleanPath = storedPath.trim();
      if (cleanPath.contains('content://')) {
        // Extract content:// URI if present
        final uriMatch = RegExp(r'content://[^\s]+').firstMatch(cleanPath);
        if (uriMatch != null) {
          cleanPath = uriMatch.group(0)!;
          print("➡ Extracted content URI: $cleanPath");
          // For content:// URIs, return as-is (they should work directly)
          return cleanPath;
        }
      }
      
      // First, check if the stored path is already a full file path.
      // Using `startsWith('/')` makes this work for iOS absolute paths too.
      if (cleanPath.startsWith('/')) {
        print("➡ Stored path appears to be a full file path");
        final file = File(cleanPath);
        if (await file.exists()) {
          print("✅ Found file at stored path: $cleanPath");
          return cleanPath;
        }

        // If path has .mp4, also try without it (or vice versa)
        if (cleanPath.endsWith('.mp4')) {
          final pathWithoutExt = cleanPath.replaceAll('.mp4', '');
          final altFile = File(pathWithoutExt);
          if (await altFile.exists()) {
            print("✅ Found file without .mp4 extension: $pathWithoutExt");
            return pathWithoutExt;
          }
        } else {
          final pathWithExt = '$cleanPath.mp4';
          final altFile = File(pathWithExt);
          if (await altFile.exists()) {
            print("✅ Found file with .mp4 extension: $pathWithExt");
            return pathWithExt;
          }
        }
      }
      
      // Extract filename (keep extension for images)
      String fileName = cleanPath.contains('/') 
          ? cleanPath.split('/').last 
          : cleanPath;
      final isLikelyImage = fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png') ||
          fileName.toLowerCase().endsWith('.gif') ||
          fileName.toLowerCase().endsWith('.webp');
      final String fileNameNoMp4 = fileName.endsWith('.mp4') 
          ? fileName.replaceAll('.mp4', '') 
          : fileName;
      
      final possiblePaths = [
        cleanPath,
        if (!isLikelyImage) '$cleanPath.mp4',
        '/storage/emulated/0/Download/$fileName',
        '/storage/emulated/0/Download/$fileNameNoMp4.mp4',
        '/storage/emulated/0/Download/$fileNameNoMp4',
        '/storage/emulated/0/Movies/VideoDownloader/$fileName',
        '/storage/emulated/0/Movies/VideoDownloader/$fileNameNoMp4.mp4',
        '/storage/emulated/0/Movies/VideoDownloader/$fileNameNoMp4',
        '/storage/emulated/0/Pictures/VideoDownloader/$fileName',
        '/storage/emulated/0/Pictures/VideoDownloader/$fileNameNoMp4.mp4',
      ];
      
      for (String path in possiblePaths) {
        print("🔍 Checking path: $path");
        File file = File(path);
        if (await file.exists()) {
          print("✅ Found file at: $path");
          return path;
        }
      }
      
      print("❌ Video file not found at any location");
      return null;
      
    } catch (e) {
      print("❌ Error finding video path: $e");
      return null;
    }
  }
}

class _CollectionItem extends StatelessWidget {
  final int index;
  final bool isSelected;
  final DownloadVideoItem item;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;
  final bool showFavoritesOnly;
  final Future<String?> Function(String)? findVideoPath;
  
  const _CollectionItem({
    super.key,
    required this.index,
    required this.isSelected,
    required this.item,
    required this.onTap,
    this.onFavorite,
    this.onDelete,
    this.showFavoritesOnly = false,
    this.findVideoPath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Thumbnail with proper error handling (resolve path so status images load)
              _VideoThumbnailWidget(
                imageUrl: item.imageUrl,
                videoPath: item.videoPath,
                fallbackColor: _getThumbnailColor(index),
                findMediaPath: findVideoPath,
              ),
              
              // Favorite indicator
              if (item.isFavorite)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              
              // Share/Options button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    showActionPopup(context);
                    print("Share icon tapped!");
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      "assets/images/shareIcon.png",
                      width: 28,
                      height: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getThumbnailColor(int index) {
    final colors = [
      const Color(0xFF667EEA),
      const Color(0xFF764BA2),
      const Color(0xFFF093FB),
      const Color(0xFFF5576C),
      const Color(0xFF4FACFE),
      const Color(0xFF00F2FE),
    ];
    return colors[index % colors.length];
  }

  Widget _popupItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Gradient Icon Circle
            Container(
              width: 36,
              height: 36,
              child: Center(
                child: Image.asset(
                  icon,
                  width: 30,
                  height: 30,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showActionPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _popupItem(
                icon: "assets/menuicon/shareic.png",
                title: 'Share',
                onTap: () {
                  Navigator.pop(context);
                  _shareVideo(context);
                },
              ),
              _popupItem(
                icon: "assets/menuicon/favorite.png",
                title: item.isFavorite ? 'Remove Favorite' : 'Add to Favorite',
                onTap: () {
                  Navigator.pop(context);
                  onFavorite?.call();
                },
              ),
              //   _popupItem(
              //   icon: "assets/menuicon/repostic.png",
              //   title: "Re Post",
              //   onTap: () {
              //     Navigator.pop(context);
              //   },
              // ),
              _popupItem(
                icon: "assets/menuicon/deleteic.png",
                title: 'Delete',
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ],
          ),
        ));
      },
    );
  }

  Future<void> _shareVideo(BuildContext context) async {
    try {
      print("Attempting to share video for item ID: ${item.id}");
      print("Video path from DB: ${item.videoPath}");
      
      if (item.videoPath.isEmpty) {
        print("Video path is null or empty");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video file path not found in database'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check multiple possible locations for the file
      String? actualVideoPath;
      if (findVideoPath != null) {
        actualVideoPath = await findVideoPath!(item.videoPath);
      } else {
        // Fallback: try to find path directly
        actualVideoPath = item.videoPath;
      }
      
      if (actualVideoPath == null) {
        print("Could not find video file at any location");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video file not found. It may have been moved or deleted.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // For content:// URIs, we don't need to check file existence
      File? videoFile;
      if (!actualVideoPath.startsWith('content://')) {
        videoFile = File(actualVideoPath);
        
        // Check if file exists
        if (!await videoFile.exists()) {
          print("File does not exist at path: $actualVideoPath");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video file not found on device'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      print("Found video file at: $actualVideoPath");
      
      // Handle content:// URIs differently
      List<XFile> files;
      if (actualVideoPath.startsWith('content://')) {
        // For content:// URIs, use the URI directly
        files = [XFile(actualVideoPath, mimeType: 'video/mp4')];
      } else {
        // For file paths, check if file exists and get size
        if (videoFile == null || !await videoFile.exists()) {
          print("File does not exist at path: $actualVideoPath");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video file not found on device'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        print("File size: ${await videoFile.length()} bytes");
        files = [XFile(videoFile.path, mimeType: 'video/mp4')];
      }
      
      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preparing to share...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      // Share the video file using share_plus
      await Share.shareXFiles(
        files,
        text: 'Check out this video!', // Optional message
        subject: 'Video Shared from App', // Optional subject
      );

      print("Share dialog opened successfully");

    } catch (e, stackTrace) {
      print('Error sharing video: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Widget to display video thumbnail - uses network image if available, otherwise generates from video file
class _VideoThumbnailWidget extends StatefulWidget {
  final String? imageUrl;
  final String videoPath;
  final Color fallbackColor;
  final Future<String?> Function(String)? findMediaPath;

  const _VideoThumbnailWidget({
    required this.imageUrl,
    required this.videoPath,
    required this.fallbackColor,
    this.findMediaPath,
  });

  @override
  State<_VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<_VideoThumbnailWidget> {
  VideoPlayerController? _thumbnailController;
  bool _isThumbnailReady = false;
  String? _resolvedImagePath;
  bool _imageResolveDone = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      final imageUrl = widget.imageUrl!;
      final isLocal = imageUrl.startsWith('/storage') ||
          imageUrl.startsWith('/data') ||
          imageUrl.startsWith('file://') ||
          (imageUrl.startsWith('/') && !imageUrl.startsWith('http'));
      if (isLocal) {
        _resolveImagePath(imageUrl);
        return;
      }
    }
    _loadVideoThumbnail();
  }

  Future<void> _resolveImagePath(String imageUrl) async {
    final resolved = widget.findMediaPath != null
        ? await widget.findMediaPath!(imageUrl)
        : await _findVideoPath(imageUrl);
    if (mounted) {
      setState(() {
        _resolvedImagePath = resolved;
        _imageResolveDone = true;
      });
    }
  }

  Future<void> _loadVideoThumbnail() async {
    try {
      debugPrint("🖼️ Loading thumbnail for video: ${widget.videoPath}");
      
      // Use the same path finding logic as _findActualVideoPath
      String? actualVideoPath = await _findVideoPath(widget.videoPath);
      
      if (actualVideoPath == null || actualVideoPath.isEmpty) {
        debugPrint("❌ Could not find video path for thumbnail");
        return;
      }
      
      debugPrint("📍 Found video path for thumbnail: $actualVideoPath");
      
      late final VideoPlayerController controller;
      if (actualVideoPath.startsWith('content://')) {
        controller = VideoPlayerController.contentUri(Uri.parse(actualVideoPath));
      } else {
        final file = File(actualVideoPath);
        if (!(await file.exists())) {
          debugPrint("❌ Video file does not exist: $actualVideoPath");
          return;
        }
        controller = VideoPlayerController.file(file);
      }

      await controller.initialize();
      await controller.seekTo(Duration.zero);
      controller.setVolume(0);
      controller.pause();

      if (mounted) {
        setState(() {
          _thumbnailController = controller;
          _isThumbnailReady = true;
        });
        debugPrint("✅ Thumbnail loaded successfully");
      }
    } catch (e) {
      debugPrint('❌ Error loading video thumbnail: $e');
    }
  }

  // Helper method to find video path (same logic as _findActualVideoPath)
  Future<String?> _findVideoPath(String storedPath) async {
    try {
      // Clean the path - remove any extra content:// URI or SaveInfo text if present
      String cleanPath = storedPath.trim();
      if (cleanPath.contains('content://')) {
        // Extract content:// URI if present
        final uriMatch = RegExp(r'content://[^\s]+').firstMatch(cleanPath);
        if (uriMatch != null) {
          cleanPath = uriMatch.group(0)!;
          return cleanPath;
        }
      }
      
      // First, check if the stored path is already a full file path.
      // This also covers iOS absolute paths like /var/mobile/Containers/...
      if (cleanPath.startsWith('/')) {
        final file = File(cleanPath);
        if (await file.exists()) {
          return cleanPath;
        }

        // If path has .mp4, also try without it (or vice versa)
        if (cleanPath.endsWith('.mp4')) {
          final pathWithoutExt = cleanPath.replaceAll('.mp4', '');
          final altFile = File(pathWithoutExt);
          if (await altFile.exists()) {
            return pathWithoutExt;
          }
        } else {
          final pathWithExt = '$cleanPath.mp4';
          final altFile = File(pathWithExt);
          if (await altFile.exists()) {
            return pathWithExt;
          }
        }
      }
      
      // Extract filename (keep extension for images)
      String fileName = cleanPath.contains('/')
          ? cleanPath.split('/').last
          : cleanPath;
      final isLikelyImage = fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png') ||
          fileName.toLowerCase().endsWith('.gif') ||
          fileName.toLowerCase().endsWith('.webp');
      final String fileNameNoMp4 = fileName.endsWith('.mp4')
          ? fileName.replaceAll('.mp4', '')
          : fileName;

      final possiblePaths = [
        cleanPath,
        if (!isLikelyImage) '$cleanPath.mp4',
        '/storage/emulated/0/Download/$fileName',
        '/storage/emulated/0/Download/$fileNameNoMp4.mp4',
        '/storage/emulated/0/Download/$fileNameNoMp4',
        '/storage/emulated/0/Movies/VideoDownloader/$fileName',
        '/storage/emulated/0/Movies/VideoDownloader/$fileNameNoMp4.mp4',
        '/storage/emulated/0/Movies/VideoDownloader/$fileNameNoMp4',
        '/storage/emulated/0/Pictures/VideoDownloader/$fileName',
        '/storage/emulated/0/Pictures/VideoDownloader/$fileNameNoMp4.mp4',
      ];

      for (String path in possiblePaths) {
        File file = File(path);
        if (await file.exists()) {
          return path;
        }
      }

      return null;
    } catch (e) {
      debugPrint("Error finding video path: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _thumbnailController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If we have an image URL (local file), use resolved path so status images load
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      final imageUrl = widget.imageUrl!;
      final isLocalFile = imageUrl.startsWith('/') &&
          !imageUrl.startsWith('http') &&
          !imageUrl.startsWith('https') ||
          imageUrl.startsWith('file://');

      if (isLocalFile) {
        if (!_imageResolveDone) {
          return _buildFallbackThumbnail();
        }
        final pathToUse = _resolvedImagePath ?? imageUrl.replaceFirst('file://', '');
        if (pathToUse.isEmpty) return _buildFallbackThumbnail();
        return Image.file(
          File(pathToUse),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("❌ Error loading local image: $error");
            return _buildFallbackThumbnail();
          },
        );
      }
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: widget.fallbackColor,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
      );
    }

    // If we have a video thumbnail ready, show it
    if (_isThumbnailReady && _thumbnailController != null && _thumbnailController!.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _thumbnailController!.value.size.width,
            height: _thumbnailController!.value.size.height,
            child: VideoPlayer(_thumbnailController!),
          ),
        ),
      );
    }

    // Fallback: show placeholder
    return _buildFallbackThumbnail();
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      color: widget.fallbackColor,
      child: Center(
        child: Icon(
          Icons.videocam_outlined,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Image viewer screen for displaying images
class ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  
  const ImageViewerScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 50),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}



class DownloadVideoItem {
  final int id;
  final String imageUrl;
  final String videoPath;
  final DateTime createdAt;
  final bool isFavorite;

  DownloadVideoItem({
    required this.id,
    required this.imageUrl,
    required this.videoPath,
    required this.createdAt,
    required this.isFavorite,
  });

  factory DownloadVideoItem.fromJson(Map<String, dynamic> json) {
    return DownloadVideoItem(
      id: json["id"],
      imageUrl: json["imageUrl"] ?? "",
      videoPath: json["videoPath"] ?? "",
      createdAt: DateTime.parse(json["createdAt"]),
      isFavorite: (json["isFavorite"] ?? 0) == 1,
    );
  }

  // Helper method to copy with new favorite status
  DownloadVideoItem copyWith({
    bool? isFavorite,
  }) {
    return DownloadVideoItem(
      id: id,
      imageUrl: imageUrl,
      videoPath: videoPath,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
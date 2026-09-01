class InstagramDownloadResponse {
  final String message;
  final String shortcode;
   List<String> s3Files;

  InstagramDownloadResponse({
    required this.message,
    required this.shortcode,
    required this.s3Files,
  });

  factory InstagramDownloadResponse.fromJson(Map<String, dynamic> json) {
    return InstagramDownloadResponse(
      message: json['message'] ?? '',
      shortcode: json['shortcode'] ?? '',
      s3Files: List<String>.from(json['downloads'] ?? json['s3_files'] ?? []),
    );
  }
}
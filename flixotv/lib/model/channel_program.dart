class ChannelProgram {
  const ChannelProgram({
    required this.showId,
    required this.showTitle,
    required this.programStartTime,
    required this.programEndTime,
  });

  final String showId;
  final String showTitle;
  final String programStartTime;
  final String programEndTime;

  factory ChannelProgram.fromJson(Map<String, dynamic> json) {
    return ChannelProgram(
      showId: _string(json['showId'] ?? json['_id'] ?? json['id']),
      showTitle: _string(json['showTitle'] ?? json['title'] ?? json['name']),
      programStartTime: _string(
        json['programStartTime'] ?? json['startTime'] ?? json['start'],
      ),
      programEndTime: _string(
        json['programEndTime'] ?? json['endTime'] ?? json['end'],
      ),
    );
  }

  bool get isValid =>
      showId.isNotEmpty &&
      showTitle.isNotEmpty &&
      programStartTime.isNotEmpty &&
      programEndTime.isNotEmpty;

  static String _string(Object? value) => value?.toString().trim() ?? '';
}

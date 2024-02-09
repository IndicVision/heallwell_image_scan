class VideoMetadata {
  final String title;
  final String description;

  VideoMetadata({required this.title, required this.description});

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
      };
}

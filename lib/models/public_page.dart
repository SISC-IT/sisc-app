class PublicPageInfo {
  PublicPageInfo({
    required this.title,
    required this.contentText,
    required this.contentHtml,
    required this.publishedAt,
  });

  factory PublicPageInfo.fromJson(Map<String, dynamic> json) {
    return PublicPageInfo(
      title: json['title'] as String? ?? '',
      contentText: json['contentText'] as String?,
      contentHtml: json['contentHtml'] as String?,
      publishedAt: json['publishedAt'] as String?,
    );
  }

  final String title;
  final String? contentText;
  final String? contentHtml;
  final String? publishedAt;
}

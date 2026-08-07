class FeedbackItem {
  FeedbackItem({required this.feedbackId, required this.content, required this.createdDate});

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      feedbackId: json['feedbackId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdDate: json['createdDate'] as String? ?? '',
    );
  }

  final String feedbackId;
  final String content;
  final String createdDate;
}

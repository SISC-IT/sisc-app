class BoardInfo {
  BoardInfo({required this.boardId, required this.boardName, this.parentBoardId});

  factory BoardInfo.fromJson(Map<String, dynamic> json) {
    return BoardInfo(
      boardId: json['boardId'] as String,
      boardName: json['boardName'] as String? ?? '',
      parentBoardId: json['parentBoardId'] as String?,
    );
  }

  final String boardId;
  final String boardName;
  final String? parentBoardId;
}

import 'package:flutter/material.dart';

import '../../api/board_api.dart';
import '../../core/api_client.dart';
import '../../models/board.dart';
import '../../models/post.dart';
import '../../state/auth_state.dart';
import '../../widgets/glass_bottom_nav_bar.dart';
import 'post_detail_screen.dart';
import 'post_write_screen.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.authState});

  final AuthState authState;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> with TickerProviderStateMixin {
  final _boardApi = BoardApi(ApiClient.instance);
  final _searchController = TextEditingController();

  List<BoardInfo> _selectableBoards = [];
  List<BoardInfo> _parents = [];
  BoardInfo? _selectedBoard;
  TabController? _tabController;
  final List<PostItem> _posts = [];
  int _page = 0;
  bool _last = true;
  bool _loadingBoards = true;
  bool _loadingPosts = false;
  bool _loadingMore = false;
  String? _errorMessage;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadBoards() async {
    setState(() {
      _loadingBoards = true;
      _errorMessage = null;
    });
    try {
      final parents = await _boardApi.getParentBoards();
      final children = await _boardApi.getChildBoards();
      final parentIdsWithChildren = children
          .map((c) => c.parentBoardId)
          .whereType<String>()
          .toSet();
      final leafBoards = <BoardInfo>[
        ...parents.where((p) => !parentIdsWithChildren.contains(p.boardId)),
        ...children,
      ];
      setState(() {
        _selectableBoards = leafBoards;
        _parents = parents;
        _selectedBoard = null;
        _tabController?.dispose();
        _tabController = leafBoards.isEmpty
            ? null
            : TabController(length: leafBoards.length + 1, vsync: this);
      });
      if (leafBoards.isNotEmpty) {
        await _loadPosts();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loadingBoards = false);
    }
  }

  Future<void> _loadPosts() async {
    final board = _selectedBoard;
    setState(() {
      _loadingPosts = true;
      _errorMessage = null;
      _searching = false;
    });
    try {
      if (board == null) {
        final responses = await Future.wait(
          _selectableBoards.map((b) => _boardApi.getPosts(boardId: b.boardId, pageNumber: 0)),
        );
        final merged = <PostItem>[for (final r in responses) ...r.content]
          ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
        setState(() {
          _posts
            ..clear()
            ..addAll(merged);
          _page = 0;
          _last = true;
        });
      } else {
        final result = await _boardApi.getPosts(boardId: board.boardId, pageNumber: 0);
        setState(() {
          _posts
            ..clear()
            ..addAll(result.content);
          _page = 0;
          _last = result.last;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _loadMore() async {
    final board = _selectedBoard;
    if (board == null || _loadingMore || _last || _searching) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await _boardApi.getPosts(boardId: board.boardId, pageNumber: nextPage);
      setState(() {
        _posts.addAll(result.content);
        _page = nextPage;
        _last = result.last;
      });
    } catch (_) {
      // 무시하고 재시도 가능하게 둔다.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _search(String keyword) async {
    final board = _selectedBoard;
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      _loadPosts();
      return;
    }
    setState(() {
      _loadingPosts = true;
      _errorMessage = null;
      _searching = true;
    });
    try {
      if (board == null) {
        final responses = await Future.wait(
          _selectableBoards.map((b) => _boardApi.searchPosts(boardId: b.boardId, keyword: trimmed)),
        );
        final merged = <PostItem>[for (final r in responses) ...r.content]
          ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
        setState(() {
          _posts
            ..clear()
            ..addAll(merged);
          _last = true;
        });
      } else {
        final result = await _boardApi.searchPosts(boardId: board.boardId, keyword: trimmed);
        setState(() {
          _posts
            ..clear()
            ..addAll(result.content);
          _last = true;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  void _selectBoard(BoardInfo? board) {
    if (board?.boardId == _selectedBoard?.boardId) return;
    setState(() {
      _selectedBoard = board;
      _searchController.clear();
    });
    _loadPosts();
  }

  Future<void> _openWrite() async {
    final board = _selectedBoard;
    if (board == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostWriteScreen(
          boards: _selectableBoards,
          initialBoard: board,
        ),
      ),
    );
    if (created == true) {
      _loadPosts();
    }
  }

  Future<void> _manageBoards() async {
    String? newBoardName;
    BoardInfo? newBoardParent;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('게시판 관리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: '새 게시판 이름'),
                onChanged: (v) => newBoardName = v,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<BoardInfo?>(
                initialValue: newBoardParent,
                decoration: const InputDecoration(labelText: '상위 게시판 (없으면 최상위)'),
                items: [
                  const DropdownMenuItem<BoardInfo?>(value: null, child: Text('없음 (최상위)')),
                  ..._parents.map((p) => DropdownMenuItem(value: p, child: Text(p.boardName))),
                ],
                onChanged: (v) => setSheetState(() => newBoardParent = v),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  if (newBoardName == null || newBoardName!.trim().isEmpty) return;
                  try {
                    await _boardApi.createBoard(
                      boardName: newBoardName!.trim(),
                      parentBoardId: newBoardParent?.boardId,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                    _loadBoards();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('게시판 생성'),
              ),
              const Divider(height: 32),
              const Text('게시판 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
              ...[..._parents, ..._selectableBoards.where((b) => !_parents.contains(b))].map(
                (board) => ListTile(
                  title: Text(board.boardName),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('게시판 삭제'),
                          content: Text('"${board.boardName}" 게시판과 모든 게시글을 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('삭제', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        await _boardApi.deleteBoard(board.boardId);
                        if (context.mounted) Navigator.of(context).pop();
                        _loadBoards();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시판'),
        actions: [
          if (widget.authState.userInfo?.isAdmin ?? false)
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: _manageBoards),
        ],
      ),
      floatingActionButton: _selectedBoard == null
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: glassBottomBarClearance(context) - 16),
              child: FloatingActionButton(
                onPressed: _openWrite,
                child: const Icon(Icons.edit),
              ),
            ),
      body: _loadingBoards
          ? const Center(child: CircularProgressIndicator())
          : _selectableBoards.isEmpty
          ? const Center(child: Text('게시판이 없습니다.'))
          : Column(
              children: [
                TabBar(
                  controller: _tabController!,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.white60,
                  onTap: (index) =>
                      _selectBoard(index == 0 ? null : _selectableBoards[index - 1]),
                  tabs: [
                    const Tab(text: '전체'),
                    for (final board in _selectableBoards) Tab(text: board.boardName),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '검색어를 입력하세요',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onSubmitted: _search,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPosts,
                    child: _loadingPosts
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text('불러오기에 실패했습니다: $_errorMessage'),
                              ),
                            ],
                          )
                        : _posts.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('게시글이 없습니다.'),
                              ),
                            ],
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.pixels >=
                                  notification.metrics.maxScrollExtent - 200) {
                                _loadMore();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              padding: EdgeInsets.only(bottom: glassBottomBarClearance(context)),
                              itemCount: _posts.length + (_last ? 0 : 1),
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                if (index >= _posts.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final post = _posts[index];
                                return ListTile(
                                  title: Text(
                                    post.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    post.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: SizedBox(
                                    width: 72,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          post.userName,
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
                                            const SizedBox(width: 2),
                                            Text('${post.likeCount}', style: const TextStyle(fontSize: 12)),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.comment, size: 12),
                                            const SizedBox(width: 2),
                                            Text('${post.commentCount}', style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () async {
                                    final changed = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => PostDetailScreen(
                                          postId: post.postId,
                                          boards: _selectableBoards,
                                          authState: widget.authState,
                                        ),
                                      ),
                                    );
                                    if (changed == true) {
                                      _loadPosts();
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

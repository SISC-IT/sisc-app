import 'package:flutter/material.dart';

import '../../api/backtest_api.dart';
import '../../core/api_client.dart';
import '../../models/backtest.dart';
import 'backtest_result_screen.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  final _backtestApi = BacktestApi(ApiClient.instance);
  late Future<List<TemplateInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _backtestApi.getTemplates();
  }

  Future<void> _refresh() async {
    final future = _backtestApi.getTemplates();
    setState(() => _future = future);
    await future;
  }

  Future<void> _deleteTemplate(TemplateInfo template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('템플릿 삭제'),
        content: Text('"${template.title}" 템플릿을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _backtestApi.deleteTemplate(template.templateId);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('백테스트 템플릿')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<TemplateInfo>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('불러오기에 실패했습니다: ${snapshot.error}'),
                  ),
                ],
              );
            }
            final templates = snapshot.data ?? [];
            if (templates.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('저장된 템플릿이 없습니다.'),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: templates.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final template = templates[index];
                return ListTile(
                  title: Text(template.title),
                  subtitle: Text(template.description ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteTemplate(template),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TemplateDetailScreen(templateId: template.templateId),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class TemplateDetailScreen extends StatefulWidget {
  const TemplateDetailScreen({super.key, required this.templateId});
  final String templateId;

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  final _backtestApi = BacktestApi(ApiClient.instance);
  late Future<TemplateDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _backtestApi.getTemplateDetail(widget.templateId);
  }

  Future<void> _refresh() async {
    final future = _backtestApi.getTemplateDetail(widget.templateId);
    setState(() => _future = future);
    await future;
  }

  Future<void> _deleteRun(BacktestRunInfo run) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결과 삭제'),
        content: Text('"${run.title}" 결과를 이 템플릿에서 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _backtestApi.deleteRunsFromTemplate(templateId: widget.templateId, runIds: [run.id]);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('템플릿 상세')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<TemplateDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('불러오기에 실패했습니다: ${snapshot.error}'),
                  ),
                ],
              );
            }
            final detail = snapshot.data!;
            final runs = detail.runs;
            if (runs.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${detail.template?.title ?? ''}에 저장된 결과가 없습니다.'),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: runs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final run = runs[index];
                return ListTile(
                  title: Text(run.title),
                  subtitle: Text('${run.startDate ?? ''} ~ ${run.endDate ?? ''} · ${run.status}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteRun(run),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BacktestResultScreen(runId: run.id)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

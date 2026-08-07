import 'package:flutter/material.dart';

import '../../api/backtest_api.dart';
import '../../core/api_client.dart';
import '../../data/indicator_dictionary.dart';
import '../../models/strategy_builder.dart';
import '../../widgets/glass_card.dart';
import 'backtest_result_screen.dart';
import 'template_list_screen.dart';

class BacktestBuilderScreen extends StatefulWidget {
  const BacktestBuilderScreen({super.key});

  @override
  State<BacktestBuilderScreen> createState() => _BacktestBuilderScreenState();
}

class _BacktestBuilderScreenState extends State<BacktestBuilderScreen> {
  final _backtestApi = BacktestApi(ApiClient.instance);
  final _titleController = TextEditingController();
  final _capitalController = TextEditingController(text: '10000000');
  final _exitDaysController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  final _tickerController = TextEditingController();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();

  List<String> _availableTickers = [];
  bool _loadingTickers = true;
  bool _submitting = false;
  String? _errorMessage;

  final List<ConditionState> _buyConditions = [ConditionState()];
  final List<ConditionState> _sellConditions = [ConditionState()];

  @override
  void initState() {
    super.initState();
    _loadTickers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _capitalController.dispose();
    _exitDaysController.dispose();
    _noteController.dispose();
    _tickerController.dispose();
    super.dispose();
  }

  Future<void> _loadTickers() async {
    try {
      final tickers = await _backtestApi.getAvailableTickers();
      setState(() => _availableTickers = tickers);
    } catch (_) {
      // 종목 목록 로드 실패 시 직접 입력으로 대체 가능하도록 조용히 넘어간다.
    } finally {
      if (mounted) setState(() => _loadingTickers = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _run() async {
    if (_titleController.text.trim().isEmpty || _tickerController.text.trim().isEmpty) {
      setState(() => _errorMessage = '전략 이름과 종목을 입력해주세요.');
      return;
    }
    if (_buyConditions.isEmpty || _sellConditions.isEmpty) {
      setState(() => _errorMessage = '매수/매도 조건을 하나 이상 추가해주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final result = await _backtestApi.runBacktest(
        title: _titleController.text.trim(),
        startDate: _formatDate(_startDate),
        endDate: _formatDate(_endDate),
        strategy: {
          'initialCapital': double.tryParse(_capitalController.text) ?? 10000000,
          'ticker': _tickerController.text.trim().toUpperCase(),
          'defaultExitDays': int.tryParse(_exitDaysController.text) ?? 0,
          'buyConditions': _buyConditions.map((c) => c.toJson()).toList(),
          'sellConditions': _sellConditions.map((c) => c.toJson()).toList(),
          'note': _noteController.text.trim(),
        },
      );
      if (!mounted) return;
      if (result.run == null) {
        setState(() => _errorMessage = '백테스트 실행에 실패했습니다.');
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BacktestResultScreen(runId: result.run!.id, initial: result)),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('백테스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: '템플릿 목록',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TemplateListScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '전략 이름'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text('시작일: ${_formatDate(_startDate)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text('종료일: ${_formatDate(_endDate)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _loadingTickers
                ? const LinearProgressIndicator()
                : Autocomplete<String>(
                    optionsBuilder: (value) {
                      if (value.text.isEmpty) return _availableTickers;
                      return _availableTickers.where(
                        (t) => t.toUpperCase().contains(value.text.toUpperCase()),
                      );
                    },
                    onSelected: (value) => _tickerController.text = value,
                    fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                      controller.text = _tickerController.text;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: '종목 티커 (예: AAPL)'),
                        onChanged: (v) => _tickerController.text = v,
                      );
                    },
                  ),
            const SizedBox(height: 12),
            TextField(
              controller: _capitalController,
              decoration: const InputDecoration(labelText: '초기 자본금'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _exitDaysController,
              decoration: const InputDecoration(labelText: '기본 청산 기간 (일)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _ConditionGroup(
              label: '매수 조건',
              conditions: _buyConditions,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 20),
            _ConditionGroup(
              label: '매도 조건',
              conditions: _sellConditions,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: '노트 (선택)', alignLabelWithHint: true),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: _submitting ? null : _run,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('실행하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionGroup extends StatelessWidget {
  const _ConditionGroup({required this.label, required this.conditions, required this.onChanged});

  final String label;
  final List<ConditionState> conditions;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('조건 추가'),
              onPressed: () {
                conditions.add(ConditionState());
                onChanged();
              },
            ),
          ],
        ),
        ...conditions.map(
          (condition) => _ConditionRow(
            condition: condition,
            onRemove: conditions.length > 1
                ? () {
                    conditions.remove(condition);
                    onChanged();
                  }
                : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({required this.condition, required this.onRemove, required this.onChanged});

  final ConditionState condition;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _OperandEditor(operand: condition.left, onChanged: onChanged)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: condition.operator,
                  items: operatorLabels.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      condition.setOperator(v);
                      onChanged();
                    }
                  },
                ),
                if (onRemove != null)
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove),
              ],
            ),
            const SizedBox(height: 8),
            _OperandEditor(operand: condition.right, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _OperandEditor extends StatelessWidget {
  const _OperandEditor({required this.operand, required this.onChanged});

  final OperandState operand;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: operand,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'indicator', label: Text('지표', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: 'price', label: Text('가격', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: 'const', label: Text('상수', style: TextStyle(fontSize: 11))),
              ],
              selected: {operand.type},
              onSelectionChanged: (s) {
                operand.setType(s.first);
                onChanged();
              },
            ),
            const SizedBox(height: 6),
            if (operand.type == 'indicator') ...[
              DropdownButton<IndicatorSpec>(
                isDense: true,
                value: operand.indicator,
                items: indicatorDictionary
                    .map((spec) => DropdownMenuItem(value: spec, child: Text(spec.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    operand.setIndicator(v);
                    onChanged();
                  }
                },
              ),
              if (operand.indicator?.hasMultipleOutputs ?? false)
                DropdownButton<String>(
                  isDense: true,
                  value: operand.output,
                  items: operand.indicator!.outputs
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      operand.setOutput(v);
                      onChanged();
                    }
                  },
                ),
              Wrap(
                spacing: 8,
                children: (operand.indicator?.params ?? []).map((paramSpec) {
                  return SizedBox(
                    width: 90,
                    child: TextFormField(
                      initialValue: '${operand.params[paramSpec.key] ?? paramSpec.defaultValue}',
                      decoration: InputDecoration(labelText: paramSpec.label, isDense: true),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          operand.setParam(paramSpec.key, parsed);
                          onChanged();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ] else if (operand.type == 'price')
              DropdownButton<String>(
                isDense: true,
                value: operand.priceField,
                items: priceFields.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) {
                  if (v != null) {
                    operand.setPriceField(v);
                    onChanged();
                  }
                },
              )
            else
              SizedBox(
                width: 120,
                child: TextFormField(
                  initialValue: '${operand.constantValue}',
                  decoration: const InputDecoration(labelText: '값', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) {
                      operand.setConstantValue(parsed);
                      onChanged();
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 백테스트 조건 빌더에서 사용하는 보조지표 사전.
/// 백엔드 BacktestController의 Swagger 예제/StrategyOperand 문서를 기준으로 이식.
class ParamSpec {
  const ParamSpec(this.key, this.label, this.defaultValue);
  final String key;
  final String label;
  final double defaultValue;
}

class IndicatorSpec {
  const IndicatorSpec(this.code, this.label, this.outputs, this.params);
  final String code;
  final String label;
  final List<String> outputs;
  final List<ParamSpec> params;

  bool get hasMultipleOutputs => outputs.isNotEmpty;
}

const List<IndicatorSpec> indicatorDictionary = [
  IndicatorSpec('SMA', '단순이동평균 (SMA)', [], [ParamSpec('length', '기간', 20)]),
  IndicatorSpec('EMA', '지수이동평균 (EMA)', [], [ParamSpec('length', '기간', 20)]),
  IndicatorSpec('RSI', 'RSI', [], [ParamSpec('length', '기간', 14)]),
  IndicatorSpec('MACD', 'MACD', ['macd', 'signal', 'hist'], [
    ParamSpec('fast', '단기', 12),
    ParamSpec('slow', '장기', 26),
    ParamSpec('signal', '시그널', 9),
  ]),
  IndicatorSpec('BB', '볼린저밴드 (BB)', ['upper', 'middle', 'lower'], [
    ParamSpec('length', '기간', 20),
    ParamSpec('k', '승수', 2),
  ]),
  IndicatorSpec('STOCH', '스토캐스틱', ['k', 'd'], [
    ParamSpec('kLength', 'K 기간', 14),
    ParamSpec('dLength', 'D 기간', 3),
  ]),
  IndicatorSpec('CCI', 'CCI', [], [ParamSpec('length', '기간', 14)]),
  IndicatorSpec('ATR', 'ATR', [], [ParamSpec('length', '기간', 14)]),
  IndicatorSpec('ADX', 'ADX', [], [ParamSpec('length', '기간', 14)]),
];

const List<String> priceFields = ['Close', 'Open', 'High', 'Low', 'Volume'];

const Map<String, String> operatorLabels = {
  'GT': '>',
  'LT': '<',
  'CROSSES_ABOVE': '상향 돌파',
  'CROSSES_BELOW': '하향 돌파',
};

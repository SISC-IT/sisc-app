import 'package:flutter/foundation.dart';

import '../data/indicator_dictionary.dart';

/// 매수/매도 조건 빌더 화면에서 사용하는 편집 가능한 피연산자 상태.
class OperandState extends ChangeNotifier {
  OperandState({String type = 'indicator'}) : _type = type {
    if (type == 'indicator') _applyIndicator(indicatorDictionary.first);
  }

  String _type; // indicator | price | const
  IndicatorSpec? _indicator;
  String? _output;
  final Map<String, double> _params = {};
  String _priceField = priceFields.first;
  double _constantValue = 0;

  String get type => _type;
  IndicatorSpec? get indicator => _indicator;
  String? get output => _output;
  Map<String, double> get params => _params;
  String get priceField => _priceField;
  double get constantValue => _constantValue;

  void setType(String type) {
    _type = type;
    if (type == 'indicator' && _indicator == null) {
      _applyIndicator(indicatorDictionary.first);
    }
    notifyListeners();
  }

  void _applyIndicator(IndicatorSpec spec) {
    _indicator = spec;
    _output = spec.hasMultipleOutputs ? spec.outputs.first : null;
    _params
      ..clear()
      ..addEntries(spec.params.map((p) => MapEntry(p.key, p.defaultValue)));
  }

  void setIndicator(IndicatorSpec spec) {
    _applyIndicator(spec);
    notifyListeners();
  }

  void setOutput(String output) {
    _output = output;
    notifyListeners();
  }

  void setParam(String key, double value) {
    _params[key] = value;
    notifyListeners();
  }

  void setPriceField(String field) {
    _priceField = field;
    notifyListeners();
  }

  void setConstantValue(double value) {
    _constantValue = value;
    notifyListeners();
  }

  String get label {
    switch (_type) {
      case 'indicator':
        final spec = _indicator;
        if (spec == null) return '지표';
        final paramText = spec.params.map((p) => '${p.key}=${_params[p.key]}').join(', ');
        return '${spec.code}${_output != null ? '.$_output' : ''}($paramText)';
      case 'price':
        return _priceField;
      case 'const':
        return '$_constantValue';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() {
    switch (_type) {
      case 'indicator':
        return {
          'type': 'indicator',
          'indicatorCode': _indicator!.code,
          'output': _output,
          'params': _params,
        };
      case 'price':
        return {'type': 'price', 'priceField': _priceField, 'params': <String, dynamic>{}};
      case 'const':
        return {'type': 'const', 'constantValue': _constantValue, 'params': <String, dynamic>{}};
      default:
        return {'type': _type, 'params': <String, dynamic>{}};
    }
  }
}

class ConditionState extends ChangeNotifier {
  ConditionState()
    : left = OperandState(),
      right = OperandState(type: 'const'),
      operator = 'GT';

  final OperandState left;
  final OperandState right;
  String operator;
  bool isAbsolute = false;

  void setOperator(String value) {
    operator = value;
    notifyListeners();
  }

  void setAbsolute(bool value) {
    isAbsolute = value;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'leftOperand': left.toJson(),
    'operator': operator,
    'rightOperand': right.toJson(),
    'isAbsolute': isAbsolute,
  };
}

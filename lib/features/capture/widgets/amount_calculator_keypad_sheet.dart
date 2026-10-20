import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AmountCalculatorKeypadSheet extends StatefulWidget {
  final String initialAmount;
  final String currency;
  final String amountPrefix;
  final Color accentColor;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback? onConfirm;
  final VoidCallback? onMaxDigitsExceeded;
  final bool? isDark;

  const AmountCalculatorKeypadSheet({
    super.key,
    required this.initialAmount,
    required this.currency,
    required this.amountPrefix,
    required this.accentColor,
    required this.onAmountChanged,
    this.onConfirm,
    this.onMaxDigitsExceeded,
    this.isDark,
  });

  static Future<String?> show(
    BuildContext context, {
    required String initialAmount,
    required String currency,
    required String amountPrefix,
    required Color accentColor,
    required ValueChanged<String> onAmountChanged,
    VoidCallback? onConfirm,
    VoidCallback? onMaxDigitsExceeded,
    bool? isDark,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => AmountCalculatorKeypadSheet(
        initialAmount: initialAmount,
        currency: currency,
        amountPrefix: amountPrefix,
        accentColor: accentColor,
        onAmountChanged: onAmountChanged,
        onConfirm: onConfirm,
        onMaxDigitsExceeded: onMaxDigitsExceeded,
        isDark: isDark,
      ),
    );
  }

  @override
  State<AmountCalculatorKeypadSheet> createState() =>
      _AmountCalculatorKeypadSheetState();
}

class _AmountCalculatorKeypadSheetState
    extends State<AmountCalculatorKeypadSheet> {
  // Biểu thức thô dạng chuỗi ký tự máy tính (vd: "50000+35000*2")
  String _rawExpression = '';
  final NumberFormat _vndFormatter = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    _syncInitialAmount();
  }

  @override
  void didUpdateWidget(covariant AmountCalculatorKeypadSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAmount != widget.initialAmount && _rawExpression.isEmpty) {
      _syncInitialAmount();
    }
  }

  void _syncInitialAmount() {
    final clean = widget.initialAmount.replaceAll(RegExp(r'[^0-9.]'), '');
    if (clean.isNotEmpty && clean != '0') {
      _rawExpression = clean;
    }
  }

  bool get _isUsd => widget.currency.toUpperCase() == 'USD';

  /// Lấy phân đoạn số hiện tại đang nhập ở cuối biểu thức
  String get _currentNumberSegment {
    if (_rawExpression.isEmpty) return '';
    final lastOpIndex = _rawExpression.lastIndexOf(RegExp(r'[+\-*/]'));
    if (lastOpIndex == -1) return _rawExpression;
    return _rawExpression.substring(lastOpIndex + 1);
  }

  /// Tính toán kết quả của biểu thức
  double? get _calculatedResult {
    if (_rawExpression.isEmpty) return null;
    return _MathExpressionEvaluator.evaluate(_rawExpression);
  }

  /// Biểu thức có chứa phép toán hay không (+, -, *, /)
  bool get _hasOperator {
    return _rawExpression.contains(RegExp(r'[+\-*/]'));
  }

  /// Định dạng 1 số độc lập sang dạng tiền tệ đẹp mắt
  String _formatNumberString(String numberStr) {
    if (numberStr.isEmpty) return '';
    if (_isUsd) {
      final parts = numberStr.split('.');
      final intPart = parts[0];
      final formattedInt = intPart.isEmpty
          ? '0'
          : NumberFormat('#,##0', 'en_US').format(int.tryParse(intPart) ?? 0);
      if (parts.length > 1) {
        return '$formattedInt.${parts[1]}';
      }
      return numberStr.endsWith('.') ? '$formattedInt.' : formattedInt;
    } else {
      final clean = numberStr.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isEmpty) return '';
      final val = int.tryParse(clean) ?? 0;
      return _vndFormatter.format(val);
    }
  }

  /// Định dạng toàn bộ biểu thức để hiển thị trực quan cho người dùng
  String get _formattedDisplayExpression {
    if (_rawExpression.isEmpty) return '';

    final buffer = StringBuffer();
    var currentSegment = '';

    for (int i = 0; i < _rawExpression.length; i++) {
      final char = _rawExpression[i];
      if (char == '+' || char == '-' || char == '*' || char == '/') {
        if (currentSegment.isNotEmpty) {
          buffer.write(_formatNumberString(currentSegment));
          currentSegment = '';
        }
        final displayOp = char == '*'
            ? ' × '
            : char == '/'
                ? ' ÷ '
                : ' $char ';
        buffer.write(displayOp);
      } else {
        currentSegment += char;
      }
    }

    if (currentSegment.isNotEmpty) {
      buffer.write(_formatNumberString(currentSegment));
    }

    return buffer.toString();
  }

  /// Trả về số tiền đã tính toán hoàn chỉnh để cập nhật vào controller
  String get _finalFormattedAmountText {
    final result = _calculatedResult;
    if (result == null || result <= 0) {
      if (_rawExpression.isNotEmpty && !_hasOperator) {
        return _formatNumberString(_rawExpression);
      }
      return '';
    }

    if (_isUsd) {
      if (result == result.roundToDouble()) {
        return result.toInt().toString();
      }
      return result.toStringAsFixed(2);
    } else {
      final intVal = result.round();
      return _vndFormatter.format(intVal);
    }
  }

  void _notifyAmountChanged() {
    final formatted = _formattedDisplayExpression;
    widget.onAmountChanged(formatted);
  }

  void _onDigitPressed(String digit) {
    HapticFeedback.selectionClick();
    final seg = _currentNumberSegment;
    if (seg.replaceAll('.', '').length >= 12) {
      widget.onMaxDigitsExceeded?.call();
      return;
    }

    setState(() {
      if (_rawExpression == '0' && digit != '.') {
        _rawExpression = digit;
      } else {
        _rawExpression += digit;
      }
    });
    _notifyAmountChanged();
  }

  void _onThousandShortcutsPressed() {
    HapticFeedback.selectionClick();
    final seg = _currentNumberSegment;
    if (seg.isEmpty || seg == '0') return;
    if (seg.replaceAll('.', '').length + 3 > 12) {
      widget.onMaxDigitsExceeded?.call();
      return;
    }

    setState(() {
      _rawExpression += '000';
    });
    _notifyAmountChanged();
  }

  void _onDotPressed() {
    HapticFeedback.selectionClick();
    final seg = _currentNumberSegment;
    if (seg.contains('.')) return;

    setState(() {
      if (seg.isEmpty) {
        _rawExpression += '0.';
      } else {
        _rawExpression += '.';
      }
    });
    _notifyAmountChanged();
  }

  void _onOperatorPressed(String op) {
    HapticFeedback.mediumImpact();
    if (_rawExpression.isEmpty) {
      if (op == '-') {
        setState(() => _rawExpression = '-');
      }
      return;
    }

    setState(() {
      final lastChar = _rawExpression[_rawExpression.length - 1];
      if (lastChar == '+' ||
          lastChar == '-' ||
          lastChar == '*' ||
          lastChar == '/') {
        _rawExpression =
            _rawExpression.substring(0, _rawExpression.length - 1) + op;
      } else {
        _rawExpression += op;
      }
    });
    _notifyAmountChanged();
  }

  void _onEqualsPressed() {
    HapticFeedback.mediumImpact();
    final result = _calculatedResult;
    if (result != null) {
      setState(() {
        if (_isUsd) {
          _rawExpression = (result == result.roundToDouble())
              ? result.toInt().toString()
              : result.toStringAsFixed(2);
        } else {
          _rawExpression = result.round().toString();
        }
      });
      _notifyAmountChanged();
    }
  }

  void _onBackspacePressed() {
    HapticFeedback.selectionClick();
    if (_rawExpression.isEmpty) return;

    setState(() {
      _rawExpression = _rawExpression.substring(0, _rawExpression.length - 1);
    });
    _notifyAmountChanged();
  }

  void _onClearPressed() {
    HapticFeedback.mediumImpact();
    setState(() {
      _rawExpression = '';
    });
    _notifyAmountChanged();
  }

  void _onDonePressed() {
    HapticFeedback.mediumImpact();
    _onEqualsPressed();
    final finalAmount = _finalFormattedAmountText;
    widget.onAmountChanged(finalAmount);
    if (widget.onConfirm != null) {
      widget.onConfirm!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, finalAmount);
    }
  }

  @override
  void dispose() {
    final finalAmount = _finalFormattedAmountText;
    if (finalAmount.isNotEmpty) {
      widget.onAmountChanged(finalAmount);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);

    final sheetBg =
        isDarkMode ? const Color(0xFF141622) : const Color(0xFFFFFFFF);
    final sheetBorderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE5E9F2);
    final sheetShadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.45)
        : const Color(0xFF0F172A).withValues(alpha: 0.08);
    final handleColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.22)
        : const Color(0xFFD3D7E3);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Absorb all taps so fast typing never dismisses the keyboard
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! > 7) {
          _onDonePressed();
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 120) {
          _onDonePressed();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: sheetBorderColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: sheetShadowColor,
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle with gesture support
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! > 4) {
                    _onDonePressed();
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Live calculation preview banner if expression has operators
              if (_hasOperator)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFF0F172A).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formattedDisplayExpression,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.70)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if (_calculatedResult != null)
                        Text(
                          '= $_finalFormattedAmountText ${widget.currency}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: widget.accentColor,
                          ),
                        ),
                    ],
                  ),
                ),

              // Row 1: C, ÷, ×, ⌫
              Row(
                children: [
                  _buildCalcKey(
                    label: 'C',
                    isSpecial: true,
                    textColor: const Color(0xFFFF5252),
                    backgroundColor: isDarkMode
                        ? const Color(0xFFFF5252).withValues(alpha: 0.14)
                        : const Color(0xFFFF5252).withValues(alpha: 0.09),
                    borderColor:
                        const Color(0xFFFF5252).withValues(alpha: 0.25),
                    onTap: _onClearPressed,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '÷',
                    isOperator: true,
                    onTap: () => _onOperatorPressed('/'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '×',
                    isOperator: true,
                    onTap: () => _onOperatorPressed('*'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    icon: Icons.backspace_outlined,
                    isSpecial: true,
                    textColor: isDarkMode
                        ? Colors.white.withValues(alpha: 0.85)
                        : const Color(0xFF475569),
                    onTap: _onBackspacePressed,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: 7, 8, 9, -
              Row(
                children: [
                  _buildCalcKey(
                    label: '7',
                    onTap: () => _onDigitPressed('7'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '8',
                    onTap: () => _onDigitPressed('8'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '9',
                    onTap: () => _onDigitPressed('9'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '-',
                    isOperator: true,
                    onTap: () => _onOperatorPressed('-'),
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 3: 4, 5, 6, +
              Row(
                children: [
                  _buildCalcKey(
                    label: '4',
                    onTap: () => _onDigitPressed('4'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '5',
                    onTap: () => _onDigitPressed('5'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '6',
                    onTap: () => _onDigitPressed('6'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '+',
                    isOperator: true,
                    onTap: () => _onOperatorPressed('+'),
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 4: 1, 2, 3, =
              Row(
                children: [
                  _buildCalcKey(
                    label: '1',
                    onTap: () => _onDigitPressed('1'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '2',
                    onTap: () => _onDigitPressed('2'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '3',
                    onTap: () => _onDigitPressed('3'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '=',
                    isOperator: true,
                    backgroundColor: widget.accentColor.withValues(
                      alpha: isDarkMode ? 0.28 : 0.20,
                    ),
                    borderColor: widget.accentColor.withValues(alpha: 0.45),
                    textColor: widget.accentColor,
                    onTap: _onEqualsPressed,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 5: 000 / +/-, 0, ., Done
              Row(
                children: [
                  _buildCalcKey(
                    label: _isUsd ? '+/-' : '000',
                    isSpecial: true,
                    onTap: _isUsd
                        ? () => _onOperatorPressed('-')
                        : _onThousandShortcutsPressed,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '0',
                    onTap: () => _onDigitPressed('0'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '.',
                    isSpecial: true,
                    onTap: _onDotPressed,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    icon: Icons.check_rounded,
                    isAction: true,
                    backgroundColor: widget.accentColor,
                    textColor: Colors.white,
                    onTap: _onDonePressed,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcKey({
    String? label,
    IconData? icon,
    bool isOperator = false,
    bool isSpecial = false,
    bool isAction = false,
    Color? backgroundColor,
    Color? borderColor,
    Color? textColor,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    // Determine effective background
    final effectiveBg = backgroundColor ??
        (isAction
            ? widget.accentColor
            : isOperator
                ? widget.accentColor.withValues(
                    alpha: isDarkMode ? 0.16 : 0.12,
                  )
                : isSpecial
                    ? (isDarkMode
                        ? const Color(0xFF222636)
                        : const Color(0xFFEFF2F8))
                    : (isDarkMode
                        ? const Color(0xFF1E212E)
                        : const Color(0xFFF9FAFD)));

    // Determine effective border
    final effectiveBorder = borderColor ??
        (isAction
            ? widget.accentColor
            : isOperator
                ? widget.accentColor.withValues(
                    alpha: isDarkMode ? 0.35 : 0.28,
                  )
                : isSpecial
                    ? (isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E7F0))
                    : (isDarkMode
                        ? Colors.white.withValues(alpha: 0.07)
                        : const Color(0xFFE8ECF4)));

    // Determine effective text/icon color
    final effectiveTextColor = textColor ??
        (isAction
            ? Colors.white
            : isOperator
                ? widget.accentColor
                : isSpecial
                    ? (isDarkMode
                        ? Colors.white.withValues(alpha: 0.90)
                        : const Color(0xFF334155))
                    : (isDarkMode
                        ? Colors.white
                        : const Color(0xFF0F172A)));

    // Key elevation shadow
    final keyShadow = isAction
        ? BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.40),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 3),
          )
        : isOperator
            ? BoxShadow(
                color: widget.accentColor.withValues(
                  alpha: isDarkMode ? 0.18 : 0.10,
                ),
                blurRadius: 6,
                offset: const Offset(0, 1.5),
              )
            : BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFF64748B).withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              );

    return Expanded(
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: effectiveBorder,
            width: isAction || isOperator ? 1.4 : 1.0,
          ),
          boxShadow: [keyShadow],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: isAction
                ? Colors.white.withValues(alpha: 0.25)
                : widget.accentColor.withValues(alpha: 0.20),
            highlightColor: isAction
                ? Colors.white.withValues(alpha: 0.12)
                : widget.accentColor.withValues(alpha: 0.10),
            child: Center(
              child: icon != null
                  ? (label != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 20, color: effectiveTextColor),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                color: effectiveTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          icon,
                          size: isAction ? 24 : 22,
                          color: effectiveTextColor,
                        ))
                  : Text(
                      label ?? '',
                      style: TextStyle(
                        color: effectiveTextColor,
                        fontSize: isOperator
                            ? 24
                            : (label == '000' || label == '+/-' ? 16.5 : 21),
                        fontWeight:
                            isOperator ? FontWeight.w900 : FontWeight.w700,
                        letterSpacing: label == '000' ? -0.5 : 0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MathExpressionEvaluator {
  static double? evaluate(String expression) {
    if (expression.trim().isEmpty) return null;

    String expr = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '');

    while (expr.isNotEmpty &&
        (expr.endsWith('+') ||
            expr.endsWith('-') ||
            expr.endsWith('*') ||
            expr.endsWith('/'))) {
      expr = expr.substring(0, expr.length - 1);
    }
    if (expr.isEmpty) return null;

    try {
      final tokens = <dynamic>[];
      var currentNumber = '';

      for (int i = 0; i < expr.length; i++) {
        final char = expr[i];
        if (char == '+' || char == '-' || char == '*' || char == '/') {
          if (currentNumber.isNotEmpty) {
            final num = double.tryParse(currentNumber);
            if (num == null) return null;
            tokens.add(num);
            currentNumber = '';
          } else if (char == '-' &&
              (tokens.isEmpty || tokens.last is String)) {
            currentNumber = '-';
            continue;
          }
          tokens.add(char);
        } else {
          currentNumber += char;
        }
      }

      if (currentNumber.isNotEmpty) {
        final num = double.tryParse(currentNumber);
        if (num == null) return null;
        tokens.add(num);
      }

      if (tokens.isEmpty) return null;

      // Pass 1: * và /
      final pass1 = <dynamic>[];
      int i = 0;
      while (i < tokens.length) {
        final token = tokens[i];
        if (token == '*' || token == '/') {
          if (pass1.isEmpty ||
              i + 1 >= tokens.length ||
              tokens[i + 1] is! double) {
            return null;
          }
          final prevNum = pass1.removeLast() as double;
          final nextNum = tokens[i + 1] as double;
          if (token == '/') {
            if (nextNum == 0) return null;
            pass1.add(prevNum / nextNum);
          } else {
            pass1.add(prevNum * nextNum);
          }
          i += 2;
        } else {
          pass1.add(token);
          i++;
        }
      }

      // Pass 2: + và -
      if (pass1.isEmpty || pass1.first is! double) return null;
      double result = pass1[0] as double;
      int j = 1;
      while (j < pass1.length) {
        final op = pass1[j] as String;
        if (j + 1 >= pass1.length || pass1[j + 1] is! double) return null;
        final nextNum = pass1[j + 1] as double;
        if (op == '+') {
          result += nextNum;
        } else if (op == '-') {
          result -= nextNum;
        }
        j += 2;
      }

      return result;
    } catch (_) {
      return null;
    }
  }
}

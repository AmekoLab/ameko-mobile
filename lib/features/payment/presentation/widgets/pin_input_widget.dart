import 'package:flutter/material.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';

/// A 6-digit PIN input widget with individual boxes and obscured display.
class PinInputWidget extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final String? errorText;
  final bool autoFocus;

  const PinInputWidget({
    super.key,
    required this.onCompleted,
    this.errorText,
    this.autoFocus = true,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _pin = List.filled(6, '');

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty) {
      _pin[index] = value[0];
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        widget.onCompleted(_pin.join());
      }
    } else {
      _pin[index] = '';
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    setState(() {});
  }

  void clearPin() {
    for (int i = 0; i < 6; i++) {
      _controllers[i].clear();
      _pin[i] = '';
    }
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) => _buildBox(i)),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: AppTextStyles.caption.copyWith(color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildBox(int index) {
    final filled = _pin[index].isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;

    return Container(
      width: 44,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: widget.errorText != null
              ? Colors.red
              : isFocused
                  ? AppColors.primary
                  : AppColors.border,
          width: isFocused ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Actual TextField — invisible but intercepts input
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              maxLength: 1,
              textAlign: TextAlign.center,
              onChanged: (val) => _onDigitEntered(index, val),
              onTap: () {
                _controllers[index].clear();
                _pin[index] = '';
                setState(() {});
              },
            ),
          ),
          // Visual display
          if (filled)
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

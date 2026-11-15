import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grid_os/theme/app_theme.dart';

void returnToSetupStep(
  BuildContext context, {
  required int currentStep,
  required int targetStep,
}) {
  var stepsToPop = currentStep - targetStep;
  if (stepsToPop <= 0) return;
  Navigator.of(context).popUntil((route) => stepsToPop-- <= 0);
}

class SetupPageFrame extends StatelessWidget {
  const SetupPageFrame({
    super.key,
    required this.step,
    required this.workspaceName,
    required this.title,
    required this.description,
    required this.child,
    required this.summary,
    required this.onContinue,
    this.onBack,
    this.onFinishLater,
    this.continueLabel = 'Continue',
    this.secondaryAction,
    this.panelChild = true,
  });

  final int step;
  final String workspaceName;
  final String title;
  final String description;
  final Widget child;
  final Widget summary;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onFinishLater;
  final String continueLabel;
  final Widget? secondaryAction;
  final bool panelChild;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: Column(
          children: [
            SetupProgressAppBar(
              workspaceName: workspaceName,
              step: step,
              onBack: onBack,
              onFinishLater: onFinishLater,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 820;
                  return SingleChildScrollView(
                    key: PageStorageKey<String>('startup-step-$step'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 28 : 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1050),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _pageColumn(context),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: summary,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _pageHeading(),
                                  if (panelChild)
                                    SetupPanel(child: child)
                                  else
                                    child,
                                  const SizedBox(height: 20),
                                  summary,
                                  const SizedBox(height: 12),
                                  _actions(context),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageHeading(),
        if (panelChild) SetupPanel(child: child) else child,
        const SizedBox(height: 20),
        _actions(context),
      ],
    );
  }

  Widget _pageHeading() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $step of 5',
            style: const TextStyle(
              color: AppColors.authGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 5),
          Text(title, style: AppTextStyles.authHeading),
          const SizedBox(height: 4),
          Text(description, style: AppTextStyles.authDescription),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final continueButton = FilledButton(
      onPressed: onContinue,
      child: Text(continueLabel),
    );
    if (MediaQuery.sizeOf(context).width < 480) {
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (onBack case final back?)
            TextButton.icon(
              onPressed: back,
              icon: const Icon(Icons.arrow_back, size: 15),
              label: const Text('Back'),
            ),
          ?secondaryAction,
          continueButton,
        ],
      );
    }
    return Row(
      children: [
        if (onBack case final back?)
          TextButton.icon(
            onPressed: back,
            icon: const Icon(Icons.arrow_back, size: 15),
            label: const Text('Back'),
          ),
        const Spacer(),
        if (secondaryAction case final action?) ...[
          action,
          const SizedBox(width: 8),
        ],
        continueButton,
      ],
    );
  }
}

class SetupProgressAppBar extends StatelessWidget {
  const SetupProgressAppBar({
    super.key,
    required this.workspaceName,
    required this.step,
    this.onBack,
    this.onFinishLater,
    this.title,
  });

  final String workspaceName;
  final int step;
  final VoidCallback? onBack;
  final VoidCallback? onFinishLater;
  final String? title;

  static const _steps = ['Workspace', 'Spaces', 'Prices', 'Kitchen', 'Staff'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 18,
            vertical: compact ? 8 : 10,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.authBorder)),
          ),
          child: compact
              ? Column(
                  children: [
                    Row(
                      children: [
                        if (onBack != null)
                          SizedBox(
                            width: 30,
                            height: 32,
                            child: IconButton(
                              onPressed: onBack,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.arrow_back, size: 18),
                              tooltip: 'Back',
                            ),
                          ),
                        _brandMark(),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            title ?? workspaceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.authInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _savedStatus(),
                      ],
                    ),
                    const SizedBox(height: 7),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _progress(),
                          if (onFinishLater != null) ...[
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: onFinishLater,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Finish later',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        tooltip: 'Back',
                      ),
                    _brandMark(),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 190),
                      child: Text(
                        title ?? workspaceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.authInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _progress(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    _savedStatus(),
                    if (onFinishLater != null) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: onFinishLater,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 30),
                          textStyle: const TextStyle(fontSize: 10),
                        ),
                        child: const Text('Finish later'),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _brandMark() {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: AppColors.authGreen,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.grid_view_rounded,
        size: 10,
        color: AppColors.white,
      ),
    );
  }

  Widget _savedStatus() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, size: 12, color: AppColors.authMuted),
        SizedBox(width: 3),
        Text(
          'Saved as you go',
          style: TextStyle(color: AppColors.authMuted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _progress() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < _steps.length; index++)
          _progressStep(index),
      ],
    );
  }

  Widget _progressStep(int index) {
    final completed = index < step - 1;
    final active = index == step - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: completed ? AppColors.authGreen : AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: completed || active
                      ? AppColors.authGreen
                      : AppColors.authBorder,
                ),
              ),
              child: completed
                  ? const Icon(Icons.check, size: 10, color: AppColors.white)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active ? AppColors.authGreen : AppColors.authMuted,
                        fontSize: 8,
                      ),
                    ),
            ),
            const SizedBox(width: 4),
            Text(
              _steps[index],
              style: TextStyle(
                color: completed || active
                    ? AppColors.authInk
                    : AppColors.authMuted,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
        if (index < _steps.length - 1)
          Container(
            width: 18,
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: index < step - 1
                ? AppColors.authGreen
                : AppColors.authBorder,
          ),
      ],
    );
  }
}

class SetupSection extends StatelessWidget {
  const SetupSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.authFieldLabel),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

class SetupPanel extends StatelessWidget {
  const SetupPanel({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFFF9FAF8),
    this.padding = const EdgeInsets.all(13),
  });

  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: child,
    );
  }
}

InputDecoration setupInputDecoration({
  String? hintText,
  String? suffixText,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    suffixText: suffixText,
    prefixIcon: prefixIcon,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
  );
}

Widget setupTextField({
  Key? key,
  required String label,
  required String initialValue,
  required ValueChanged<String> onChanged,
  String? hintText,
  TextInputType keyboardType = TextInputType.text,
  String? suffixText,
  int? maxLength,
}) {
  return TextFormField(
    key: key,
    initialValue: initialValue,
    onChanged: onChanged,
    keyboardType: keyboardType,
    maxLength: maxLength,
    decoration: setupInputDecoration(
      hintText: hintText ?? label,
      suffixText: suffixText,
    ).copyWith(counterText: ''),
  );
}

class SetupQuantityInput extends StatefulWidget {
  const SetupQuantityInput({
    super.key,
    required this.valueKey,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showLabel = true,
  });

  final String valueKey;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool showLabel;

  @override
  State<SetupQuantityInput> createState() => _SetupQuantityInputState();
}

class _SetupQuantityInputState extends State<SetupQuantityInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant SetupQuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setCount(int count) {
    final value = count.toString();
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final count = int.tryParse(_controller.text) ?? 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 150;
        final buttonWidth = compact ? 28.0 : 36.0;
        final valueWidth = compact ? 38.0 : 48.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showLabel) ...[
              Text(
                widget.label,
                style: AppTextStyles.authHelper.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 4),
            ],
            Container(
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4D8D3)),
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuantityButton(
                    key: ValueKey('decrement-${widget.valueKey}'),
                    width: buttonWidth,
                    icon: Icons.remove,
                    semanticLabel: 'Decrease ${widget.label}',
                    onPressed: count > 1 ? () => _setCount(count - 1) : null,
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: const Color(0xFFD4D8D3),
                  ),
                  SizedBox(
                    width: valueWidth,
                    child: TextField(
                      key: ValueKey(widget.valueKey),
                      controller: _controller,
                      onChanged: widget.onChanged,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: const Color(0xFFD4D8D3),
                  ),
                  _QuantityButton(
                    key: ValueKey('increment-${widget.valueKey}'),
                    width: buttonWidth,
                    icon: Icons.add,
                    semanticLabel: 'Increase ${widget.label}',
                    onPressed: () => _setCount(count + 1),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    super.key,
    required this.width,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: IconButton(
        onPressed: onPressed,
        tooltip: semanticLabel,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 17, color: AppColors.authGreen),
      ),
    );
  }
}

class SetupChoiceChips extends StatelessWidget {
  const SetupChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(option),
            selected: selected.contains(option),
            onSelected: (_) => onSelected(option),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

Future<String?> pickSetupTime(BuildContext context, String current) async {
  final parts = current.split(':');
  final hour = int.tryParse(parts.first) ?? 9;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  final result = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: hour, minute: minute),
  );
  if (result == null) return null;
  return '${result.hour.toString().padLeft(2, '0')}:'
      '${result.minute.toString().padLeft(2, '0')}';
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/visit_form.dart';

typedef FormAnswersMap = Map<String, dynamic>;

class DynamicVisitForm extends StatelessWidget {
  const DynamicVisitForm({
    super.key,
    required this.template,
    required this.answers,
    required this.onChanged,
    this.fieldErrors = const {},
  });

  final VisitFormTemplate template;
  final FormAnswersMap answers;
  final ValueChanged<FormAnswersMap> onChanged;
  final Map<String, String> fieldErrors;

  void _setAnswer(String key, dynamic value) {
    final next = Map<String, dynamic>.from(answers);
    if (value == null || (value is String && value.isEmpty)) {
      next.remove(key);
    } else if (value is List && value.isEmpty) {
      next.remove(key);
    } else if (value is Map && value.isEmpty) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final questions = template.questions
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final question in questions) ...[
          if (question.questionType == FormQuestionType.sectionHeader)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                question.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
              ),
            )
          else
            _QuestionCard(
              question: question,
              errorText: fieldErrors[question.questionKey],
              child: _buildInput(context, question),
            ),
        ],
      ],
    );
  }

  Widget _buildInput(BuildContext context, FormQuestion question) {
    switch (question.questionType) {
      case FormQuestionType.singleChoice:
        return _SingleChoiceInput(
          question: question,
          value: answers[question.questionKey] as String?,
          onChanged: (v) => _setAnswer(question.questionKey, v),
        );
      case FormQuestionType.multiChoice:
        return _MultiChoiceInput(
          question: question,
          values: (answers[question.questionKey] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          onChanged: (v) => _setAnswer(question.questionKey, v),
        );
      case FormQuestionType.ratingScale:
        return _RatingScaleInput(
          question: question,
          value: answers[question.questionKey]?.toString(),
          onChanged: (v) => _setAnswer(question.questionKey, v),
        );
      case FormQuestionType.matrix:
        return _MatrixInput(
          question: question,
          values: Map<String, String>.from(
            (answers[question.questionKey] as Map?)?.map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                ) ??
                {},
          ),
          onChanged: (v) => _setAnswer(question.questionKey, v),
        );
      case FormQuestionType.textarea:
        return _TextInput(
          question: question,
          value: answers[question.questionKey] as String? ?? '',
          maxLines: 4,
          onChanged: (v) => _setAnswer(question.questionKey, v),
        );
      case FormQuestionType.text:
        return _TextInput(
          question: question,
          value: answers[question.questionKey] as String? ?? '',
          maxLines: 1,
          onChanged: (v) => _setAnswer(question.questionKey, v),
        );
      case FormQuestionType.sectionHeader:
        return const SizedBox.shrink();
    }
  }

  static List<FormAnswerEntry> toFormAnswers(
    VisitFormTemplate template,
    FormAnswersMap answers,
  ) {
    final entries = <FormAnswerEntry>[];
    for (final question in template.inputQuestions) {
      final raw = answers[question.questionKey];
      if (raw == null) continue;
      switch (question.questionType) {
        case FormQuestionType.multiChoice:
          entries.add(FormAnswerEntry(
            questionKey: question.questionKey,
            answerJson: (raw as List).map((e) => e.toString()).toList(),
          ));
        case FormQuestionType.matrix:
          entries.add(FormAnswerEntry(
            questionKey: question.questionKey,
            answerJson: Map<String, dynamic>.from(raw as Map),
          ));
        case FormQuestionType.ratingScale:
        case FormQuestionType.singleChoice:
        case FormQuestionType.text:
        case FormQuestionType.textarea:
          entries.add(FormAnswerEntry(
            questionKey: question.questionKey,
            answer: raw.toString(),
          ));
        case FormQuestionType.sectionHeader:
          break;
      }
    }
    return entries;
  }

  static Map<String, String> validateRequired(
    VisitFormTemplate template,
    FormAnswersMap answers,
  ) {
    final errors = <String, String>{};
    for (final question in template.inputQuestions.where((q) => q.isRequired)) {
      final raw = answers[question.questionKey];
      if (raw == null) {
        errors[question.questionKey] = 'This field is required';
        continue;
      }
      if (raw is String && raw.trim().isEmpty) {
        errors[question.questionKey] = 'This field is required';
      } else if (raw is List && raw.isEmpty) {
        errors[question.questionKey] = 'Select at least one option';
      } else if (raw is Map) {
        final rows = question.config?['rows'] as List<dynamic>? ?? [];
        if (raw.length < rows.length) {
          errors[question.questionKey] = 'Please complete all rows';
        }
      }
    }
    return errors;
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.child,
    this.errorText,
  });

  final FormQuestion question;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppColors.cardDecoration(radius: AppSpacing.radiusLg).copyWith(
        border: hasError
            ? Border.all(color: AppColors.error.withValues(alpha: 0.55), width: 1.5)
            : Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (question.isRequired)
                Text(
                  '*',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                ),
            ],
          ),
          if (question.helpText != null && question.helpText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              question.helpText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          child,
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SingleChoiceInput extends StatelessWidget {
  const _SingleChoiceInput({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final FormQuestion question;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: question.options.map((option) {
        return RadioListTile<String>(
          value: option.value,
          groupValue: value,
          onChanged: onChanged,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(option.label),
          activeColor: AppColors.primary,
        );
      }).toList(),
    );
  }
}

class _MultiChoiceInput extends StatelessWidget {
  const _MultiChoiceInput({
    required this.question,
    required this.values,
    required this.onChanged,
  });

  final FormQuestion question;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: question.options.map((option) {
        final checked = values.contains(option.value);
        return CheckboxListTile(
          value: checked,
          onChanged: (v) {
            final next = List<String>.from(values);
            if (v == true) {
              next.add(option.value);
            } else {
              next.remove(option.value);
            }
            onChanged(next);
          },
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(option.label),
          activeColor: AppColors.primary,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}

class _RatingScaleInput extends StatelessWidget {
  const _RatingScaleInput({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final FormQuestion question;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final min = (question.config?['min'] as num?)?.toInt() ?? 1;
    final max = (question.config?['max'] as num?)?.toInt() ?? 5;
    final minLabel = question.config?['min_label'] as String? ?? '$min';
    final maxLabel = question.config?['max_label'] as String? ?? '$max';
    final current = int.tryParse(value ?? '') ?? min;

    return Column(
      children: [
        Slider(
          value: current.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: current.toString(),
          activeColor: AppColors.primary,
          onChanged: (v) => onChanged(v.round().toString()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: Theme.of(context).textTheme.labelSmall),
            Text(
              current.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
            ),
            Text(maxLabel, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _MatrixInput extends StatelessWidget {
  const _MatrixInput({
    required this.question,
    required this.values,
    required this.onChanged,
  });

  final FormQuestion question;
  final Map<String, String> values;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = (question.config?['rows'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final columns = (question.config?['columns'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Column(
      children: rows.map((row) {
        final rowKey = row['key'] as String? ?? '';
        final rowLabel = row['label'] as String? ?? rowKey;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rowLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: columns.map((col) {
                  final colKey = col['key'] as String? ?? '';
                  final colLabel = col['label'] as String? ?? colKey;
                  final selected = values[rowKey] == colKey;
                  return ChoiceChip(
                    label: Text(colLabel),
                    selected: selected,
                    onSelected: (_) {
                      final next = Map<String, String>.from(values);
                      next[rowKey] = colKey;
                      onChanged(next);
                    },
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TextInput extends StatefulWidget {
  const _TextInput({
    required this.question,
    required this.value,
    required this.maxLines,
    required this.onChanged,
  });

  final FormQuestion question;
  final String value;
  final int maxLines;
  final ValueChanged<String> onChanged;

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: widget.maxLines,
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Enter your response',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

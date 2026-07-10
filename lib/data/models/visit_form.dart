class AssignedExecutive {
  const AssignedExecutive({required this.id, required this.name});

  final String id;
  final String name;

  factory AssignedExecutive.fromJson(Map<String, dynamic> json) =>
      AssignedExecutive(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
      );
}

enum FormQuestionType {
  sectionHeader('section_header'),
  singleChoice('single_choice'),
  multiChoice('multi_choice'),
  ratingScale('rating_scale'),
  matrix('matrix'),
  text('text'),
  textarea('textarea');

  const FormQuestionType(this.apiValue);
  final String apiValue;

  static FormQuestionType fromApi(String value) => FormQuestionType.values
      .firstWhere((e) => e.apiValue == value, orElse: () => FormQuestionType.text);
}

class FormQuestionOption {
  const FormQuestionOption({
    required this.id,
    required this.value,
    required this.label,
    this.sortOrder = 0,
  });

  final String id;
  final String value;
  final String label;
  final int sortOrder;

  factory FormQuestionOption.fromJson(Map<String, dynamic> json) =>
      FormQuestionOption(
        id: json['id']?.toString() ?? '',
        value: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}

class FormQuestion {
  const FormQuestion({
    required this.id,
    required this.questionKey,
    required this.label,
    required this.questionType,
    this.helpText,
    this.sortOrder = 0,
    this.isRequired = false,
    this.config,
    this.options = const [],
  });

  final String id;
  final String questionKey;
  final String label;
  final FormQuestionType questionType;
  final String? helpText;
  final int sortOrder;
  final bool isRequired;
  final Map<String, dynamic>? config;
  final List<FormQuestionOption> options;

  factory FormQuestion.fromJson(Map<String, dynamic> json) => FormQuestion(
        id: json['id']?.toString() ?? '',
        questionKey: json['question_key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        questionType: FormQuestionType.fromApi(
          json['question_type'] as String? ?? 'text',
        ),
        helpText: json['help_text'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        isRequired: json['is_required'] as bool? ?? false,
        config: json['config'] is Map<String, dynamic>
            ? json['config'] as Map<String, dynamic>
            : null,
        options: (json['options'] as List<dynamic>?)
                ?.map(
                  (e) => FormQuestionOption.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}

class VisitFormTemplate {
  const VisitFormTemplate({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.questions = const [],
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final List<FormQuestion> questions;

  List<FormQuestion> get inputQuestions => questions
      .where((q) => q.questionType != FormQuestionType.sectionHeader)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  factory VisitFormTemplate.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>?)
            ?.map((e) => FormQuestion.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    questions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return VisitFormTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      questions: questions,
    );
  }
}

class VisitFormPrefill {
  const VisitFormPrefill({
    required this.executiveName,
    required this.visitDate,
    this.farmLocation,
    this.farmerContactName,
    this.checkinTime,
  });

  final String executiveName;
  final String visitDate;
  final String? farmLocation;
  final String? farmerContactName;
  final DateTime? checkinTime;

  factory VisitFormPrefill.fromJson(Map<String, dynamic> json) =>
      VisitFormPrefill(
        executiveName: json['executive_name'] as String? ?? '',
        visitDate: json['visit_date'] as String? ?? '',
        farmLocation: json['farm_location'] as String?,
        farmerContactName: json['farmer_contact_name'] as String?,
        checkinTime: json['checkin_time'] != null
            ? DateTime.tryParse(json['checkin_time'] as String)
            : null,
      );
}

class VisitFormContext {
  const VisitFormContext({
    required this.template,
    required this.prefill,
  });

  final VisitFormTemplate template;
  final VisitFormPrefill prefill;

  factory VisitFormContext.fromJson(Map<String, dynamic> json) =>
      VisitFormContext(
        template: VisitFormTemplate.fromJson(
          json['template'] as Map<String, dynamic>,
        ),
        prefill: VisitFormPrefill.fromJson(
          json['prefill'] as Map<String, dynamic>,
        ),
      );
}

class FormAnswerEntry {
  const FormAnswerEntry({
    required this.questionKey,
    this.answer,
    this.answerJson,
  });

  final String questionKey;
  final String? answer;
  final dynamic answerJson;

  Map<String, dynamic> toJson() => {
        'question_key': questionKey,
        if (answer != null) 'answer': answer,
        if (answerJson != null) 'answer_json': answerJson,
      };

  factory FormAnswerEntry.fromJson(Map<String, dynamic> json) =>
      FormAnswerEntry(
        questionKey: json['question_key'] as String? ?? '',
        answer: json['answer'] as String?,
        answerJson: json['answer_json'],
      );
}

class FormAnswerDisplay {
  const FormAnswerDisplay({
    required this.questionKey,
    required this.questionLabel,
    required this.questionType,
    this.answer,
    this.answerJson,
  });

  final String questionKey;
  final String questionLabel;
  final FormQuestionType questionType;
  final String? answer;
  final dynamic answerJson;

  factory FormAnswerDisplay.fromJson(Map<String, dynamic> json) =>
      FormAnswerDisplay(
        questionKey: json['question_key'] as String? ?? '',
        questionLabel: json['question_label'] as String? ?? '',
        questionType: FormQuestionType.fromApi(
          json['question_type'] as String? ?? 'text',
        ),
        answer: json['answer'] as String?,
        answerJson: json['answer_json'],
      );

  String displayValue({VisitFormTemplate? template}) {
    final question = _questionFor(template);

    if (questionType == FormQuestionType.matrix) {
      return _displayMatrix(question);
    }

    if (questionType == FormQuestionType.multiChoice) {
      final values = _rawListValues();
      if (values.isEmpty) return '—';
      return values
          .map((v) => _labelForValue(template, question, v))
          .join(', ');
    }

    if (questionType == FormQuestionType.singleChoice &&
        answer != null &&
        answer!.isNotEmpty) {
      return _labelForValue(template, question, answer!);
    }

    if (answer != null && answer!.isNotEmpty) return answer!;

    if (answerJson is List) {
      final values = (answerJson as List).map((e) => e.toString()).toList();
      if (values.isEmpty) return '—';
      return values
          .map((v) => _labelForValue(template, question, v))
          .join(', ');
    }

    if (answerJson is Map) {
      return _displayMatrix(question);
    }

    if (answerJson != null) return answerJson.toString();
    return '—';
  }

  Map<String, String> matrixEntries({VisitFormTemplate? template}) {
    final question = _questionFor(template);
    final map = answerJson is Map
        ? Map<String, String>.from(
            (answerJson as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ),
          )
        : <String, String>{};
    if (map.isEmpty) return const {};
    return map.map(
      (rowKey, colKey) => MapEntry(
        _matrixRowLabel(template, questionKey, rowKey, question),
        _matrixColLabel(question, colKey),
      ),
    );
  }

  FormQuestion? _questionFor(VisitFormTemplate? template) {
    if (template == null) return null;
    return template.questions
        .where((q) => q.questionKey == questionKey)
        .firstOrNull;
  }

  List<String> _rawListValues() {
    if (answerJson is List) {
      return (answerJson as List).map((e) => e.toString()).toList();
    }
    if (answer != null && answer!.isNotEmpty) {
      return answer!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  String _displayMatrix(FormQuestion? question) {
    final map = answerJson is Map
        ? Map<String, String>.from(
            (answerJson as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ),
          )
        : <String, String>{};
    if (map.isEmpty) return '—';
    final lines = map.entries.map((entry) {
      final rowLabel = _matrixRowLabel(
        null,
        questionKey,
        entry.key,
        question,
      );
      final colLabel = _matrixColLabel(question, entry.value);
      return '$rowLabel: $colLabel';
    });
    return lines.join('\n');
  }

  String _labelForValue(
    VisitFormTemplate? template,
    FormQuestion? question,
    String value,
  ) {
    final q = question ?? _questionFor(template);
    if (q != null) {
      final fromOption = q.options
          .where((o) => o.value == value)
          .map((o) => o.label)
          .firstOrNull;
      if (fromOption != null && fromOption.isNotEmpty) return fromOption;
    }
    return humanizeKey(value);
  }

  static String humanizeKey(String key) {
    if (key.isEmpty) return key;
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String _matrixRowLabel(
    VisitFormTemplate? template,
    String questionKey,
    String rowKey,
    FormQuestion? question,
  ) {
    final q = question ??
        (template == null
            ? null
            : template.questions
                .where((item) => item.questionKey == questionKey)
                .firstOrNull);
    final rows = q?.config?['rows'] as List<dynamic>?;
    if (rows != null) {
      for (final row in rows) {
        if (row is Map && row['key'] == rowKey) {
          return row['label'] as String? ?? humanizeKey(rowKey);
        }
      }
    }
    return humanizeKey(rowKey);
  }

  static String _matrixColLabel(FormQuestion? question, String colKey) {
    final columns = question?.config?['columns'] as List<dynamic>?;
    if (columns != null) {
      for (final col in columns) {
        if (col is Map && col['key'] == colKey) {
          return col['label'] as String? ?? humanizeKey(colKey);
        }
      }
    }
    final fromOption = question?.options
        .where((o) => o.value == colKey)
        .map((o) => o.label)
        .firstOrNull;
    return fromOption ?? humanizeKey(colKey);
  }
}

class FarmInvitation {
  const FarmInvitation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.locationAddress,
    this.distanceKm,
    this.farmerName,
    this.farmerMobile,
    this.assignmentRadiusKm = 70,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? locationAddress;
  final double? distanceKm;
  final String? farmerName;
  final String? farmerMobile;
  final double assignmentRadiusKm;

  factory FarmInvitation.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    var lat = (json['location_lat'] as num?)?.toDouble() ?? 0.0;
    var lng = (json['location_lng'] as num?)?.toDouble() ?? 0.0;
    var address = json['location_address'] as String?;
    if (location is Map<String, dynamic>) {
      lat = (location['lat'] as num?)?.toDouble() ?? lat;
      lng = (location['lng'] as num?)?.toDouble() ?? lng;
      address = location['address'] as String? ?? address;
    }
    final farmer = json['farmer'];
    return FarmInvitation(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      locationAddress: address,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      farmerName: farmer is Map ? farmer['name'] as String? : null,
      farmerMobile: farmer is Map ? farmer['mobile_number'] as String? : null,
      assignmentRadiusKm:
          (json['assignment_radius_km'] as num?)?.toDouble() ?? 70,
    );
  }
}

// Modelo de proyecto/startup para la plataforma InvestMatch

class ProjectModel {
  final String id;
  final String founderId;
  final String founderName;
  final String? founderAvatarUrl;
  final String title;
  final String description;
  final String vertical;
  final String stage;
  final String ticketSeeking;
  final String province;
  final List<String> impactFocus;
  final List<String> imageUrls;
  final String? pitchDeckUrl;
  final String? videoUrl;
  final String? websiteUrl;
  final bool isHighlighted;
  final bool isActive;
  final ProjectMetrics metrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos financieros opcionales
  final double? mrr;
  final double? arr;
  final int? teamSize;
  final int? foundedYear;
  final String? problemStatement;
  final String? solutionStatement;
  final String? businessModel;
  final String? competitiveAdvantage;
  final double? fundingRaised;

  const ProjectModel({
    required this.id,
    required this.founderId,
    required this.founderName,
    this.founderAvatarUrl,
    required this.title,
    required this.description,
    required this.vertical,
    required this.stage,
    required this.ticketSeeking,
    required this.province,
    required this.impactFocus,
    required this.imageUrls,
    this.pitchDeckUrl,
    this.videoUrl,
    this.websiteUrl,
    required this.isHighlighted,
    required this.isActive,
    required this.metrics,
    required this.createdAt,
    required this.updatedAt,
    this.mrr,
    this.arr,
    this.teamSize,
    this.foundedYear,
    this.problemStatement,
    this.solutionStatement,
    this.businessModel,
    this.competitiveAdvantage,
    this.fundingRaised,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      founderId: json['founderId'] as String,
      founderName: json['founderName'] as String,
      founderAvatarUrl: json['founderAvatarUrl'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      vertical: json['vertical'] as String,
      stage: json['stage'] as String,
      ticketSeeking: json['ticketSeeking'] as String,
      province: json['province'] as String,
      impactFocus: List<String>.from(json['impactFocus'] as List),
      imageUrls: List<String>.from(json['imageUrls'] as List),
      pitchDeckUrl: json['pitchDeckUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      isHighlighted: json['isHighlighted'] as bool,
      isActive: json['isActive'] as bool,
      metrics: ProjectMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      mrr: (json['mrr'] as num?)?.toDouble(),
      arr: (json['arr'] as num?)?.toDouble(),
      teamSize: json['teamSize'] as int?,
      foundedYear: json['foundedYear'] as int?,
      problemStatement: json['problemStatement'] as String?,
      solutionStatement: json['solutionStatement'] as String?,
      businessModel: json['businessModel'] as String?,
      competitiveAdvantage: json['competitiveAdvantage'] as String?,
      fundingRaised: (json['fundingRaised'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'founderId': founderId,
        'founderName': founderName,
        'founderAvatarUrl': founderAvatarUrl,
        'title': title,
        'description': description,
        'vertical': vertical,
        'stage': stage,
        'ticketSeeking': ticketSeeking,
        'province': province,
        'impactFocus': impactFocus,
        'imageUrls': imageUrls,
        'pitchDeckUrl': pitchDeckUrl,
        'videoUrl': videoUrl,
        'websiteUrl': websiteUrl,
        'isHighlighted': isHighlighted,
        'isActive': isActive,
        'metrics': metrics.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'mrr': mrr,
        'arr': arr,
        'teamSize': teamSize,
        'foundedYear': foundedYear,
        'problemStatement': problemStatement,
        'solutionStatement': solutionStatement,
        'businessModel': businessModel,
        'competitiveAdvantage': competitiveAdvantage,
        'fundingRaised': fundingRaised,
      };
}

class ProjectMetrics {
  final int totalViews;
  final int uniqueViews;
  final int contactsReceived;
  final int savedAsFavorite;
  final int pitchOpens;
  final double pitchCtr; // click-through rate del pitch deck
  final int meetingsScheduled;

  const ProjectMetrics({
    required this.totalViews,
    required this.uniqueViews,
    required this.contactsReceived,
    required this.savedAsFavorite,
    required this.pitchOpens,
    required this.pitchCtr,
    required this.meetingsScheduled,
  });

  factory ProjectMetrics.fromJson(Map<String, dynamic> json) {
    return ProjectMetrics(
      totalViews: json['totalViews'] as int,
      uniqueViews: json['uniqueViews'] as int,
      contactsReceived: json['contactsReceived'] as int,
      savedAsFavorite: json['savedAsFavorite'] as int,
      pitchOpens: json['pitchOpens'] as int,
      pitchCtr: (json['pitchCtr'] as num).toDouble(),
      meetingsScheduled: json['meetingsScheduled'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalViews': totalViews,
        'uniqueViews': uniqueViews,
        'contactsReceived': contactsReceived,
        'savedAsFavorite': savedAsFavorite,
        'pitchOpens': pitchOpens,
        'pitchCtr': pitchCtr,
        'meetingsScheduled': meetingsScheduled,
      };
}

// Modelo de pipeline de inversión (para inversores)
class PipelineEntry {
  final String id;
  final String investorId;
  final String projectId;
  final ProjectModel project;
  final PipelineStage stage;
  final String? notes;
  final DateTime addedAt;
  final DateTime updatedAt;

  const PipelineEntry({
    required this.id,
    required this.investorId,
    required this.projectId,
    required this.project,
    required this.stage,
    this.notes,
    required this.addedAt,
    required this.updatedAt,
  });

  factory PipelineEntry.fromJson(Map<String, dynamic> json) {
    return PipelineEntry(
      id: json['id'] as String,
      investorId: json['investorId'] as String,
      projectId: json['projectId'] as String,
      project: ProjectModel.fromJson(json['project'] as Map<String, dynamic>),
      stage: PipelineStage.values.byName(json['stage'] as String),
      notes: json['notes'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'investorId': investorId,
        'projectId': projectId,
        'project': project.toJson(),
        'stage': stage.name,
        'notes': notes,
        'addedAt': addedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  PipelineEntry copyWith({PipelineStage? stage, String? notes}) {
    return PipelineEntry(
      id: id,
      investorId: investorId,
      projectId: projectId,
      project: project,
      stage: stage ?? this.stage,
      notes: notes ?? this.notes,
      addedAt: addedAt,
      updatedAt: DateTime.now(),
    );
  }
}

enum PipelineStage {
  discovered,
  contacted,
  evaluating,
  met,
  dueDiligence,
  closed,
  rejected,
}

extension PipelineStageLabel on PipelineStage {
  String get label {
    switch (this) {
      case PipelineStage.discovered:
        return 'Descubierto';
      case PipelineStage.contacted:
        return 'Contactado';
      case PipelineStage.evaluating:
        return 'Evaluando';
      case PipelineStage.met:
        return 'Reunido';
      case PipelineStage.dueDiligence:
        return 'Due Diligence';
      case PipelineStage.closed:
        return 'Cerrado';
      case PipelineStage.rejected:
        return 'Rechazado';
    }
  }
}

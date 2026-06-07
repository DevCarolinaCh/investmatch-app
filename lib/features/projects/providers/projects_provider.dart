import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/project_model.dart';

// Proyectos destacados para el home
final highlightedProjectsProvider =
    FutureProvider<List<ProjectModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getProjects(highlighted: true);
  final list = data['data'] as List;
  return list.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)).toList();
});

// Proyectos recientes para el home
final recentProjectsProvider =
    FutureProvider<List<ProjectModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getProjects(page: 1);
  final list = data['data'] as List;
  return list.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)).toList();
});

// Proyecto individual por ID
final projectProvider =
    FutureProvider.family<ProjectModel, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getProject(id);
  return ProjectModel.fromJson(data);
});

// Filtros de búsqueda
class SearchFilters {
  final String? query;
  final String? vertical;
  final String? stage;
  final String? ticket;
  final String? province;
  final String? impact;
  final int page;

  const SearchFilters({
    this.query,
    this.vertical,
    this.stage,
    this.ticket,
    this.province,
    this.impact,
    this.page = 1,
  });

  SearchFilters copyWith({
    String? query,
    String? vertical,
    String? stage,
    String? ticket,
    String? province,
    String? impact,
    int? page,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      vertical: vertical ?? this.vertical,
      stage: stage ?? this.stage,
      ticket: ticket ?? this.ticket,
      province: province ?? this.province,
      impact: impact ?? this.impact,
      page: page ?? this.page,
    );
  }

  bool get hasActiveFilters =>
      vertical != null ||
      stage != null ||
      ticket != null ||
      province != null ||
      impact != null;

  int get activeFilterCount {
    int count = 0;
    if (vertical != null) count++;
    if (stage != null) count++;
    if (ticket != null) count++;
    if (province != null) count++;
    if (impact != null) count++;
    return count;
  }
}

final searchFiltersProvider =
    StateProvider<SearchFilters>((ref) => const SearchFilters());

final searchResultsProvider =
    FutureProvider<List<ProjectModel>>((ref) async {
  final filters = ref.watch(searchFiltersProvider);
  final api = ref.watch(apiServiceProvider);

  final data = await api.getProjects(
    page: filters.page,
    vertical: filters.vertical,
    stage: filters.stage,
    ticket: filters.ticket,
    province: filters.province,
    impact: filters.impact,
    search: filters.query,
  );
  final list = data['data'] as List;
  return list.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)).toList();
});

// Favoritos del inversor
final favoritesProvider =
    FutureProvider<List<ProjectModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getFavorites();
  return data
      .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Pipeline del inversor
final pipelineProvider =
    FutureProvider<List<PipelineEntry>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getPipeline();
  return data
      .map((e) => PipelineEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Notifier para gestionar el pipeline
class PipelineNotifier extends AsyncNotifier<List<PipelineEntry>> {
  @override
  Future<List<PipelineEntry>> build() async {
    final api = ref.watch(apiServiceProvider);
    final data = await api.getPipeline();
    return data
        .map((e) => PipelineEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addProject(String projectId) async {
    final api = ref.read(apiServiceProvider);
    await api.addToPipeline(projectId);
    ref.invalidateSelf();
  }

  Future<void> updateStage(
    String entryId,
    PipelineStage stage, {
    String? notes,
  }) async {
    final api = ref.read(apiServiceProvider);
    await api.updatePipelineStage(
      entryId,
      stage.name,
      notes: notes,
    );
    ref.invalidateSelf();
  }
}

final pipelineNotifierProvider =
    AsyncNotifierProvider<PipelineNotifier, List<PipelineEntry>>(
  PipelineNotifier.new,
);

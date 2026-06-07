import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/project_model.dart';
import '../../../shared/services/demo_data.dart';

// Proyectos destacados para el home
final highlightedProjectsProvider =
    FutureProvider<List<ProjectModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return DemoData.projects.where((p) => p.isHighlighted).toList();
});

// Proyectos recientes para el home
final recentProjectsProvider =
    FutureProvider<List<ProjectModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return DemoData.projects;
});

// Proyecto individual por ID
final projectProvider =
    FutureProvider.family<ProjectModel, String>((ref, id) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return DemoData.projects.firstWhere(
    (p) => p.id == id,
    orElse: () => DemoData.projects.first,
  );
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
  await Future.delayed(const Duration(milliseconds: 500));

  var results = DemoData.projects.toList();

  if (filters.query != null && filters.query!.isNotEmpty) {
    final q = filters.query!.toLowerCase();
    results = results.where((p) =>
      p.title.toLowerCase().contains(q) ||
      p.description.toLowerCase().contains(q) ||
      p.vertical.toLowerCase().contains(q),
    ).toList();
  }
  if (filters.vertical != null) {
    results = results.where((p) => p.vertical == filters.vertical).toList();
  }
  if (filters.stage != null) {
    results = results.where((p) => p.stage == filters.stage).toList();
  }
  if (filters.ticket != null) {
    results = results.where((p) => p.ticketSeeking == filters.ticket).toList();
  }
  if (filters.province != null) {
    results = results.where((p) => p.province == filters.province).toList();
  }
  if (filters.impact != null) {
    results = results.where((p) => p.impactFocus.contains(filters.impact)).toList();
  }
  return results;
});

// Favoritos del inversor
final favoritesProvider =
    FutureProvider<List<ProjectModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return DemoData.projects.take(3).toList();
});

// Pipeline del inversor
final pipelineProvider =
    FutureProvider<List<PipelineEntry>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return DemoData.pipeline;
});

// Notifier para gestionar el pipeline con estado mutable
class PipelineNotifier extends AsyncNotifier<List<PipelineEntry>> {
  @override
  Future<List<PipelineEntry>> build() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(DemoData.pipeline);
  }

  Future<void> addProject(String projectId) async {
    final project = DemoData.projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => DemoData.projects.first,
    );
    final current = state.value ?? [];
    final already = current.any((e) => e.projectId == projectId);
    if (already) return;

    final newEntry = PipelineEntry(
      id: 'pipe_${DateTime.now().millisecondsSinceEpoch}',
      investorId: 'investor_001',
      projectId: projectId,
      project: project,
      stage: PipelineStage.discovered,
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = AsyncValue.data([...current, newEntry]);
  }

  Future<void> updateStage(
    String entryId,
    PipelineStage stage, {
    String? notes,
  }) async {
    final current = state.value ?? [];
    final updated = current.map((e) {
      if (e.id == entryId) {
        return PipelineEntry(
          id: e.id,
          investorId: e.investorId,
          projectId: e.projectId,
          project: e.project,
          stage: stage,
          notes: notes ?? e.notes,
          addedAt: e.addedAt,
          updatedAt: DateTime.now(),
        );
      }
      return e;
    }).toList();
    state = AsyncValue.data(updated);
  }

  Future<void> removeFromPipeline(String entryId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((e) => e.id != entryId).toList());
  }
}

final pipelineNotifierProvider =
    AsyncNotifierProvider<PipelineNotifier, List<PipelineEntry>>(
  PipelineNotifier.new,
);

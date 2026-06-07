import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../projects/providers/projects_provider.dart';
import '../../../shared/models/project_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter(String field, String? value) {
    final current = ref.read(searchFiltersProvider);
    ref.read(searchFiltersProvider.notifier).state = switch (field) {
      'vertical' => current.copyWith(vertical: value),
      'stage' => current.copyWith(stage: value),
      'ticket' => current.copyWith(ticket: value),
      'province' => current.copyWith(province: value),
      'impact' => current.copyWith(impact: value),
      _ => current,
    };
  }

  void _clearFilters() {
    ref.read(searchFiltersProvider.notifier).state = const SearchFilters();
    _searchCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar proyectos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, descripción...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(searchFiltersProvider.notifier).state =
                              filters.copyWith(query: null);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                ref.read(searchFiltersProvider.notifier).state =
                    filters.copyWith(query: v.isEmpty ? null : v);
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Barra de filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Botón filtrar
                _FilterChipButton(
                  label: 'Filtros',
                  icon: Icons.tune,
                  count: filters.activeFilterCount,
                  onTap: () => _showFilterSheet(context, filters),
                ),
                const SizedBox(width: 8),

                // Chips de filtros activos
                if (filters.vertical != null)
                  _ActiveFilterChip(
                    label: filters.vertical!,
                    onRemove: () => _applyFilter('vertical', null),
                  ),
                if (filters.stage != null)
                  _ActiveFilterChip(
                    label: filters.stage!,
                    onRemove: () => _applyFilter('stage', null),
                  ),
                if (filters.ticket != null)
                  _ActiveFilterChip(
                    label: filters.ticket!,
                    onRemove: () => _applyFilter('ticket', null),
                  ),
                if (filters.province != null)
                  _ActiveFilterChip(
                    label: filters.province!,
                    onRemove: () => _applyFilter('province', null),
                  ),
                if (filters.impact != null)
                  _ActiveFilterChip(
                    label: filters.impact!,
                    onRemove: () => _applyFilter('impact', null),
                  ),
                if (filters.hasActiveFilters) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Resultados
          Expanded(
            child: results.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Error al cargar: $e'),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(searchResultsProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (projects) => projects.isEmpty
                  ? _EmptyResults(hasFilters: filters.hasActiveFilters)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _ProjectSearchCard(
                        project: projects[index],
                        onTap: () =>
                            context.push('/projects/${projects[index].id}'),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, SearchFilters current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(
        current: current,
        onApply: (filters) {
          ref.read(searchFiltersProvider.notifier).state = filters;
        },
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: count > 0 ? AppColors.primaryLight : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: count > 0 ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: count > 0 ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: count > 0 ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ProjectSearchCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _ProjectSearchCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: project.imageUrls.isNotEmpty
                      ? Image.network(
                          project.imageUrls.first,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.rocket_launch_outlined,
                              color: AppColors.primary, size: 28),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (project.isHighlighted)
                            const Icon(Icons.star,
                                size: 16, color: AppColors.warning),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.founderName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              project.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                _InfoChip(label: project.vertical, color: AppColors.primary),
                _InfoChip(label: project.stage, color: AppColors.secondary),
                _InfoChip(label: project.province, color: AppColors.textSecondary),
                _InfoChip(label: project.ticketSeeking, color: AppColors.accent),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.visibility_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${project.metrics.totalViews} vistas',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.bookmark_outline,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${project.metrics.savedAsFavorite} guardados',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final bool hasFilters;
  const _EmptyResults({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters ? Icons.filter_alt_off : Icons.search_off,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No encontramos proyectos\ncon esos filtros'
                : 'No hay proyectos disponibles',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 12),
            const Text(
              'Intentá ampliar los criterios de búsqueda',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

// Bottom sheet de filtros avanzados
class _FilterBottomSheet extends StatefulWidget {
  final SearchFilters current;
  final ValueChanged<SearchFilters> onApply;

  const _FilterBottomSheet({required this.current, required this.onApply});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late SearchFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtros',
                      style: Theme.of(context).textTheme.headlineSmall),
                  TextButton(
                    onPressed: () =>
                        setState(() => _draft = const SearchFilters()),
                    child: const Text('Limpiar todo'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  _FilterSection(
                    title: 'Vertical / Industria',
                    options: AppConstants.verticals,
                    selected: _draft.vertical,
                    onSelect: (v) => setState(() => _draft = _draft.copyWith(vertical: v)),
                  ),
                  const SizedBox(height: 20),
                  _FilterSection(
                    title: 'Etapa de la startup',
                    options: AppConstants.startupStages,
                    selected: _draft.stage,
                    onSelect: (v) => setState(() => _draft = _draft.copyWith(stage: v)),
                  ),
                  const SizedBox(height: 20),
                  _FilterSection(
                    title: 'Ticket de inversión',
                    options: AppConstants.ticketRanges,
                    selected: _draft.ticket,
                    onSelect: (v) => setState(() => _draft = _draft.copyWith(ticket: v)),
                  ),
                  const SizedBox(height: 20),
                  _FilterSection(
                    title: 'Provincia',
                    options: AppConstants.provinces,
                    selected: _draft.province,
                    onSelect: (v) => setState(() => _draft = _draft.copyWith(province: v)),
                  ),
                  const SizedBox(height: 20),
                  _FilterSection(
                    title: 'Impacto',
                    options: AppConstants.impactCategories,
                    selected: _draft.impact,
                    onSelect: (v) => setState(() => _draft = _draft.copyWith(impact: v)),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_draft);
                  Navigator.pop(context);
                },
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _FilterSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return GestureDetector(
              onTap: () => onSelect(isSelected ? null : opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

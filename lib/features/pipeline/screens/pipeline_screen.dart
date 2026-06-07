import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/project_model.dart';
import '../../projects/providers/projects_provider.dart';

class PipelineScreen extends ConsumerWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipeline = ref.watch(pipelineNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Pipeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: pipeline.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(pipelineNotifierProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) return _EmptyPipeline();

          // Agrupar por etapa
          final grouped = <PipelineStage, List<PipelineEntry>>{};
          for (final stage in PipelineStage.values) {
            grouped[stage] = entries
                .where((e) => e.stage == stage)
                .toList();
          }

          return Column(
            children: [
              // Resumen de etapas (kanban header)
              _PipelineSummary(grouped: grouped),
              const Divider(height: 1),
              // Lista por etapas
              Expanded(
                child: DefaultTabController(
                  length: PipelineStage.values.length,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                        tabs: PipelineStage.values.map((stage) {
                          final count =
                              grouped[stage]?.length ?? 0;
                          return Tab(
                            child: Row(
                              children: [
                                Text(stage.label),
                                if (count > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _stageColor(stage),
                                      borderRadius: BorderRadius.circular(10),
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
                          );
                        }).toList(),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: PipelineStage.values.map((stage) {
                            final stageEntries = grouped[stage] ?? [];
                            if (stageEntries.isEmpty) {
                              return _EmptyStage(stage: stage);
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: stageEntries.length,
                              itemBuilder: (context, index) =>
                                  _PipelineCard(
                                entry: stageEntries[index],
                                onTap: () => context.push(
                                    '/projects/${stageEntries[index].projectId}'),
                                onStageChange: (newStage) =>
                                    ref
                                        .read(pipelineNotifierProvider.notifier)
                                        .updateStage(
                                          stageEntries[index].id,
                                          newStage,
                                        ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _stageColor(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.discovered:
        return AppColors.pipelineDiscovered;
      case PipelineStage.contacted:
        return AppColors.pipelineContacted;
      case PipelineStage.evaluating:
        return AppColors.pipelineEvaluating;
      case PipelineStage.met:
        return AppColors.pipelineMet;
      case PipelineStage.dueDiligence:
        return AppColors.pipelineDueDiligence;
      case PipelineStage.closed:
        return AppColors.pipelineClosed;
      case PipelineStage.rejected:
        return AppColors.pipelineRejected;
    }
  }
}

class _PipelineSummary extends StatelessWidget {
  final Map<PipelineStage, List<PipelineEntry>> grouped;
  const _PipelineSummary({required this.grouped});

  @override
  Widget build(BuildContext context) {
    final active = PipelineStage.values
        .where((s) => s != PipelineStage.rejected)
        .expand((s) => grouped[s] ?? [])
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _SummaryChip(
            label: 'Activos',
            value: '$active',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _SummaryChip(
            label: 'Due Diligence',
            value: '${grouped[PipelineStage.dueDiligence]?.length ?? 0}',
            color: AppColors.pipelineDueDiligence,
          ),
          const SizedBox(width: 10),
          _SummaryChip(
            label: 'Cerrados',
            value: '${grouped[PipelineStage.closed]?.length ?? 0}',
            color: AppColors.pipelineClosed,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  final PipelineEntry entry;
  final VoidCallback onTap;
  final ValueChanged<PipelineStage> onStageChange;

  const _PipelineCard({
    required this.entry,
    required this.onTap,
    required this.onStageChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: entry.project.imageUrls.isNotEmpty
                        ? Image.network(
                            entry.project.imageUrls.first,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: AppColors.primaryLight,
                            child: const Icon(Icons.business_outlined,
                                color: AppColors.primary, size: 22),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.project.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${entry.project.vertical} · ${entry.project.stage}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Menú para cambiar etapa
                  PopupMenuButton<PipelineStage>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: onStageChange,
                    itemBuilder: (_) => PipelineStage.values
                        .map(
                          (stage) => PopupMenuItem(
                            value: stage,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _stageColor(stage),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  stage.label,
                                  style: TextStyle(
                                    fontWeight: stage == entry.stage
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _StageLabel(stage: entry.stage),
                  const Spacer(),
                  Text(
                    entry.project.ticketSeeking,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _stageColor(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.discovered:
        return AppColors.pipelineDiscovered;
      case PipelineStage.contacted:
        return AppColors.pipelineContacted;
      case PipelineStage.evaluating:
        return AppColors.pipelineEvaluating;
      case PipelineStage.met:
        return AppColors.pipelineMet;
      case PipelineStage.dueDiligence:
        return AppColors.pipelineDueDiligence;
      case PipelineStage.closed:
        return AppColors.pipelineClosed;
      case PipelineStage.rejected:
        return AppColors.pipelineRejected;
    }
  }
}

class _StageLabel extends StatelessWidget {
  final PipelineStage stage;
  const _StageLabel({required this.stage});

  Color get _color {
    switch (stage) {
      case PipelineStage.discovered:
        return AppColors.pipelineDiscovered;
      case PipelineStage.contacted:
        return AppColors.pipelineContacted;
      case PipelineStage.evaluating:
        return AppColors.pipelineEvaluating;
      case PipelineStage.met:
        return AppColors.pipelineMet;
      case PipelineStage.dueDiligence:
        return AppColors.pipelineDueDiligence;
      case PipelineStage.closed:
        return AppColors.pipelineClosed;
      case PipelineStage.rejected:
        return AppColors.pipelineRejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            stage.label,
            style: TextStyle(
              fontSize: 11,
              color: _color,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStage extends StatelessWidget {
  final PipelineStage stage;
  const _EmptyStage({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            'Sin proyectos en "${stage.label}"',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyPipeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_tree_outlined,
              size: 72, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Tu pipeline está vacío',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Guardá proyectos para hacer seguimiento\nde tus oportunidades de inversión',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
            label: const Text('Explorar proyectos'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
          ),
        ],
      ),
    );
  }
}

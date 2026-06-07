import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/project_model.dart';

final projectAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getProjectAnalytics(projectId);
});

class AnalyticsScreen extends ConsumerWidget {
  final String projectId;
  const AnalyticsScreen({required this.projectId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(projectAnalyticsProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas del proyecto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {}, // TODO: compartir reporte
          ),
        ],
      ),
      body: analytics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final metrics = data['metrics'] as Map<String, dynamic>? ?? {};
          final weeklyViews = (data['weeklyViews'] as List?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              List.filled(7, 0.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen de métricas clave
                Text('Resumen',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _MetricCard(
                      label: 'Vistas totales',
                      value: '${metrics['totalViews'] ?? 0}',
                      subLabel: '+12% esta semana',
                      icon: Icons.visibility_outlined,
                      color: AppColors.primary,
                      trend: TrendDirection.up,
                    ),
                    _MetricCard(
                      label: 'Vistas únicas',
                      value: '${metrics['uniqueViews'] ?? 0}',
                      subLabel: 'inversores distintos',
                      icon: Icons.person_search_outlined,
                      color: AppColors.secondary,
                    ),
                    _MetricCard(
                      label: 'Contactos',
                      value: '${metrics['contactsReceived'] ?? 0}',
                      subLabel: 'mensajes recibidos',
                      icon: Icons.mail_outline,
                      color: AppColors.accent,
                      trend: TrendDirection.up,
                    ),
                    _MetricCard(
                      label: 'CTR del pitch',
                      value:
                          '${((metrics['pitchCtr'] ?? 0.0) as num).toStringAsFixed(1)}%',
                      subLabel: 'abrieron el pitch deck',
                      icon: Icons.open_in_new_outlined,
                      color: AppColors.pipelineDueDiligence,
                    ),
                    _MetricCard(
                      label: 'Guardados',
                      value: '${metrics['savedAsFavorite'] ?? 0}',
                      subLabel: 'en favoritos',
                      icon: Icons.bookmark_outline,
                      color: AppColors.pipelineEvaluating,
                    ),
                    _MetricCard(
                      label: 'Reuniones',
                      value: '${metrics['meetingsScheduled'] ?? 0}',
                      subLabel: 'intro calls agendadas',
                      icon: Icons.video_call_outlined,
                      color: AppColors.pipelineClosed,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Gráfico de vistas semanales
                Text('Vistas esta semana',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Container(
                  height: 180,
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                              final index = value.toInt();
                              if (index < 0 || index >= days.length) {
                                return const SizedBox();
                              }
                              return Text(
                                days[index],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Inter',
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: weeklyViews.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value);
                          }).toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Inversores que vieron el proyecto
                Text('Últimos inversores que visitaron',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Datos simulados de visitantes recientes
                      ...[
                        ('Juan M.', 'Buenos Aires', '2h atrás'),
                        ('María P.', 'Córdoba', 'Ayer'),
                        ('Carlos R.', 'CABA', 'Hace 3 días'),
                      ].map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  v.$1[0],
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.$1,
                                        style: Theme.of(context).textTheme.labelLarge),
                                    Text(v.$2,
                                        style:
                                            Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              Text(v.$3,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Ver todos los visitantes'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum TrendDirection { up, down, neutral }

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final IconData icon;
  final Color color;
  final TrendDirection trend;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.icon,
    required this.color,
    this.trend = TrendDirection.neutral,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (trend != TrendDirection.neutral)
                Icon(
                  trend == TrendDirection.up
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 16,
                  color: trend == TrendDirection.up
                      ? AppColors.secondary
                      : AppColors.error,
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                subLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

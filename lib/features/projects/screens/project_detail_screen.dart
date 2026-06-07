import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/project_model.dart';
import '../../../shared/models/user_model.dart';
import '../providers/projects_provider.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({required this.projectId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider(projectId));
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      body: project.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error: $e')),
        ),
        data: (p) => _ProjectDetailContent(project: p, currentUser: user),
      ),
    );
  }
}

class _ProjectDetailContent extends ConsumerStatefulWidget {
  final ProjectModel project;
  final UserModel? currentUser;

  const _ProjectDetailContent({
    required this.project,
    required this.currentUser,
  });

  @override
  ConsumerState<_ProjectDetailContent> createState() =>
      _ProjectDetailContentState();
}

class _ProjectDetailContentState
    extends ConsumerState<_ProjectDetailContent> {
  bool _isFavorite = false;
  bool _isInPipeline = false;
  int _currentImageIndex = 0;

  Future<void> _toggleFavorite() async {
    final api = ref.read(apiServiceProvider);
    setState(() => _isFavorite = !_isFavorite);
    try {
      if (_isFavorite) {
        await api.addFavorite(widget.project.id);
      } else {
        await api.removeFavorite(widget.project.id);
      }
    } catch (e) {
      setState(() => _isFavorite = !_isFavorite);
    }
  }

  Future<void> _addToPipeline() async {
    await ref
        .read(pipelineNotifierProvider.notifier)
        .addProject(widget.project.id);
    setState(() => _isInPipeline = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proyecto agregado a tu pipeline'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Future<void> _contactFounder() async {
    final api = ref.read(apiServiceProvider);
    final data = await api.getOrCreateConversation(widget.project.id);
    final conversationId = data['id'] as String;
    if (!mounted) return;
    context.push(
      '/chat/$conversationId?title=${Uri.encodeComponent(widget.project.title)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final isInvestor = widget.currentUser?.isInvestor ?? true;
    final isOwner = widget.currentUser?.id == p.founderId;

    return CustomScrollView(
      slivers: [
        // App bar con imagen
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          leading: const BackButton(),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                color: _isFavorite ? AppColors.primary : Colors.white,
              ),
              onPressed: isInvestor ? _toggleFavorite : null,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onPressed: () {}, // TODO: compartir
            ),
            if (!isOwner)
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: Colors.white),
                onPressed: () => _showReportSheet(context),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: p.imageUrls.isNotEmpty
                ? PageView.builder(
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemCount: p.imageUrls.length,
                    itemBuilder: (_, i) => Image.network(
                      p.imageUrls[i],
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    color: AppColors.primaryLight,
                    child: const Center(
                      child: Icon(Icons.rocket_launch_outlined,
                          size: 80, color: AppColors.primary),
                    ),
                  ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y verificación
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.isHighlighted)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('⭐ Proyecto Destacado',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter')),
                            ),
                          Text(p.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Fundador
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: p.founderAvatarUrl != null
                          ? NetworkImage(p.founderAvatarUrl!)
                          : null,
                      child: p.founderAvatarUrl == null
                          ? Text(p.founderName[0],
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600))
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text('por ${p.founderName}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 16),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoBadge(
                        icon: Icons.category_outlined,
                        label: p.vertical,
                        color: AppColors.primary),
                    _InfoBadge(
                        icon: Icons.stairs_outlined,
                        label: p.stage,
                        color: AppColors.secondary),
                    _InfoBadge(
                        icon: Icons.attach_money,
                        label: p.ticketSeeking,
                        color: AppColors.accent),
                    _InfoBadge(
                        icon: Icons.location_on_outlined,
                        label: p.province,
                        color: AppColors.textSecondary),
                    ...p.impactFocus.map((impact) => _InfoBadge(
                          icon: Icons.eco_outlined,
                          label: impact,
                          color: AppColors.secondary,
                        )),
                  ],
                ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 16),

                // Descripción
                Text('Sobre el proyecto',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(p.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        )),

                // Problema / Solución
                if (p.problemStatement != null) ...[
                  const SizedBox(height: 20),
                  _Section(
                    title: 'El problema',
                    content: p.problemStatement!,
                    icon: Icons.help_outline,
                    color: AppColors.error,
                  ),
                ],
                if (p.solutionStatement != null) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Nuestra solución',
                    content: p.solutionStatement!,
                    icon: Icons.lightbulb_outline,
                    color: AppColors.secondary,
                  ),
                ],
                if (p.businessModel != null) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Modelo de negocio',
                    content: p.businessModel!,
                    icon: Icons.monetization_on_outlined,
                    color: AppColors.primary,
                  ),
                ],

                // Números clave
                if (p.mrr != null || p.teamSize != null || p.foundedYear != null) ...[
                  const SizedBox(height: 20),
                  Text('Números clave',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (p.mrr != null)
                        _NumberCard(
                            label: 'MRR',
                            value: 'USD ${p.mrr!.toStringAsFixed(0)}'),
                      if (p.arr != null)
                        _NumberCard(
                            label: 'ARR',
                            value: 'USD ${p.arr!.toStringAsFixed(0)}'),
                      if (p.teamSize != null)
                        _NumberCard(
                            label: 'Equipo',
                            value: '${p.teamSize} personas'),
                      if (p.foundedYear != null)
                        _NumberCard(
                            label: 'Fundado', value: '${p.foundedYear}'),
                    ],
                  ),
                ],

                // Links
                if (p.websiteUrl != null || p.pitchDeckUrl != null) ...[
                  const SizedBox(height: 20),
                  Text('Recursos',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  if (p.websiteUrl != null)
                    _LinkButton(
                      icon: Icons.language_outlined,
                      label: 'Visitar sitio web',
                      onTap: () => launchUrl(Uri.parse(p.websiteUrl!)),
                    ),
                  if (p.pitchDeckUrl != null) ...[
                    const SizedBox(height: 8),
                    _LinkButton(
                      icon: Icons.slideshow_outlined,
                      label: 'Ver Pitch Deck',
                      onTap: () => launchUrl(Uri.parse(p.pitchDeckUrl!)),
                    ),
                  ],
                ],

                const SizedBox(height: 100), // Espacio para los botones flotantes
              ],
            ),
          ),
        ),
      ],

      // Botones de acción flotantes
    );
  }

  Widget build2(BuildContext context) {
    return const SizedBox();
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reportar proyecto',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...['Información falsa', 'Contenido inapropiado', 'Spam', 'Otro']
                .map((reason) => ListTile(
                      title: Text(reason),
                      contentPadding: EdgeInsets.zero,
                      onTap: () async {
                        Navigator.pop(context);
                        final api = ref.read(apiServiceProvider);
                        await api.reportProject(widget.project.id, reason);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Reporte enviado. Gracias.')),
                        );
                      },
                    )),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _Section({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  )),
        ],
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  final String label;
  final String value;

  const _NumberCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontFamily: 'Inter',
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/projects_provider.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final isFounder = user?.isFounder ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFounder ? 'Mis proyectos' : 'Todos los proyectos'),
        actions: [
          if (isFounder)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/projects/new'),
            ),
        ],
      ),
      body: const Center(child: Text('Lista de proyectos')),
    );
  }
}

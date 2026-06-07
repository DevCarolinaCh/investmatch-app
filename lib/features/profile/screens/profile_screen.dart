import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authNotifierProvider);

    return userState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox());
        return _ProfileContent(user: user);
      },
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final UserModel user;
  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            title: const Text('Mi Perfil'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {}, // TODO: pantalla de configuración
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(
                                    user.fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {}, // TODO: cambiar avatar
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 16, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                  // Nombre y rol
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  color: AppColors.primary, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        _RoleBadge(role: user.role),
                        const SizedBox(height: 4),
                        _KycStatusBadge(status: user.kycStatus),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // KYC warning si no está verificado
                  if (user.kycStatus == KycStatus.pending)
                    _VerificationBanner(onTap: () => context.push('/kyc')),

                  // Plan actual
                  _PlanBanner(plan: user.plan, onUpgrade: () => context.push('/payments')),

                  const SizedBox(height: 20),

                  // Info del perfil
                  if (user.bio != null) ...[
                    Text('Bio', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(user.bio!, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                  ],

                  if (user.province != null)
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: user.province!,
                    ),

                  if (user.linkedinUrl != null)
                    _InfoRow(
                      icon: Icons.link,
                      label: 'LinkedIn',
                      onTap: () {},
                    ),

                  const SizedBox(height: 24),

                  // Secciones según rol
                  if (user.isFounder) ...[
                    Text('Mis proyectos',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.rocket_launch_outlined,
                      title: 'Ver y gestionar mis proyectos',
                      subtitle: 'Editar, analytics, actualizar estado',
                      onTap: () => context.push('/projects'),
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.bar_chart_outlined,
                      title: 'Ver métricas',
                      subtitle: 'Vistas, contactos, CTR del pitch',
                      onTap: () {
                        // Navegar al primer proyecto del founder
                      },
                    ),
                  ],

                  if (user.isInvestor) ...[
                    Text('Mi actividad',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.account_tree_outlined,
                      title: 'Mi pipeline',
                      subtitle: 'Gestionar mis oportunidades de inversión',
                      onTap: () => context.go('/pipeline'),
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.bookmark_outlined,
                      title: 'Proyectos favoritos',
                      subtitle: 'Los proyectos que guardaste',
                      onTap: () {},
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Configuración general
                  Text('Configuración',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),

                  _ActionCard(
                    icon: Icons.person_outline,
                    title: 'Editar perfil',
                    subtitle: 'Nombre, bio, provincia, LinkedIn',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.notifications_outlined,
                    title: 'Notificaciones',
                    subtitle: 'Configurar qué notificaciones recibís',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.security_outlined,
                    title: 'Seguridad',
                    subtitle: 'Cambiar contraseña, 2FA',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacidad y datos',
                    subtitle: 'Descargar tus datos (Ley 25.326)',
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),

                  // Cerrar sesión
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cerrar sesión'),
                          content: const Text(
                              '¿Estás seguro que querés cerrar sesión?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Cerrar sesión',
                                  style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) context.go('/auth/login');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.logout_outlined),
                    label: const Text('Cerrar sesión'),
                  ),

                  const SizedBox(height: 16),

                  // Eliminar cuenta
                  Center(
                    child: TextButton(
                      onPressed: () {}, // TODO: flujo de eliminación de cuenta
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textTertiary),
                      child: const Text('Eliminar cuenta'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      UserRole.investor => ('Inversor', AppColors.primary),
      UserRole.founder => ('Emprendedor', AppColors.secondary),
      UserRole.admin => ('Admin', AppColors.error),
      UserRole.moderator => ('Moderador', AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _KycStatusBadge extends StatelessWidget {
  final KycStatus status;
  const _KycStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      KycStatus.verified => ('Identidad verificada', AppColors.secondary, Icons.verified),
      KycStatus.pending => ('Sin verificar', AppColors.warning, Icons.warning_amber),
      KycStatus.inProgress => ('Verificación en proceso', AppColors.primary, Icons.hourglass_top),
      KycStatus.rejected => ('Verificación rechazada', AppColors.error, Icons.cancel_outlined),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _VerificationBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verificá tu identidad',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'Completar el KYC desbloquea todas las funciones',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.warning),
          ],
        ),
      ),
    );
  }
}

class _PlanBanner extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onUpgrade;

  const _PlanBanner({required this.plan, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    if (plan != SubscriptionPlan.free) return const SizedBox();

    return GestureDetector(
      onTap: onUpgrade,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_outline, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pasate a Pro',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'Filtros avanzados, mensajería ilimitada, pipeline completo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _InfoRow({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'Inter',
                fontSize: 14,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

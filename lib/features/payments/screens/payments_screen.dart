import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _selectedPlan = 'pro';
  String _selectedCycle = 'monthly';
  bool _isLoading = false;

  static const _plans = [
    _PlanData(
      id: 'free',
      name: 'Gratuito',
      monthlyPrice: 0,
      annualPrice: 0,
      features: [
        'Perfil básico',
        'Hasta 5 proyectos guardados',
        'Búsqueda básica',
        'Mensajería limitada (5/mes)',
      ],
      limits: [
        'Sin filtros avanzados',
        'Sin analytics',
        'Sin agenda integrada',
      ],
    ),
    _PlanData(
      id: 'pro',
      name: 'Pro',
      monthlyPrice: 9990,
      annualPrice: 89900,
      badge: 'Más popular',
      features: [
        'Perfil verificado completo',
        'Proyectos guardados ilimitados',
        'Filtros avanzados de búsqueda',
        'Mensajería ilimitada',
        'Pipeline de inversión completo',
        'Analytics básico',
        'Agenda integrada',
        'Soporte prioritario',
      ],
      limits: [],
    ),
    _PlanData(
      id: 'enterprise',
      name: 'Enterprise',
      monthlyPrice: 24990,
      annualPrice: 249900,
      features: [
        'Todo lo de Pro',
        'Proyecto destacado en el home',
        'Analytics avanzado + exportación',
        'Manager de cuenta dedicado',
        'API access',
        'White-label disponible',
        'Due Diligence tools',
      ],
      limits: [],
    ),
  ];

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.createPaymentPreference(
        plan: _selectedPlan,
        billingCycle: _selectedCycle,
      );

      // URL del checkout de Mercado Pago
      final checkoutUrl = data['checkoutUrl'] as String?;
      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes y suscripción'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cycle toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _CycleButton(
                    label: 'Mensual',
                    isSelected: _selectedCycle == 'monthly',
                    onTap: () => setState(() => _selectedCycle = 'monthly'),
                  ),
                  _CycleButton(
                    label: 'Anual  -20%',
                    isSelected: _selectedCycle == 'annual',
                    onTap: () => setState(() => _selectedCycle = 'annual'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tarjetas de planes
            ..._plans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanCard(
                    plan: plan,
                    isSelected: _selectedPlan == plan.id,
                    cycle: _selectedCycle,
                    onSelect: () => setState(() => _selectedPlan = plan.id),
                  ),
                )),

            const SizedBox(height: 20),

            // Botón de suscripción
            if (_selectedPlan != 'free') ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _subscribe,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo de Mercado Pago (ícono representativo)
                          const Icon(Icons.payment, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pagar con Mercado Pago — ${_formatPrice(_selectedPlan, _selectedCycle)}',
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Podés cancelar en cualquier momento.\nPago procesado de forma segura por Mercado Pago.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Sección de fee de éxito
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.handshake_outlined,
                          color: AppColors.secondary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Fee de éxito',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.secondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Si se concreta una inversión a través de InvestMatch, se aplica un fee de éxito acordado con anticipación entre las partes. Contactanos para más información.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Consultar fee de éxito →'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatPrice(String planId, String cycle) {
    final plan = _plans.firstWhere((p) => p.id == planId);
    final price = cycle == 'monthly' ? plan.monthlyPrice : plan.annualPrice;
    return '\$${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}

class _CycleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CycleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4)
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _PlanData plan;
  final bool isSelected;
  final String cycle;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.cycle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final price = cycle == 'monthly' ? plan.monthlyPrice : plan.annualPrice;
    final isFree = price == 0;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                      ),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            plan.badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Precio
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isFree
                          ? 'Gratis'
                          : '\$${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (!isFree)
                      Text(
                        cycle == 'monthly' ? '/mes' : '/año',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter'),
                        ),
                      ),
                    ],
                  ),
                )),
            if (plan.limits.isNotEmpty)
              ...plan.limits.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_circle_outline,
                            size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text(
                          l,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                              fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _PlanData {
  final String id;
  final String name;
  final int monthlyPrice;
  final int annualPrice;
  final String? badge;
  final List<String> features;
  final List<String> limits;

  const _PlanData({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.annualPrice,
    this.badge,
    required this.features,
    required this.limits,
  });
}

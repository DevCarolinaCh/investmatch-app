import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';

// KYC: Know Your Customer - Verificación de identidad
// Flujo: DNI frente → DNI dorso → Selfie → Envío para revisión

enum KycStep { intro, frontDoc, backDoc, selfie, submitted }

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  KycStep _step = KycStep.intro;
  File? _frontDocFile;
  File? _backDocFile;
  File? _selfieFile;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source, String type) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    setState(() {
      switch (type) {
        case 'front':
          _frontDocFile = File(picked.path);
          _step = KycStep.backDoc;
        case 'back':
          _backDocFile = File(picked.path);
          _step = KycStep.selfie;
        case 'selfie':
          _selfieFile = File(picked.path);
      }
    });
  }

  Future<void> _submitKyc() async {
    if (_frontDocFile == null || _backDocFile == null || _selfieFile == null) return;
    setState(() => _isUploading = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.submitKycDocuments(
        frontDocPath: _frontDocFile!.path,
        backDocPath: _backDocFile!.path,
        selfiePath: _selfieFile!.path,
      );
      setState(() => _step = KycStep.submitted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al enviar documentos. Intentá nuevamente.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de identidad'),
        automaticallyImplyLeading: _step != KycStep.intro,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case KycStep.intro:
        return _buildIntro();
      case KycStep.frontDoc:
        return _buildDocCapture(
          title: 'Frente del DNI',
          hint: 'Fotografiá el frente de tu DNI',
          icon: Icons.credit_card,
          onCamera: () => _pickImage(ImageSource.camera, 'front'),
          onGallery: () => _pickImage(ImageSource.gallery, 'front'),
        );
      case KycStep.backDoc:
        return _buildDocCapture(
          title: 'Dorso del DNI',
          hint: 'Fotografiá el dorso de tu DNI',
          icon: Icons.credit_card,
          onCamera: () => _pickImage(ImageSource.camera, 'back'),
          onGallery: () => _pickImage(ImageSource.gallery, 'back'),
          preview: _frontDocFile,
        );
      case KycStep.selfie:
        return _buildSelfieStep();
      case KycStep.submitted:
        return _buildSubmittedStep();
    }
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress
        _KycProgressBar(currentStep: 0, totalSteps: 3),
        const SizedBox(height: 32),
        const Icon(Icons.verified_user_outlined, size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          'Verificá tu identidad',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Para garantizar la seguridad de la plataforma, necesitamos verificar tu identidad. El proceso toma menos de 2 minutos.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        _KycInfoRow(
          icon: Icons.document_scanner_outlined,
          text: 'DNI argentino frente y dorso',
        ),
        const SizedBox(height: 12),
        _KycInfoRow(
          icon: Icons.face_outlined,
          text: 'Selfie de liveness (foto en tiempo real)',
        ),
        const SizedBox(height: 12),
        _KycInfoRow(
          icon: Icons.lock_outline,
          text: 'Datos protegidos bajo Ley 25.326',
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => setState(() => _step = KycStep.frontDoc),
          child: const Text('Comenzar verificación'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Omitir por ahora (acceso limitado)'),
        ),
      ],
    );
  }

  Widget _buildDocCapture({
    required String title,
    required String hint,
    required IconData icon,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    File? preview,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KycProgressBar(
          currentStep: _step == KycStep.frontDoc ? 1 : 2,
          totalSteps: 3,
        ),
        const SizedBox(height: 32),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(hint, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 32),
        // Preview del documento anterior si existe
        if (preview != null) ...[
          Text('Frente capturado ✓',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.secondary)),
          const SizedBox(height: 24),
        ],
        // Área de captura
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(
                'Asegurate de que el documento\nsea legible y esté bien iluminado',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onCamera,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Tomar foto'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onGallery,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Elegir de galería'),
        ),
      ],
    );
  }

  Widget _buildSelfieStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KycProgressBar(currentStep: 3, totalSteps: 3),
        const SizedBox(height: 32),
        Text('Selfie de verificación',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text(
          'Sacate una selfie mirando a la cámara. Asegurate de tener buena iluminación.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        if (_selfieFile != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _selfieFile!,
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera, 'selfie'),
            icon: const Icon(Icons.refresh),
            label: const Text('Retomar selfie'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isUploading ? null : _submitKyc,
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Enviar documentos'),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.face_outlined,
                size: 80, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera, 'selfie'),
            icon: const Icon(Icons.camera_front_outlined),
            label: const Text('Tomar selfie'),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmittedStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline,
            size: 80, color: AppColors.secondary),
        const SizedBox(height: 24),
        Text('¡Documentos enviados!',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text(
          'Tu verificación está en proceso. Te notificaremos el resultado en 24-48 horas hábiles.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Ir a la app'),
        ),
      ],
    );
  }
}

class _KycProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _KycProgressBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final done = i < currentStep;
        final active = i == currentStep - 1;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: done || active ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _KycInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _KycInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          child: Text(text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  )),
        ),
      ],
    );
  }
}

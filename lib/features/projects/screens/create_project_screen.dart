import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _solutionCtrl = TextEditingController();
  final _businessModelCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  String? _selectedVertical;
  String? _selectedStage;
  String? _selectedTicket;
  String? _selectedProvince;
  final List<String> _selectedImpact = [];
  final List<File> _images = [];
  File? _pitchDeck;
  bool _isLoading = false;
  int _currentStep = 0;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _problemCtrl.dispose();
    _solutionCtrl.dispose();
    _businessModelCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() {
        final toAdd = picked.take(AppConstants.maxProjectImages - _images.length);
        _images.addAll(toAdd.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _pickPitchDeck() async {
    // En producción usar file_picker para PDFs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selector de archivos en desarrollo')),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiServiceProvider);

      // Crear proyecto
      final data = await api.createProject({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'vertical': _selectedVertical,
        'stage': _selectedStage,
        'ticketSeeking': _selectedTicket,
        'province': _selectedProvince,
        'impactFocus': _selectedImpact,
        'problemStatement': _problemCtrl.text.trim().isEmpty
            ? null
            : _problemCtrl.text.trim(),
        'solutionStatement': _solutionCtrl.text.trim().isEmpty
            ? null
            : _solutionCtrl.text.trim(),
        'businessModel': _businessModelCtrl.text.trim().isEmpty
            ? null
            : _businessModelCtrl.text.trim(),
        'websiteUrl': _websiteCtrl.text.trim().isEmpty
            ? null
            : _websiteCtrl.text.trim(),
      });

      final projectId = data['id'] as String;

      // Subir imágenes
      for (final img in _images) {
        await api.uploadProjectImage(projectId, img.path);
      }

      // Subir pitch deck
      if (_pitchDeck != null) {
        await api.uploadPitchDeck(projectId, _pitchDeck!.path);
      }

      if (!mounted) return;
      context.go('/projects/$projectId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear proyecto'),
        leading: const BackButton(),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(_currentStep < 3 ? 'Siguiente' : 'Publicar'),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(80, 52)),
                      child: const Text('Atrás'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            // Paso 1: Info básica
            Step(
              title: const Text('Información básica'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del proyecto *',
                      hintText: 'Ej: EcoFinance AR',
                    ),
                    validator: (v) =>
                        v?.isEmpty == true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción *',
                      hintText: 'Describe tu proyecto en pocas palabras...',
                    ),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Campo requerido';
                      if ((v?.length ?? 0) < 50) return 'Mínimo 50 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _DropdownField(
                    label: 'Vertical / Industria *',
                    value: _selectedVertical,
                    items: AppConstants.verticals,
                    onChanged: (v) => setState(() => _selectedVertical = v),
                    validator: (v) =>
                        v == null ? 'Seleccioná una vertical' : null,
                  ),
                  const SizedBox(height: 14),
                  _DropdownField(
                    label: 'Etapa *',
                    value: _selectedStage,
                    items: AppConstants.startupStages,
                    onChanged: (v) => setState(() => _selectedStage = v),
                    validator: (v) =>
                        v == null ? 'Seleccioná una etapa' : null,
                  ),
                ],
              ),
            ),

            // Paso 2: Detalles de inversión
            Step(
              title: const Text('Detalles de inversión'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _DropdownField(
                    label: 'Ticket buscado *',
                    value: _selectedTicket,
                    items: AppConstants.ticketRanges,
                    onChanged: (v) => setState(() => _selectedTicket = v),
                    validator: (v) =>
                        v == null ? 'Seleccioná un rango de ticket' : null,
                  ),
                  const SizedBox(height: 14),
                  _DropdownField(
                    label: 'Provincia *',
                    value: _selectedProvince,
                    items: AppConstants.provinces,
                    onChanged: (v) => setState(() => _selectedProvince = v),
                    validator: (v) =>
                        v == null ? 'Seleccioná una provincia' : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Impacto (seleccioná los que apliquen)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: AppConstants.impactCategories.map((impact) {
                      final selected = _selectedImpact.contains(impact);
                      return FilterChip(
                        label: Text(impact),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedImpact.add(impact);
                            } else {
                              _selectedImpact.remove(impact);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Paso 3: Historia del proyecto
            Step(
              title: const Text('Historia del proyecto'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _problemCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'El problema que resolvés',
                      hintText: '¿Qué dolor o problema existe en el mercado?',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _solutionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Tu solución',
                      hintText: '¿Cómo lo resolvés?',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _businessModelCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Modelo de negocio',
                      hintText: '¿Cómo monetizás?',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _websiteCtrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Sitio web',
                      hintText: 'https://tuproyecto.com',
                      prefixIcon: Icon(Icons.language_outlined),
                    ),
                  ),
                ],
              ),
            ),

            // Paso 4: Media
            Step(
              title: const Text('Imágenes y Pitch Deck'),
              isActive: _currentStep >= 3,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Imágenes del proyecto (máx. ${AppConstants.maxProjectImages})',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_images.isNotEmpty) ...[
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (_, i) => Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _images[i],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _images.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_images.length < AppConstants.maxProjectImages)
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Agregar imágenes'),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Pitch Deck (PDF)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_pitchDeck != null)
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_pitchDeck!.path.split('/').last)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _pitchDeck = null),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _pickPitchDeck,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Subir Pitch Deck (PDF)'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

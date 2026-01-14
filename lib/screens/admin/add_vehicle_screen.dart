import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/vehicle_service.dart';
// Images provided by URL only (no local picker/upload in this screen)
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_buttom.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _precioPorDiaController = TextEditingController();
  // URL-only image inputs
  final _coverUrlController = TextEditingController();
  final List<TextEditingController> _imageUrlControllers = [TextEditingController()];
  final _descripcionController = TextEditingController();
  final _capacidadController = TextEditingController();

  String _tipoSeleccionado = VehicleTypes.sedan;
  String _transmisionSeleccionada = TransmissionTypes.automatic;
  bool _isLoading = false;

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _precioPorDiaController.dispose();
    _descripcionController.dispose();
    _capacidadController.dispose();
    _coverUrlController.dispose();
    for (final c in _imageUrlControllers) { c.dispose(); }
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vehicleService = VehicleService();

      final vehicleId = vehicleService.newVehicleId();

      // Recolectar URLs de las entradas (omitimos vacíos)
      final urls = _imageUrlControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
      String? coverUrl = _coverUrlController.text.trim().isNotEmpty ? _coverUrlController.text.trim() : (urls.isNotEmpty ? urls.first : null);

      if (urls.isEmpty && (coverUrl == null || coverUrl.isEmpty)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agrega al menos una URL de imagen'), backgroundColor: AppColors.error),
        );
        setState(() => _isLoading = false);
        return;
      }

      final newVehicle = VehicleModel(
        id: vehicleId,
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        anio: int.parse(_anioController.text.trim()),
        tipo: _tipoSeleccionado,
        precioPorDia: double.parse(_precioPorDiaController.text.trim()),
        imagenes: urls,
        imagenPortada: coverUrl,
        descripcion: _descripcionController.text.trim(),
        disponible: true,
        capacidad: int.parse(_capacidadController.text.trim()),
        transmision: _transmisionSeleccionada,
        calificacionPromedio: 0.0,
        totalCalificaciones: 0,
        fechaCreacion: DateTime.now(),
      );

      await vehicleService.createVehicle(newVehicle, id: vehicleId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehículo agregado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );

      // Recargar vehículos
      context.read<VehicleProvider>().reloadVehicles();

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Vehículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _marcaController,
                label: 'Marca',
                hint: 'Toyota, Honda, etc.',
                prefixIcon: Icons.branding_watermark,
                validator: (value) =>
                    Validators.validateRequired(value, 'Marca'),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _modeloController,
                label: 'Modelo',
                hint: 'Corolla, Civic, etc.',
                prefixIcon: Icons.directions_car,
                validator: (value) =>
                    Validators.validateRequired(value, 'Modelo'),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _anioController,
                label: 'Año',
                hint: '2023',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.calendar_today,
                validator: Validators.validatePositiveNumber,
              ),
              const SizedBox(height: AppSpacing.md),

              // Tipo de vehículo
              const Text(
                'Tipo de Vehículo',
                style: TextStyle(
                  fontSize: AppFontSizes.sm,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: _tipoSeleccionado,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.category, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                ),
                items: VehicleTypes.all.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (value) {
                  setState(() => _tipoSeleccionado = value!);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _capacidadController,
                label: 'Capacidad (personas)',
                hint: '5',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.people,
                validator: Validators.validatePositiveNumber,
              ),
              const SizedBox(height: AppSpacing.md),

              // Transmisión
              const Text(
                'Transmisión',
                style: TextStyle(
                  fontSize: AppFontSizes.sm,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _transmisionSeleccionada,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.settings, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                ),
                items: TransmissionTypes.all.map((trans) {
                  return DropdownMenuItem(value: trans, child: Text(trans));
                }).toList(),
                onChanged: (value) {
                  setState(() => _transmisionSeleccionada = value!);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _precioPorDiaController,
                label: 'Precio por Día (USD)',
                hint: '45.00',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                validator: Validators.validatePositiveNumber,
              ),
              const SizedBox(height: AppSpacing.md),

              const Text(
                'Imagen de Portada (URL)',
                style: TextStyle(
                  fontSize: AppFontSizes.sm,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              CustomTextField(
                controller: _coverUrlController,
                label: 'URL de la imagen de portada',
                hint: 'https://mi-host.com/imagen.jpg',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null; // opcional
                  return Validators.validateUrl(value);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              const Text(
                'Imágenes del Vehículo (URLs)',
                style: TextStyle(
                  fontSize: AppFontSizes.sm,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Column(
                children: List.generate(_imageUrlControllers.length, (index) {
                  final controller = _imageUrlControllers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'https://mi-host.com/imagen.jpg',
                              labelText: 'Imagen ${index + 1}',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              return Validators.validateUrl(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_imageUrlControllers.length > 1)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _imageUrlControllers.removeAt(index).dispose();
                              });
                            },
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _imageUrlControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir URL'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _descripcionController,
                label: 'Descripción',
                hint: 'Descripción del vehículo...',
                maxLines: 4,
                validator: (value) =>
                    Validators.validateRequired(value, 'Descripción'),
              ),
              const SizedBox(height: AppSpacing.xl),

              CustomButton(
                text: 'Guardar Vehículo',
                onPressed: _handleSave,
                isLoading: _isLoading,
                icon: Icons.save,
              ),
              const SizedBox(height: AppSpacing.md),

              CustomButton(
                text: 'Cancelar',
                onPressed: () => Navigator.pop(context),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

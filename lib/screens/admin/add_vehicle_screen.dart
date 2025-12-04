import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/vehicle_service.dart';
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
  final _imagenUrlController = TextEditingController();
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
    _imagenUrlController.dispose();
    _descripcionController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vehicleService = VehicleService();

      final newVehicle = VehicleModel(
        id: '',
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        anio: int.parse(_anioController.text.trim()),
        tipo: _tipoSeleccionado,
        precioPorDia: double.parse(_precioPorDiaController.text.trim()),
        imagenUrl: _imagenUrlController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        disponible: true,
        capacidad: int.parse(_capacidadController.text.trim()),
        transmision: _transmisionSeleccionada,
        calificacionPromedio: 0.0,
        totalCalificaciones: 0,
        fechaCreacion: DateTime.now(),
      );

      await vehicleService.createVehicle(newVehicle);

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
                value: _tipoSeleccionado,
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

              CustomTextField(
                controller: _imagenUrlController,
                label: 'URL de Imagen',
                hint: 'https://...',
                prefixIcon: Icons.image,
                validator: (value) =>
                    Validators.validateRequired(value, 'URL de imagen'),
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

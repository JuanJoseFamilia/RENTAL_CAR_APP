import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/vehicle_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_buttom.dart';

class EditVehicleScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const EditVehicleScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _anioController;
  late TextEditingController _precioPorDiaController;
  late TextEditingController _imagenUrlController;
  late TextEditingController _descripcionController;
  late TextEditingController _capacidadController;

  late String _tipoSeleccionado;
  late String _transmisionSeleccionada;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _marcaController = TextEditingController(text: widget.vehicle.marca);
    _modeloController = TextEditingController(text: widget.vehicle.modelo);
    _anioController =
        TextEditingController(text: widget.vehicle.anio.toString());
    _precioPorDiaController =
        TextEditingController(text: widget.vehicle.precioPorDia.toString());
    _imagenUrlController =
        TextEditingController(text: widget.vehicle.imagenUrl);
    _descripcionController =
        TextEditingController(text: widget.vehicle.descripcion);
    _capacidadController =
        TextEditingController(text: widget.vehicle.capacidad.toString());
    _tipoSeleccionado = widget.vehicle.tipo;
    _transmisionSeleccionada = widget.vehicle.transmision;
  }

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

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vehicleService = VehicleService();

      final updates = {
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'anio': int.parse(_anioController.text.trim()),
        'tipo': _tipoSeleccionado,
        'precioPorDia': double.parse(_precioPorDiaController.text.trim()),
        'imagenUrl': _imagenUrlController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'capacidad': int.parse(_capacidadController.text.trim()),
        'transmision': _transmisionSeleccionada,
      };

      await vehicleService.updateVehicle(widget.vehicle.id, updates);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehículo actualizado exitosamente'),
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
        title: const Text('Editar Vehículo'),
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
                prefixIcon: Icons.branding_watermark,
                validator: (value) =>
                    Validators.validateRequired(value, 'Marca'),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _modeloController,
                label: 'Modelo',
                prefixIcon: Icons.directions_car,
                validator: (value) =>
                    Validators.validateRequired(value, 'Modelo'),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _anioController,
                label: 'Año',
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
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                validator: Validators.validatePositiveNumber,
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _imagenUrlController,
                label: 'URL de Imagen',
                prefixIcon: Icons.image,
                validator: (value) =>
                    Validators.validateRequired(value, 'URL de imagen'),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _descripcionController,
                label: 'Descripción',
                maxLines: 4,
                validator: (value) =>
                    Validators.validateRequired(value, 'Descripción'),
              ),
              const SizedBox(height: AppSpacing.xl),

              CustomButton(
                text: 'Actualizar Vehículo',
                onPressed: _handleUpdate,
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

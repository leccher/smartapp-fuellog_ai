import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/fuel_log.dart';
import 'settings_screen.dart';

class VehicleManagementScreen extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final List<FuelLog> fuelLogs;
  final Function(Vehicle) onVehicleSelected;
  final Function(Vehicle) onVehicleAdded;
  final Function(Vehicle) onVehicleUpdated;
  final Function(String) onVehicleDeleted;

  const VehicleManagementScreen({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.fuelLogs,
    required this.onVehicleSelected,
    required this.onVehicleAdded,
    required this.onVehicleUpdated,
    required this.onVehicleDeleted,
  });

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  Vehicle? _currentSelected;

  @override
  void initState() {
    super.initState();
    _currentSelected = widget.selectedVehicle;
  }

  Future<void> _exportVehicleToCsv(Vehicle vehicle) async {
    try {
      // 1. Filtra i log relativi solo a questo veicolo
      final vehicleLogs = widget.fuelLogs.where((log) => log.vehicleId == vehicle.id).toList();

      // 2. Costruisci il contenuto del file CSV
      StringBuffer csvContent = StringBuffer();
      
      // Intestazione del veicolo
      csvContent.writeln('vehicle_csv_vehicle_columns'.tr());
      csvContent.writeln('${vehicle.id},"${vehicle.name}","${vehicle.type}"');
      csvContent.writeln(); // Riga vuota di separazione
      
      // Intestazione dei rifornimenti
      csvContent.writeln('csv_costs_columns'.tr());
      
      for (var log in vehicleLogs) {
        csvContent.writeln('${log.id},"${log.date.toIso8601String()}",${log.liters},${log.costEuro},${log.odometer}');
      }

      // 3. Salva il file nella directory temporanea del dispositivo
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/report_${vehicle.name.replaceAll(' ', '_')}.csv';
      final file = File(path);
      
      await file.writeAsString(csvContent.toString());

      if (!mounted) return;

      // 4. Apri il pannello di condivisione del file CSV generato
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'vehicle_consumes_for'.tr(namedArgs: {"vehicle":vehicle.name}),
          subject: 'vehicle_consumes_export',
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('csv_export_error'.tr(namedArgs: {'error': e.toString()}))),
      );
    }
  }

  void _showAddVehicleDialog() {
    _showVehicleFormDialog(title: 'vehicle_add_new'.tr(), onSave: (name, type) {
      final newVehicle = Vehicle(
        id: DateTime.now().toString(),
        name: name,
        type: type,
      );
      widget.onVehicleAdded(newVehicle);
      setState(() {
        _currentSelected = newVehicle;
      });
    });
  }

  void _showEditVehicleDialog(Vehicle vehicle) {
    _showVehicleFormDialog(
      title: 'vehicle_edit'.tr(),
      initialName: vehicle.name,
      initialType: vehicle.type,
      onSave: (name, type) {
        final updated = Vehicle(
          id: vehicle.id,
          name: name,
          type: type,
        );
        widget.onVehicleUpdated(updated);
        setState(() {});
      },
    );
  }

  void _showVehicleFormDialog({
    required String title,
    String? initialName,
    String? initialType,
    required Function(String name, String type) onSave,
  }) {
    final nameController = TextEditingController(text: initialName ?? '');
    String selectedType = initialType ?? 'type_car'.tr();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'vehicle_new_name'.tr()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: InputDecoration(labelText: 'vehicle_type'.tr()),
                items: [
                  DropdownMenuItem(value: 'type_car'.tr(), child: Text('type_car'.tr())),
                  DropdownMenuItem(value: 'type_motobike'.tr(), child: Text('type_motobike'.tr())),
                  DropdownMenuItem(value: 'type_scooter'.tr(), child: Text('type_scooter'.tr())),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setStateDialog(() {
                      selectedType = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('cancel'.tr())),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  onSave(name, selectedType);
                  Navigator.of(ctx).pop();
                }
              },
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('vehicle_list'.tr()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Pulsante per aprire la pagina delle impostazioni
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'settings'.tr(),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              // Ricarica lo stato della schermata al ritorno dalle impostazioni (es. cambio lingua)
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: widget.vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = widget.vehicles[index];
          final isSelected = vehicle.id == _currentSelected?.id;

          final vehicleLogs = widget.fuelLogs.where((log) => log.vehicleId == vehicle.id).toList();
          double totalLiters = 0;
          double totalCost = 0;
          double totalKmDriven = 0;
          double latestKm = 0;
          double averageConsumption = 0;

          if (vehicleLogs.isNotEmpty) {
            totalLiters = vehicleLogs.fold(0, (sum, log) => sum + log.liters);
            totalCost = vehicleLogs.fold(0, (sum, log) => sum + log.costEuro);
            latestKm = vehicleLogs.first.odometer;

            if (vehicleLogs.length > 1) {
              double oldestKm = vehicleLogs.last.odometer;
              if (latestKm > oldestKm) {
                totalKmDriven = latestKm - oldestKm;
              }
            }

            if (totalKmDriven > 0) {
              averageConsumption = (totalLiters * 100) / totalKmDriven;
            }
          }

          return Card(
            elevation: isSelected ? 3 : 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? Colors.teal : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle.name} (${vehicle.type})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isSelected ? Colors.teal.shade900 : Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // Pulsante Esporta CSV
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.teal),
                            tooltip: 'vehicle_export_csv'.tr(),
                            onPressed: () => _exportVehicleToCsv(vehicle),
                          ),
                          
                          // Pulsante spunta attivo
                          IconButton(
                            icon: Icon(
                              isSelected ? Icons.search : Icons.search_off,
                              color: isSelected ? Colors.teal : Colors.grey,
                              size: 26,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentSelected = vehicle;
                              });
                              widget.onVehicleSelected(vehicle);
                              Navigator.of(context).pop();
                            },
                            tooltip: 'vehicle_selection'.tr(),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditVehicleDialog(vehicle);
                              } else if (value == 'delete') {
                                //if (widget.vehicles.length <= 1) {
                                //  ScaffoldMessenger.of(context).showSnackBar(
                                //    SnackBar(content: Text('vehicle_cannot_delete'.tr())),
                                //  );
                                //} else {
                                  widget.onVehicleDeleted(vehicle.id);
                                  setState(() {});
                                //}
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'edit', child: Text('edit'.tr())),
                              PopupMenuItem(value: 'delete', child: Text('delete'.tr())),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (vehicleLogs.isEmpty)
                    Text(
                      'vehicle_no_fuel_logs'.tr(),
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13),
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('total_km'.tr(), '${latestKm.toStringAsFixed(0)} km'),
                        _buildStatItem('passed_km'.tr(), '${totalKmDriven.toStringAsFixed(0)} km'),
                        _buildStatItem('average_consumption'.tr(), vehicleLogs.length > 1 ? '${averageConsumption.toStringAsFixed(1)} L/100km' : 'N/D'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('total_fuel'.tr(), '${totalLiters.toStringAsFixed(2)} L'),
                        _buildStatItem('total_cost'.tr(), '${totalCost.toStringAsFixed(2)} €'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVehicleDialog,
        icon: const Icon(Icons.add),
        label: Text('vehicle_add_new'.tr()),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/api_key_service.dart';
import 'services/database_helper.dart';
import 'models/fuel_log.dart';
import 'screens/settings_screen.dart';
import 'screens/vehicle_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // Proviamo a caricare il .env, ma se non c'è catturiamo l'eccezione
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Il file .env non esiste o non è negli asset: procediamo comunque
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('it', 'IT'),
        Locale('en', 'US'),
        Locale('de', 'DE'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('it', 'IT'),
      child: const FuelLogApp(),
    ),
  );
}

class FuelLogApp extends StatelessWidget {
  const FuelLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_title'.tr(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  bool _isLoading = true;
  bool _hasApiKey = false;
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  List<FuelLog> _fuelLogs = [];

  final _secureStorage = const FlutterSecureStorage();
  static const String _lastVehicleIdKey = 'last_selected_vehicle_id';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Controllo presenza API Key
      final apiKey = await ApiKeyService.getActiveApiKey();
      _hasApiKey = apiKey != null && apiKey.trim().isNotEmpty;

      // 2. Caricamento veicoli dal database SQLite
      final vehicleMaps = await DatabaseHelper.instance.fetchVehicles();
      _vehicles = vehicleMaps.map((map) => Vehicle.fromMap(map)).toList();

      // 3. Caricamento dei log carburante
      final logMaps = await DatabaseHelper.instance.fetchFuelLogs();
      _fuelLogs = logMaps.map((map) => FuelLog.fromMap(map)).toList();

      // 4. Recupero dell'ultimo veicolo selezionato (senza generare eccezioni in caso di fallimento)
      if (_vehicles.isNotEmpty) {
        String? lastId;
        try {
          lastId = await _secureStorage.read(key: _lastVehicleIdKey);
        } catch (_) {
          lastId = null;
        }

        if (lastId != null) {
          try {
            _selectedVehicle = _vehicles.firstWhere((v) => v.id == lastId);
          } catch (_) {
            _selectedVehicle = _vehicles.first;
          }
        } else {
          _selectedVehicle = _vehicles.first;
        }
      }
    } catch (_) {
      // Gestione sicura di eventuali errori di inizializzazione
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSelectedVehicle(Vehicle vehicle) async {
    setState(() {
      _selectedVehicle = vehicle;
    });
    try {
      await _secureStorage.write(key: _lastVehicleIdKey, value: vehicle.id);
    } catch (_) {}
  }

  Future<void> _openGoogleAIStudio() async {
    final Uri url = Uri.parse('google_api_key_page_link'.tr());
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('google_api_key_page_not_available'.tr())),
        );
      }
    }
  }

  void _navigateToVehicleManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleManagementScreen(
          vehicles: _vehicles,
          selectedVehicle: _selectedVehicle,
          fuelLogs: _fuelLogs,
          onVehicleSelected: (Vehicle vehicle) {
            _saveSelectedVehicle(vehicle);
          },
          onVehicleAdded: (Vehicle vehicle) async {
            // 1. Salva nel database
            await DatabaseHelper.instance.insertVehicle(vehicle.toMap());
            
            // 2. Aggiorna subito la lista locale
            setState(() {
              _vehicles.add(vehicle);
              _selectedVehicle ??= vehicle;
            });

            _initializeApp();
          },
          onVehicleUpdated: (Vehicle vehicle) async {
            // 1. Aggiorna nel database
            await DatabaseHelper.instance.insertVehicle(vehicle.toMap());
            
            // 2. Aggiorna subito l'elemento nella lista locale
            setState(() {
              final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
              if (index != -1) {
                _vehicles[index] = vehicle;
              }
              // Se il veicolo modificato è quello attualmente selezionato, aggiorniamo il riferimento
              if (_selectedVehicle?.id == vehicle.id) {
                _selectedVehicle = vehicle;
              }
            });

            _initializeApp();
          },
          onVehicleDeleted: (String vehicleId) async {
            // 1. Elimina dal database
            await DatabaseHelper.instance.deleteVehicle(vehicleId);
            
            // 2. Rimuovi subito dalla lista locale
            setState(() {
              _vehicles.removeWhere((v) => v.id == vehicleId);
              
              // Se abbiamo eliminato il veicolo selezionato, ne selezioniamo un altro se disponibile
              if (_selectedVehicle?.id == vehicleId) {
                _selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
              }
            });

            _initializeApp();
          },
        ),
      ),
    );
  }

  void _navigateToSettings() async {
    // 1. Attende il ritorno dalla schermata delle impostazioni
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    
    /*
    // 2. Ricarica lo stato della chiave API e aggiorna la UI
    final apiKey = await ApiKeyService.getActiveApiKey();
    setState(() {
      _hasApiKey = apiKey != null && apiKey.trim().isNotEmpty;
    });
    */
    // 2. Ricarica interamente l'app (chiave API, veicoli e log)
    await _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('app_title'.tr()),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    // Caso 1: La chiave API non esiste
    if (!_hasApiKey) {
      return Scaffold(
        appBar: AppBar(
          title: Text('app_title'.tr()),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'settings'.tr(),
              onPressed: _navigateToSettings,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'google_api_key_description'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'google_api_key_instructions'.tr(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _openGoogleAIStudio,
                  icon: const Icon(Icons.open_in_new),
                  label: Text('google_api_key_action'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Caso 2: Non ci sono veicoli registrati
    if (_vehicles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('app_title'.tr()),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.directions_car),
              tooltip: 'manage_vehicles'.tr(),
              onPressed: _navigateToVehicleManagement,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'settings'.tr(),
              onPressed: _navigateToSettings,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'no_vehicle_available'.tr(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'starting_message'.tr(),
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToVehicleManagement,
                  icon: const Icon(Icons.add),
                  label: Text('add_vehicle'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Caso 3: Chiave e veicoli presenti -> Mostra la dashboard dell'ultimo veicolo selezionato
    final currentLogs = _selectedVehicle != null
        ? _fuelLogs.where((log) => log.vehicleId == _selectedVehicle!.id).toList()
        : <FuelLog>[];

    double totalLiters = 0;
    double totalCost = 0;
    double totalKmDriven = 0;
    double latestKm = 0;
    double averageConsumption = 0;

    if (currentLogs.isNotEmpty) {
      totalLiters = currentLogs.fold(0, (sum, log) => sum + log.liters);
      totalCost = currentLogs.fold(0, (sum, log) => sum + log.costEuro);
      latestKm = currentLogs.first.odometer;

      if (currentLogs.length > 1) {
        double oldestKm = currentLogs.last.odometer;
        if (latestKm > oldestKm) {
          totalKmDriven = latestKm - oldestKm;
        }
      }

      if (totalKmDriven > 0) {
        averageConsumption = (totalLiters * 100) / totalKmDriven;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car),
            tooltip: 'manage_vehicles'.tr(),
            onPressed: _navigateToVehicleManagement,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'settings'.tr(),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Intestazione con nome del veicolo e menu a tendina per cambiarlo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedVehicle != null
                        ? '${_selectedVehicle!.name} (${_selectedVehicle!.type})'
                        : '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                PopupMenuButton<Vehicle>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (Vehicle vehicle) {
                    _saveSelectedVehicle(vehicle);
                  },
                  itemBuilder: (BuildContext context) {
                    return _vehicles.map((Vehicle vehicle) {
                      return PopupMenuItem<Vehicle>(
                        value: vehicle,
                        child: Text('${vehicle.name} (${vehicle.type})'),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
          ),

          // Riepilogo consumi e statistiche del veicolo
          if (currentLogs.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('consumption_list'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('total_km'.tr(), '${latestKm.toStringAsFixed(0)} km'),
                        _buildStatItem('passed_km'.tr(), '${totalKmDriven.toStringAsFixed(0)} km'),
                        _buildStatItem('average_consumption'.tr(), currentLogs.length > 1 ? '${averageConsumption.toStringAsFixed(1)} L/100km' : 'N/D'),
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
                ),
              ),
            ),

          // Lista dei rifornimenti o messaggio esplicativo se vuota
          Expanded(
            child: currentLogs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_gas_station, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            _selectedVehicle != null
                                ? 'no_refuel_for'.tr(namedArgs: {"vehicle": _selectedVehicle!.name})
                                : '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('howto_add_fuel_log_description'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('howto_add_fuel_log_instructions'.tr()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: currentLogs.length,
                    itemBuilder: (ctx, index) {
                      final log = currentLogs[index];
                      final costPerLiter = log.liters > 0 ? log.costEuro / log.liters : 0.0;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.local_gas_station)),
                          title: Text('${log.liters.toStringAsFixed(2)} L - ${log.costEuro.toStringAsFixed(2)} €'),
                          subtitle: Text('fuel_log_row'.tr(namedArgs: {
                            "km": log.odometer.toStringAsFixed(0),
                            "price": costPerLiter.toStringAsFixed(3),
                            "date": "${log.date.day}/${log.date.month}/${log.date.year}"
                          })),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
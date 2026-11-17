import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const DrainageApp());

const navy = Color(0xFF12243A);
const teal = Color(0xFF087F78);
const paper = Color(0xFFF3F6F8);

class DrainageApp extends StatelessWidget {
  const DrainageApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Conferência de Drenagem',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: paper,
          colorScheme: ColorScheme.fromSeed(seedColor: teal),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        home: const InspectionScreen(),
      );
}

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _station = TextEditingController();
  final _side = TextEditingController();
  final _measurements = TextEditingController();
  final _notes = TextEditingController();
  final _picker = ImagePicker();
  final _prefs = SharedPreferencesAsync();

  String _road = 'GO-110';
  String? _type;
  String? _projectChoice;
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _projectItems = [];
  List<String> _records = [];
  Position? _position;
  XFile? _photo;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _id.dispose();
    _station.dispose();
    _side.dispose();
    _measurements.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final catalog = jsonDecode(await rootBundle
          .loadString('material-base/data/processed/device-catalog.json'));
      final types = List<Map<String, dynamic>>.from(catalog['sharedTypes']);
      final items = <Map<String, dynamic>>[];

      final point = jsonDecode(await rootBundle.loadString(
          'material-base/data/processed/projects/GO110/point-devices.json'));
      for (final value in point['structures'] as List) {
        final item = Map<String, dynamic>.from(value);
        items.add({...item, 'displayType': item['designType'] ?? item['class']});
      }
      for (final value in point['catchmentBasins'] ?? const []) {
        final item = Map<String, dynamic>.from(value);
        items.add({...item, 'displayType': item['type'] ?? 'Bacia de captação'});
      }

      final linear = jsonDecode(await rootBundle.loadString(
          'material-base/data/processed/projects/GO110/linear-drainage.json'));
      for (final value in linear['linearDrainRuns'] as List) {
        final item = Map<String, dynamic>.from(value);
        items.add({
          ...item,
          'id': item['type'],
          'station': '${item['start']}–${item['end']}',
          'displayType': item['type'],
        });
      }

      final surface = jsonDecode(await rootBundle.loadString(
          'material-base/data/processed/projects/GO110/surface-devices.json'));
      final groups = Map<String, dynamic>.from(surface['surfaceDevices']);
      for (final group in groups.values) {
        if (group is! List) continue;
        for (final value in group) {
          final item = Map<String, dynamic>.from(value);
          items.add({
            ...item,
            'id': item['id'] ?? item['type'] ?? 'Drenagem superficial',
            'station': item['station'] ??
                (item['start'] != null
                    ? '${item['start']}${item['end'] == null ? '' : '–${item['end']}'}'
                    : ''),
            'displayType': item['type'] ?? 'Drenagem superficial',
          });
        }
      }
      final saved = await _prefs.getStringList('inspections') ?? [];
      if (!mounted) return;
      setState(() {
        _types = types;
        _projectItems = items;
        _records = saved;
        _loading = false;
        _type = types.isEmpty ? null : types.first['id'] as String;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Não consegui carregar os dados do projeto: $error');
    }
  }

  String _label(Map<String, dynamic> item) {
    final parts = [
      item['id']?.toString(),
      item['station']?.toString(),
      item['displayType']?.toString(),
      item['side']?.toString(),
    ].where((value) => value != null && value.trim().isNotEmpty).toList();
    return parts.join(' • ');
  }

  Future<void> _captureGps() async {
    setState(() => _busy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _message('Ative a localização do celular e tente novamente.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _message('Permita o acesso à localização para registrar as coordenadas.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      if (!mounted) return;
      setState(() => _position = position);
    } catch (error) {
      _message('Não consegui obter o GPS: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 90);
      if (photo != null && mounted) setState(() => _photo = photo);
    } catch (error) {
      _message('Não consegui abrir a câmera/galeria: $error');
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    final selectedTypes = _types.where((value) => value['id'] == _type).toList();
    final typeName = selectedTypes.isEmpty
        ? (_type ?? 'Dispositivo')
        : selectedTypes.first['name'].toString();
    final record = <String, dynamic>{
      'road': _road,
      'id': _id.text.trim(),
      'type': typeName,
      'station': _station.text.trim(),
      'side': _side.text.trim(),
      'measurements': _measurements.text.trim(),
      'notes': _notes.text.trim(),
      'latitude': _position?.latitude,
      'longitude': _position?.longitude,
      'gpsAccuracyMeters': _position?.accuracy,
      'photoPath': _photo?.path,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'Pendente de comparação com os critérios do projeto',
    };
    final updated = [..._records, jsonEncode(record)];
    await _prefs.setStringList('inspections', updated);
    if (!mounted) return;
    setState(() => _records = updated);
    _message('Registro salvo neste aparelho.');
  }

  void _selectProjectItem(String? label) {
    if (label == null) return;
    final item = _projectItems.firstWhere((value) => _label(value) == label);
    final station = item['station']?.toString() ?? '';
    setState(() {
      _projectChoice = label;
      _id.text = item['id']?.toString() ?? '';
      if (station.isNotEmpty) _station.text = station;
      if (item['side'] != null) _side.text = item['side'].toString();
    });
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showRecords() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text('Registros neste aparelho (${_records.length})',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: _records.isEmpty
                  ? const Center(child: Text('Nenhum registro salvo ainda.'))
                  : ListView.builder(
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final item = jsonDecode(_records[_records.length - 1 - index]);
                        return ListTile(
                          leading: const Icon(Icons.water_drop_outlined),
                          title: Text('${item['id']} • ${item['type']}'),
                          subtitle: Text(
                              '${item['road']} • Estaca ${item['station']}\n${item['status']}'),
                          isThreeLine: true,
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = _types.where((item) => item['id'] == _type).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conferência de Drenagem'),
        actions: [
          IconButton(
            tooltip: 'Registros salvos',
            onPressed: _showRecords,
            icon: Badge(label: Text('${_records.length}'), child: const Icon(Icons.assignment_outlined)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: navy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'material-base/app/public/assets/marca-strata-basitec.jpeg',
                          height: 54,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                            'STRATA • BASITEC',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Fiscalização em campo',
                            style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('Registre medidas, localização e fotos da drenagem.',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _section('Obra e dispositivo'),
                  DropdownButtonFormField<String>(
                    value: _road,
                    decoration: const InputDecoration(labelText: 'Rodovia'),
                    items: const [
                      DropdownMenuItem(value: 'GO-110', child: Text('GO-110')),
                      DropdownMenuItem(value: 'GO-236', child: Text('GO-236')),
                    ],
                    onChanged: (value) => setState(() {
                      _road = value ?? 'GO-110';
                      _projectChoice = null;
                      _id.clear();
                      _station.clear();
                      _side.clear();
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType.isEmpty ? null : _type,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tipo do dispositivo'),
                    items: _types.map((item) => DropdownMenuItem<String>(
                      value: item['id'].toString(),
                      child: Text(item['name'].toString(), overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (value) => setState(() => _type = value),
                  ),
                  if (_road == 'GO-110') ...[
                    const SizedBox(height: 12),
                    Autocomplete<String>(
                      key: ValueKey(_road),
                      optionsBuilder: (value) {
                        if (value.text.trim().length < 2) return const <String>[];
                        final query = value.text.toLowerCase();
                        return _projectItems.map(_label).where((label) => label.toLowerCase().contains(query)).take(30);
                      },
                      onSelected: _selectProjectItem,
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Buscar dispositivo previsto na GO-110',
                          hintText: 'Ex.: B49 ou estaca 1555',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _id,
                    decoration: const InputDecoration(labelText: 'Identificação do dispositivo'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe a identificação.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _station,
                    decoration: InputDecoration(
                      labelText: 'Estaca / localização',
                      helperText: _road == 'GO-236'
                          ? 'Na GO-236, informe o local manualmente até chegar o projeto.'
                          : 'O eixo fornece a referência; confirme a posição em campo.',
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe a estaca/local.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _side, decoration: const InputDecoration(labelText: 'Lado (LE/LD, se aplicável)')),
                  const SizedBox(height: 20),
                  _section('Conferência'),
                  TextFormField(
                    controller: _measurements,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Medidas conferidas', hintText: 'Ex.: largura, altura, comprimento (com unidade)'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Registre as medidas verificadas.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _notes, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Observações')),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _captureGps,
                    icon: const Icon(Icons.my_location),
                    label: Text(_busy ? 'Obtendo GPS…' : 'Registrar coordenadas GPS'),
                  ),
                  if (_position != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on, color: teal),
                        title: Text('${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}'),
                        subtitle: Text('Precisão aproximada: ${_position!.accuracy.toStringAsFixed(1)} m. Estaca não calculada do GPS.'),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => _pickPhoto(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Tirar foto'))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(onPressed: () => _pickPhoto(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galeria'))),
                  ]),
                  if (_photo != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_photo!.path), height: 190, fit: BoxFit.cover)),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(14)),
                    child: const Text('Situação inicial: pendente de comparação com os critérios e tolerâncias do projeto.'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saveRecord,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar vistoria neste aparelho'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Registros guardados localmente neste celular. Sincronização e relatório PDF serão etapas seguintes.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: const TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.w700)),
      );
}


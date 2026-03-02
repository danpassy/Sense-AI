import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/ble_constants.dart';
import '../../../../shared/widgets/animated_fade_in.dart';
import '../../../ble/services/ble_service.dart';
import '../models/activity_model.dart';
import 'activity_session_page.dart';

/// Page listant les activités disponibles pour l'acquisition (onglet Acquisition)
class AcquisitionListPage extends StatefulWidget {
  const AcquisitionListPage({super.key});

  @override
  State<AcquisitionListPage> createState() => _AcquisitionListPageState();
}

enum _AcqTab { activities, files }

class _AcquisitionListPageState extends State<AcquisitionListPage> {
  _AcqTab _tab = _AcqTab.activities;
  final List<PlatformFile> _selectedFiles = [];
  bool _isDownloading = false;

  // --- STM32 files via BLE ---
  final BleService _ble = BleService();
  StreamSubscription? _bleSub;
  bool _stm32Loading = false;
  bool _stm32Downloading = false;
  final List<String> _stm32Files = [];
  final Set<String> _stm32Selected = {};
  IOSink? _stm32Sink;
  Completer<void>? _stm32DlCompleter;
  String? _stm32CurrentName;

  static String _normUuid(String u) => u.toLowerCase().replaceAll('-', '');

  @override
  void initState() {
    super.initState();
    _bleSub = _ble.dataReceivedStream.listen(_onBleData);
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _stm32Sink?.close();
    super.dispose();
  }

  void _onBleData(dynamic evt) {
    if (evt is! BleDataReceived) return;
    final char = _normUuid(evt.characteristicUuid);
    final fileData = _normUuid(BleConstants.fileDataCharUuid);
    if (!char.endsWith(fileData.replaceAll('-', ''))) {
      // Some platforms report short UUIDs; also accept contains.
      if (!char.contains('fe45')) return;
    }
    if (evt.data.isEmpty) return;

    final type = evt.data[0];
    // LIST: 0x21 + name\0, 0x22 end, 0xEE error
    if (type == 0x21) {
      final bytes = evt.data.sublist(1);
      final end = bytes.indexOf(0);
      final nameBytes = end >= 0 ? bytes.sublist(0, end) : bytes;
      final name = utf8.decode(nameBytes, allowMalformed: true).trim();
      if (name.isNotEmpty && mounted) {
        setState(() {
          if (!_stm32Files.contains(name)) _stm32Files.add(name);
        });
      }
      return;
    }
    if (type == 0x22) {
      if (mounted) setState(() => _stm32Loading = false);
      return;
    }
    // GET: 0x11 + chunk, 0x12 end of file, 0xEE error
    if (type == 0x11) {
      final chunk = evt.data.sublist(1);
      _stm32Sink?.add(chunk);
      return;
    }
    if (type == 0x12) {
      _stm32Sink?.close();
      _stm32Sink = null;
      _stm32DlCompleter?.complete();
      _stm32DlCompleter = null;
      return;
    }
    if (type == 0xEE) {
      _stm32Sink?.close();
      _stm32Sink = null;
      _stm32DlCompleter?.completeError(Exception('Erreur STM32 (FatFs): ${evt.data.length > 1 ? evt.data[1] : 0}'));
      _stm32DlCompleter = null;
      if (mounted) setState(() => _stm32Loading = false);
      return;
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true, // important: works even when path is null (scoped storage)
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedFiles
        ..clear()
        ..addAll(result.files);
    });
  }

  Future<Directory?> _getDownloadsDirectory() async {
    if (!Platform.isAndroid) return null;
    final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
    if (dirs != null && dirs.isNotEmpty) return dirs.first;
    return await getExternalStorageDirectory();
  }

  String _dedupeName(Directory dir, String fileName) {
    final dot = fileName.lastIndexOf('.');
    final base = dot >= 0 ? fileName.substring(0, dot) : fileName;
    final ext = dot >= 0 ? fileName.substring(dot) : '';

    var candidate = fileName;
    var i = 1;
    while (File('${dir.path}/$candidate').existsSync()) {
      candidate = '${base}_$i$ext';
      i++;
    }
    return candidate;
  }

  Future<void> _downloadSelected() async {
    if (_isDownloading) return;
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun fichier sélectionné'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Téléchargement supporté uniquement sur Android (pour le moment)');
      }
      await downloadsDir.create(recursive: true);

      int copied = 0;
      for (final f in _selectedFiles) {
        final name = f.name.isNotEmpty ? f.name : 'fichier_${DateTime.now().millisecondsSinceEpoch}';
        final targetName = _dedupeName(downloadsDir, name);
        final target = File('${downloadsDir.path}/$targetName');

        if (f.bytes != null) {
          await target.writeAsBytes(f.bytes!, flush: true);
          copied++;
        } else if (f.path != null) {
          await File(f.path!).copy(target.path);
          copied++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Téléchargé: $copied fichier(s) → ${downloadsDir.path}'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur téléchargement: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _refreshStm32Files() async {
    if (_stm32Loading) return;
    if (!_ble.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non connecté au STM32'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }
    setState(() {
      _stm32Loading = true;
      _stm32Files.clear();
      _stm32Selected.clear();
    });
    try {
      await _ble.requestFileList();
    } catch (e) {
      if (!mounted) return;
      setState(() => _stm32Loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur LIST STM32: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _downloadStm32Selected() async {
    if (_stm32Downloading) return;
    if (_stm32Selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun fichier STM32 sélectionné'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }
    final downloadsDir = await _getDownloadsDirectory();
    if (downloadsDir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléchargement STM32 supporté uniquement sur Android'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }
    await downloadsDir.create(recursive: true);

    setState(() => _stm32Downloading = true);
    try {
      for (final name in _stm32Selected.toList()) {
        _stm32CurrentName = name;
        final targetName = _dedupeName(downloadsDir, name);
        final target = File('${downloadsDir.path}/$targetName');
        _stm32Sink = target.openWrite(mode: FileMode.writeOnly);
        _stm32DlCompleter = Completer<void>();

        await _ble.requestFileGet(name);
        await _stm32DlCompleter!.future.timeout(const Duration(seconds: 15));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Téléchargement STM32 terminé → ${downloadsDir.path}'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur GET STM32: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      _stm32CurrentName = null;
      _stm32Sink?.close();
      _stm32Sink = null;
      _stm32DlCompleter = null;
      if (mounted) setState(() => _stm32Downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                AppTheme.spacingL,
                AppTheme.spacingL,
                AppTheme.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tab == _AcqTab.activities ? 'Choisissez une activité' : 'Fichiers',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                        ),
                      ),
                      SegmentedButton<_AcqTab>(
                        segments: const [
                          ButtonSegment(value: _AcqTab.activities, label: Text('Activités')),
                          ButtonSegment(value: _AcqTab.files, label: Text('Fichiers')),
                        ],
                        selected: {_tab},
                        onSelectionChanged: (s) => setState(() => _tab = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    _tab == _AcqTab.activities
                        ? 'Sélectionnez une activité pour démarrer l\'acquisition des données.'
                        : 'Explorez, sélectionnez et téléchargez des fichiers (mobile uniquement).',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary),
                  ),
                ],
              ),
            ),
          ),
          if (_tab == _AcqTab.activities) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final activity = ActivityList.items[index];
                    return AnimatedFadeIn(
                      delay: Duration(milliseconds: 50 * index),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                        child: _ActivityCard(
                          activity: activity,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ActivitySessionPage(activity: activity),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  childCount: ActivityList.items.length,
                ),
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.spacingM),
                    // --- STM32 files section ---
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bluetooth_connected_rounded, color: AppTheme.primaryColor),
                              const SizedBox(width: AppTheme.spacingS),
                              Expanded(
                                child: Text(
                                  'Fichiers STM32',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Rafraîchir',
                                onPressed: _stm32Loading ? null : _refreshStm32Files,
                                icon: _stm32Loading
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.refresh_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            _ble.isConnected ? 'Connecté: ${_stm32Files.length} fichier(s)' : 'Non connecté',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          ElevatedButton.icon(
                            onPressed: (_stm32Downloading || _stm32Selected.isEmpty) ? null : _downloadStm32Selected,
                            icon: _stm32Downloading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.file_download_rounded),
                            label: Text(
                              _stm32CurrentName != null ? 'Téléchargement…' : 'Télécharger sélection',
                            ),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    if (_stm32Files.isNotEmpty)
                      ..._stm32Files.map((name) {
                        final selected = _stm32Selected.contains(name);
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: selected,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _stm32Selected.add(name);
                                    } else {
                                      _stm32Selected.remove(name);
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.folder_open_rounded),
                            label: const Text('Explorer'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isDownloading ? null : _downloadSelected,
                            icon: _isDownloading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.file_download_rounded),
                            label: const Text('Télécharger'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final f = _selectedFiles[index];
                    final sizeKb = (f.size / 1024).toStringAsFixed(1);
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_rounded, color: AppTheme.primaryColor),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sizeKb} KB',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Retirer',
                            onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _selectedFiles.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: AppTheme.softShadow,
            border: Border.all(
              color: activity.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: activity.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  activity.icon,
                  color: activity.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  activity.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/material_model.dart';
import '../services/storage_service.dart';
import '../widgets/section_header.dart';
import '../widgets/workspace_page.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({
    super.key,
    required this.storageService,
    required this.onOpenMaterial,
  });

  final StorageService storageService;
  final ValueChanged<String> onOpenMaterial;

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  late Future<List<MaterialModel>> _materialsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _materialsFuture = widget.storageService.loadMaterials();
  }

  Future<void> _delete(String id) async {
    await widget.storageService.deleteMaterial(id);
    if (!mounted) {
      return;
    }

    setState(_reload);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Материал удален.')));
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Мои материалы',
            description:
                'Сохраненные тексты доступны в этом списке. Их можно открыть для редактирования или удалить.',
            icon: Icons.article_outlined,
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<MaterialModel>>(
            future: _materialsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }

              final materials = snapshot.data ?? [];
              if (materials.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text('Пока нет сохраненных материалов.'),
                  ),
                );
              }

              return Column(
                children: [
                  for (final material in materials) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.description_outlined, size: 30),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    material.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Изменено: ${_formatDate(material.updatedAt)}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      widget.onOpenMaterial(material.id),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('Открыть'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _delete(material.id),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Удалить'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

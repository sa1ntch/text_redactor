import 'package:flutter/material.dart';

import '../widgets/section_header.dart';
import '../widgets/workspace_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Рабочее место редакции',
            description:
                'Простой веб-прототип для подготовки газетных материалов: набор текста, расшифровка аудио через Deepgram, проверка русской орфографии через Яндекс Спеллер и локальное сохранение статей.',
            icon: Icons.newspaper_outlined,
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 780 ? 2 : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: columns == 2 ? 2.5 : 2.8,
                children: [
                  _HomeActionCard(
                    title: 'Новый материал',
                    description:
                        'Создать статью, добавить аудио-транскрибацию и проверить русский текст.',
                    icon: Icons.edit_note_outlined,
                    onTap: () => onNavigate(1),
                  ),
                  _HomeActionCard(
                    title: 'Мои материалы',
                    description:
                        'Открыть, изменить или удалить сохраненные тексты.',
                    icon: Icons.article_outlined,
                    onTap: () => onNavigate(2),
                  ),
                  _HomeActionCard(
                    title: 'О приложении',
                    description: 'Посмотреть сведения о проекте и технологиях.',
                    icon: Icons.info_outline,
                    onTap: () => onNavigate(3),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                icon,
                size: 34,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

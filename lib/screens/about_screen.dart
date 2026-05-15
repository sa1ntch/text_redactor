import 'package:flutter/material.dart';

import '../widgets/section_header.dart';
import '../widgets/workspace_page.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'О приложении',
            description:
                'Учебный Flutter Web-проект для автоматизации базовой работы редакции газеты.',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _InfoRow(
                    label: 'Название проекта',
                    value: 'Веб-приложение для сотрудников газеты',
                  ),
                  _InfoRow(
                    label: 'Назначение',
                    value:
                        'Создание, редактирование, проверка и локальное хранение текстовых материалов.',
                  ),
                  _InfoRow(
                    label: 'Технологии',
                    value:
                        'Flutter, Dart, Flutter Web, SharedPreferences, Deepgram Speech-to-Text, Яндекс Спеллер',
                  ),
                  _InfoRow(label: 'Автор', value: 'Шанаурина Анна Игоревна'),
                  _InfoRow(label: 'Учебное заведение', value: 'НИУ МАИ'),
                  _InfoRow(label: 'Группа', value: 'М8О-405Б-22'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

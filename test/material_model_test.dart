import 'package:flutter_test/flutter_test.dart';
import 'package:text_redactor_for_magazine/models/material_model.dart';

void main() {
  test('serializes and restores material model', () {
    final updatedAt = DateTime.parse('2026-05-13T10:15:00.000');
    final material = MaterialModel(
      id: '1',
      title: 'Интервью',
      text: 'Текст материала',
      updatedAt: updatedAt,
    );

    final restored = MaterialModel.fromJson(material.toJson());

    expect(restored.id, '1');
    expect(restored.title, 'Интервью');
    expect(restored.text, 'Текст материала');
    expect(restored.updatedAt, updatedAt);
  });
}

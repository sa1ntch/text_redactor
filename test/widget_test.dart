import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:text_redactor_for_magazine/main.dart';

void main() {
  testWidgets('home screen shows primary sections', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    expect(find.text('Рабочее место редакции'), findsOneWidget);
    expect(find.text('Новый материал'), findsWidgets);
    expect(find.text('Мои материалы'), findsWidgets);
    expect(find.text('О приложении'), findsWidgets);
    expect(find.text('Проверка орфографии'), findsNothing);
    expect(find.text('Транскрибация аудио'), findsNothing);
  });

  testWidgets(
    'editor contains transcription utility and live spelling status',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Новый материал').first);
      await tester.pumpAndSettle();

      expect(find.text('Транскрибация аудио'), findsOneWidget);
      expect(find.text('Текст материала'), findsOneWidget);
      expect(
        find.text('Проверка русского текста: ошибок не найдено.'),
        findsOneWidget,
      );
    },
  );
}

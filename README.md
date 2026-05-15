# text_redactor_for_magazine

Text redactor for magazine

## Audio to text

Аудио расшифровывается через Deepgram Speech-to-Text (`nova-3`).
Ключ можно вставить прямо в редакторе или передать при запуске:

```bash
flutter run -d chrome --dart-define=DEEPGRAM_API_KEY=your_deepgram_api_key
```

В запросах используется заголовок `Authorization: Token DEEPGRAM_API_KEY`.
Deepgram дает бесплатный стартовый кредит для учебных и тестовых проектов.

Если во время Flutter Web-разработки появляется CanvasKit ошибка вида
`LateInitializationError: Field '_handledContextLostEvent' has not been initialized`,
запускайте локальный web-server через Wasm:

```bash
flutter run -d web-server --wasm --web-hostname 127.0.0.1 --web-port 5570
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

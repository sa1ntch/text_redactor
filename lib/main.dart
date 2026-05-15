import 'package:flutter/material.dart';

import 'screens/about_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/home_screen.dart';
import 'screens/materials_screen.dart';
import 'services/storage_service.dart';
import 'widgets/app_menu.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const inkBlue = Color(0xFF245A92);
    const paper = Color(0xFFF6F8FB);

    return MaterialApp(
      title: 'Редактор газеты',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: inkBlue,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: paper,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1F2937),
          elevation: 0,
          surfaceTintColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: inkBlue, width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const MagazineWorkspace(),
    );
  }
}

class MagazineWorkspace extends StatefulWidget {
  const MagazineWorkspace({super.key});

  @override
  State<MagazineWorkspace> createState() => _MagazineWorkspaceState();
}

class _MagazineWorkspaceState extends State<MagazineWorkspace> {
  final StorageService _storageService = StorageService();
  int _selectedIndex = 0;
  String? _editingMaterialId;
  int _editorRevision = 0;

  static const _destinations = <AppMenuItem>[
    AppMenuItem(label: 'Главная', icon: Icons.home_outlined),
    AppMenuItem(label: 'Новый материал', icon: Icons.edit_note_outlined),
    AppMenuItem(label: 'Мои материалы', icon: Icons.article_outlined),
    AppMenuItem(label: 'О приложении', icon: Icons.info_outline),
  ];

  void _selectSection(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _editingMaterialId = null;
        _editorRevision++;
      }
    });
  }

  void _openEditorFor(String materialId) {
    setState(() {
      _selectedIndex = 1;
      _editingMaterialId = materialId;
      _editorRevision++;
    });
  }

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 1:
        return EditorScreen(
          key: ValueKey('editor-$_editingMaterialId-$_editorRevision'),
          storageService: _storageService,
          materialId: _editingMaterialId,
        );
      case 2:
        return MaterialsScreen(
          storageService: _storageService,
          onOpenMaterial: _openEditorFor,
        );
      case 3:
        return const AboutScreen();
      default:
        return HomeScreen(onNavigate: _selectSection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Редактор газеты'),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
          ),
          drawer: compact
              ? Drawer(
                  child: SafeArea(
                    child: AppMenu(
                      compact: true,
                      destinations: _destinations,
                      selectedIndex: _selectedIndex,
                      onSelected: (index) {
                        Navigator.of(context).pop();
                        _selectSection(index);
                      },
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!compact)
                AppMenu(
                  compact: false,
                  destinations: _destinations,
                  selectedIndex: _selectedIndex,
                  onSelected: _selectSection,
                ),
              Expanded(child: _buildScreen()),
            ],
          ),
        );
      },
    );
  }
}

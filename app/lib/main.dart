import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'pages/home_page.dart';
import 'models/workspace.dart';
import 'controllers/workspace_controller.dart';
import 'models/stroke.dart';
import 'models/canvas_objects.dart';
import 'models/adapters.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/hydrop_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter('Hydrop');

  Hive.registerAdapter(OffsetAdapter());
  Hive.registerAdapter(NoteDocumentAdapter());
  Hive.registerAdapter(FolderAdapter());
  Hive.registerAdapter(StrokeAdapter());
  Hive.registerAdapter(StrokePointAdapter());
  Hive.registerAdapter(TextNodeAdapter());
  Hive.registerAdapter(ImageNodeAdapter());
  Hive.registerAdapter(CanvasLayerAdapter());

  final workspace = WorkspaceController();
  await workspace.init();

  runApp(HydropApp(workspace: workspace));
}

class HydropApp extends StatefulWidget {
  final WorkspaceController workspace;

  const HydropApp({super.key, required this.workspace});

  @override
  State<HydropApp> createState() => _HydropAppState();
}

class _HydropAppState extends State<HydropApp> {
  final ThemeController _themeController = ThemeController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        final ht = _themeController.current;
        final textTheme = _themeController.isInk
            ? GoogleFonts.getTextTheme(_themeController.inkFontFamily)
            : GoogleFonts.interTextTheme();

        return HydropThemeProvider(
          theme: ht,
          child: MaterialApp(
            title: 'Hydrop',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              textTheme: textTheme,
              colorScheme: ColorScheme.fromSeed(
                seedColor: ht.primary,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: ht.background,
              useMaterial3: true,
            ),
            home: HomePage(
              workspace: widget.workspace,
              themeController: _themeController,
            ),
          ),
        );
      },
    );
  }
}

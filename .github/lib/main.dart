import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

// ═══════════════════════════════════════════════════════════════════════════════
// TROK — TikTok-Style Local Video Media Manager
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0E),
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TrokApp());
}

// ─── CONSTANTS ───────────────────────────────────────────────────────────────

class TrokColors {
  static const Color bg = Color(0xFF0A0A0E);
  static const Color cyan = Color(0xFF00F2FE);
  static const Color magenta = Color(0xFFFF0844);
  static const Color surface = Color(0xFF1A1A22);
  static const Color surfaceLight = Color(0xFF2A2A35);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8888AA);

  static const Gradient neonGradient = LinearGradient(
    colors: [cyan, magenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient neonGradientHorizontal = LinearGradient(
    colors: [cyan, magenta],
  );
}

const List<String> _videoExtensions = [
  '.mp4', '.mkv', '.mov', '.avi', '.webm', '.3gp',
];

const List<String> _scanDirs = [
  'DCIM', 'Download', 'Downloads', 'Movies', 'WhatsApp',
  'Telegram', 'Pictures', 'Video', 'Videos', 'Media',
  'Camera', 'ScreenRecorder', 'Recordings',
];

// ─── APP ROOT ────────────────────────────────────────────────────────────────

class TrokApp extends StatelessWidget {
  const TrokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trok',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: TrokColors.bg,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: TrokColors.cyan,
          secondary: TrokColors.magenta,
          surface: TrokColors.surface,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: TrokColors.surface.withValues(alpha: 0.95),
          contentTextStyle: const TextStyle(color: TrokColors.textPrimary),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── TROK LOGO (Custom Painter) ──────────────────────────────────────────────

class TrokLogoPainter extends CustomPainter {
  final double glowOpacity;

  TrokLogoPainter({this.glowOpacity = 0.6});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glow background
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..shader = LinearGradient(
        colors: [
          TrokColors.cyan.withValues(alpha: glowOpacity * 0.3),
          TrokColors.magenta.withValues(alpha: glowOpacity * 0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.4, glowPaint);

    // Main gradient paint
    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [TrokColors.cyan, TrokColors.magenta],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // "T" letter
    final tPath = Path();
    tPath.moveTo(w * 0.2, h * 0.2);
    tPath.lineTo(w * 0.8, h * 0.2);
    tPath.moveTo(w * 0.5, h * 0.2);
    tPath.lineTo(w * 0.5, h * 0.75);
    canvas.drawPath(tPath, gradientPaint);

    // Play triangle (filled)
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          TrokColors.cyan.withValues(alpha: 0.8),
          TrokColors.magenta.withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final playPath = Path();
    playPath.moveTo(w * 0.55, h * 0.35);
    playPath.lineTo(w * 0.78, h * 0.52);
    playPath.lineTo(w * 0.55, h * 0.68);
    playPath.close();
    canvas.drawPath(playPath, fillPaint);

    // Shuffle arrows
    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [TrokColors.cyan, TrokColors.magenta],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final a1 = Path();
    a1.moveTo(w * 0.18, h * 0.42);
    a1.quadraticBezierTo(w * 0.35, h * 0.65, w * 0.48, h * 0.42);
    canvas.drawPath(a1, arrowPaint);
    canvas.drawLine(Offset(w * 0.48, h * 0.42), Offset(w * 0.43, h * 0.36), arrowPaint);
    canvas.drawLine(Offset(w * 0.48, h * 0.42), Offset(w * 0.42, h * 0.46), arrowPaint);

    final a2 = Path();
    a2.moveTo(w * 0.18, h * 0.62);
    a2.quadraticBezierTo(w * 0.35, h * 0.38, w * 0.48, h * 0.62);
    canvas.drawPath(a2, arrowPaint);
    canvas.drawLine(Offset(w * 0.48, h * 0.62), Offset(w * 0.43, h * 0.56), arrowPaint);
    canvas.drawLine(Offset(w * 0.48, h * 0.62), Offset(w * 0.42, h * 0.66), arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrokLogo extends StatelessWidget {
  final double size;
  final double glowOpacity;

  const TrokLogo({super.key, this.size = 80, this.glowOpacity = 0.6});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: TrokLogoPainter(glowOpacity: glowOpacity)),
    );
  }
}

class TrokBrandHeader extends StatelessWidget {
  final double logoSize;
  final double fontSize;

  const TrokBrandHeader({super.key, this.logoSize = 32, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TrokLogo(size: logoSize),
        const SizedBox(width: 6),
        ShaderMask(
          shaderCallback: (bounds) => TrokColors.neonGradientHorizontal.createShader(bounds),
          child: Text(
            'trok',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ─── SPLASH SCREEN ──────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this);
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), _checkPermissions);
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PermissionScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrokColors.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _opacityAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TrokLogo(size: 140, glowOpacity: 0.8),
                    const SizedBox(height: 24),
                    ShaderMask(
                      shaderCallback: (bounds) => TrokColors.neonGradientHorizontal.createShader(bounds),
                      child: const Text('trok', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    Text('Media Manager', style: TextStyle(fontSize: 14, color: TrokColors.textSecondary.withValues(alpha: 0.7), letterSpacing: 6, fontWeight: FontWeight.w300)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── PERMISSION SCREEN ──────────────────────────────────────────────────────

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _checking = true;
  String _statusText = 'Checking permissions...';

  @override
  void initState() {
    super.initState();
    _verifyPermission();
  }

  Future<void> _verifyPermission() async {
    setState(() { _checking = true; _statusText = 'Checking permissions...'; });

    bool granted = false;
    if (await Permission.manageExternalStorage.isGranted) {
      granted = true;
    } else if (await Permission.storage.isGranted) {
      granted = true;
    }

    if (granted) { _navigateToFeed(); return; }
    setState(() { _checking = false; _statusText = 'Trok needs storage access to browse your videos'; });
  }

  Future<void> _requestPermission() async {
    setState(() { _checking = true; _statusText = 'Requesting permission...'; });

    PermissionStatus status = await Permission.manageExternalStorage.request();
    if (status.isGranted) { _navigateToFeed(); return; }

    status = await Permission.storage.request();
    if (status.isGranted) { _navigateToFeed(); return; }

    if (status.isPermanentlyDenied) {
      setState(() { _checking = false; _statusText = 'Permission denied. Please enable in Settings.'; });
      return;
    }
    setState(() { _checking = false; _statusText = 'Permission denied. Tap below to try again.'; });
  }

  void _navigateToFeed() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const VideoFeedScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrokColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TrokLogo(size: 100, glowOpacity: 0.7),
              const SizedBox(height: 32),
              ShaderMask(
                shaderCallback: (bounds) => TrokColors.neonGradientHorizontal.createShader(bounds),
                child: const Text('trok', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
              ),
              const SizedBox(height: 32),
              Icon(Icons.folder_open_rounded, color: TrokColors.cyan.withValues(alpha: 0.5), size: 60),
              const SizedBox(height: 20),
              Text(_statusText, textAlign: TextAlign.center, style: const TextStyle(color: TrokColors.textSecondary, fontSize: 16, height: 1.5)),
              const SizedBox(height: 36),
              if (_checking)
                SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(TrokColors.cyan.withValues(alpha: 0.8))))
              else ...[
                _NeonButton(label: 'Grant Access', icon: Icons.lock_open_rounded, onTap: _requestPermission),
                const SizedBox(height: 16),
                TextButton(onPressed: () => openAppSettings(), child: const Text('Open Settings', style: TextStyle(color: TrokColors.textSecondary, fontSize: 14))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── NEON BUTTON ─────────────────────────────────────────────────────────────

class _NeonButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NeonButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: TrokColors.neonGradient,
          boxShadow: [
            BoxShadow(color: TrokColors.cyan.withValues(alpha: _pressed ? 0.6 : 0.3), blurRadius: _pressed ? 24 : 12, spreadRadius: _pressed ? 2 : 0),
            BoxShadow(color: TrokColors.magenta.withValues(alpha: _pressed ? 0.6 : 0.3), blurRadius: _pressed ? 24 : 12, spreadRadius: _pressed ? 2 : 0),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ─── VIDEO FEED SCREEN ──────────────────────────────────────────────────────

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  List<File> _allVideos = [];
  List<File> _filteredVideos = [];
  bool _loading = true;
  String _scanStatus = 'Scanning for videos...';
  bool _instantDelete = false;
  String _selectedFolder = 'All Videos';
  List<String> _availableFolders = ['All Videos'];
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scanVideos();
  }

  Future<void> _scanVideos() async {
    setState(() { _loading = true; _scanStatus = 'Scanning for videos...'; });

    final List<File> videos = [];
    final Set<String> folders = {};
    Directory root = Directory('/storage/emulated/0');
    if (!root.existsSync()) {
      final sdcard = Directory('/sdcard');
      if (sdcard.existsSync()) {
        root = sdcard;
      } else if (Platform.isMacOS || Platform.isLinux) {
        final home = Platform.environment['HOME'];
        if (home != null && Directory(home).existsSync()) {
          root = Directory(home);
        }
      }
    }

    if (!root.existsSync()) {
      setState(() { _loading = false; _scanStatus = 'Storage not accessible'; });
      return;
    }

    for (final dirName in _scanDirs) {
      final dir = Directory('${root.path}/$dirName');
      if (dir.existsSync()) {
        await _scanDirectory(dir, videos, folders);
      }
    }

    // Also scan root level
    try {
      final rootEntries = root.listSync(followLinks: false);
      for (final entry in rootEntries) {
        if (entry is File && _isVideo(entry.path)) {
          videos.add(entry);
          folders.add(p.basename(root.path));
        }
      }
    } catch (_) {}

    videos.shuffle(Random());
    final folderList = ['All Videos', ...folders.toList()..sort()];

    setState(() {
      _allVideos = videos;
      _filteredVideos = List.from(videos);
      _availableFolders = folderList;
      _selectedFolder = 'All Videos';
      _loading = false;
      _scanStatus = '${videos.length} videos found';
    });
  }

  Future<void> _scanDirectory(Directory dir, List<File> videos, Set<String> folders) async {
    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File && _isVideo(entity.path)) {
          final path = entity.path;
          if (path.contains('/Android/data') || path.contains('/Android/obb') ||
              path.split('/').any((s) => s.startsWith('.') && s.length > 1)) {
            continue;
          }
          videos.add(entity);
          folders.add(p.basename(entity.parent.path));
        }
      }
    } catch (_) {}
  }

  bool _isVideo(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return _videoExtensions.contains(ext);
  }

  void _reshuffle() {
    setState(() { _filteredVideos.shuffle(Random()); _currentPage = 0; });
    _pageController.jumpToPage(0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [Icon(Icons.shuffle_rounded, color: TrokColors.cyan, size: 20), SizedBox(width: 10), Text('Trok feed reshuffled!')]),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _filterByFolder(String folder) {
    setState(() {
      _selectedFolder = folder;
      if (folder == 'All Videos') {
        _filteredVideos = List.from(_allVideos);
      } else {
        _filteredVideos = _allVideos.where((f) => p.basename(f.parent.path) == folder).toList();
      }
      _filteredVideos.shuffle(Random());
      _currentPage = 0;
    });
    _pageController.jumpToPage(0);
  }

  void _onVideoRenamed(int index, File oldFile, File newFile) {
    setState(() {
      final filtIdx = _filteredVideos.indexOf(oldFile);
      if (filtIdx >= 0) _filteredVideos[filtIdx] = newFile;
      final allIdx = _allVideos.indexOf(oldFile);
      if (allIdx >= 0) _allVideos[allIdx] = newFile;
    });
  }

  void _onVideoDeleted(int index, File file) {
    setState(() {
      _filteredVideos.remove(file);
      _allVideos.remove(file);
      if (_currentPage >= _filteredVideos.length && _filteredVideos.isNotEmpty) {
        _currentPage = _filteredVideos.length - 1;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [Icon(Icons.delete_rounded, color: TrokColors.magenta.withValues(alpha: 0.9), size: 20), const SizedBox(width: 10), const Text('Deleted from device')]),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: TrokColors.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const TrokLogo(size: 80),
            const SizedBox(height: 24),
            SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(TrokColors.cyan.withValues(alpha: 0.8)))),
            const SizedBox(height: 16),
            Text(_scanStatus, style: const TextStyle(color: TrokColors.textSecondary, fontSize: 14)),
          ]),
        ),
      );
    }

    if (_filteredVideos.isEmpty) {
      return Scaffold(
        backgroundColor: TrokColors.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.video_library_outlined, color: TrokColors.textSecondary.withValues(alpha: 0.4), size: 80),
            const SizedBox(height: 20),
            const Text('No videos found', style: TextStyle(color: TrokColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(_selectedFolder == 'All Videos' ? 'Try adding videos to your device' : 'No videos in $_selectedFolder',
              style: TextStyle(color: TrokColors.textSecondary.withValues(alpha: 0.6), fontSize: 14)),
            const SizedBox(height: 24),
            TextButton.icon(onPressed: _scanVideos, icon: const Icon(Icons.refresh_rounded, color: TrokColors.cyan), label: const Text('Rescan', style: TextStyle(color: TrokColors.cyan))),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TrokColors.bg,
      body: Stack(
        children: [
          // Video feed
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _filteredVideos.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return VideoFeedItem(
                key: ValueKey(_filteredVideos[index].path),
                file: _filteredVideos[index],
                isActive: index == _currentPage,
                instantDelete: _instantDelete,
                onRenamed: (oldFile, newFile) => _onVideoRenamed(index, oldFile, newFile),
                onDeleted: (file) => _onVideoDeleted(index, file),
              );
            },
          ),

          // Top overlay bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 12, right: 12, bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [TrokColors.bg.withValues(alpha: 0.85), TrokColors.bg.withValues(alpha: 0.0)],
                ),
              ),
              child: Row(
                children: [
                  const TrokBrandHeader(logoSize: 28, fontSize: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: TrokColors.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TrokColors.cyan.withValues(alpha: 0.2), width: 0.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFolder,
                          isExpanded: true,
                          dropdownColor: TrokColors.surface,
                          icon: const Icon(Icons.arrow_drop_down, color: TrokColors.cyan, size: 20),
                          style: const TextStyle(color: TrokColors.textPrimary, fontSize: 12),
                          items: _availableFolders.map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f, overflow: TextOverflow.ellipsis, style: TextStyle(color: f == _selectedFolder ? TrokColors.cyan : TrokColors.textPrimary, fontSize: 12)),
                          )).toList(),
                          onChanged: (v) { if (v != null) _filterByFolder(v); },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _GlowIconButton(icon: Icons.shuffle_rounded, tooltip: 'Reshuffle', onTap: _reshuffle, color: TrokColors.cyan),
                  const SizedBox(width: 4),
                  _DeleteModeToggle(instantDelete: _instantDelete, onChanged: (v) => setState(() => _instantDelete = v)),
                ],
              ),
            ),
          ),

          // Video counter
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 14, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: TrokColors.bg.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
              child: Text('${_currentPage + 1} / ${_filteredVideos.length}', style: TextStyle(color: TrokColors.textSecondary.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GLOW ICON BUTTON ────────────────────────────────────────────────────────

class _GlowIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _GlowIconButton({required this.icon, required this.tooltip, required this.onTap, this.color = TrokColors.cyan});

  @override
  State<_GlowIconButton> createState() => _GlowIconButtonState();
}

class _GlowIconButtonState extends State<_GlowIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { _animController.forward(from: 0); widget.onTap(); },
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TrokColors.surface.withValues(alpha: 0.6),
              boxShadow: _animController.isAnimating
                ? [BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 2)]
                : null,
            ),
            child: Transform.rotate(
              angle: _animController.value * 2 * pi,
              child: Icon(widget.icon, color: widget.color, size: 20),
            ),
          );
        },
      ),
    );
  }
}

// ─── DELETE MODE TOGGLE ──────────────────────────────────────────────────────

class _DeleteModeToggle extends StatelessWidget {
  final bool instantDelete;
  final ValueChanged<bool> onChanged;

  const _DeleteModeToggle({required this.instantDelete, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!instantDelete),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: TrokColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: instantDelete ? TrokColors.magenta.withValues(alpha: 0.5) : TrokColors.cyan.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(instantDelete ? Icons.flash_on_rounded : Icons.shield_outlined, color: instantDelete ? TrokColors.magenta : TrokColors.cyan, size: 14),
            const SizedBox(width: 4),
            Text(instantDelete ? 'Instant' : 'Safe', style: TextStyle(color: instantDelete ? TrokColors.magenta : TrokColors.cyan, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── VIDEO FEED ITEM ─────────────────────────────────────────────────────────

class VideoFeedItem extends StatefulWidget {
  final File file;
  final bool isActive;
  final bool instantDelete;
  final void Function(File oldFile, File newFile) onRenamed;
  final void Function(File file) onDeleted;

  const VideoFeedItem({super.key, required this.file, required this.isActive, required this.instantDelete, required this.onRenamed, required this.onDeleted});

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _showPlayPauseIcon = false;
  bool _disposed = false;
  late File _currentFile;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.file;
    if (widget.isActive) _initController();
  }

  @override
  void didUpdateWidget(VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initController();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposeController();
    }
  }

  Future<void> _initController() async {
    if (_disposed) return;
    _disposeController();
    final ctrl = VideoPlayerController.file(_currentFile);
    _controller = ctrl;
    try {
      await ctrl.initialize();
      if (_disposed || _controller != ctrl) return;
      ctrl.setLooping(true);
      ctrl.play();
      if (mounted) setState(() { _initialized = true; _isPlaying = true; });
    } catch (e) {
      if (mounted) setState(() => _initialized = false);
    }
  }

  void _disposeController() {
    final ctrl = _controller;
    _controller = null;
    _initialized = false;
    _isPlaying = false;
    ctrl?.dispose();
  }

  @override
  void dispose() { _disposed = true; _disposeController(); super.dispose(); }

  void _togglePlayPause() {
    final ctrl = _controller;
    if (ctrl == null || !_initialized) return;
    if (ctrl.value.isPlaying) { ctrl.pause(); setState(() => _isPlaying = false); }
    else { ctrl.play(); setState(() => _isPlaying = true); }
    setState(() => _showPlayPauseIcon = true);
    Future.delayed(const Duration(milliseconds: 600), () { if (mounted) setState(() => _showPlayPauseIcon = false); });
  }

  Future<void> _handleRename() async {
    _controller?.pause();
    setState(() => _isPlaying = false);

    final nameWithoutExt = p.basenameWithoutExtension(_currentFile.path);
    final ext = p.extension(_currentFile.path);
    final parentDir = _currentFile.parent.path;
    final textController = TextEditingController(text: nameWithoutExt)
      ..selection = TextSelection(baseOffset: 0, extentOffset: nameWithoutExt.length);

    final newName = await showDialog<String>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: TrokColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: ShaderMask(
          shaderCallback: (b) => TrokColors.neonGradientHorizontal.createShader(b),
          child: const Text('Rename Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Extension: $ext', style: TextStyle(color: TrokColors.textSecondary.withValues(alpha: 0.7), fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: TrokColors.textPrimary),
              decoration: InputDecoration(
                filled: true, fillColor: TrokColors.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: TrokColors.cyan.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TrokColors.cyan)),
                hintText: 'Enter new name', hintStyle: TextStyle(color: TrokColors.textSecondary.withValues(alpha: 0.4)),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: TextStyle(color: TrokColors.textSecondary.withValues(alpha: 0.7)))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: TrokColors.cyan, foregroundColor: TrokColors.bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Rename', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != nameWithoutExt) {
      try {
        final newPath = '$parentDir/$newName$ext';
        final renamedFile = _currentFile.renameSync(newPath);
        final oldFile = _currentFile;
        _currentFile = renamedFile;
        widget.onRenamed(oldFile, renamedFile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Renamed to $newName$ext'), duration: const Duration(seconds: 2)));
        }
        _initController();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rename failed: $e'), duration: const Duration(seconds: 3)));
          _controller?.play();
          setState(() => _isPlaying = true);
        }
      }
    } else {
      _controller?.play();
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _handleDelete() async {
    if (widget.instantDelete) {
      _executeDelete();
    } else {
      _controller?.pause();
      setState(() => _isPlaying = false);

      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black87,
        builder: (ctx) => AlertDialog(
          backgroundColor: TrokColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Video?', style: TextStyle(color: TrokColors.magenta, fontWeight: FontWeight.w700, fontSize: 18)),
          content: Text('This will permanently delete\n"${p.basename(_currentFile.path)}"', style: const TextStyle(color: TrokColors.textSecondary, fontSize: 14, height: 1.5)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: TextStyle(color: TrokColors.textSecondary.withValues(alpha: 0.7)))),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: TrokColors.magenta, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

      if (confirm == true) { _executeDelete(); }
      else { _controller?.play(); setState(() => _isPlaying = true); }
    }
  }

  void _executeDelete() {
    _disposeController();
    try {
      _currentFile.deleteSync();
      widget.onDeleted(_currentFile);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), duration: const Duration(seconds: 3)));
    }
  }

  Future<void> _handleShare() async {
    _controller?.pause();
    setState(() => _isPlaying = false);
    try { await Share.shareXFiles([XFile(_currentFile.path)]); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e'), duration: const Duration(seconds: 3)));
    }
    if (mounted && _controller != null) { _controller?.play(); setState(() => _isPlaying = true); }
  }

  String _formatFileSize(File file) {
    try { final bytes = file.lengthSync(); final mb = bytes / (1024 * 1024); return '${mb.toStringAsFixed(1)} MB'; } catch (_) { return '? MB'; }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          if (_initialized && _controller != null)
            GestureDetector(
              onTap: _togglePlayPause,
              child: Center(child: AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))),
            )
          else
            GestureDetector(
              onTap: _togglePlayPause,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(TrokColors.cyan.withValues(alpha: 0.5)))),
                  const SizedBox(height: 12),
                  Text('Loading...', style: TextStyle(color: TrokColors.textSecondary.withValues(alpha: 0.5), fontSize: 12)),
                ]),
              ),
            ),

          // Play/Pause indicator
          if (_showPlayPauseIcon)
            Center(
              child: AnimatedOpacity(
                opacity: _showPlayPauseIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.5)),
                  child: Icon(_isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white.withValues(alpha: 0.9), size: 40),
                ),
              ),
            ),

          // Bottom metadata
          Positioned(
            left: 16, bottom: 68, right: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.basenameWithoutExtension(_currentFile.path),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 8, color: Colors.black)]),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Text('📁 ', style: TextStyle(fontSize: 12)),
                  Flexible(child: Text('${p.basename(_currentFile.parent.path)} • ${_formatFileSize(_currentFile)}',
                    style: TextStyle(color: TrokColors.textSecondary.withValues(alpha: 0.8), fontSize: 13, shadows: const [Shadow(blurRadius: 6, color: Colors.black)]),
                    overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ),
          ),

          // Right action buttons
          Positioned(
            right: 12, bottom: 80,
            child: Column(children: [
              _ActionButton(icon: Icons.edit_rounded, label: 'Rename', color: TrokColors.cyan, onTap: _handleRename),
              const SizedBox(height: 18),
              _ActionButton(icon: Icons.delete_rounded, label: 'Delete', color: TrokColors.magenta, onTap: _handleDelete),
              const SizedBox(height: 18),
              _ActionButton(icon: Icons.share_rounded, label: 'Share', color: Colors.white, onTap: _handleShare),
            ]),
          ),

          // Progress bar
          if (_initialized && _controller != null)
            Positioned(left: 0, right: 0, bottom: 0, child: _NeonProgressBar(controller: _controller!)),
        ],
      ),
    );
  }
}

// ─── ACTION BUTTON (Glassmorphic) ────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: _pressed ? 0.2 : 0.1),
            border: Border.all(color: widget.color.withValues(alpha: _pressed ? 0.6 : 0.25), width: 1.2),
            boxShadow: _pressed ? [BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)] : null,
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Center(child: Icon(widget.icon, color: widget.color, size: 24)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(widget.label, style: TextStyle(color: widget.color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600, shadows: const [Shadow(blurRadius: 4, color: Colors.black)])),
      ]),
    );
  }
}

// ─── NEON PROGRESS BAR ──────────────────────────────────────────────────────

class _NeonProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  const _NeonProgressBar({required this.controller});

  @override
  State<_NeonProgressBar> createState() => _NeonProgressBarState();
}

class _NeonProgressBarState extends State<_NeonProgressBar> {
  bool _dragging = false;

  @override
  void initState() { super.initState(); widget.controller.addListener(_onUpdate); }

  @override
  void dispose() { widget.controller.removeListener(_onUpdate); super.dispose(); }

  void _onUpdate() { if (!_dragging && mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final duration = widget.controller.value.duration;
    final position = widget.controller.value.position;
    final progress = duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;

    return GestureDetector(
      onHorizontalDragStart: (_) => _dragging = true,
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final dx = details.localPosition.dx / box.size.width;
        final seekTo = duration * dx.clamp(0.0, 1.0);
        widget.controller.seekTo(seekTo);
      },
      onHorizontalDragEnd: (_) => _dragging = false,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(bottom: 8),
        child: CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 4),
          painter: _ProgressPainter(progress: progress.clamp(0.0, 1.0)),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  _ProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeCap = StrokeCap.round..strokeWidth = 3;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..strokeCap = StrokeCap.round..strokeWidth = 3
        ..shader = const LinearGradient(colors: [TrokColors.cyan, TrokColors.magenta]).createShader(Rect.fromLTWH(0, 0, size.width * progress, 3));
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width * progress, size.height / 2), fgPaint);

      final dotPaint = Paint()..color = TrokColors.cyan..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(size.width * progress, size.height / 2), 5, dotPaint);
      canvas.drawCircle(Offset(size.width * progress, size.height / 2), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter old) => old.progress != progress;
}

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

// --- 1. DATA MODEL FOR SAVED COLORS ---
class ColorRecord {
  final Color color;
  final String hex;
  final String rgba;
  final String name;
  final DateTime timestamp;

  ColorRecord({
    required this.color,
    required this.hex,
    required this.rgba,
    required this.name,
    required this.timestamp,
  });
}

// --- 2. MOCK ASIAN PAINTS DATABASE ---
final List<Map<String, dynamic>> asianPaintsColors = [
  {'name': 'Mystic Mauve', 'hex': 0xE8D5D5},
  {'name': 'Tranquil Blue', 'hex': 0xA4C2D4},
  {'name': 'Saffron Strands', 'hex': 0xF4C430},
  {'name': 'Royal Red', 'hex': 0xC41E3A},
  {'name': 'Emerald Isle', 'hex': 0x50C878},
  {'name': 'Midnight Blue', 'hex': 0x191970},
  {'name': 'Coral Pink', 'hex': 0xF88379},
  {'name': 'Lemon Zest', 'hex': 0xFFF44F},
  {'name': 'Charcoal Grey', 'hex': 0x36454F},
  
  {'name': 'Pure White', 'hex': 0xFFFFFF},
  {'name': 'Jet Black', 'hex': 0x0A0A0A},
  {'name': 'Ocean Depth', 'hex': 0x006994},
  {'name': 'Forest Canopy', 'hex': 0x228B22},
  {'name': 'Desert Sand', 'hex': 0xEDC9AF},
  {'name': 'Plum Velvet', 'hex': 0x7D0552},
  {'name': 'Golden Harvest', 'hex': 0xDAA520},
  {'name': 'Silver Mist', 'hex': 0xC0C0C0},
  {'name': 'Ruby Glow', 'hex': 0xE0115F},
  {'name': 'Sage Green', 'hex': 0x9DC183},
  {'name': 'Ivory Cream', 'hex': 0xFFFFF0},
];

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // --- CAMERA & STATE VARIABLES ---
  CameraController? _cameraController;
  bool _isCameraPermissionGranted = false;
  bool _permissionDenied = false;
  bool _isFrameFrozen = false;
  Uint8List? _frozenFrameBytes;

  // --- GALLERY VARIABLES ---
  Uint8List? _galleryImageBytes;
  final ImagePicker _picker = ImagePicker();

  // --- COLOR PICKING VARIABLES ---
  final GlobalKey _viewportKey = GlobalKey();
  Offset _cursorPosition = Offset.zero;
  Color _pickedColor = Colors.white;
  String _hexCode = '#FFFFFF';
  String _rgbCode = 'RGB(255, 255, 255)';
  String _colorName = 'Unknown';
  
  // --- HISTORY ---
  List<ColorRecord> _colorHistory = [];

  // --- HAPTIC THROTTLING ---
  DateTime _lastHapticTime = DateTime.now();
  Color? _lastHapticColor;

  // --- VIEWPORT MODE ---
  int _currentMode = 0; 

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  // --- PERMISSIONS ---
  Future<void> _requestCameraPermission() async {
    print('🔐 Requesting camera permission...');
    var status = await Permission.camera.request();
    print('📋 Permission status: ${status.isGranted}');
    
    if (status.isGranted) {
      setState(() => _isCameraPermissionGranted = true);
      _initializeCamera();
    } else {
      setState(() => _permissionDenied = true);
    }
  }

  Future<void> _initializeCamera() async {
    print('🎥 Initializing camera...');
    try {
      final cameras = await availableCameras();
      print('📷 Found ${cameras.length} cameras');
      
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras[0], ResolutionPreset.high);
        await _cameraController!.initialize();
        print('✅ Camera initialized successfully!');
        
        if (mounted) {
          setState(() {});
        }
      } else {
        print('❌ No cameras available!');
      }
    } catch (e) {
      print('❌ Camera initialization error: $e');
    }
  }

  // --- FREEZE / RESUME LOGIC ---
  Future<void> _freezeFrame() async {
    HapticFeedback.mediumImpact();
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      setState(() {
        _isFrameFrozen = true;
        _frozenFrameBytes = bytes;
        _currentMode = 1;
      });
    }
  }

  void _resumeCamera() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isFrameFrozen = false;
      _frozenFrameBytes = null;
      _currentMode = 0;
    });
  }

  // --- GALLERY LOGIC ---
  Future<void> _pickFromGallery() async {
    HapticFeedback.selectionClick();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _galleryImageBytes = bytes;
        _currentMode = 2;
      });
    }
  }

  // --- THE CORE: READING THE PIXEL ---
  Future<void> _readPixelAt(Offset position) async {
    final renderObject = _viewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;
    final boundary = renderObject;

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    final Uint8List pixels = byteData.buffer.asUint8List();
    final RenderBox renderBox = boundary;
    final Size boxSize = renderBox.size;

    final int x = (position.dx / boxSize.width * image.width).clamp(0, image.width - 1).toInt();
    final int y = (position.dy / boxSize.height * image.height).clamp(0, image.height - 1).toInt();

    final int pixelIndex = (y * image.width + x) * 4;
    final int r = pixels[pixelIndex];
    final int g = pixels[pixelIndex + 1];
    final int b = pixels[pixelIndex + 2];

    final Color newColor = Color.fromRGBO(r, g, b, 1);
    final String hex = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    
    // Throttled haptic feedback for cursor dragging
    final now = DateTime.now();
    final timeSinceLastHaptic = now.difference(_lastHapticTime).inMilliseconds;
    final colorChanged = _lastHapticColor == null || 
        (_lastHapticColor!.red != newColor.red || 
         _lastHapticColor!.green != newColor.green || 
         _lastHapticColor!.blue != newColor.blue);
    
    if (colorChanged && timeSinceLastHaptic > 80) {
      HapticFeedback.lightImpact();
      _lastHapticTime = now;
      _lastHapticColor = newColor;
    }
    
    setState(() {
      _pickedColor = newColor;
      _hexCode = hex;
      _rgbCode = 'RGB($r, $g, $b)';
      _colorName = _findClosestAsianPaintsName(r, g, b);
    });
  }

  // --- ASIAN PAINTS MATCHING ALGORITHM ---
  String _findClosestAsianPaintsName(int r, int g, int b) {
    double minDistance = double.infinity;
    String closestName = 'Unknown';

    for (var paint in asianPaintsColors) {
      int hex = paint['hex'];
      int pR = (hex >> 16) & 0xFF;
      int pG = (hex >> 8) & 0xFF;
      int pB = hex & 0xFF;

      double distance = sqrt(pow(r - pR, 2) + pow(g - pG, 2) + pow(b - pB, 2));

      if (distance < minDistance) {
        minDistance = distance;
        closestName = paint['name'];
      }
    }
    return closestName;
  }

  // --- SAVE TO HISTORY ---
  void _saveToHistory() {
    HapticFeedback.mediumImpact();
    setState(() {
      _colorHistory.insert(0, ColorRecord(
        color: _pickedColor,
        hex: _hexCode,
        rgba: _rgbCode,
        name: _colorName,
        timestamp: DateTime.now(),
      ));
    });
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    print('🔨 Build called - Permission: $_isCameraPermissionGranted, Controller: ${_cameraController != null}, Initialized: ${_cameraController?.value.isInitialized}');
    
    if (_permissionDenied) {
      print('❌ Permission denied');
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 80, color: Colors.white54),
              SizedBox(height: 20),
              Text('Permission Denied', style: TextStyle(color: Colors.white, fontSize: 20)),
              SizedBox(height: 10),
              Text('Please grant camera permission in settings', 
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (!_isCameraPermissionGranted || _cameraController == null || !_cameraController!.value.isInitialized) {
      print('⏳ Showing loading screen');
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text('Loading camera...', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    print('✅ Showing main UI');

    if (_cursorPosition == Offset.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final size = MediaQuery.of(context).size;
        setState(() {
          _cursorPosition = Offset(size.width / 2, size.height / 2 - 100); 
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // TOP MODE SWITCHER
          Container(
            color: Colors.black87,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _modeButton('Live', 0),
                _modeButton('Gallery', 2),
                if (_isFrameFrozen) _modeButton('Resume', -1), 
              ],
            ),
          ),

          // MAIN VIEWPORT (The Stack)
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    key: _viewportKey,
                    child: _buildViewport(),
                  ),
                ),

                Positioned(
                  left: _cursorPosition.dx - 20, 
                  top: _cursorPosition.dy - 20,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _cursorPosition += details.delta;
                      });
                      _readPixelAt(_cursorPosition);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM INFO & HISTORY PANEL
          Container(
            height: 220,
            color: Colors.grey[900],
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: _pickedColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white)),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_colorName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(_hexCode, style: TextStyle(color: Colors.white70)),
                            Text(_rgbCode, style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.save, color: Colors.white),
                        onPressed: _saveToHistory,
                      ),
                      if (_currentMode == 0)
                        IconButton(
                          icon: Icon(Icons.pause_circle_filled, color: Colors.white),
                          onPressed: _freezeFrame,
                        ),
                    ],
                  ),
                ),
                Divider(color: Colors.white24),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorHistory.length,
                    itemBuilder: (context, index) {
                      final record = _colorHistory[index];
                      final time = DateFormat('HH:mm dd/MM').format(record.timestamp);
                      return Container(
                        width: 120,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 30, width: double.infinity, decoration: BoxDecoration(color: record.color, borderRadius: BorderRadius.circular(4))),
                            SizedBox(height: 5),
                            Text(record.name, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(record.hex, style: TextStyle(color: Colors.white70, fontSize: 10)),
                            Text(time, style: TextStyle(color: Colors.white54, fontSize: 9)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewport() {
    if (_currentMode == 1 && _frozenFrameBytes != null) {
      return Image.memory(_frozenFrameBytes!, fit: BoxFit.cover);
    } else if (_currentMode == 2 && _galleryImageBytes != null) {
      return Image.memory(_galleryImageBytes!, fit: BoxFit.cover);
    } else if (_cameraController != null && _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    } else {
      return Container(
        color: Colors.grey[800],
        child: Center(
          child: Text('Camera not ready', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Widget _modeButton(String text, int mode) {
    final bool isActive = (mode == -1 && _isFrameFrozen) || 
                         (mode != -1 && _currentMode == mode);
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        if (mode == -1) {
          _resumeCamera();
        } else if (mode == 2) {
          _pickFromGallery();
        } else {
          setState(() => _currentMode = mode);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.white : Colors.grey[800],
        foregroundColor: isActive ? Colors.black : Colors.white,
      ),
      child: Text(text),
    );
  }
}
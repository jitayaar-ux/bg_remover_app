import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'package:crop_image/crop_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Photo & BG Editor',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  File? _displayFile;
  img.Image? _decodedImage;
  bool _isLoading = false;
  
  // Modes: 0 = Zoom/View, 1 = Crop, 2 = Eraser
  int _currentMode = 0; 

  final CropController _cropController = CropController(
    aspectRatio: 1.0,
    defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
  );

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      File file = File(pickedFile.path);
      Uint8List bytes = await file.readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);

      if (decoded != null) {
        _decodedImage = img.copyResize(decoded, width: 600);
        _imageFile = file;
        await _updateDisplayImage();
      }

      setState(() {
        _isLoading = false;
        _currentMode = 0;
      });
    }
  }

  Future<void> _updateDisplayImage() async {
    if (_decodedImage == null) return;
    final tempDir = Directory.systemTemp;
    final targetPath = '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
    File outputFile = File(targetPath)..writeAsBytesSync(img.encodePng(_decodedImage!));
    
    setState(() {
      _displayFile = outputFile;
    });
  }

  // 1. AI Auto Background Remover
  Future<void> _aiAutoRemoveBg() async {
    if (_decodedImage == null) return;
    setState(() { _isLoading = true; });

    // Sample background color from top-left corner
    img.Pixel refPixel = _decodedImage!.getPixel(0, 0);
    num refR = refPixel.r;
    num refG = refPixel.g;
    num refB = refPixel.b;

    for (int y = 0; y < _decodedImage!.height; y++) {
      for (int x = 0; x < _decodedImage!.width; x++) {
        img.Pixel pixel = _decodedImage!.getPixel(x, y);
        num r = pixel.r;
        num g = pixel.g;
        num b = pixel.b;

        double diff = ((r - refR).abs() + (g - refG).abs() + (b - refB).abs()) / 3;
        if (diff < 45 || (r > 235 && g > 235 && b > 235)) {
          _decodedImage!.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    await _updateDisplayImage();
    setState(() { _isLoading = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Background Removed Successfully!')),
    );
  }

  // 2. Clear HD Enhancer
  Future<void> _enhanceHD() async {
    if (_decodedImage == null) return;
    setState(() { _isLoading = true; });

    for (int y = 0; y < _decodedImage!.height; y++) {
      for (int x = 0; x < _decodedImage!.width; x++) {
        img.Pixel p = _decodedImage!.getPixel(x, y);
        // Boost contrast and brightness for clear HD look
        num r = ((p.r - 128) * 1.15 + 128).clamp(0, 255);
        num g = ((p.g - 128) * 1.15 + 128).clamp(0, 255);
        num b = ((p.b - 128) * 1.15 + 128).clamp(0, 255);
        _decodedImage!.setPixelRgb(x, y, r.toInt(), g.toInt(), b.toInt());
      }
    }

    await _updateDisplayImage();
    setState(() { _isLoading = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image Enhanced to HD Clarity!')),
    );
  }

  // Apply Crop
  Future<void> _applyCrop() async {
    setState(() { _isLoading = true; });
    try {
      final bitmap = await _cropController.croppedBitmap();
      final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
      if (data != null) {
        Uint8List bytes = data.buffer.asUint8List();
        img.Image? croppedDecoded = img.decodeImage(bytes);
        if (croppedDecoded != null) {
          _decodedImage = img.copyResize(croppedDecoded, width: 600);
          await _updateDisplayImage();
        }
      }
    } catch (e) {
      print("Crop error: $e");
    }
    setState(() {
      _isLoading = false;
      _currentMode = 0;
    });
  }

  // Manual Eraser Touch Logic
  void _eraseAt(Offset localPosition, Size imageSize) async {
    if (_decodedImage == null) return;
    int x = (localPosition.dx / imageSize.width * _decodedImage!.width).toInt();
    int y = (localPosition.dy / imageSize.height * _decodedImage!.height).toInt();
    int brushSize = 15;
    bool changed = false;

    for (int dy = -brushSize; dy <= brushSize; dy++) {
      for (int dx = -brushSize; dx <= brushSize; dx++) {
        int nx = x + dx;
        int ny = y + dy;
        if (nx >= 0 && nx < _decodedImage!.width && ny >= 0 && ny < _decodedImage!.height) {
          _decodedImage!.setPixelRgba(nx, ny, 0, 0, 0, 0);
          changed = true;
        }
      }
    }
    if (changed) {
      await _updateDisplayImage();
    }
  }

  Future<void> _saveToGallery() async {
    if (_displayFile == null) return;
    try {
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();
      await Gal.putImage(_displayFile!.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo successfully saved to Gallery!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Photo & BG Editor'),
        actions: [
          if (_displayFile != null)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveToGallery,
              tooltip: 'Save to Gallery',
            ),
        ],
      ),
      body: Column(
        children: [
          // Quick AI & HD Action Bar
          if (_displayFile != null && _currentMode == 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: Colors.deepPurple.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _aiAutoRemoveBg,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('AI Auto BG Remove'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                  ElevatedButton.icon(
                    onPressed: _enhanceHD,
                    icon: const Icon(Icons.high_quality, size: 18),
                    label: const Text('HD Clear'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _displayFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                            const SizedBox(height: 10),
                            const Text('No photo selected yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.image),
                              label: const Text('Select Photo from Gallery'),
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: _currentMode == 1
                              ? CropImage(
                                  controller: _cropController,
                                  image: Image.file(_displayFile!),
                                  gridColor: Colors.deepPurple,
                                  scrimColor: Colors.black54,
                                )
                              : InteractiveViewer(
                                  panEnabled: _currentMode != 2,
                                  scaleEnabled: true,
                                  minScale: 1.0,
                                  maxScale: 5.0,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return GestureDetector(
                                        onPanUpdate: (details) {
                                          if (_currentMode == 2) {
                                            _eraseAt(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight));
                                          }
                                        },
                                        onTapDown: (details) {
                                          if (_currentMode == 2) {
                                            _eraseAt(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight));
                                          }
                                        },
                                        child: Image.file(
                                          _displayFile!,
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
            ),
          ),
          if (_displayFile != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentMode == 1) ...[
                    ElevatedButton.icon(
                      onPressed: _applyCrop,
                      icon: const Icon(Icons.check),
                      label: const Text('Apply Crop'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _currentMode = 0),
                        icon: const Icon(Icons.zoom_in),
                        label: const Text('Zoom'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentMode == 0 ? Colors.deepPurple : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _currentMode = 1),
                        icon: const Icon(Icons.crop),
                        label: const Text('Crop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentMode == 1 ? Colors.deepPurple : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _currentMode = 2),
                        icon: const Icon(Icons.brush),
                        label: const Text('Eraser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentMode == 2 ? Colors.deepPurple : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    label: const Text('Choose Another Photo', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

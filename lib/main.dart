import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'package:crop_image/crop_image.dart';

void main() {
  runApp(const ProStudioApp());
}

class ProStudioApp extends StatelessWidget {
  const ProStudioApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart BG Remover',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  File? _selectedImage;
  File? _editedImage;
  img.Image? _decodedImg;
  bool _isLoading = false;
  int _currentMode = 0; // 0 = Zoom/View, 1 = Crop, 2 = Eraser

  final ImagePicker _picker = ImagePicker();
  final CropController _cropController = CropController(aspectRatio: 1.0);

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _isLoading = true);
      File file = File(picked.path);
      Uint8List bytes = await file.readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded != null) {
        _decodedImg = img.copyResize(decoded, width: 600);
        _selectedImage = file;
        await _updateDisplay();
      }
      setState(() {
        _isLoading = false;
        _currentMode = 0;
      });
    }
  }

  Future<void> _updateDisplay() async {
    if (_decodedImg == null) return;
    final tempDir = Directory.systemTemp;
    final path = '${tempDir.path}/studio_${DateTime.now().millisecondsSinceEpoch}.png';
    File out = File(path)..writeAsBytesSync(img.encodePng(_decodedImg!));
    setState(() => _editedImage = out);
  }

  // Smart Edge-Connected Background Removal (Kapde kharab nahi honge!)
  Future<void> _smartEdgeRemoveBg() async {
    if (_decodedImg == null) return;
    setState(() => _isLoading = true);

    img.Image imgCopy = img.Image.from(_decodedImg!);
    int width = imgCopy.width;
    int height = imgCopy.height;
    int tolerance = 40;

    List<Point<int>> queue = [];
    Set<int> visited = {};
    int getIndex(int x, int y) => y * width + x;

    // Add all border pixels as background seed points
    for (int x = 0; x < width; x++) {
      queue.add(Point(x, 0));
      queue.add(Point(x, height - 1));
    }
    for (int y = 0; y < height; y++) {
      queue.add(Point(0, y));
      queue.add(Point(width - 1, y));
    }

    img.Pixel seedPixel = imgCopy.getPixel(0, 0);
    num refR = seedPixel.r;
    num refG = seedPixel.g;
    num refB = seedPixel.b;

    int head = 0;
    while (head < queue.length) {
      Point<int> p = queue[head++];
      int x = p.x;
      int y = p.y;
      int idx = getIndex(x, y);

      if (visited.contains(idx)) continue;
      visited.add(idx);

      img.Pixel px = imgCopy.getPixel(x, y);
      num r = px.r;
      num g = px.g;
      num b = px.b;

      double diff = ((r - refR).abs() + (g - refG).abs() + (b - refB).abs()) / 3;

      if (diff <= tolerance || (r > 235 && g > 235 && b > 235)) {
        imgCopy.setPixelRgba(x, y, 0, 0, 0, 0);

        if (x > 0 && !visited.contains(getIndex(x - 1, y))) queue.add(Point(x - 1, y));
        if (x < width - 1 && !visited.contains(getIndex(x + 1, y))) queue.add(Point(x + 1, y));
        if (y > 0 && !visited.contains(getIndex(x, y - 1))) queue.add(Point(x, y - 1));
        if (y < height - 1 && !visited.contains(getIndex(x, y + 1))) queue.add(Point(x, y + 1));
      }
    }

    _decodedImg = imgCopy;
    await _updateDisplay();
    setState(() => _isLoading = false);
    _showMsg('Smart Edge Background Removed Safely!');
  }

  // HD Clear Enhancer
  Future<void> _enhanceHD() async {
    if (_decodedImg == null) return;
    setState(() => _isLoading = true);

    for (int y = 0; y < _decodedImg!.height; y++) {
      for (int x = 0; x < _decodedImg!.width; x++) {
        img.Pixel p = _decodedImg!.getPixel(x, y);
        num r = ((p.r - 128) * 1.15 + 128).clamp(0, 255);
        num g = ((p.g - 128) * 1.15 + 128).clamp(0, 255);
        num b = ((p.b - 128) * 1.15 + 128).clamp(0, 255);
        _decodedImg!.setPixelRgb(x, y, r.toInt(), g.toInt(), b.toInt());
      }
    }
    await _updateDisplay();
    setState(() => _isLoading = false);
    _showMsg('Image Enhanced to HD!');
  }

  // Apply Crop
  Future<void> _applyCrop() async {
    setState(() => _isLoading = true);
    try {
      final bitmap = await _cropController.croppedBitmap();
      final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
      if (data != null) {
        Uint8List bytes = data.buffer.asUint8List();
        img.Image? croppedDecoded = img.decodeImage(bytes);
        if (croppedDecoded != null) {
          _decodedImg = img.copyResize(croppedDecoded, width: 600);
          await _updateDisplay();
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
    if (_decodedImg == null) return;
    int x = (localPosition.dx / imageSize.width * _decodedImg!.width).toInt();
    int y = (localPosition.dy / imageSize.height * _decodedImg!.height).toInt();
    int brushSize = 15;
    bool changed = false;

    for (int dy = -brushSize; dy <= brushSize; dy++) {
      for (int dx = -brushSize; dx <= brushSize; dx++) {
        int nx = x + dx;
        int ny = y + dy;
        if (nx >= 0 && nx < _decodedImg!.width && ny >= 0 && ny < _decodedImg!.height) {
          _decodedImg!.setPixelRgba(nx, ny, 0, 0, 0, 0);
          changed = true;
        }
      }
    }
    if (changed) {
      await _updateDisplay();
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveGallery() async {
    if (_editedImage == null) return;
    try {
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putImage(_editedImage!.path);
      _showMsg('Saved to Gallery successfully!');
    } catch (e) {
      _showMsg('Error saving: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Photo & BG Remover'),
        actions: [
          if (_editedImage != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveGallery,
              tooltip: 'Save to Gallery',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _editedImage == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library, size: 90, color: Colors.deepPurple),
                      const SizedBox(height: 16),
                      const Text('Select Photo for Smart Removal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Open Gallery Photo'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_currentMode == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: Colors.deepPurple.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _smartEdgeRemoveBg,
                              icon: const Icon(Icons.auto_fix_high, size: 18),
                              label: const Text('Smart Edge BG Remove'),
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
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        color: Colors.grey[300],
                        child: _currentMode == 1
                            ? CropImage(
                                controller: _cropController,
                                image: Image.file(_editedImage!),
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
                                      child: Image.file(_editedImage!, fit: BoxFit.contain),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
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
                ),
    );
  }
}

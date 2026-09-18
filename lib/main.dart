import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pro Background Remover',
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
  File? _processedImageFile;
  bool _isLoading = false;
  double _tolerance = 40.0; // Background removal sensitivity slider
  Color _bgPreviewColor = Colors.transparent;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _processedImageFile = null;
      });
      _processImage(_imageFile!);
    }
  }

  Future<void> _processImage(File image) async {
    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List bytes = await image.readAsBytes();
      img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        img.Pixel refPixel = decodedImage.getPixel(0, 0);
        num refR = refPixel.r;
        num refG = refPixel.g;
        num refB = refPixel.b;

        for (int y = 0; y < decodedImage.height; y++) {
          for (int x = 0; x < decodedImage.width; x++) {
            img.Pixel pixel = decodedImage.getPixel(x, y);
            num r = pixel.r;
            num g = pixel.g;
            num b = pixel.b;

            double diff = ((r - refR).abs() + (g - refG).abs() + (b - refB).abs()) / 3;
            bool isLight = (r > (255 - _tolerance) && g > (255 - _tolerance) && b > (255 - _tolerance));
            bool matchesRef = diff < _tolerance;

            if (isLight || matchesRef) {
              decodedImage.setPixelRgba(x, y, 0, 0, 0, 0);
            }
          }
        }

        final tempDir = Directory.systemTemp;
        final targetPath = '${tempDir.path}/pro_bg_${DateTime.now().millisecondsSinceEpoch}.png';
        File outputFile = File(targetPath)..writeAsBytesSync(img.encodePng(decodedImage));

        setState(() {
          _processedImageFile = outputFile;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error: $e");
    }
  }

  Future<void> _saveToGallery() async {
    if (_processedImageFile == null) return;
    try {
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImage(_processedImageFile!.path);
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
        title: const Text('Pro Background Remover'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_imageFile != null) ...[
              const Text('Original Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Image.file(_imageFile!, height: 150),
              const SizedBox(height: 20),
            ],
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_processedImageFile != null) ...[
              const Text('Processed Result:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: _bgPreviewColor,
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(
                  child: Image.file(_processedImageFile!),
                ),
              ),
              const SizedBox(height: 12),
              // Background Color Changer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('BG Color: '),
                  IconButton(
                    icon: const Icon(Icons.crop_din, color: Colors.grey),
                    onPressed: () => setState(() => _bgPreviewColor = Colors.transparent),
                    tooltip: 'Transparent',
                  ),
                  IconButton(
                    icon: const Icon(Icons.circle, color: Colors.white),
                    onPressed: () => setState(() => _bgPreviewColor = Colors.white),
                    tooltip: 'White',
                  ),
                  IconButton(
                    icon: const Icon(Icons.circle, color: Colors.black),
                    onPressed: () => setState(() => _bgPreviewColor = Colors.black),
                    tooltip: 'Black',
                  ),
                  IconButton(
                    icon: const Icon(Icons.circle, color: Colors.red),
                    onPressed: () => setState(() => _bgPreviewColor = Colors.red),
                    tooltip: 'Red',
                  ),
                  IconButton(
                    icon: const Icon(Icons.circle, color: Colors.blue),
                    onPressed: () => setState(() => _bgPreviewColor = Colors.blue),
                    tooltip: 'Blue',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Sensitivity Slider
              Row(
                children: [
                  const Text('Sensitivity: '),
                  Expanded(
                    child: Slider(
                      value: _tolerance,
                      min: 10,
                      max: 100,
                      divisions: 18,
                      label: _tolerance.round().toString(),
                      onChanged: (val) {
                        setState(() {
                          _tolerance = val;
                        });
                        if (_imageFile != null) {
                          _processImage(_imageFile!);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Save Button
              ElevatedButton.icon(
                onPressed: _saveToGallery,
                icon: const Icon(Icons.save),
                label: const Text('Save to Phone Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Select Photo from Gallery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

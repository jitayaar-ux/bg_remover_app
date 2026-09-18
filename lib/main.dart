import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Free BG Remover',
      theme: ThemeData(primarySwatch: Colors.blue),
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

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _processedImageFile = null;
      });
      _removeBackground(_imageFile!);
    }
  }

  Future<void> _removeBackground(File image) async {
    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List bytes = await image.readAsBytes();
      img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        // Loop through pixels and make light/white background transparent
        for (int y = 0; y < decodedImage.height; y++) {
          for (int x = 0; x < decodedImage.width; x++) {
            img.Pixel pixel = decodedImage.getPixel(x, y);
            int red = pixel.r.toInt();
            int green = pixel.g.toInt();
            int blue = pixel.b.toInt();

            // Jekar background white ya light hove taan usnu transparent kar do
            if (red > 240 && green > 240 && blue > 240) {
              decodedImage.setPixelRgba(x, y, 0, 0, 0, 0);
            }
          }
        }

        final tempDir = Directory.systemTemp;
        final targetPath = '${tempDir.path}/removed_bg_${DateTime.now().millisecondsSinceEpoch}.png';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Background Remover (No Ads)'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageFile != null) ...[
                const Text('Original Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Image.file(_imageFile!, height: 150),
                const SizedBox(height: 20),
              ],
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_processedImageFile != null) ...[
                const Text('Background Removed (Transparent):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  color: Colors.grey[300],
                  child: Image.file(_processedImageFile!, height: 150),
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
      ),
    );
  }
}

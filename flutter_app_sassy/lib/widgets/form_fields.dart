import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:sassy/services/api_service.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class FormTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int? maxLength;
  final Function(String)? onChanged;

  const FormTextField({
    Key? key,
    required this.label,
    required this.placeholder,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class FormPasswordField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController? controller;
  final bool showPassword;
  final Function()? onToggleVisibility;

  const FormPasswordField({
    Key? key,
    required this.label,
    required this.placeholder,
    this.controller,
    required this.showPassword,
    this.onToggleVisibility,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: !showPassword,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            suffixIcon: IconButton(
              icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggleVisibility,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class FormDateField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController? controller;

  const FormDateField({
    Key? key,
    required this.label,
    required this.placeholder,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 10,
          decoration: InputDecoration(
            hintText: placeholder,
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
            String formatted = '';
            for (int i = 0; i < clean.length && i < 8; i++) {
              formatted += clean[i];
              if ((i == 1 || i == 3) && i != clean.length - 1) {
                formatted += '/';
              }
            }
            controller?.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          },
        ),
      ],
    );
  }
}

class FormImagePicker extends StatefulWidget {
  final String label;
  final Function(String) onImagePathSelected; // Callback with the server path
  final String? initialImagePath; // Initial image path from server if editing
  final bool cropToSquare; // Parameter pre nastavenie cropovania
  
  const FormImagePicker({
    Key? key,
    required this.label,
    required this.onImagePathSelected,
    this.initialImagePath,
    this.cropToSquare = true, // Štandardne zapnuté cropovanie do štvorca
  }) : super(key: key);

  @override
  State<FormImagePicker> createState() => _FormImagePickerState();
}

class _FormImagePickerState extends State<FormImagePicker> {
  final ApiService _apiService = ApiService();
  File? _selectedImage;
  String? _serverImagePath;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _serverImagePath = widget.initialImagePath;
  }
  
  // Funkcia na výber obrázka zo súborov
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        
        // Ak je zapnuté cropovanie do štvorca
        if (widget.cropToSquare) {
          setState(() => _isLoading = true);
          File? croppedFile;
          
          try {
            if (Platform.isAndroid || Platform.isIOS) {
              croppedFile = await _cropWithImageCropper(file);
            } else {
              croppedFile = await _showInteractiveCropper(file);
            }
          } catch (e) {
            print('Error during cropping: $e');
            // Fallback ak cropovanie zlyhá, použijeme originálny súbor
            croppedFile = file;
          }
          
          setState(() => _isLoading = false);
          
          if (croppedFile != null) {
            _processSelectedImage(croppedFile);
          }
        } else {
          // Bez cropovania
          _processSelectedImage(file);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba pri výbere súboru: $e')),
        );
      }
    }
  }
  
  // Použitie image_cropper pre Android/iOS
  Future<File?> _cropWithImageCropper(File imageFile) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Pomer 1:1 pre štvorec
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Orezať obrázok',
            toolbarColor: const Color(0xFFF67E4A),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Orezať obrázok',
            doneButtonTitle: 'Hotovo',
            cancelButtonTitle: 'Zrušiť',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      
      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    } catch (e) {
      print('Error with image_cropper: $e');
    }
    
    return null;
  }
  
  // Zobrazenie interaktívneho croppera pre desktop
  Future<File?> _showInteractiveCropper(File imageFile) async {
    CropResult? result = await showDialog<CropResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveCropper(
          imageFile: imageFile,
          aspectRatio: 1.0, // Štvorcový pomer
          primaryColor: const Color(0xFFF67E4A),
        ),
      ),
    );
    
    if (result != null && result.croppedFile != null) {
      return result.croppedFile;
    }
    
    return null;
  }
  
  // Spracovanie vybraného obrázka
  Future<void> _processSelectedImage(File image) async {
    setState(() {
      _selectedImage = image;
      _isLoading = true;
    });
    
    try {
      // Nahranie obrázka na server a získanie cesty
      final imagePath = await _apiService.uploadImage(image);
      
      if (imagePath != null) {
        setState(() {
          _serverImagePath = imagePath;
          _isLoading = false;
        });
        
        // Zavoláme callback s cestou k obrázku
        widget.onImagePathSelected(imagePath);
      } else {
        // Chyba pri nahrávaní
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nepodarilo sa nahrať obrázok')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Zobrazenie vybraného obrázka alebo prázdneho kontajnera
        // Ak je cropToSquare, používame AspectRatio pre zobrazenie štvorca
        AspectRatio(
          aspectRatio: widget.cropToSquare ? 1.0 : 16/9, // 1:1 pre štvorec, inak 16:9
          child: GestureDetector(
            onTap: _isLoading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildImagePreview(),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Tlačidlo pre výber obrázka
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _pickImage,
          icon: const Icon(Icons.file_upload),
          label: Text(_serverImagePath == null ? 'Vybrať súbor' : 'Zmeniť súbor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF67E4A),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Metóda na zobrazenie náhľadu obrázka
  Widget _buildImagePreview() {
    // Ak máme lokálne vybraný obrázok, zobrazíme ho
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    
    // Ak máme cestu k obrázku na serveri, zobrazíme ho
    if (_serverImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: NetworkImageFromBytes(
          imagePath: _serverImagePath!,
          apiService: _apiService,
        ),
      );
    }
    
    // Prázdny stav
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.crop_square, size: 50, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            widget.cropToSquare ? 'Kliknite pre výber a orezanie obrázka' : 'Kliknutím vyberte súbor',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class NetworkImageFromBytes extends StatefulWidget {
  final String imagePath;
  final ApiService apiService;
  
  const NetworkImageFromBytes({
    Key? key,
    required this.imagePath,
    required this.apiService,
  }) : super(key: key);

  @override
  State<NetworkImageFromBytes> createState() => _NetworkImageFromBytesState();
}

class _NetworkImageFromBytesState extends State<NetworkImageFromBytes> {
  late Future<Uint8List?> _imageFuture;
  
  @override
  void initState() {
    super.initState();
    _imageFuture = widget.apiService.getImageBytes(widget.imagePath);
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data != null) {
          return Image(image: MemoryImage(snapshot.data!));
        } else {
          return const Center(child: Text('No image available'));
        }
      },
    );
  }
}

class CropResult {
  final File? croppedFile;

  CropResult({this.croppedFile});
}

// Interaktívny orezávač obrázkov
class InteractiveCropper extends StatefulWidget {
  final File imageFile;
  final double aspectRatio;
  final Color primaryColor;

  const InteractiveCropper({
    Key? key,
    required this.imageFile,
    required this.aspectRatio,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<InteractiveCropper> createState() => _InteractiveCropperState();
}

class _InteractiveCropperState extends State<InteractiveCropper> {
  Rect _cropRect = Rect.zero;
  Size _imageSize = Size.zero;
  late ui.Image _uiImage;
  bool _isImageLoaded = false;
  bool _isDragging = false;
  Offset _lastPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final image = await decodeImageFromList(bytes);

      setState(() {
        _uiImage = image;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _initializeCropRect();
        _isImageLoaded = true;
      });
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  void _initializeCropRect() {
    final minSide = math.min(_imageSize.width, _imageSize.height);
    final left = (_imageSize.width - minSide) / 2;
    final top = (_imageSize.height - minSide) / 2;

    _cropRect = Rect.fromLTWH(left, top, minSide, minSide);
  }

  void _moveCropRect(Offset delta) {
    setState(() {
      final newLeft = _cropRect.left + delta.dx;
      final newTop = _cropRect.top + delta.dy;

      if (newLeft >= 0 && newLeft + _cropRect.width <= _imageSize.width &&
          newTop >= 0 && newTop + _cropRect.height <= _imageSize.height) {
        _cropRect = Rect.fromLTWH(
          newLeft,
          newTop,
          _cropRect.width,
          _cropRect.height,
        );
      }
    });
  }

  // Orezanie obrázka podľa aktuálneho výrezu
  Future<File?> _cropImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return null;

      final scaleX = originalImage.width / _imageSize.width;
      final scaleY = originalImage.height / _imageSize.height;

      final int cropX = (_cropRect.left * scaleX).toInt();
      final int cropY = (_cropRect.top * scaleY).toInt();
      final int cropWidth = (_cropRect.width * scaleX).toInt();
      final int cropHeight = (_cropRect.height * scaleY).toInt();

      final safeX = math.max(0, math.min(cropX, originalImage.width - 1));
      final safeY = math.max(0, math.min(cropY, originalImage.height - 1));
      final safeWidth = math.max(1, math.min(cropWidth, originalImage.width - safeX));
      final safeHeight = math.max(1, math.min(cropHeight, originalImage.height - safeY));

      final croppedImage = img.copyCrop(
        originalImage,
        x: safeX,
        y: safeY,
        width: safeWidth,
        height: safeHeight,
      );

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final croppedFile = File(tempPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

      return croppedFile;
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 800,
        maxHeight: 600,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Orezať obrázok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
          ),

          Flexible(
            child: _isImageLoaded
              ? Stack(
                  children: [
                    Center(
                      child: FittedBox(
                        child: SizedBox(
                          width: _imageSize.width,
                          height: _imageSize.height,
                          child: Stack(
                            children: [
                              RawImage(
                                image: _uiImage,
                                fit: BoxFit.contain,
                              ),
                              CustomPaint(
                                size: _imageSize,
                                painter: CropOverlayPainter(
                                  cropRect: _cropRect,
                                  color: widget.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned.fill(
                      child: GestureDetector(
                        onPanStart: (details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final Offset localPosition = box.globalToLocal(details.globalPosition);

                          final imageRect = _getImageRect();
                          if (imageRect == null) return;

                          final imageX = (localPosition.dx - imageRect.left) / imageRect.width * _imageSize.width;
                          final imageY = (localPosition.dy - imageRect.top) / imageRect.height * _imageSize.height;

                          if (_cropRect.contains(Offset(imageX, imageY))) {
                            setState(() {
                              _isDragging = true;
                              _lastPosition = localPosition;
                            });
                          }
                        },
                        onPanUpdate: (details) {
                          if (!_isDragging) return;

                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final Offset localPosition = box.globalToLocal(details.globalPosition);

                          final imageRect = _getImageRect();
                          if (imageRect == null) return;

                          final dx = (localPosition.dx - _lastPosition.dx) / imageRect.width * _imageSize.width;
                          final dy = (localPosition.dy - _lastPosition.dy) / imageRect.height * _imageSize.height;

                          _moveCropRect(Offset(dx, dy));
                          _lastPosition = localPosition;
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _isDragging = false;
                          });
                        },
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Zrušiť'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isImageLoaded
                    ? () async {
                        final croppedFile = await _cropImage();
                        Navigator.of(context).pop(CropResult(croppedFile: croppedFile));
                      }
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Potvrdiť'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Rect? _getImageRect() {
    try {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final size = box.size;

      final imageAspect = _imageSize.width / _imageSize.height;
      final screenAspect = size.width / size.height;

      double renderWidth, renderHeight;
      double offsetX = 0, offsetY = 0;

      if (imageAspect > screenAspect) {
        renderWidth = size.width;
        renderHeight = renderWidth / imageAspect;
        offsetY = (size.height - renderHeight) / 2;
      } else {
        renderHeight = size.height;
        renderWidth = renderHeight * imageAspect;
        offsetX = (size.width - renderWidth) / 2;
      }

      return Rect.fromLTWH(offsetX, offsetY, renderWidth, renderHeight);
    } catch (e) {
      return null;
    }
  }
}

// Vlastný painter pre overlay
class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Color color;

  CropOverlayPainter({
    required this.cropRect,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(cropRect, borderPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final stepY = cropRect.height / 3;
    for (int i = 1; i < 3; i++) {
      final y = cropRect.top + stepY * i;
      canvas.drawLine(
        Offset(cropRect.left, y),
        Offset(cropRect.right, y),
        gridPaint,
      );
    }

    final stepX = cropRect.width / 3;
    for (int i = 1; i < 3; i++) {
      final x = cropRect.left + stepX * i;
      canvas.drawLine(
        Offset(x, cropRect.top),
        Offset(x, cropRect.bottom),
        gridPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(CropOverlayPainter oldDelegate) => 
    cropRect != oldDelegate.cropRect || color != oldDelegate.color;
}
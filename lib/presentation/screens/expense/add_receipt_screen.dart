import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/services/receipt_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';

class AddReceiptScreen extends StatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  final ReceiptService _receiptService = ReceiptService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _receiptService.dispose();
    super.dispose();
  }

  Future<void> _handlePasteText() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Receipt Text'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Paste message from SMS/WhatsApp here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                if (_receiptService.isValidReceipt(controller.text)) {
                  final data = _receiptService.processText(controller.text);
                  Navigator.pop(context);
                  context.push('/receipt-preview', extra: data);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This doesn\'t look like a valid receipt. Please check and try again.')),
                  );
                }
              }
            },
            child: const Text('Extract'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _processImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image. Please try again.')),
        );
      }
    }
  }

  Future<void> _handleCapture() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        _processImage(File(image.path));
      }
    } else {
      _showPermissionDenied('Camera');
    }
  }

  Future<void> _handleQRCode() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  Navigator.pop(context);
                  // Basic QR logic: if it's text, parse it. If it's a URL, maybe error or something.
                  if (code.startsWith('http')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Valid receipt data not found in this QR code.')),
                    );
                  } else {
                    final data = _receiptService.processText(code);
                    context.push('/receipt-preview', extra: data);
                  }
                }
              }
            },
          ),
        ),
      );
    } else {
      _showPermissionDenied('Camera');
    }
  }

  Future<void> _processImage(File file) async {
    setState(() => _isLoading = true);
    try {
      final data = await _receiptService.processImage(file);
      if (mounted) {
        context.push('/receipt-preview', extra: data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process receipt image. Please recapture clearly.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPermissionDenied(String permission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$permission permission is required to use this feature.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Receipt'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : AnimationLimiter(
            child: GridView.count(
              padding: const EdgeInsets.all(24),
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _buildOptionCard(
                    'Paste Text',
                    Icons.paste_rounded,
                    Colors.blue,
                    _handlePasteText,
                  ),
                  _buildOptionCard(
                    'Gallery',
                    Icons.photo_library_rounded,
                    Colors.green,
                    _handleGallery,
                  ),
                  _buildOptionCard(
                    'QR Code',
                    Icons.qr_code_scanner_rounded,
                    Colors.orange,
                    _handleQRCode,
                  ),
                  _buildOptionCard(
                    'Capture',
                    Icons.camera_alt_rounded,
                    Colors.red,
                    _handleCapture,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildOptionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

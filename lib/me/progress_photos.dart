import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProgressPhotosPage extends StatefulWidget {
  const ProgressPhotosPage({super.key});

  @override
  State<ProgressPhotosPage> createState() => _ProgressPhotosPageState();
}

class _ProgressPhotosPageState extends State<ProgressPhotosPage> {
  final Color _headerColor = const Color(0xFF2E7D6F);
  final Color _iconColor = const Color(0xFF67B0A3);

  final List<Map<String, dynamic>> _photos = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _photos.insert(0, {
            'file': File(picked.path),
            'date': DateTime.now(),
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking photo: $e")),
        );
      }
    }
  }

  void _showAddPhotoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Progress Photo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: _headerColor),
                ),
                title: const Text("Take Photo with Camera"),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library, color: _headerColor),
                ),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewSinglePhoto(File file, DateTime date) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.file(file, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy - hh:mm a').format(date),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSideBySideComparison() {
    if (_photos.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You need at least 2 photos for side-by-side comparison.")),
      );
      return;
    }

    final before = _photos.last;
    final after = _photos.first;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Side-by-Side Comparison",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Before", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: Image.file(before['file'] as File, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat('MMM d, yyyy').format(before['date'] as DateTime), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Text("Current", style: TextStyle(fontWeight: FontWeight.bold, color: _headerColor)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: Image.file(after['file'] as File, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat('MMM d, yyyy').format(after['date'] as DateTime), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _headerColor),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Progress Photos",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_photos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_a_photo, color: Colors.white),
              onPressed: _showAddPhotoSheet,
            ),
        ],
      ),
      body: _photos.isEmpty ? _buildEmptyState() : _buildPhotosList(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 140,
                  color: _iconColor.withValues(alpha: 0.3),
                ),
                Icon(Icons.add_a_photo_outlined, size: 80, color: _iconColor),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Track Your Visual Journey",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "See your progress firsthand. Upload photos to visually track changes, celebrate milestones, and stay motivated on your path to achieving your goals.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _showAddPhotoSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: _headerColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                "Add Your First Photo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  "View Single Photo",
                  onPressed: null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  "Side-by-Side Comparison",
                  onPressed: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Unlock comparison features once you've added photos",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildPhotosList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  "View Latest Photo",
                  onPressed: () => _viewSinglePhoto(
                    _photos.first['file'] as File,
                    _photos.first['date'] as DateTime,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  "Side-by-Side Comparison",
                  onPressed: _photos.length >= 2 ? _showSideBySideComparison : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Your Photo Logs (${_photos.length})",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final item = _photos[index];
              final File file = item['file'] as File;
              final DateTime date = item['date'] as DateTime;

              return InkWell(
                onTap: () => _viewSinglePhoto(file, date),
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(file, fit: BoxFit.cover),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(date),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _photos.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(String text, {VoidCallback? onPressed}) {
    final bool isEnabled = onPressed != null;
    return SizedBox(
      height: 45,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isEnabled ? const Color(0xFF42A5F5) : const Color(0xFF90CAF9).withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isEnabled ? const Color(0xFF42A5F5) : Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

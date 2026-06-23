
class ImagePickerScreen extends StatefulWidget {
  final List<File>? initialImages;
  final Function(List<File>)? onImagesSelected;
  final int maxImages;

  const ImagePickerScreen({
    super.key,
    this.initialImages,
    this.onImagesSelected,
    this.maxImages = 5,
  });

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  List<File> _selectedImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialImages != null) {
      _selectedImages = List.from(widget.initialImages!);
    }
  }

  Future<void> _pickImageFromCamera() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final File? image = await _imagePickerService.pickImageFromCamera();
      if (image != null) {
        if (_selectedImages.length < widget.maxImages) {
          setState(() {
            _selectedImages.add(image);
          });
        } else {
          _showMaxImagesReachedDialog();
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image from camera: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final File? image = await _imagePickerService.pickImageFromGallery();
      if (image != null) {
        if (_selectedImages.length < widget.maxImages) {
          setState(() {
            _selectedImages.add(image);
          });
        } else {
          _showMaxImagesReachedDialog();
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image from gallery: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<File> images = await _imagePickerService.pickMultipleImages();
      final int remainingSlots = widget.maxImages - _selectedImages.length;
      final int imagesToAdd = images.length > remainingSlots ? remainingSlots : images.length;
      
      if (imagesToAdd > 0) {
        setState(() {
          _selectedImages.addAll(images.take(imagesToAdd));
        });
      }
      
      if (images.length > remainingSlots) {
        _showMaxImagesReachedDialog();
      }
    } catch (e) {
      _showErrorDialog('Failed to pick multiple images: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final File item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }

  void _showMaxImagesReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.exclamationTriangle,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Maximum Images Reached',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You can only select up to ${widget.maxImages} images.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassLiquidTheme.accentBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.exclamationCircle,
                color: Colors.red,
                size: 48,

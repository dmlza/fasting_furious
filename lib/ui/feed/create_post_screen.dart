import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import "../../config/theme.dart";
import "../../providers/auth_provider.dart";
import "../../providers/habit_provider.dart";
import "../../services/supabase_service.dart";

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _controller = TextEditingController();
  String _selectedType = 'general';
  bool _loading = false;
  bool _shareFasting = false;
  bool _shareSmoking = false;
  bool _shareSugar = false;
  bool _shareExercise = false;
  File? _selectedImage;
  bool _uploadingImage = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1080, imageQuality: 80);
      if (picked != null && mounted) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        String message = 'Failed to pick image.';
        if (e.toString().contains('camera') || e.toString().contains('Camera')) {
          message = 'Camera access denied. Please check permissions in Settings.';
        } else if (e.toString().contains('photo') || e.toString().contains('gallery') || e.toString().contains('library')) {
          message = 'Photo library access denied. Please check permissions in Settings.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;
    if (!mounted) return null;
    setState(() => _uploadingImage = true);
    try {
      final ext = _selectedImage!.path.split('.').last;
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await ref.read(supabaseServiceProvider).client.storage
          .from('post-images')
          .upload(path, _selectedImage!);
      final url = ref.read(supabaseServiceProvider).client.storage
          .from('post-images')
          .getPublicUrl(path);
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image. Please try again.')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  String _buildContent() {
    final parts = <String>[];
    if (_shareFasting) parts.add('Currently fasting');
    if (_shareSmoking) parts.add('Smoke-free streak alive');
    if (_shareSugar) parts.add('Sugar-free streak alive');
    if (_shareExercise) parts.add('Crushing today\'s workout');
    final typed = _controller.text.trim();
    if (typed.isNotEmpty) parts.add(typed);
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final habitState = ref.watch(habitProvider);
    final habits = habitState.habits;
    final smokingStreak = habitState.getStreak('no_smoking');
    final sugarStreak = habitState.getStreak('no_sugar');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: user == null || _loading
                  ? null
                  : () async {
                      final content = _buildContent();
                      if (content.trim().isEmpty && _selectedImage == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Select a stat, add a message, or attach a photo')),
                          );
                        }
                        return;
                      }
                      setState(() => _loading = true);
                      try {
                        String? imageUrl;
                        if (_selectedImage != null) {
                          imageUrl = await _uploadImage(user.id);
                          if (_selectedImage != null && imageUrl == null) {
                            if (mounted) setState(() => _loading = false);
                            return;
                          }
                        }
                        await ref.read(supabaseServiceProvider).createPost(
                          user.id,
                          type: _selectedType,
                          content: content.trim().isNotEmpty ? content.trim() : null,
                          imageUrl: imageUrl,
                        );
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Posted!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _loading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to post. Please try again.')),
                          );
                        }
                      }
                    },
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Share Your Stats', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (habits.exerciseMinutes > 0 || habits.exercise)
                _StatChip(
                  emoji: '\u{1F3C3}',
                  label: '${habitState.habits.exerciseMinutes}min exercise',
                  isSelected: _shareExercise,
                  color: AppColors.green,
                  onTap: () => setState(() => _shareExercise = !_shareExercise),
                ),
              if (smokingStreak > 0)
                _StatChip(
                  emoji: '\u{1F6AB}',
                  label: '$smokingStreak day${smokingStreak != 1 ? 's' : ''} smoke-free',
                  isSelected: _shareSmoking,
                  color: AppColors.green,
                  onTap: () => setState(() => _shareSmoking = !_shareSmoking),
                ),
              if (sugarStreak > 0)
                _StatChip(
                  emoji: '\u{1F525}',
                  label: '$sugarStreak day${sugarStreak != 1 ? 's' : ''} sugar-free',
                  isSelected: _shareSugar,
                  color: AppColors.purple,
                  onTap: () => setState(() => _shareSugar = !_shareSugar),
                ),
              _StatChip(
                emoji: '\u{1F37D}\u{FE0F}',
                label: 'Fasting',
                isSelected: _shareFasting,
                color: AppColors.purple,
                onTap: () => setState(() => _shareFasting = !_shareFasting),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Post Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _TypeChip(label: 'General', emoji: '\u{1F4AC}', isSelected: _selectedType == 'general', onTap: () => setState(() => _selectedType = 'general')),
              _TypeChip(label: 'Fasting', emoji: '\u{1F37D}\u{FE0F}', isSelected: _selectedType == 'fasting', onTap: () => setState(() => _selectedType = 'fasting')),
              _TypeChip(label: 'Exercise', emoji: '\u{1F3C3}', isSelected: _selectedType == 'exercise', onTap: () => setState(() => _selectedType = 'exercise')),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(hintText: "What's on your mind?"),
          ),
          const SizedBox(height: 16),
          if (_selectedImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                if (_uploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    ),
                  ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ImagePickerButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImagePickerButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          if (user == null)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Not logged in', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : Theme.of(context).textTheme.bodySmall?.color,
            )),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.purple : Theme.of(context).dividerColor,
          ),
        ),
        child: Text('$emoji $label', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? AppColors.purple : null)),
      ),
    );
  }
}

class _ImagePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }
}

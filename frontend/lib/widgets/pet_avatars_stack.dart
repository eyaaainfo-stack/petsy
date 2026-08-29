import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// ============================================================================
// PetAvatarsStack
// ============================================================================
// 🔵 ZID: 3ammamneha (List<String?> photoUrls bark, mch List<BookedPet>)
// bch tetsta3ml m3a AY model (BookedPet, SchedulePet, PetSummary, ...) -
// mch marbouta b'model wa7ed.
// ============================================================================
class PetAvatarsStack extends StatelessWidget {
  final List<String?> photoUrls;
  final double avatarSize;
  final int maxVisible;

  const PetAvatarsStack({
    super.key,
    required this.photoUrls,
    required this.avatarSize,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    // 🔵 el border tel avatar ne5od loun el "background" tel écran
    // (mch abyadh fixe) - bch el "fasl" bin el avatars ye5dem sa7i7 fi
    // dark mode zeda (mch ghir light mode).
    final Color borderColor = Theme.of(context).scaffoldBackgroundColor;

    if (photoUrls.isEmpty) {
      return _avatarCircle(photoUrl: null, size: avatarSize, borderColor: borderColor);
    }

    final visiblePhotos = photoUrls.take(maxVisible).toList();
    final int overflowCount = photoUrls.length - visiblePhotos.length;
    final double overlap = avatarSize * 0.6;
    final int totalCircles = visiblePhotos.length + (overflowCount > 0 ? 1 : 0);

    return SizedBox(
      width: avatarSize + overlap * (totalCircles - 1),
      height: avatarSize,
      child: Stack(
        children: [
          for (int i = 0; i < visiblePhotos.length; i++)
            Positioned(
              left: overlap * i,
              child: _avatarCircle(photoUrl: visiblePhotos[i], size: avatarSize, borderColor: borderColor),
            ),
          if (overflowCount > 0)
            Positioned(
              left: overlap * visiblePhotos.length,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.pinkpetsy, border: Border.all(color: borderColor, width: 2)),
                alignment: Alignment.center,
                child: Text('+$overflowCount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: avatarSize * 0.32)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatarCircle({required String? photoUrl, required double size, required Color borderColor}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.vertpetsy.withOpacity(0.25),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: photoUrl != null
          ? Image.network(photoUrl, fit: BoxFit.cover)
          : Icon(Icons.pets, color: AppColors.vertpetsy, size: size * 0.55),
    );
  }
}
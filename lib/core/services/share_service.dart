// lib/core/services/share_service.dart
import 'package:share_plus/share_plus.dart';
import '../utils/helpers.dart';

class ShareService {
  static Future<void> shareVideo({
    required String videoId,
    required String title,
  }) async {
    final url = 'https://pitchup.app/video?id=$videoId';
    final text = Helpers.generateShareText(title: title, url: url);

    await Share.share(
      text,
      subject: 'PitchUp\'ta "$title" videosunu keşfet!',
    );
  }

  static Future<void> shareApp() async {
    const text =
        'PitchUp uygulamasını indirin ve girişimcilerle yatırımcıları buluşturun!\n\nhttps://pitchup.app';
    await Share.share(text,
        subject: 'PitchUp - Yatırımcı ve Girişimci Platformu');
  }

  static Future<void> shareOffer({
    required String offerId,
    required double amount,
  }) async {
    final text =
        'PitchUp\'ta ${amount.toStringAsFixed(0)}₺ tutarında yatırım teklifi!\n\nhttps://pitchup.app/offer?id=$offerId';
    await Share.share(text, subject: 'Yatırım Teklifi - PitchUp');
  }

  static Future<void> shareProfile({
    required String userId,
    required String name,
  }) async {
    final text =
        'PitchUp\'ta $name\'in profilini keşfedin!\n\nhttps://pitchup.app/profile?id=$userId';
    await Share.share(text, subject: '$name - PitchUp Profili');
  }
}
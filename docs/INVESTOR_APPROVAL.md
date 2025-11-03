# Yatırımcı Onaylama Süreci

## Genel Bakış

PitchUp uygulamasında iki tip kullanıcı rolü bulunmaktadır:
- **Entrepreneur (Girişimci)**: Video yükler, teklifleri alır
- **Investor (Yatırımcı)**: Videoları izler, teklif gönderir

Yatırımcılar manuel onay sürecinden geçmek zorundadır. Sadece onaylı yatırımcılar girişimcilere teklif gönderebilir.

## Kullanıcı Veri Yapısı

```dart
class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;          // investor veya entrepreneur
  final bool isApproved;         // Onay durumu
  final String? profilePicture;
  final String? bio;
  final CompanyInfo? company;    // Yatırımcı/Girişimci şirket bilgileri
  ...
}
```

## Mevcut Onaylama Yöntemi (Manuel)

### 1. Firebase Console Üzerinden

1. **Firebase Console** → **Firestore Database** → **users** collection
2. Onay bekleyen yatırımcıyı bulun
3. İlgili kullanıcı dokümanına tıklayın
4. `isApproved` field'ını `false` → `true` olarak değiştirin
5. Kaydedin

### 2. Onay Filtresi Kullanımı

Sistem şu anda teklif gönderme yetkisini kontrol ediyor:

```dart
// lib/presentation/screens/main/discover/video_detail_screen.dart:406
bool _canMakeOffer() {
  final user = auth.currentUser;

  return user != null &&
      user.role == UserRole.investor &&
      user.isApproved &&              // ← Onay kontrolü
      user.id != _video?.userId;
}
```

## Önerilen İyileştirmeler

### A) Admin Panel (Önerilen)

Gelecekte eklenebilecek özellikler:

1. **Bekleyen Yatırımcılar Listesi**
   ```
   Admin Panel → Pending Investors
   - Kullanıcı bilgileri
   - Şirket detayları
   - Yatırım geçmişi
   - Approve / Reject butonları
   ```

2. **Email Bildirimleri**
   - Başvuru alındı bildirimi
   - Onaylandı bildirimi
   - Reddedildi bildirimi

### B) Otomatik Onay Kriterleri

Belirli kriterleri karşılayan yatırımcılar için otomatik onay:
- LinkedIn profili doğrulaması
- Minimum yatırım tutarı gösterimi
- Referans kontrolleri

### C) Katmanlı Onay Sistemi

```
Level 1: Görüntüleme (Otomatik)
  - Videoları izleyebilir
  - Profilleri görüntüleyebilir

Level 2: İletişim (Manuel Onay)
  - Teklif gönderebilir
  - Mesajlaşabilir

Level 3: Premium (Ödeme)
  - Sınırsız teklif
  - Özel istatistikler
  - Öncelikli destek
```

## Firestore Queries

### Onaysız Yatırımcıları Listeleme

```dart
final pendingInvestors = await FirebaseFirestore.instance
  .collection('users')
  .where('role', isEqualTo: 'investor')
  .where('isApproved', isEqualTo: false)
  .orderBy('createdAt', descending: true)
  .get();
```

### Yatırımcı Onaylama

```dart
Future<void> approveInvestor(String userId) async {
  await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
      'isApproved': true,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': currentAdminId,
    });

  // Send approval email
  await sendApprovalEmail(userId);
}
```

### Yatırımcı Reddetme

```dart
Future<void> rejectInvestor(String userId, String reason) async {
  await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
      'isApproved': false,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });

  // Send rejection email
  await sendRejectionEmail(userId, reason);
}
```

## Best Practices

1. **KYC (Know Your Customer)**
   - Kimlik doğrulama
   - Şirket dokümanları
   - Banka hesabı bilgileri

2. **İzleme ve Analitik**
   - Onay süreleri
   - Red sebepleri
   - Yatırımcı aktiviteleri

3. **Güvenlik**
   - Firestore Security Rules ile onaylı yatırımcı kontrolü
   - Rate limiting
   - Spam koruması

4. **İletişim**
   - Net onay kriterleri
   - Bekleme süresi bildirimi
   - Red durumunda açıklama

## Firestore Security Rules Örneği

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Sadece onaylı yatırımcılar teklif gönderebilir
    match /offers/{offerId} {
      allow create: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'investor'
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isApproved == true;
    }

    // Sadece admin kullanıcıları onaylayabilir
    match /users/{userId} {
      allow update: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isApproved', 'approvedAt', 'approvedBy']);
    }
  }
}
```

## Sonraki Adımlar

1. ✅ Manuel onay sistemi (Mevcut)
2. ⏳ Admin panel oluşturma
3. ⏳ Email bildirim sistemi
4. ⏳ Otomatik onay kriterleri
5. ⏳ KYC entegrasyonu

## Yardım ve Destek

Sorularınız için:
- Firebase Console: https://console.firebase.google.com
- Firestore Dokümantasyonu: https://firebase.google.com/docs/firestore

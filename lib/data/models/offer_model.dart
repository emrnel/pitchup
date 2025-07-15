import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferStatus { pending, accepted, rejected }

class OfferModel {
  final String id;
  final String videoId;
  final String entrepreneurId;
  final String investorId;
  final double amount;
  final double equityPercentage;
  final String? note;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OfferModel({
    required this.id,
    required this.videoId,
    required this.entrepreneurId,
    required this.investorId,
    required this.amount,
    required this.equityPercentage,
    this.note,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferModel(
      id: doc.id,
      videoId: data['videoId'] ?? '',
      entrepreneurId: data['entrepreneurId'] ?? '',
      investorId: data['investorId'] ?? '',
      amount: data['amount']?.toDouble() ?? 0.0,
      equityPercentage: data['equityPercentage']?.toDouble() ?? 0.0,
      note: data['note'],
      status: _parseOfferStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'videoId': videoId,
      'entrepreneurId': entrepreneurId,
      'investorId': investorId,
      'amount': amount,
      'equityPercentage': equityPercentage,
      'note': note,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static OfferStatus _parseOfferStatus(String? status) {
    switch (status) {
      case 'accepted':
        return OfferStatus.accepted;
      case 'rejected':
        return OfferStatus.rejected;
      default:
        return OfferStatus.pending;
    }
  }

  OfferModel copyWith({
    String? id,
    String? videoId,
    String? entrepreneurId,
    String? investorId,
    double? amount,
    double? equityPercentage,
    String? note,
    OfferStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfferModel(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      entrepreneurId: entrepreneurId ?? this.entrepreneurId,
      investorId: investorId ?? this.investorId,
      amount: amount ?? this.amount,
      equityPercentage: equityPercentage ?? this.equityPercentage,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

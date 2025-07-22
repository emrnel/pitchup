// lib/data/models/video_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum VideoStatus { pending, approved, rejected }

class VideoModel {
  final String id;
  final String userId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String title;
  final String description;
  final String sector;
  final int duration;
  final int viewCount;
  final int likeCount;
  final int offerCount;
  final VideoStatus status;
  final VideoMetadata metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VideoModel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.title,
    required this.description,
    required this.sector,
    required this.duration,
    required this.viewCount,
    required this.likeCount,
    required this.offerCount,
    required this.status,
    required this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      sector: data['sector'] ?? '',
      duration: data['duration'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      offerCount: data['offerCount'] ?? 0,
      status: _parseVideoStatus(data['status']),
      metadata: VideoMetadata.fromMap(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'sector': sector,
      'duration': duration,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'offerCount': offerCount,
      'status': status.toString().split('.').last,
      'metadata': metadata.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static VideoStatus _parseVideoStatus(String? status) {
    switch (status) {
      case 'approved':
        return VideoStatus.approved;
      case 'rejected':
        return VideoStatus.rejected;
      default:
        return VideoStatus.pending;
    }
  }

  VideoModel copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? thumbnailUrl,
    String? title,
    String? description,
    String? sector,
    int? duration,
    int? viewCount,
    int? likeCount,
    int? offerCount,
    VideoStatus? status,
    VideoMetadata? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      sector: sector ?? this.sector,
      duration: duration ?? this.duration,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      offerCount: offerCount ?? this.offerCount,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VideoMetadata {
  final double? requestedAmount;
  final double? equityOffered;
  final int? teamSize;
  final double? monthlyRevenue;

  VideoMetadata({
    this.requestedAmount,
    this.equityOffered,
    this.teamSize,
    this.monthlyRevenue,
  });

  factory VideoMetadata.fromMap(Map<String, dynamic> map) {
    return VideoMetadata(
      requestedAmount: map['requestedAmount']?.toDouble(),
      equityOffered: map['equityOffered']?.toDouble(),
      teamSize: map['teamSize'],
      monthlyRevenue: map['monthlyRevenue']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestedAmount': requestedAmount,
      'equityOffered': equityOffered,
      'teamSize': teamSize,
      'monthlyRevenue': monthlyRevenue,
    };
  }
}
import 'package:flutter/material.dart';

// Mall Model - Tambahkan ke file lib/models/models.dart
class Mall {
  final String id;
  final String name;
  final String address;
  final String description;
  final String city;
  final String phone;
  final String operatingHours;
  final String? imageUrl;
  final bool isActive;

  Mall({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    this.city = 'Surabaya',
    required this.phone,
    this.operatingHours = '10:00 - 22:00',
    this.imageUrl,
    this.isActive = true,
  });

  factory Mall.fromJson(Map<String, dynamic> json) {
    return Mall(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? 'Surabaya',
      phone: json['phone'] ?? '',
      operatingHours: json['operating_hours'] ?? '10:00 - 22:00',
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'city': city,
      'phone': phone,
      'operating_hours': operatingHours,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}

// Spot Model
class Spot {
  final String id;
  final String name;
  final String description;
  final double pricePerHour;
  final bool isAvailable;
  final String? mallId;

  Spot({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerHour,
    required this.isAvailable,
    this.mallId,
  });

  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pricePerHour: (json['price_per_hour'] ?? 0.0).toDouble(),
      isAvailable: json['is_available'] ?? true,
      mallId: json['mall_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price_per_hour': pricePerHour,
      'is_available': isAvailable,
      'mall_id': mallId,
    };
  }
}

// Booking Model
class Booking {
  final String id;
  final String userId;
  final String spotId;
  final String spotName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final BookingStatus status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.spotId,
    required this.spotName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      spotId: json['spot_id'].toString(),
      spotName: json['spots']?['name'] ?? 'Unknown Spot',
      date: DateTime.parse(json['date']),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'spot_id': spotId,
      'date': date.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'status': status.name,
    };
  }

  bool canCheckIn() {
    final now = DateTime.now();
    final bookingDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );

    // Can check in 15 minutes before start time
    final checkInTime = bookingDateTime.subtract(const Duration(minutes: 15));

    return status == BookingStatus.pending &&
        now.isAfter(checkInTime) &&
        now.isBefore(bookingDateTime.add(const Duration(hours: 1)));
  }

  bool canCheckOut() {
    return status == BookingStatus.checkedIn;
  }

  bool canCancel() {
    final now = DateTime.now();
    final bookingDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );

    return status == BookingStatus.pending && now.isBefore(bookingDateTime);
  }
}

enum BookingStatus { pending, checkedIn, checkedOut, cancelled }

extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.checkedIn:
        return 'Checked In';
      case BookingStatus.checkedOut:
        return 'Checked Out';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.checkedIn:
        return Colors.blue;
      case BookingStatus.checkedOut:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.pending;
      case BookingStatus.checkedIn:
        return Icons.login;
      case BookingStatus.checkedOut:
        return Icons.logout;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }
}

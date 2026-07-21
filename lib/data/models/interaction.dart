import 'package:flutter/foundation.dart';

import '../../core/network/json_helpers.dart';
import 'enums.dart';

@immutable
class FarmerInteraction {
  const FarmerInteraction({
    required this.id,
    required this.executiveId,
    required this.farmerName,
    required this.phoneNumber,
    required this.landLocation,
    required this.acres,
    required this.currentCrop,
    required this.plannedMonths,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String executiveId;
  final String farmerName;
  final String phoneNumber;
  final String landLocation;
  final double acres;
  final String currentCrop;
  final int plannedMonths;
  final InteractionStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FarmerInteraction.fromJson(Map<String, dynamic> json) {
    return FarmerInteraction(
      id: json['id']?.toString() ?? '',
      executiveId: json['executive_id']?.toString() ?? '',
      farmerName: json['farmer_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      landLocation: json['land_location'] as String? ?? '',
      acres: (json['acres'] as num?)?.toDouble() ?? 0,
      currentCrop: json['current_crop'] as String? ?? '',
      plannedMonths: json['planned_months'] as int? ?? 0,
      status: parseInteractionStatus(json['status'] as String? ?? ''),
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

@immutable
class CreateInteractionRequest {
  const CreateInteractionRequest({
    required this.farmerName,
    required this.phoneNumber,
    required this.landLocation,
    required this.acres,
    required this.currentCrop,
    required this.plannedMonths,
    required this.status,
    this.notes,
  });

  final String farmerName;
  final String phoneNumber;
  final String landLocation;
  final double acres;
  final String currentCrop;
  final int plannedMonths;
  final InteractionStatus status;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'farmer_name': farmerName,
        'phone_number': phoneNumber,
        'land_location': landLocation,
        'acres': acres,
        'current_crop': currentCrop,
        'planned_months': plannedMonths,
        'status': interactionStatusToApi(status),
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

@immutable
class UpdateInteractionRequest {
  const UpdateInteractionRequest({
    this.farmerName,
    this.phoneNumber,
    this.landLocation,
    this.acres,
    this.currentCrop,
    this.plannedMonths,
    this.status,
    this.notes,
  });

  final String? farmerName;
  final String? phoneNumber;
  final String? landLocation;
  final double? acres;
  final String? currentCrop;
  final int? plannedMonths;
  final InteractionStatus? status;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      if (farmerName != null) 'farmer_name': farmerName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (landLocation != null) 'land_location': landLocation,
      if (acres != null) 'acres': acres,
      if (currentCrop != null) 'current_crop': currentCrop,
      if (plannedMonths != null) 'planned_months': plannedMonths,
      if (status != null) 'status': interactionStatusToApi(status!),
      if (notes != null) 'notes': notes,
    };
  }
}

import 'package:equatable/equatable.dart';

/// 用药记录
class MedicationRecord extends Equatable {
  final String id;
  final DateTime recordedAt;
  final String medicationName;
  final double? dosageMg;
  final String? note;

  const MedicationRecord({
    required this.id,
    required this.recordedAt,
    this.medicationName = '左旋多巴',
    this.dosageMg,
    this.note,
  });

  @override
  List<Object?> get props =>
      [id, recordedAt, medicationName, dosageMg, note];
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 0;

  @override
  Medicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medicine(
      id: fields[0] as String,
      name: fields[1] as String,
      dosage: fields[2] as String,
      type: fields[3] as String,
      interval: fields[4] as int,
      startTime: fields[5] as DateTime,
      imagePath: fields[6] as String?,
      takenHistory: (fields[7] as List).cast<DateTime>(),
      timeSlots: fields[8] == null ? [] : (fields[8] as List).cast<String>(),
      instruction: fields[9] as String?,
      endDate: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dosage)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.interval)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(8)
      ..write(obj.timeSlots)
      ..writeByte(9)
      ..write(obj.instruction)
      ..writeByte(10)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.takenHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchaseHistoryModelAdapter extends TypeAdapter<PurchaseHistoryModel> {
  @override
  final int typeId = 4;

  @override
  PurchaseHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseHistoryModel(
      finalPrice: fields[0] as double,
      currency: fields[1] as String,
      purchaseTime: fields[2] as DateTime,
      items: (fields[3] as List).cast<CartItemModel>(),
      userEmail: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseHistoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.finalPrice)
      ..writeByte(1)
      ..write(obj.currency)
      ..writeByte(2)
      ..write(obj.purchaseTime)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.userEmail);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

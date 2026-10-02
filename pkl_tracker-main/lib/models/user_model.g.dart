// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// Manual TypeAdapter (adjusted to current UserModel fields)
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as int?,
      uid: fields[1] as String,
      nama: fields[2] as String,
      email: fields[3] as String,
      password: fields[4] as String,
      role: fields[5] as String,
      noInduk: fields[6] as String?,
      sekolah: fields[7] as String?,
      jurusan: fields[8] as String?,
      alamat: fields[9] as String?,
      photoUrl: fields[10] as String?,
      phone: fields[11] as String?,
      guruUid: fields[12] as String?,
      pklPlaceName: fields[13] as String?,
      pklPlaceAddress: fields[14] as String?,
      pklLatitude: (fields[15] as num?)?.toDouble(),
      pklLongitude: (fields[16] as num?)?.toDouble(),
      createdAt: fields[17] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.uid)
      ..writeByte(2)
      ..write(obj.nama)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.password)
      ..writeByte(5)
      ..write(obj.role)
      ..writeByte(6)
      ..write(obj.noInduk)
      ..writeByte(7)
      ..write(obj.sekolah)
      ..writeByte(8)
      ..write(obj.jurusan)
      ..writeByte(9)
      ..write(obj.alamat)
      ..writeByte(10)
      ..write(obj.photoUrl)
      ..writeByte(11)
      ..write(obj.phone)
      ..writeByte(12)
      ..write(obj.guruUid)
      ..writeByte(13)
      ..write(obj.pklPlaceName)
      ..writeByte(14)
      ..write(obj.pklPlaceAddress)
      ..writeByte(15)
      ..write(obj.pklLatitude)
      ..writeByte(16)
      ..write(obj.pklLongitude)
      ..writeByte(17)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

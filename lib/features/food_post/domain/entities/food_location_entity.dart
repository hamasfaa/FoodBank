import 'package:equatable/equatable.dart';

class FoodLocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String address;

  const FoodLocationEntity({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

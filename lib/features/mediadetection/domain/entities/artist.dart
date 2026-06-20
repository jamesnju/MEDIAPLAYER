import 'package:equatable/equatable.dart';

class Artist extends Equatable {
  final String id;
  final String name;
  final int albumCount;
  final int trackCount;
  final String? image;

  const Artist({
    required this.id,
    required this.name,
    this.albumCount = 0,
    this.trackCount = 0,
    this.image,
  });

  Artist copyWith({
    String? id,
    String? name,
    int? albumCount,
    int? trackCount,
    String? image,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      albumCount: albumCount ?? this.albumCount,
      trackCount: trackCount ?? this.trackCount,
      image: image ?? this.image,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        albumCount,
        trackCount,
        image,
      ];
}
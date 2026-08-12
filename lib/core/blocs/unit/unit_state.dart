// // ignore_for_file: public_member_api_docs, sort_constructors_first
// part of 'unit_bloc.dart';

// abstract class UnitState extends Equatable {
//   const UnitState();

//   @override
//   List<Object> get props => [];
// }

// class UnitInitial extends UnitState {}

// class UnitLoadingState extends UnitState {}

// class UnitLoadedState extends UnitState {
//   final List<UnitTire> units;
//   // List<UnitTire>? totalActualUnits;
//   final List<Map<String, dynamic>> reccPress;
//   final int countAllTire;
//   final Map<String, dynamic> allTireSize;
//   UnitLoadedState({
//     required this.units,
//     // this.totalActualUnits,
//     required this.reccPress,
//     required this.countAllTire,
//     required this.allTireSize,
//   });
// }

// class UnitErrorState extends UnitState {
//   final String message;

//   UnitErrorState({required this.message});
// }

// class UnitTiresErrorState extends UnitState {}

part of 'unit_bloc.dart';

abstract class UnitState extends Equatable {
  const UnitState();

  @override
  List<Object?> get props => [];
}

class UnitInitial extends UnitState {}

class UnitLoadingState extends UnitState {}

class UnitLoadedState extends UnitState {
  final String idSite;
  final String requestSource;
  final List<UnitTire> units;
  final List<Map<String, dynamic>> reccPress;
  final int countAllTire;
  final Map<String, dynamic> allTireSize;
  final bool loadedFromApi;

  /// Key adalah nama area.
  /// Value adalah target area.
  ///
  /// Contoh:
  /// {
  ///   'Central': 6,
  ///   'North West': 6,
  /// }
  final Map<String, int> targetArea;

  const UnitLoadedState({
    required this.idSite,
    required this.requestSource,
    required this.units,
    required this.reccPress,
    required this.countAllTire,
    required this.allTireSize,
    this.targetArea = const <String, int>{},
    this.loadedFromApi = false,
  });

  /// Daftar nama area untuk dropdown/filter.
  List<String> get areaNames {
    final List<String> result = targetArea.keys.toList();

    result.sort(
      (String a, String b) {
        return a.toLowerCase().compareTo(
              b.toLowerCase(),
            );
      },
    );

    return result;
  }

  /// Daftar pilihan area beserta opsi All.
  List<String> get areaOptions {
    return <String>[
      'All',
      ...areaNames,
    ];
  }

  @override
  List<Object?> get props => [
        idSite,
        requestSource,
        units,
        reccPress,
        countAllTire,
        allTireSize,
        targetArea,
        loadedFromApi,
      ];
}

class UnitErrorState extends UnitState {
  final String message;

  const UnitErrorState({
    required this.message,
  });

  @override
  List<Object?> get props => [
        message,
      ];
}

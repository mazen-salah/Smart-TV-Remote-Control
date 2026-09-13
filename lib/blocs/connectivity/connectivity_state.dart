import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

class ConnectivityStateView extends Equatable {
  const ConnectivityStateView(this.results);
  const ConnectivityStateView.unknown() : results = const [];

  final List<ConnectivityResult> results;

  bool get hasNetwork => results.any((r) => r != ConnectivityResult.none);

  bool get hasLan =>
      results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet);

  @override
  List<Object?> get props => [results];
}

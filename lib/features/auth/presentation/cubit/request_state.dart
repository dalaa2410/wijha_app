import 'package:equatable/equatable.dart';

enum RequestStatus { initial, loading, success, failure }

class RequestState extends Equatable {
  final RequestStatus status;
  final String? message;
  const RequestState({this.status = RequestStatus.initial, this.message});

  @override
  List<Object?> get props => [status, message];
}
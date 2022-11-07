part of 'printers_cubit.dart';

class PrintersState extends Equatable {
  final RequestState requestState;
  final RequestState printState;
  final String message;
  final List<PrinterDevice> printers;

  const PrintersState({
    required this.requestState,
    required this.printState,
    required this.message,
    required this.printers,
  });

  factory PrintersState.init() {
    return const PrintersState(
      requestState: RequestState.none,
      printState: RequestState.none,
      message: '',
      printers: [],
    );
  }

  PrintersState copyWith({
    RequestState? requestState,
    RequestState? printState,
    String? message,
    List<PrinterDevice>? printers,
  }) {
    return PrintersState(
      requestState: requestState ?? this.requestState,
      printState: printState ?? this.printState,
      message: message ?? this.message,
      printers: printers ?? this.printers,
    );
  }

  @override
  List<Object> get props => [
        requestState,
        printState,
        message,
        printers,
      ];
}

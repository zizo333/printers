import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
// import 'package:image/image.dart';

part 'printers_state.dart';

enum RequestState { loading, loaded, error, none }

class PrintersCubit extends Cubit<PrintersState> {
  PrintersCubit() : super(PrintersState.init());

  StreamSubscription<PrinterDevice>? _subscription;
  final PrinterManager _printerManager = PrinterManager.instance;

  getPrinters() async {
    emit(state.copyWith(requestState: RequestState.loading));
    try {
      List<PrinterDevice> printers = [];
      _subscription = _printerManager
          .discovery(type: PrinterType.network, isBle: false)
          .listen((device) {
        printers.add(device);
      })
        ..onDone(() {
          emit(state.copyWith(
            requestState: RequestState.loaded,
            printers: printers,
          ));
        })
        ..onError((error) {
          emit(state.copyWith(
            requestState: RequestState.error,
            message: error.toString(),
          ));
        });
    } catch (error) {
      emit(
        state.copyWith(
          requestState: RequestState.error,
          message: 'check the internet connection',
        ),
      );
    }
  }

  Future<void> startPrinting(String ipAddress) async {
    print(ipAddress);
    emit(
      state.copyWith(
        printState: RequestState.loading,
      ),
    );
    try {
      await _printerManager.connect(
        type: PrinterType.network,
        model: TcpPrinterInput(
          ipAddress: ipAddress,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 200));
      await _printerManager.disconnect(type: PrinterType.network);
      emit(
        state.copyWith(printState: RequestState.loaded, message: 'success'),
      );
    } catch (error) {
      emit(
        state.copyWith(
          printState: RequestState.error,
          message: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

// import 'dart:async';
// import 'package:equatable/equatable.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
// // import 'package:image/image.dart';

// part 'printers_state.dart';

// enum RequestState { loading, loaded, error, none }

// class PrintersCubit extends Cubit<PrintersState> {
//   PrintersCubit() : super(PrintersState.init());

//   StreamSubscription<PrinterDevice>? _subscription;
//   final PrinterManager _printerManager = PrinterManager.instance;

//   getPrinters() async {
//     emit(state.copyWith(requestState: RequestState.loading));
//     try {
//       List<PrinterDevice> printers = [];
//       _subscription = _printerManager
//           .discovery(type: PrinterType.network, isBle: false)
//           .listen((device) {
//         printers.add(device);
//       })
//         ..onDone(() {
//           emit(state.copyWith(
//             requestState: RequestState.loaded,
//             printers: printers,
//           ));
//         })
//         ..onError((error) {
//           emit(state.copyWith(
//             requestState: RequestState.error,
//             message: error.toString(),
//           ));
//         });
//     } catch (error) {
//       emit(
//         state.copyWith(
//           requestState: RequestState.error,
//           message: 'check the internet connection',
//         ),
//       );
//     }
//   }

//   Future<void> startPrinting(String ipAddress) async {
//     print(ipAddress);
//     emit(
//       state.copyWith(
//         printState: RequestState.loading,
//       ),
//     );
//     try {
//       await _printerManager.connect(
//         type: PrinterType.network,
//         model: TcpPrinterInput(
//           ipAddress: ipAddress,
//         ),
//       );
//       await Future.delayed(const Duration(milliseconds: 200));
//       await _printerManager.disconnect(type: PrinterType.network);
//       emit(
//         state.copyWith(printState: RequestState.loaded, message: 'success'),
//       );
//     } catch (error) {
//       emit(
//         state.copyWith(
//           printState: RequestState.error,
//           message: error.toString(),
//         ),
//       );
//     }
//   }

//   @override
//   Future<void> close() {
//     _subscription?.cancel();
//     return super.close();
//   }
// }

import 'package:equatable/equatable.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';

part 'printers_state.dart';

enum RequestState { loading, loaded, error, none }

class PrintersCubit extends Cubit<PrintersState> {
  PrintersCubit() : super(PrintersState.init());

  final int _port = 9100;

  getPrinters() async {
    emit(state.copyWith(requestState: RequestState.loading));
    try {
      List<String> printers = [];
      final localIp = await NetworkInfo().getWifiIP();
      debugPrint('local ip: $localIp');
      if (localIp != null) {
        final String subnet = localIp.substring(0, localIp.lastIndexOf('.'));
        debugPrint(subnet);
        final stream = NetworkAnalyzer.discover2(subnet, _port);
        stream.listen((NetworkAddress address) {
          if (address.exists) {
            debugPrint('Found device: ${address.ip}');
            printers.add(address.ip);
          }
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
      }
    } catch (error) {
      emit(
        state.copyWith(
          requestState: RequestState.error,
          message: 'check the internet connection',
        ),
      );
    }
  }

  void startPrinting(String printerIp) async {
    emit(state.copyWith(printState: RequestState.loading));
    try {
      const PaperSize paper = PaperSize.mm80;
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(paper, profile);

      final PosPrintResult res = await printer.connect(printerIp, port: _port);

      if (res == PosPrintResult.success) {
        await testReceipt(printer);
        printer.disconnect();
        emit(state.copyWith(
            printState: RequestState.loaded, message: 'printed successfully'));
      } else {
        emit(
          state.copyWith(
            printState: RequestState.error,
            message: 'connection error',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          printState: RequestState.error,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> testReceipt(NetworkPrinter printer) async {
    try {
      printer.text('Welcome to my app');
      printer.feed(2);
      printer.cut();
    } catch (_) {
      throw Exception();
    }
  }
}

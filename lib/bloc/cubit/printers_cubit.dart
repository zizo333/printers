import 'dart:typed_data';

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
      debugPrint(localIp);
      if (localIp != null) {
        final String subnet = localIp.substring(0, localIp.lastIndexOf('.'));
        debugPrint(subnet);
        int port = _port;
        final stream = NetworkAnalyzer.discover2(subnet, port);
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

  void print(String printerIp) async {
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
      printer.text(
          'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
      printer.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
          styles: const PosStyles(codeTable: 'CP1252'));
      printer.text('Special 2: blåbærgrød',
          styles: const PosStyles(codeTable: 'CP1252'));

      printer.text('Bold text', styles: const PosStyles(bold: true));
      printer.text('Reverse text', styles: const PosStyles(reverse: true));
      printer.text('Underlined text',
          styles: const PosStyles(underline: true), linesAfter: 1);
      printer.text('Align left', styles: const PosStyles(align: PosAlign.left));
      printer.text('Align center',
          styles: const PosStyles(align: PosAlign.center));
      printer.text('Align right',
          styles: const PosStyles(align: PosAlign.right), linesAfter: 1);

      printer.row([
        PosColumn(
          text: 'col3',
          width: 3,
          styles: const PosStyles(align: PosAlign.center, underline: true),
        ),
        PosColumn(
          text: 'col6',
          width: 6,
          styles: const PosStyles(align: PosAlign.center, underline: true),
        ),
        PosColumn(
          text: 'col3',
          width: 3,
          styles: const PosStyles(align: PosAlign.center, underline: true),
        ),
      ]);

      printer.text('Text size 200%',
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ));

      // Print image
      final ByteData data = await rootBundle.load('assets/logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final image = decodeImage(bytes);
      if (image != null) {
        printer.image(image);
      }

      // Print barcode
      final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
      printer.barcode(Barcode.upcA(barData));

      printer.feed(2);
      printer.cut();
    } catch (_) {
      throw Exception();
    }
  }
}

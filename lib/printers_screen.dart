import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learning/bloc/cubit/printers_cubit.dart';

class PrintersScreen extends StatelessWidget {
  const PrintersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printers'),
      ),
      body: BlocProvider<PrintersCubit>(
        create: (context) => PrintersCubit()..getPrinters(),
        child: const PrintersBody(),
      ),
    );
  }
}

class PrintersBody extends StatelessWidget {
  const PrintersBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrintersCubit, PrintersState>(
      listener: (context, state) {
        if (state.requestState == RequestState.error ||
            state.printState == RequestState.error ||
            state.printState == RequestState.loaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.requestState == RequestState.error) {
          return Center(
            child: Text(state.message),
          );
        } else if (state.requestState == RequestState.loaded) {
          return state.printers.isEmpty
              ? const Center(
                  child: Text('There are No Printers'),
                )
              : Stack(
                  children: [
                    ListView.separated(
                      itemBuilder: ((context, index) {
                        return ListTile(
                          onTap: () {
                            // context
                            //     .read<PrintersCubit>()
                            //     .startPrinting(state.printers[index].address!);
                          },
                          title: Text(
                            state.printers[index],
                          ),
                        );
                      }),
                      separatorBuilder: ((context, index) {
                        return const SizedBox(height: 12);
                      }),
                      itemCount: state.printers.length,
                    ),
                    if (state.printState == RequestState.loading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                  ],
                );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

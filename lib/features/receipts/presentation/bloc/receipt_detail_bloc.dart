import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/receipt_details.dart';
import '../../domain/usecases/get_receipt_details_usecase.dart';

part 'receipt_detail_event.dart';
part 'receipt_detail_state.dart';

class ReceiptDetailBloc extends Bloc<ReceiptDetailEvent, ReceiptDetailState> {
  final GetReceiptDetailsUseCase getReceiptDetailsUseCase;

  /// What the expiration badges count from; injectable for tests.
  final DateTime Function() today;

  /// Identifies the latest request; older answers are dropped.
  int _request = 0;

  ReceiptDetailBloc({
    required this.getReceiptDetailsUseCase,
    DateTime Function()? today,
  }) : today = today ?? DateTime.now,
       super(const ReceiptDetailState()) {
    on<ReceiptDetailRequested>(_onRequested);
    on<ReceiptDetailRetried>(_onRetried);
  }

  Future<void> _onRequested(
    ReceiptDetailRequested event,
    Emitter<ReceiptDetailState> emit,
  ) async {
    // The page dispatches on every rebuild; the same receipt isn't a reload.
    if (event.receiptId == state.receiptId) return;
    await _load(emit, event.receiptId);
  }

  Future<void> _onRetried(
    ReceiptDetailRetried event,
    Emitter<ReceiptDetailState> emit,
  ) async {
    final receiptId = state.receiptId;
    if (receiptId != null) await _load(emit, receiptId);
  }

  Future<void> _load(Emitter<ReceiptDetailState> emit, String receiptId) async {
    final request = ++_request;
    emit(ReceiptDetailState(receiptId: receiptId));

    final result = await getReceiptDetailsUseCase(receiptId);
    if (emit.isDone || request != _request) return;
    emit(
      result.match(
        (failure) => ReceiptDetailState(
          receiptId: receiptId,
          // The backend answers 400 for an unknown or malformed id.
          status: failure is ValidationFailure
              ? ReceiptDetailStatus.notFound
              : ReceiptDetailStatus.failure,
          errorMessage: failure.message,
        ),
        (receipt) => ReceiptDetailState(
          receiptId: receiptId,
          status: ReceiptDetailStatus.loaded,
          receipt: receipt,
        ),
      ),
    );
  }
}

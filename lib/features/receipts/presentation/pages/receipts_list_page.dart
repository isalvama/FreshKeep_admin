import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/creators/creator_filter_chip.dart';
import '../../../../shared/metrics/domain/entities/selected_range.dart';
import '../../../../shared/metrics/presentation/section_state.dart';
import '../../../../shared/metrics/presentation/widgets/range_bar.dart';
import '../../../../shared/widgets/pagination_bar.dart';
import '../../domain/entities/receipts_page.dart';
import '../bloc/receipts_list_bloc.dart';
import '../receipts_list_location.dart';
import '../receipts_list_query.dart';
import '../widgets/receipts_table.dart';

const kNoReceiptsInRangeMessage = 'No receipts purchased in this range';
const kNoReceiptsOnPageMessage = 'No receipts on this page';
const kUnconfirmedReceiptsNote = 'Includes unconfirmed receipts';

/// The receipts list. The URL is the source of truth for the range, creator
/// and page: this page reads [query], tells the bloc, and writes changes back.
class ReceiptsListPage extends StatefulWidget {
  final Map<String, String> query;

  /// Remembers this list's URL for "← Back to receipts".
  final ReceiptsListLocation location;

  const ReceiptsListPage({
    super.key,
    required this.query,
    required this.location,
  });

  @override
  State<ReceiptsListPage> createState() => _ReceiptsListPageState();
}

class _ReceiptsListPageState extends State<ReceiptsListPage> {
  @override
  void initState() {
    super.initState();
    _syncFromUrl();
  }

  @override
  void didUpdateWidget(ReceiptsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromUrl();
  }

  void _syncFromUrl() {
    final bloc = context.read<ReceiptsListBloc>();
    final query = parseReceiptsListQuery(widget.query, bloc.today());
    if (!mapEquals(receiptsListQueryParameters(query), widget.query)) {
      // Invalid or missing values: replace (not push) with the URL that keeps
      // everything valid, so the bad URL leaves no history entry. The
      // corrected URL comes back through didUpdateWidget.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replace(receiptsListLocation(query));
      });
      return;
    }
    widget.location.remember(receiptsListLocation(query));
    bloc.add(ReceiptsListRequested(query));
  }

  void _go(ReceiptsListQuery query) => context.go(receiptsListLocation(query));

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReceiptsListBloc>();

    return BlocBuilder<ReceiptsListBloc, ReceiptsListState>(
      builder: (context, state) {
        final creatorId = state.query.creatorId;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RangeBar(
                maxLengthInDays: kReceiptsMaxRangeLengthInDays,
                label: 'Purchased between',
                range: state.query.range,
                resolvedRange: state.resolvedRange,
                today: bloc.today(),
                // A new range starts again from the first page.
                onRangeChanged: (SelectedRange range) =>
                    _go(state.query.withRange(range)),
                onRefresh: () => bloc.add(const ReceiptsListRetried()),
              ),
              if (creatorId != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CreatorFilterChip(
                    creatorId: creatorId,
                    label: state.creatorLabel,
                    onDeleted: () => _go(state.query.withCreator(null)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        kUnconfirmedReceiptsNote,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _body(context, state),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, ReceiptsListState state) {
    final receipts = state.receipts;
    switch (receipts.status) {
      case SectionStatus.loading:
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      case SectionStatus.failure:
        return _Message(
          icon: Icons.error_outline,
          isError: true,
          message: receipts.errorMessage ?? 'Something went wrong.',
          action: OutlinedButton.icon(
            onPressed: () => context.read<ReceiptsListBloc>().add(
              const ReceiptsListRetried(),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
      case SectionStatus.loaded:
        return _loaded(context, state.query, receipts.data!);
    }
  }

  Widget _loaded(
    BuildContext context,
    ReceiptsListQuery query,
    ReceiptsPage page,
  ) {
    if (page.receipts.isEmpty) {
      if (query.page == 1) {
        return const _Message(
          icon: Icons.receipt_long_outlined,
          message: kNoReceiptsInRangeMessage,
        );
      }
      // Past the last page: the backend reports no total here, so offer a
      // way back rather than "of N".
      return _Message(
        icon: Icons.find_in_page_outlined,
        message: kNoReceiptsOnPageMessage,
        action: TextButton(
          onPressed: () => _go(query.withPage(1)),
          child: const Text('Go to first page'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReceiptsTable(
          receipts: page.receipts,
          onReceiptSelected: (receipt) =>
              context.go('$kReceiptsPath/${Uri.encodeComponent(receipt.id)}'),
        ),
        const SizedBox(height: 8),
        PaginationBar(
          page: page.page,
          firstIndex: page.firstIndex,
          lastIndex: page.lastIndex,
          total: page.totalElements,
          hasPrevious: page.hasPrevious,
          hasNext: page.hasNext,
          onPageChanged: (number) => _go(query.withPage(number)),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  final bool isError;

  const _Message({
    required this.icon,
    required this.message,
    this.action,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isError ? colors.error : colors.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

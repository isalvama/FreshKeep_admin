import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../products/domain/entities/product_filters.dart';
import '../../../products/presentation/products_list_query.dart';
import '../../../../shared/metrics/domain/entities/daily_count.dart';
import '../../../../shared/metrics/domain/entities/selected_range.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../../../../shared/metrics/presentation/range_query.dart';
import '../../../../shared/metrics/presentation/section_state.dart';
import '../../../../shared/metrics/presentation/format.dart';
import '../../../../shared/metrics/presentation/widgets/chart_card.dart';
import '../../../../shared/metrics/presentation/widgets/counts_table.dart';
import '../../../../shared/metrics/presentation/widgets/daily_column_chart.dart';
import '../../../../shared/metrics/presentation/widgets/range_bar.dart';
import '../widgets/product_type_bar_chart.dart';
import '../../../../shared/metrics/presentation/widgets/stat_tile.dart';

const kDashboardPath = '/dashboard';

/// From this width the four chart cards sit in a 2 × 2 grid.
const _twoColumnWidth = 1100.0;

/// The URL is the source of truth for the range: this page reads [query],
/// tells the bloc, and writes range changes back to the URL.
class DashboardPage extends StatefulWidget {
  final Map<String, String> query;

  const DashboardPage({super.key, required this.query});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _syncRangeFromUrl();
  }

  @override
  void didUpdateWidget(DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRangeFromUrl();
  }

  void _syncRangeFromUrl() {
    final bloc = context.read<DashboardBloc>();
    final range = parseRangeQuery(
      widget.query,
      bloc.today(),
      maxLengthInDays: kMetricsMaxRangeLengthInDays,
    );
    if (range == null) {
      // Missing or invalid: replace (not push) so the bad URL leaves no
      // history entry. The corrected URL comes back through didUpdateWidget.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replace(_location(kDefaultSelectedRange));
      });
      return;
    }
    bloc.add(DashboardRangeChanged(range));
  }

  static String _location(SelectedRange range) =>
      Uri(path: kDashboardPath, queryParameters: rangeQuery(range)).toString();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DashboardBloc>();

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RangeBar(
                maxLengthInDays: kMetricsMaxRangeLengthInDays,
                range: state.range,
                resolvedRange: state.resolvedRange,
                today: bloc.today(),
                onRangeChanged: (range) => context.go(_location(range)),
                onRefresh: () => bloc.add(const DashboardRefreshed()),
              ),
              const SizedBox(height: 24),
              _StatTiles(state: state),
              const SizedBox(height: 16),
              _ChartGrid(
                cards: [
                  _dailyCard(
                    state,
                    DashboardSection.registrations,
                    title: 'New users per day',
                    emptyMessage: 'No new users in this range',
                  ),
                  _dailyCard(
                    state,
                    DashboardSection.products,
                    title: 'Products added per day',
                    subtitle: 'Includes deleted products',
                    emptyMessage: 'No products added in this range',
                  ),
                  _dailyCard(
                    state,
                    DashboardSection.receipts,
                    title: 'Receipts per purchase date',
                    subtitle: 'Includes unconfirmed receipts',
                    emptyMessage: 'No receipts in this range',
                  ),
                  _productTypesCard(state),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dailyCard(
    DashboardState state,
    DashboardSection section, {
    required String title,
    String? subtitle,
    required String emptyMessage,
  }) {
    final data = state.daily(section);
    final days = data.data ?? const <DailyCount>[];
    return ChartCard(
      key: ValueKey('chart-card-${section.name}'),
      title: title,
      subtitle: subtitle,
      status: data.status,
      errorMessage: data.errorMessage,
      onRetry: () =>
          context.read<DashboardBloc>().add(DashboardSectionRetried(section)),
      isEmpty: days.every((d) => d.count == 0),
      emptyMessage: emptyMessage,
      chartBuilder: (_) => DailyColumnChart(days: days),
      tableBuilder: (_) => CountsTable(
        labelHeader: 'Date',
        rows: [for (final d in days) (formatDate(d.date), d.count)],
      ),
    );
  }

  Widget _productTypesCard(DashboardState state) {
    final data = state.productTypes;
    final counts = data.data ?? const [];
    return ChartCard(
      key: const ValueKey('chart-card-productTypes'),
      title: 'Products by type',
      subtitle: 'All time · excludes deleted products',
      status: data.status,
      errorMessage: data.errorMessage,
      onRetry: () => context.read<DashboardBloc>().add(
        const DashboardSectionRetried(DashboardSection.productTypes),
      ),
      isEmpty: counts.isEmpty,
      emptyMessage: 'No products yet',
      chartBuilder: (_) => ProductTypeBarChart(
        counts: counts,
        // Each type opens the products list filtered by it.
        onTypeSelected: (type) => context.go(
          productsListLocation(
            ProductsListQuery(filters: ProductFilters(productType: type)),
          ),
        ),
      ),
      tableBuilder: (_) => CountsTable(
        labelHeader: 'Type',
        rows: [for (final c in counts) (c.label, c.count)],
      ),
    );
  }
}

class _StatTiles extends StatelessWidget {
  final DashboardState state;

  const _StatTiles({required this.state});

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, SectionState<List<DailyCount>> section) =>
        Expanded(
          child: StatTile(
            label: label,
            status: section.status,
            value: section.data?.fold<int>(0, (sum, d) => sum + d.count),
          ),
        );

    return Row(
      children: [
        tile('New users', state.registrations),
        const SizedBox(width: 16),
        tile('Products added', state.products),
        const SizedBox(width: 16),
        tile('Receipts', state.receipts),
      ],
    );
  }
}

/// Two columns on wide windows, one otherwise.
class _ChartGrid extends StatelessWidget {
  final List<Widget> cards;

  const _ChartGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _twoColumnWidth) {
          return Column(
            children: [
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: card,
                ),
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[i]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: i + 1 < cards.length
                          ? cards[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../products/domain/entities/product_filters.dart';
import '../../../products/presentation/products_list_query.dart';
import '../../../receipts/presentation/receipts_list_query.dart';
import '../../../../shared/metrics/domain/entities/daily_count.dart';
import '../../../../shared/metrics/presentation/format.dart';
import '../../../../shared/metrics/presentation/section_state.dart';
import '../../../../shared/metrics/presentation/widgets/chart_card.dart';
import '../../../../shared/metrics/presentation/widgets/counts_table.dart';
import '../../../../shared/metrics/presentation/widgets/daily_column_chart.dart';
import '../../domain/entities/user_details.dart';
import '../bloc/user_detail_bloc.dart';
import '../users_list_location.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/user_receipts_card.dart';
import '../widgets/user_spaces_card.dart';

const kUserNotFoundMessage = 'User not found';

/// From this width the profile/spaces and the two activity charts sit side
/// by side.
const _twoColumnWidth = 1100.0;

class UserDetailPage extends StatefulWidget {
  final String userId;

  /// Where "← Back to users" goes: the last list URL visited.
  final UsersListLocation location;

  const UserDetailPage({
    super.key,
    required this.userId,
    required this.location,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<UserDetailBloc>().add(UserDetailRequested(widget.userId));
  }

  @override
  void didUpdateWidget(UserDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    context.read<UserDetailBloc>().add(UserDetailRequested(widget.userId));
  }

  void _retry(UserDetailSection section) =>
      context.read<UserDetailBloc>().add(UserDetailSectionRetried(section));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserDetailBloc, UserDetailState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back on the left, the user's lists on the right; on narrow
              // windows the links wrap onto their own line.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go(widget.location.value),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to users'),
                  ),
                  // Only once the user is known: an unknown id has no
                  // products or receipts to show.
                  if (state.details.status == SectionStatus.loaded)
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          key: const Key('view-products'),
                          onPressed: () => context.go(
                            productsListLocation(
                              ProductsListQuery(
                                filters: ProductFilters(
                                  creatorId: widget.userId,
                                ),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('View products'),
                        ),
                        TextButton.icon(
                          key: const Key('view-receipts'),
                          onPressed: () => context.go(
                            receiptsListLocation(
                              ReceiptsListQuery(creatorId: widget.userId),
                            ),
                          ),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('View receipts'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.userNotFound)
                const _NotFound()
              else ...[
                _details(state.details),
                const SizedBox(height: 16),
                _TwoColumns(
                  left: _activityCard(
                    state.productsActivity,
                    section: UserDetailSection.productsActivity,
                    title: 'Products added per day',
                    subtitle: 'Last 30 days · Includes deleted products',
                    emptyMessage: 'No products added in the last 30 days',
                  ),
                  right: _activityCard(
                    state.receiptsActivity,
                    section: UserDetailSection.receiptsActivity,
                    title: 'Receipts per purchase date',
                    subtitle: 'Last 30 days · Includes unconfirmed receipts',
                    emptyMessage: 'No receipts in the last 30 days',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _details(SectionState<UserDetails> details) {
    switch (details.status) {
      case SectionStatus.loading:
        return const Card(
          child: SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      case SectionStatus.failure:
        return Card(
          child: SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details.errorMessage ?? 'Something went wrong.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _retry(UserDetailSection.details),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      case SectionStatus.loaded:
        final user = details.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TwoColumns(
              left: UserProfileCard(user: user),
              right: UserSpacesCard(spaces: user.spaces),
            ),
            const SizedBox(height: 16),
            UserReceiptsCard(
              receipts: user.receipts,
              onReceiptSelected: (receipt) => context.go(
                '$kReceiptsPath/${Uri.encodeComponent(receipt.id)}',
              ),
            ),
          ],
        );
    }
  }

  Widget _activityCard(
    SectionState<List<DailyCount>> activity, {
    required UserDetailSection section,
    required String title,
    required String subtitle,
    required String emptyMessage,
  }) {
    final days = activity.data ?? const <DailyCount>[];
    return ChartCard(
      key: ValueKey('chart-card-${section.name}'),
      title: title,
      subtitle: subtitle,
      status: activity.status,
      errorMessage: activity.errorMessage,
      onRetry: () => _retry(section),
      isEmpty: days.every((d) => d.count == 0),
      emptyMessage: emptyMessage,
      chartBuilder: (_) => DailyColumnChart(days: days),
      tableBuilder: (_) => CountsTable(
        labelHeader: 'Date',
        rows: [for (final d in days) (formatDate(d.date), d.count)],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                kUserNotFoundMessage,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Side by side on wide windows, stacked otherwise.
class _TwoColumns extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _TwoColumns({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _twoColumnWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 16), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

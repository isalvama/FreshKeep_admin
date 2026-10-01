import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/metrics/domain/entities/selected_range.dart';
import '../../../../shared/metrics/presentation/section_state.dart';
import '../../../../shared/metrics/presentation/widgets/range_bar.dart';
import '../../../../shared/widgets/pagination_bar.dart';
import '../../domain/entities/users_page.dart';
import '../bloc/users_list_bloc.dart';
import '../users_list_location.dart';
import '../users_list_query.dart';
import '../widgets/last_login_footnote.dart';
import '../widgets/users_table.dart';

const kNoUsersInRangeMessage = 'No users registered in this range';
const kEmptyPageMessage = 'No users on this page';

/// The users list. The URL is the source of truth for the range and page:
/// this page reads [query], tells the bloc, and writes changes back.
class UsersListPage extends StatefulWidget {
  final Map<String, String> query;

  /// Remembers this list's URL for "← Back to users".
  final UsersListLocation location;

  const UsersListPage({super.key, required this.query, required this.location});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  @override
  void initState() {
    super.initState();
    _syncFromUrl();
  }

  @override
  void didUpdateWidget(UsersListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromUrl();
  }

  void _syncFromUrl() {
    final bloc = context.read<UsersListBloc>();
    final query = parseUsersListQuery(widget.query, bloc.today());
    if (query == null) {
      // Missing or invalid: replace (not push) so the bad URL leaves no
      // history entry. The corrected URL comes back through didUpdateWidget.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replace(usersListLocation(kDefaultUsersListQuery));
      });
      return;
    }
    widget.location.remember(usersListLocation(query));
    bloc.add(UsersListQueryChanged(query));
  }

  void _go(UsersListQuery query) => context.go(usersListLocation(query));

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<UsersListBloc>();

    return BlocBuilder<UsersListBloc, UsersListState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RangeBar(
                maxLengthInDays: kUsersMaxRangeLengthInDays,
                label: 'Registered between',
                range: state.query.range,
                resolvedRange: state.resolvedRange,
                today: bloc.today(),
                // A new range starts again from the first page.
                onRangeChanged: (SelectedRange range) =>
                    _go(UsersListQuery(range: range, page: 1)),
                onRefresh: () => bloc.add(const UsersListRetried()),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _body(context, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, UsersListState state) {
    final users = state.users;
    switch (users.status) {
      case SectionStatus.loading:
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      case SectionStatus.failure:
        return _Message(
          icon: Icons.error_outline,
          isError: true,
          message: users.errorMessage ?? 'Something went wrong.',
          action: OutlinedButton.icon(
            onPressed: () =>
                context.read<UsersListBloc>().add(const UsersListRetried()),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
      case SectionStatus.loaded:
        return _loaded(context, state.query, users.data!);
    }
  }

  Widget _loaded(BuildContext context, UsersListQuery query, UsersPage page) {
    if (page.users.isEmpty) {
      if (query.page == 1) {
        return const _Message(
          icon: Icons.person_search_outlined,
          message: kNoUsersInRangeMessage,
        );
      }
      // Past the last page: the backend reports no total here, so offer a
      // way back rather than "of N".
      return _Message(
        icon: Icons.find_in_page_outlined,
        message: kEmptyPageMessage,
        action: TextButton(
          onPressed: () => _go(UsersListQuery(range: query.range, page: 1)),
          child: const Text('Go to first page'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UsersTable(
          users: page.users,
          onUserSelected: (user) =>
              context.go('$kUsersPath/${Uri.encodeComponent(user.id)}'),
        ),
        const SizedBox(height: 8),
        PaginationBar(
          page: page.page,
          firstIndex: page.firstIndex,
          lastIndex: page.lastIndex,
          total: page.totalElements,
          hasPrevious: page.hasPrevious,
          hasNext: page.hasNext,
          onPageChanged: (number) =>
              _go(UsersListQuery(range: query.range, page: number)),
        ),
        const SizedBox(height: 8),
        const LastLoginFootnote(),
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

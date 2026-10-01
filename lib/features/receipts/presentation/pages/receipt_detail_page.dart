import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../products/presentation/products_list_query.dart';
import '../../../users/presentation/users_list_query.dart';
import '../bloc/receipt_detail_bloc.dart';
import '../receipts_list_location.dart';
import '../widgets/receipt_card.dart';
import '../widgets/receipt_products_card.dart';

const kReceiptNotFoundMessage = 'Receipt not found';

class ReceiptDetailPage extends StatefulWidget {
  final String receiptId;

  /// Where "← Back to receipts" goes: the last list URL visited.
  final ReceiptsListLocation location;

  const ReceiptDetailPage({
    super.key,
    required this.receiptId,
    required this.location,
  });

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  @override
  void initState() {
    super.initState();
    _request();
  }

  @override
  void didUpdateWidget(ReceiptDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _request();
  }

  void _request() => context.read<ReceiptDetailBloc>().add(
    ReceiptDetailRequested(widget.receiptId),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptDetailBloc, ReceiptDetailState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go(widget.location.value),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to receipts'),
                ),
              ),
              const SizedBox(height: 16),
              ..._body(context, state),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _body(BuildContext context, ReceiptDetailState state) {
    final colors = Theme.of(context).colorScheme;
    switch (state.status) {
      case ReceiptDetailStatus.loading:
        return const [
          Card(
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ];
      case ReceiptDetailStatus.notFound:
        return [
          _MessageCard(
            icon: Icon(
              Icons.search_off,
              size: 40,
              color: colors.onSurfaceVariant,
            ),
            message: Text(
              kReceiptNotFoundMessage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ];
      case ReceiptDetailStatus.failure:
        return [
          _MessageCard(
            icon: Icon(Icons.error_outline, color: colors.error),
            message: Text(
              state.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
            ),
            action: OutlinedButton.icon(
              onPressed: () => context.read<ReceiptDetailBloc>().add(
                const ReceiptDetailRetried(),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ];
      case ReceiptDetailStatus.loaded:
        final receipt = state.receipt!;
        return [
          ReceiptCard(
            receipt: receipt,
            onCreatorSelected: (userId) =>
                context.go('$kUsersPath/${Uri.encodeComponent(userId)}'),
          ),
          const SizedBox(height: 16),
          ReceiptProductsCard(
            products: receipt.products,
            today: context.read<ReceiptDetailBloc>().today(),
            onProductSelected: (product) =>
                context.go('$kProductsPath/${Uri.encodeComponent(product.id)}'),
          ),
        ];
    }
  }
}

class _MessageCard extends StatelessWidget {
  final Widget icon;
  final Widget message;
  final Widget? action;

  const _MessageCard({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 12),
              message,
              if (action != null) ...[const SizedBox(height: 12), action!],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../receipts/presentation/receipts_list_query.dart';
import '../../../users/presentation/users_list_query.dart';
import '../bloc/product_detail_bloc.dart';
import '../products_list_location.dart';
import '../widgets/product_card.dart';
import '../widgets/product_origin_card.dart';

const kProductNotFoundMessage = 'Product not found';

/// From this width the product and its origin sit side by side.
const _twoColumnWidth = 1100.0;

class ProductDetailPage extends StatefulWidget {
  final String productId;

  /// Where "← Back to products" goes: the last list URL visited.
  final ProductsListLocation location;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.location,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    _request();
  }

  @override
  void didUpdateWidget(ProductDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _request();
  }

  void _request() => context.read<ProductDetailBloc>().add(
    ProductDetailRequested(widget.productId),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailBloc, ProductDetailState>(
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
                  label: const Text('Back to products'),
                ),
              ),
              const SizedBox(height: 16),
              _body(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, ProductDetailState state) {
    final colors = Theme.of(context).colorScheme;
    switch (state.status) {
      case ProductDetailStatus.loading:
        return const Card(
          child: SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      case ProductDetailStatus.notFound:
        return _MessageCard(
          icon: Icon(
            Icons.search_off,
            size: 40,
            color: colors.onSurfaceVariant,
          ),
          message: Text(
            kProductNotFoundMessage,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
      case ProductDetailStatus.failure:
        return _MessageCard(
          icon: Icon(Icons.error_outline, color: colors.error),
          message: Text(
            state.errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
          ),
          action: OutlinedButton.icon(
            onPressed: () => context.read<ProductDetailBloc>().add(
              const ProductDetailRetried(),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
      case ProductDetailStatus.loaded:
        final product = state.product!;
        return _TwoColumns(
          left: ProductCard(
            product: product,
            today: context.read<ProductDetailBloc>().today(),
          ),
          right: ProductOriginCard(
            origin: product.origin,
            onCreatorSelected: (userId) =>
                context.go('$kUsersPath/${Uri.encodeComponent(userId)}'),
            // The receipt page lists all its products.
            onReceiptSelected: (receiptId) =>
                context.go('$kReceiptsPath/${Uri.encodeComponent(receiptId)}'),
          ),
        );
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

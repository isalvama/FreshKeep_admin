import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/metrics/presentation/section_state.dart';
import '../../../../shared/widgets/pagination_bar.dart';
import '../../domain/entities/product_filters.dart';
import '../../domain/entities/products_page.dart';
import '../bloc/products_list_bloc.dart';
import '../products_list_location.dart';
import '../products_list_query.dart';
import '../widgets/products_controls.dart';
import '../widgets/products_table.dart';

const kNoProductsMessage = 'No products match these filters';
const kNoMoreProductsMessage = 'No more products';

/// The products list. The URL is the source of truth for the sort, filters
/// and page: this page reads [query], tells the bloc, and writes changes back.
class ProductsListPage extends StatefulWidget {
  final Map<String, String> query;

  /// Remembers this list's URL for "← Back to products".
  final ProductsListLocation location;

  const ProductsListPage({
    super.key,
    required this.query,
    required this.location,
  });

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  @override
  void initState() {
    super.initState();
    _syncFromUrl();
  }

  @override
  void didUpdateWidget(ProductsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromUrl();
  }

  void _syncFromUrl() {
    final query = parseProductsListQuery(widget.query);
    if (!mapEquals(productsListQueryParameters(query), widget.query)) {
      // Invalid or missing values: replace (not push) with the URL that
      // keeps everything valid, so the bad URL leaves no history entry. The
      // corrected URL comes back through didUpdateWidget.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replace(productsListLocation(query));
      });
      return;
    }
    widget.location.remember(productsListLocation(query));
    context.read<ProductsListBloc>().add(ProductsListRequested(query));
  }

  void _go(ProductsListQuery query) => context.go(productsListLocation(query));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsListBloc, ProductsListState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductsControls(
                filters: state.query.filters,
                creatorLabel: state.creatorLabel,
                receiptLabel: state.receiptLabel,
                // New sort or filters start again from the first page.
                onFiltersChanged: (ProductFilters filters) =>
                    _go(state.query.withFilters(filters)),
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

  Widget _body(BuildContext context, ProductsListState state) {
    final products = state.products;
    switch (products.status) {
      case SectionStatus.loading:
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      case SectionStatus.failure:
        return _Message(
          icon: Icons.error_outline,
          isError: true,
          message: products.errorMessage ?? 'Something went wrong.',
          action: OutlinedButton.icon(
            onPressed: () => context.read<ProductsListBloc>().add(
              const ProductsListRetried(),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
      case SectionStatus.loaded:
        return _loaded(context, state.query, products.data!);
    }
  }

  Widget _loaded(
    BuildContext context,
    ProductsListQuery query,
    ProductsPage page,
  ) {
    if (page.products.isEmpty) {
      if (query.page == 1) {
        return const _Message(
          icon: Icons.inventory_2_outlined,
          message: kNoProductsMessage,
        );
      }
      // Past the end: with no total from the backend, a page that was
      // exactly full leads here.
      return _Message(
        icon: Icons.find_in_page_outlined,
        message: kNoMoreProductsMessage,
        action: TextButton(
          onPressed: () => _go(query.withPage(1)),
          child: const Text('Go to first page'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductsTable(
          products: page.products,
          today: context.read<ProductsListBloc>().today(),
          onProductSelected: (product) =>
              context.go('$kProductsPath/${Uri.encodeComponent(product.id)}'),
        ),
        const SizedBox(height: 8),
        PaginationBar(
          page: page.page,
          label: 'Products',
          firstIndex: page.firstIndex,
          lastIndex: page.lastIndex,
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

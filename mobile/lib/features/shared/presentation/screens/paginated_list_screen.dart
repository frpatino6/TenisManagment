import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';

/// Base template for paginated list screens using the Template Method Pattern.
///
/// Subclasses provide [watchData], [buildListItem], and [getTitle].
/// Optional hooks: [buildSearchAndFilters], [buildListHeader], [buildPaginationFooter],
/// [emptyMessage], [onRetry], [appBarActions].
abstract class PaginatedListScreen<T> extends ConsumerStatefulWidget {
  const PaginatedListScreen({super.key});
}

abstract class PaginatedListScreenState<T>
    extends ConsumerState<PaginatedListScreen<T>> {
  AsyncValue<List<T>> watchData();

  String getTitle(BuildContext context);

  Widget buildListItem(BuildContext context, T item);

  Widget buildSearchAndFilters(BuildContext context) => const SizedBox.shrink();

  Widget? buildListHeader(BuildContext context, List<T> items) => null;

  Widget? buildPaginationFooter(BuildContext context) => null;

  String get emptyMessage => 'No se encontraron elementos.';

  VoidCallback? get onRetry => null;

  List<Widget>? appBarActions(BuildContext context) => null;

  EdgeInsets get listPadding => const EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context) {
    final dataAsync = watchData();
    return Scaffold(
      appBar: AppBar(
        title: Text(getTitle(context)),
        actions: appBarActions(context),
      ),
      body: Column(
        children: [
          buildSearchAndFilters(context),
          Expanded(
            child: dataAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }
                final header = buildListHeader(context, items);
                final footer = buildPaginationFooter(context);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (header != null) header,
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        padding: listPadding,
                        itemBuilder: (context, index) =>
                            buildListItem(context, items[index]),
                      ),
                    ),
                    if (footer != null) footer,
                  ],
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) =>
                  AppErrorWidget.fromError(error, onRetry: onRetry),
            ),
          ),
        ],
      ),
    );
  }
}

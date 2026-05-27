import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../domain/entities/store.dart';
import '../controllers/my_stores_state.dart';
import '../providers/workspace_context_providers.dart';

class MyStoresPage extends ConsumerWidget {
  const MyStoresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myStoresNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách cửa hàng'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingMd),
            child: TextButton.icon(
              onPressed: () => _showComingSoon(
                context,
                'Tạo cửa hàng sẽ được triển khai sau',
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm mới'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: switch (state.status) {
            MyStoresStatus.initial || MyStoresStatus.loading
                when state.stores.isEmpty =>
              const _LoadingView(),
            MyStoresStatus.error when state.stores.isEmpty => _ErrorView(
              message: state.errorMessage ?? 'Không thể tải danh sách cửa hàng',
              onRetry: () =>
                  ref.read(myStoresNotifierProvider.notifier).loadStores(),
            ),
            _ => _MyStoresContent(
              state: state,
              onSearchChanged: (query) => ref
                  .read(myStoresNotifierProvider.notifier)
                  .updateSearchQuery(query),
              onRefresh: () =>
                  ref.read(myStoresNotifierProvider.notifier).loadStores(),
              onAccessStore: () => _showComingSoon(
                context,
                'Truy cập cửa hàng sẽ được triển khai sau',
              ),
            ),
          },
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MyStoresContent extends StatelessWidget {
  final MyStoresState state;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onAccessStore;

  const _MyStoresContent({
    required this.state,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onAccessStore,
  });

  @override
  Widget build(BuildContext context) {
    final stores = state.filteredStores;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        children: [
          TextField(
            key: const Key('my_stores_search_field'),
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          if (state.stores.isEmpty)
            const _EmptyStoresView()
          else if (stores.isEmpty)
            const _EmptySearchView()
          else
            ...stores.map(
              (store) => Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                child: _StoreCard(store: store, onAccessStore: onAccessStore),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onAccessStore;

  const _StoreCard({required this.store, required this.onAccessStore});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.storeName.isEmpty
                            ? 'Cửa hàng chưa đặt tên'
                            : store.storeName,
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      _InlineInfo(
                        icon: Icons.phone_outlined,
                        text: store.phone.isEmpty
                            ? 'Chưa có số điện thoại'
                            : store.phone,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      _InlineInfo(
                        icon: Icons.location_on_outlined,
                        text: store.address.isEmpty
                            ? 'Chưa có địa chỉ'
                            : store.address,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                _StoreStatusChip(status: store.status),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            ElevatedButton.icon(
              key: Key('access_store_${store.id}'),
              onPressed: store.status.canAccess ? onAccessStore : null,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Truy cập'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreStatusChip extends StatelessWidget {
  final StoreStatus status;

  const _StoreStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            status.label,
            style: AppTextStyles.labelXs.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Color _statusColor(StoreStatus status) {
    return switch (status) {
      StoreStatus.active => AppColors.success,
      StoreStatus.inactive => AppColors.warning,
      StoreStatus.closed => AppColors.textMuted,
      StoreStatus.unknown => AppColors.info,
    };
  }
}

class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppConstants.spacingXs),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyXs.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStoresView extends StatelessWidget {
  const _EmptyStoresView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(
        child: _EmptyStateMessage(
          icon: Icons.storefront_outlined,
          title: 'Chưa có cửa hàng',
          message: 'Tài khoản của bạn chưa được liên kết với cửa hàng nào.',
        ),
      ),
    );
  }
}

class _EmptySearchView extends StatelessWidget {
  const _EmptySearchView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 260,
      child: Center(
        child: _EmptyStateMessage(
          icon: Icons.search_off_rounded,
          title: 'Không tìm thấy cửa hàng',
          message: 'Thử tìm theo tên, số điện thoại hoặc địa chỉ khác.',
        ),
      ),
    );
  }
}

class _EmptyStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 30),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text(
          title,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(message, style: AppTextStyles.bodySm, textAlign: TextAlign.center),
      ],
    );
  }
}

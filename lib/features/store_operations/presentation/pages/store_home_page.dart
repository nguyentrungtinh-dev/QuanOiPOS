import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/account_hub_header.dart';
import '../widgets/account_menu_section.dart';
import '../widgets/logout_action_button.dart';
import '../widgets/system_shell_scaffold.dart';
import '../widgets/user_profile_card.dart';

enum _AccountHubState { loading, ready, error }

class StoreHomePage extends ConsumerStatefulWidget {
  const StoreHomePage({super.key});

  @override
  ConsumerState<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends ConsumerState<StoreHomePage> {
  _AccountHubState _state = _AccountHubState.loading;

  @override
  void initState() {
    super.initState();
    _bootstrapAccountHub();
  }

  Future<void> _bootstrapAccountHub() async {
    setState(() => _state = _AccountHubState.loading);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _state = _AccountHubState.ready);
  }

  void _showComingSoon(BuildContext context, {required String feature}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature sẽ được triển khai ở phase sau')),
    );
  }

  void _onTabSelected(BuildContext context, AccountTab tab) {
    if (tab == AccountTab.account) return;
    _showComingSoon(context, feature: 'Tab này');
  }

  void _onStoreMenuTap(BuildContext context) {
    context.pushNamed(RouteNames.myStores);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final fullName = authState.fullName ?? 'Store User';
    final email = authState.email ?? '';

    return SystemShellScaffold(
      currentTab: AccountTab.account,
      onTabSelected: (tab) => _onTabSelected(context, tab),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AccountHubHeader(greeting: 'Xin chào, $fullName'),
            Expanded(
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: switch (_state) {
                  _AccountHubState.loading => const _LoadingStateView(),
                  _AccountHubState.error => _ErrorStateView(
                    onRetry: _bootstrapAccountHub,
                  ),
                  _AccountHubState.ready => _ReadyStateView(
                    fullName: fullName,
                    email: email,
                    onStoreTap: () => _onStoreMenuTap(context),
                    onFeatureTap: (feature) =>
                        _showComingSoon(context, feature: feature),
                    onLogout: () =>
                        ref.read(authNotifierProvider.notifier).logout(),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingStateView extends StatelessWidget {
  const _LoadingStateView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorStateView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorStateView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Không thể tải thông tin tài khoản',
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyStateView extends StatelessWidget {
  final String fullName;
  final String email;
  final VoidCallback onStoreTap;
  final void Function(String feature) onFeatureTap;
  final VoidCallback onLogout;

  const _ReadyStateView({
    required this.fullName,
    required this.email,
    required this.onStoreTap,
    required this.onFeatureTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UserProfileCard(
            fullName: fullName,
            email: email,
            onTap: () => onFeatureTap('Hồ sơ tài khoản'),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          AccountMenuSection(
            items: [
              AccountMenuItemData(
                title: 'Gói dịch vụ của tôi',
                leadingIcon: Icons.inventory_2_outlined,
                trailingMeta: 'Xem chi tiết',
                onTap: () => context.pushNamed(RouteNames.storeSubscription),
              ),
              AccountMenuItemData(
                title: 'Cửa hàng',
                leadingIcon: Icons.storefront_outlined,
                trailingMeta: 'Chọn cửa hàng',
                onTap: onStoreTap,
              ),
              AccountMenuItemData(
                title: 'Bảo mật',
                leadingIcon: Icons.shield_outlined,
                onTap: () => onFeatureTap('Bảo mật'),
              ),
              AccountMenuItemData(
                title: 'Cài đặt ứng dụng',
                leadingIcon: Icons.settings_outlined,
                onTap: () => onFeatureTap('Cài đặt ứng dụng'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          LogoutActionButton(onPressed: onLogout),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Về ứng dụng')),
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppConstants.spacingMd),
                _AboutAppHeaderCard(),
                SizedBox(height: AppConstants.spacingXs),
                _AboutAppContentCard(),
                SizedBox(height: AppConstants.spacingLg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutAppContentCard extends StatelessWidget {
  const _AboutAppContentCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('about_app_content_card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'QUÁN ƠI',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              '(SẢN PHẨM CỦA QUANOI CO., LTD.)',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            const _AboutParagraph(
              'Bạn mất nhiều thời gian cho theo dõi thu chi, lãi lỗ hàng ngày?',
            ),
            const _AboutParagraph(
              'Chi phí cho một hệ thống quản lý bán hàng đắt đỏ và sử dụng phức tạp?',
            ),
            const _AboutParagraph(
              'Bạn gặp khó khăn trong việc quản lý hàng tồn kho?',
            ),
            const _AboutParagraph(
              'Bạn muốn bán hàng online nhưng việc bán hàng quá phức tạp và mất thời gian?',
            ),
            const _AboutParagraph(
              'Bạn phải chia sẻ doanh thu với các sàn TMĐT?',
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'QUÁN ƠI GIÚP BẠN QUẢN LÝ BÁN HÀNG CHỈ BẰNG MỘT CHIẾC ĐIỆN THOẠI.',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              '1. QUẢN LÝ BÁN HÀNG CHỈ BẰNG MỘT CHIẾC ĐIỆN THOẠI',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            const _FeatureBullet(
              'Quản lý đơn hàng: theo dõi số lượng, trạng thái đơn hàng và tạo đơn hàng nhanh.',
            ),
            const _FeatureBullet(
              'Tự động cập nhật doanh thu hàng ngày vào báo cáo doanh thu.',
            ),
            const _FeatureBullet(
              'Quản lý hàng tồn kho, biết số lượng tồn và cảnh báo khi tồn kho thấp.',
            ),
            const _FeatureBullet(
              'Báo cáo doanh thu, lãi lỗ hàng ngày, tuần, tháng trực quan.',
            ),
            const _FeatureBullet(
              'Dễ dàng in hóa đơn trên điện thoại và gửi cho khách qua SMS hoặc Zalo.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutParagraph extends StatelessWidget {
  final String text;

  const _AboutParagraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Text(text, style: AppTextStyles.bodySm),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final String text;

  const _FeatureBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTextStyles.bodySm),
          Expanded(child: Text(text, style: AppTextStyles.bodySm)),
        ],
      ),
    );
  }
}

class _AboutAppHeaderCard extends StatelessWidget {
  const _AboutAppHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('about_app_header_card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.spacingSm),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    key: const Key('about_app_logo'),
                    width: AppConstants.avatarSizeSm,
                    height: AppConstants.avatarSizeSm,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Phiên bản ứng dụng ${AppConstants.appVersion}',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

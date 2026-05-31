import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';

class AccountPdfDocumentPage extends StatelessWidget {
  final String title;
  final String assetPath;
  final Key viewerKey;
  final String errorMessage;

  const AccountPdfDocumentPage({
    super.key,
    required this.title,
    required this.assetPath,
    required this.viewerKey,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: AccountPdfDocumentViewer(
          assetPath: assetPath,
          viewerKey: viewerKey,
          errorMessage: errorMessage,
        ),
      ),
    );
  }
}

class AccountPdfDocumentViewer extends StatelessWidget {
  final String assetPath;
  final Key viewerKey;
  final String errorMessage;

  const AccountPdfDocumentViewer({
    super.key,
    required this.assetPath,
    required this.viewerKey,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: PdfViewer.asset(
        assetPath,
        key: viewerKey,
        params: PdfViewerParams(
          margin: 0,
          backgroundColor: AppColors.surface,
          sizeDelegateProvider: const PdfViewerSizeDelegateProviderSmart(
            smartMaxScale: 4,
          ),
          loadingBannerBuilder: _buildLoadingBanner,
          errorBannerBuilder: _buildErrorBanner,
        ),
      ),
    );
  }

  static Widget _buildLoadingBanner(
    BuildContext context,
    int bytesDownloaded,
    int? totalBytes,
  ) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorBanner(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    PdfDocumentRef documentRef,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Text(
          errorMessage,
          style: AppTextStyles.bodySm,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

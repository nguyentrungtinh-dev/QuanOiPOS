import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryLedgerMockProvider = Provider<StoreInventoryLedgerMockState>(
  (ref) {
    // TODO: Replace mock data when inventory ledger API contract is available.
    return const StoreInventoryLedgerMockState(
      summary: StoreInventoryLedgerSummaryMock(
        openingValueText: '106.000 đ',
        inboundValueText: '87.500 đ',
        outboundValueText: '59.500 đ',
        closingValueText: '134.000 đ',
      ),
      groups: [
        StoreInventoryLedgerGroupMock(
          title: 'HÔM NAY',
          entries: [
            StoreInventoryLedgerEntryMock(
              productName: 'Thăng Long',
              sku: 'SP0048',
              referenceCode: '#XH2074',
              transactionType: 'Bán hàng',
              valueText: '0',
              quantityText: 'SL: -1',
              direction: StoreInventoryLedgerDirection.outbound,
            ),
            StoreInventoryLedgerEntryMock(
              productName: 'Thăng Long',
              sku: 'SP0048',
              referenceCode: '#NH266',
              transactionType: 'Nhập hàng',
              valueText: '0',
              quantityText: 'SL: +10',
              direction: StoreInventoryLedgerDirection.inbound,
            ),
            StoreInventoryLedgerEntryMock(
              productName: 'Sài gòn bạc',
              sku: 'SP0038',
              referenceCode: '#XH2073',
              transactionType: 'Bán hàng',
              valueText: '0',
              quantityText: 'SL: -1',
              direction: StoreInventoryLedgerDirection.outbound,
            ),
            StoreInventoryLedgerEntryMock(
              productName: 'Number 1',
              sku: 'SP0072',
              referenceCode: '#XH2072',
              transactionType: 'Bán hàng',
              valueText: '0',
              quantityText: 'SL: -1',
              direction: StoreInventoryLedgerDirection.outbound,
            ),
          ],
        ),
      ],
    );
  },
);

class StoreInventoryLedgerMockState {
  final StoreInventoryLedgerSummaryMock summary;
  final List<StoreInventoryLedgerGroupMock> groups;

  const StoreInventoryLedgerMockState({
    required this.summary,
    required this.groups,
  });
}

class StoreInventoryLedgerSummaryMock {
  final String openingValueText;
  final String inboundValueText;
  final String outboundValueText;
  final String closingValueText;

  const StoreInventoryLedgerSummaryMock({
    required this.openingValueText,
    required this.inboundValueText,
    required this.outboundValueText,
    required this.closingValueText,
  });
}

class StoreInventoryLedgerGroupMock {
  final String title;
  final List<StoreInventoryLedgerEntryMock> entries;

  const StoreInventoryLedgerGroupMock({
    required this.title,
    required this.entries,
  });
}

class StoreInventoryLedgerEntryMock {
  final String productName;
  final String sku;
  final String referenceCode;
  final String transactionType;
  final String valueText;
  final String quantityText;
  final StoreInventoryLedgerDirection direction;

  const StoreInventoryLedgerEntryMock({
    required this.productName,
    required this.sku,
    required this.referenceCode,
    required this.transactionType,
    required this.valueText,
    required this.quantityText,
    required this.direction,
  });
}

enum StoreInventoryLedgerDirection { inbound, outbound, adjustment }

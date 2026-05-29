import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../data/datasources/table_management_remote_data_source.dart';
import '../../domain/repositories/table_management_repository.dart';
import '../../domain/usecases/create_area_use_case.dart';
import '../../domain/usecases/create_table_use_case.dart';
import '../../domain/usecases/delete_area_use_case.dart';
import '../../domain/usecases/load_areas_use_case.dart';
import '../../domain/usecases/load_table_groups_use_case.dart';
import '../../domain/usecases/update_area_display_order_use_case.dart';
import '../../domain/usecases/update_area_use_case.dart';
import '../../domain/usecases/update_table_use_case.dart';
import '../controllers/table_management_notifier.dart';
import '../controllers/table_management_state.dart';

final tableManagementRemoteDataSourceProvider =
    Provider<TableManagementRemoteDataSource>((ref) {
      return locator<TableManagementRemoteDataSource>();
    });

final tableManagementRepositoryProvider = Provider<TableManagementRepository>((
  ref,
) {
  return locator<TableManagementRepository>();
});

final loadAreasUseCaseProvider = Provider<LoadAreasUseCase>((ref) {
  return locator<LoadAreasUseCase>();
});

final loadTableGroupsUseCaseProvider = Provider<LoadTableGroupsUseCase>((ref) {
  return locator<LoadTableGroupsUseCase>();
});

final createAreaUseCaseProvider = Provider<CreateAreaUseCase>((ref) {
  return locator<CreateAreaUseCase>();
});

final createTableUseCaseProvider = Provider<CreateTableUseCase>((ref) {
  return locator<CreateTableUseCase>();
});

final updateAreaUseCaseProvider = Provider<UpdateAreaUseCase>((ref) {
  return locator<UpdateAreaUseCase>();
});

final updateTableUseCaseProvider = Provider<UpdateTableUseCase>((ref) {
  return locator<UpdateTableUseCase>();
});

final updateAreaDisplayOrderUseCaseProvider =
    Provider<UpdateAreaDisplayOrderUseCase>((ref) {
      return locator<UpdateAreaDisplayOrderUseCase>();
    });

final deleteAreaUseCaseProvider = Provider<DeleteAreaUseCase>((ref) {
  return locator<DeleteAreaUseCase>();
});

final tableManagementNotifierProvider = NotifierProvider.autoDispose
    .family<
      TableManagementNotifier,
      TableManagementState,
      TableManagementAccess
    >(TableManagementNotifier.new);

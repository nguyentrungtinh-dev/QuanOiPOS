import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../data/datasources/workspace_remote_data_source.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/usecases/load_my_stores_use_case.dart';
import '../controllers/my_stores_notifier.dart';
import '../controllers/my_stores_state.dart';

final workspaceRemoteDataSourceProvider = Provider<WorkspaceRemoteDataSource>((
  ref,
) {
  return locator<WorkspaceRemoteDataSource>();
});

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return locator<WorkspaceRepository>();
});

final loadMyStoresUseCaseProvider = Provider<LoadMyStoresUseCase>((ref) {
  return locator<LoadMyStoresUseCase>();
});

final myStoresNotifierProvider =
    NotifierProvider.autoDispose<MyStoresNotifier, MyStoresState>(
      MyStoresNotifier.new,
    );

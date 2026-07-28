import 'package:get_it/get_it.dart';
import 'package:webnovel_tracker/data/database/app_database.dart';
import 'package:webnovel_tracker/data/entry_repository.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_bloc.dart';
import 'package:webnovel_tracker/services/backup_service.dart';
import 'package:webnovel_tracker/services/title_fetcher.dart';

/// Global service locator. Registered in [configureDependencies] at startup;
/// resolve with `getIt<T>()`.
final GetIt getIt = GetIt.instance;

/// Wires up singletons and factories. Call once in `main` before `runApp`.
Future<void> configureDependencies() async {
  // TODO: register dependencies, e.g.
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  getIt.registerLazySingleton<EntryRepository>(() => EntryRepository(getIt()));
  getIt.registerLazySingleton<TitleFetcher>(() => TitleFetcher());
  getIt.registerLazySingleton<BackupService>(() => BackupService(getIt()));
  // Blocs are short-lived -> registerFactory:
  getIt.registerFactory<EntryListBloc>(() => EntryListBloc(getIt()));
  getIt.registerFactory<NewEntryBloc>(() => NewEntryBloc(getIt(), getIt()));
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/env_service.dart';
import 'core/services/local_db_service.dart';
import 'core/services/online_sync_service.dart';
import 'core/theme/pos_theme.dart';
import 'repositories/local_auth_repository.dart';
import 'repositories/local_catalog_repository.dart';
import 'repositories/local_order_repository.dart';
import 'repositories/sync_repository.dart';
import 'viewmodels/pos_app_viewmodel.dart';
import 'viewmodels/pos_auth_viewmodel.dart';
import 'viewmodels/pos_checkout_viewmodel.dart';
import 'viewmodels/pos_held_orders_viewmodel.dart';
import 'viewmodels/pos_register_viewmodel.dart';
import 'viewmodels/pos_shift_viewmodel.dart';
import 'viewmodels/pos_sync_viewmodel.dart';
import 'views/auth/phone_pin_login_view.dart';
import 'views/pos_main_shell.dart';
import 'views/setup/pos_setup_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  String? configurationError;
  try {
    await dotenv.load(fileName: '.env');
  } catch (error, stackTrace) {
    logger.e(
      'Unable to load environment configuration',
      error: error,
      stackTrace: stackTrace,
    );
    configurationError = 'Could not read .env. Check device setup.';
  }
  configurationError ??= EnvService.configurationError;

  final localDb = LocalDbService(logger: logger);
  OnlineSyncService? onlineSyncService;
  if (configurationError == null) {
    try {
      await Supabase.initialize(
        url: EnvService.supabaseUrl!,
        publishableKey: EnvService.supabaseAnonKey!,
      );
      onlineSyncService = OnlineSyncService(
        client: Supabase.instance.client,
        localDb: localDb,
        logger: logger,
      );
    } catch (error, stackTrace) {
      logger.e(
        'Unable to initialize Supabase client',
        error: error,
        stackTrace: stackTrace,
      );
      configurationError = 'Could not initialize the catalog service.';
    }
  }

  final syncRepository = onlineSyncService == null
      ? null
      : SyncRepository(onlineSyncService);
  runApp(
    PosApplication(
      localDb: localDb,
      syncRepository: syncRepository,
      configurationError: configurationError,
      logger: logger,
    ),
  );
}

class PosApplication extends StatelessWidget {
  const PosApplication({
    required this.localDb,
    required this.syncRepository,
    required this.configurationError,
    required this.logger,
    super.key,
  });

  final LocalDbService localDb;
  final SyncRepository? syncRepository;
  final String? configurationError;
  final Logger logger;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalDbService>.value(value: localDb),
        Provider<LocalCatalogRepository>(
          create: (context) => LocalCatalogRepository(
            localDb: context.read<LocalDbService>(),
            logger: logger,
          ),
        ),
        Provider<LocalAuthRepository>(
          create: (context) => LocalAuthRepository(
            localDb: context.read<LocalDbService>(),
            logger: logger,
          ),
        ),
        Provider<LocalOrderRepository>(
          create: (context) => LocalOrderRepository(
            localDb: context.read<LocalDbService>(),
            logger: logger,
          ),
        ),
        Provider<SyncRepository?>.value(value: syncRepository),
        ChangeNotifierProvider<PosAppViewModel>(
          create: (context) => PosAppViewModel(
            catalogRepository: context.read<LocalCatalogRepository>(),
            syncRepository: context.read<SyncRepository?>(),
            configurationError: configurationError,
            logger: logger,
          ),
        ),
        ChangeNotifierProvider<PosAuthViewModel>(
          create: (context) => PosAuthViewModel(
            repository: context.read<LocalAuthRepository>(),
            catalogRepository: context.read<LocalCatalogRepository>(),
            syncRepository: context.read<SyncRepository?>(),
            logger: logger,
          ),
        ),
        ChangeNotifierProvider<PosRegisterViewModel>(
          create: (context) => PosRegisterViewModel(
            repository: context.read<LocalCatalogRepository>(),
            logger: logger,
          ),
        ),
        ChangeNotifierProvider<PosCheckoutViewModel>(
          create: (context) => PosCheckoutViewModel(
            orderRepository: context.read<LocalOrderRepository>(),
            registerViewModel: context.read<PosRegisterViewModel>(),
            logger: logger,
          ),
        ),
        ChangeNotifierProvider<PosHeldOrdersViewModel>(
          create: (context) => PosHeldOrdersViewModel(
            repository: context.read<LocalOrderRepository>(),
            registerViewModel: context.read<PosRegisterViewModel>(),
            logger: logger,
          ),
        ),
        ChangeNotifierProvider<PosShiftViewModel>(
          create: (context) => PosShiftViewModel(
            repository: context.read<LocalOrderRepository>(),
            logger: logger,
          ),
        ),
        ChangeNotifierProvider<PosSyncViewModel>(
          create: (_) => PosSyncViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Bar POS',
        debugShowCheckedModeBanner: false,
        theme: PosTheme.darkTheme,
        home: const PosRootView(),
      ),
    );
  }
}

class PosRootView extends StatefulWidget {
  const PosRootView({super.key});

  @override
  State<PosRootView> createState() => _PosRootViewState();
}

class _PosRootViewState extends State<PosRootView> {
  bool _didInitialize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialize) {
      _didInitialize = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PosAppViewModel>().initialize();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PosAppViewModel, PosAuthViewModel>(
      builder: (context, app, auth, _) {
        if (app.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!app.canProceedToLogin) return const PosSetupView();
        if (auth.bartender == null) return const PhonePinLoginView();
        return const PosMainShell();
      },
    );
  }
}

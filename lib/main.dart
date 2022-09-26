import 'dart:developer';

import 'package:commuter/pages/stop_area_page/stop_area_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'pages/home_page/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
  ));

  final client = GraphQLClient(
    link: HttpLink("http://192.168.0.102:3000/graphql"),
    cache: GraphQLCache(),
  );

  runApp(
    ProviderScope(
      child: GraphQLProvider(
        client: ValueNotifier(client),
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: "/",
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: "/stop-area/:ids",
        builder: (context, state) {
          return StopAreaPage(
            ids: state.params["ids"]!.split("."),
            name: (state.extra as Map<String, dynamic>?)?["name"] as String?,
          );
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Commuter",
      routeInformationParser: _router.routeInformationParser,
      routeInformationProvider: _router.routeInformationProvider,
      routerDelegate: _router.routerDelegate,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.red,
        colorScheme: const ColorScheme.light().copyWith(
          secondary: Colors.deepOrange,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.red,
          secondary: Colors.deepOrange,
          surface: Colors.red.shade900,
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.grey.shade900,
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
        navigationBarTheme: const NavigationBarThemeData(
          indicatorColor: Colors.deepOrange,
        ),
      ),
    );
  }
}

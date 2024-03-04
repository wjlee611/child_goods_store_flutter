import 'package:child_goods_store_flutter/blocs/auth/auth_bloc_singleton.dart';
import 'package:child_goods_store_flutter/blocs/auth/auth_event.dart';
import 'package:child_goods_store_flutter/blocs/splash/splash_cubit.dart';
import 'package:child_goods_store_flutter/constants/gaps.dart';
import 'package:child_goods_store_flutter/widgets/app_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterFirstBuild());
  }

  void _afterFirstBuild() {
    context.read<SplashCubit>().setSplash(ESplash.extraData);
  }

  Future<void> _getExtraData() async {
    print('[TEST] Get extra data...');
    await Future.delayed(const Duration(seconds: 1));
    print('[TEST] Get extra data done.');

    // ignore: use_build_context_synchronously
    context.read<SplashCubit>().setSplash(ESplash.getUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BlocConsumer<SplashCubit, ESplash>(
          listener: (context, state) {
            if (state == ESplash.extraData) {
              _getExtraData();
            }
            if (state == ESplash.getUser) {
              AuthBlocSingleton.bloc.add(AuthGetUser());
            }
          },
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                Gaps.v10,
                AppFont(state.text),
              ],
            );
          },
        ),
      ),
    );
  }
}
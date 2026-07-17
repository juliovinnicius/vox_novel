import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/app/app_state.dart';

final class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppState(AppStatus.initial));

  void markReady() {
    if (state.status == AppStatus.ready) {
      return;
    }

    emit(const AppState(AppStatus.ready));
  }
}

enum AppStatus { initial, ready }

final class AppState {
  const AppState(this.status);

  final AppStatus status;
}

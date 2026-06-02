import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  const SettingsState({
    required this.yoloThreshold,
    required this.apiUrl,
    required this.language,
  });

  final double yoloThreshold;
  final String apiUrl;
  final String language; // 'KOR' | 'ENG'

  SettingsState copyWith({
    double? yoloThreshold,
    String? apiUrl,
    String? language,
  }) {
    return SettingsState(
      yoloThreshold: yoloThreshold ?? this.yoloThreshold,
      apiUrl: apiUrl ?? this.apiUrl,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return const SettingsState(
      yoloThreshold: 0.5,
      apiUrl: 'https://api.siren-rag.com',
      language: 'KOR',
    );
  }

  void setYoloThreshold(double value) {
    state = state.copyWith(yoloThreshold: value);
  }

  void setApiUrl(String url) {
    state = state.copyWith(apiUrl: url);
  }

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
  }

  void toggleLanguage() {
    state = state.copyWith(
      language: state.language == 'KOR' ? 'ENG' : 'KOR',
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

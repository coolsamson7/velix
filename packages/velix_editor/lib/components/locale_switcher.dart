import 'package:flutter/material.dart';

class LocaleSwitcher extends StatelessWidget {
  final String currentLocale;
  final Iterable<String> supportedLocales;
  final ValueChanged<String> onLocaleChanged;

  const LocaleSwitcher({
    super.key,
    required this.currentLocale,
    required this.supportedLocales,
    required this.onLocaleChanged,
  });

  // Map locale codes to display info
  static const Map<String, LocaleInfo> _localeInfo = {
    'en': LocaleInfo(
      name: 'English',
      nativeName: 'English',
      flag: '🇬🇧',
      country: 'United Kingdom',
    ),
    'en_US': LocaleInfo(
      name: 'English (US)',
      nativeName: 'English (US)',
      flag: '🇺🇸',
      country: 'United States',
    ),
    'en_GB': LocaleInfo(
      name: 'English (UK)',
      nativeName: 'English (UK)',
      flag: '🇬🇧',
      country: 'United Kingdom',
    ),
    'de': LocaleInfo(
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
      country: 'Germany',
    ),
    'de_DE': LocaleInfo(
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
      country: 'Germany',
    ),
    'fr': LocaleInfo(
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      country: 'France',
    ),
    'es': LocaleInfo(
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
      country: 'Spain',
    ),
    'it': LocaleInfo(
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
      country: 'Italy',
    ),
    'pt': LocaleInfo(
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇵🇹',
      country: 'Portugal',
    ),
    'ja': LocaleInfo(
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
      country: 'Japan',
    ),
    'zh': LocaleInfo(
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
      country: 'China',
    ),
    'ko': LocaleInfo(
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
      country: 'South Korea',
    ),
    'ru': LocaleInfo(
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
      country: 'Russia',
    ),
  };

  LocaleInfo _getLocaleInfo(String locale) {
    return _localeInfo[locale] ?? LocaleInfo(
      name: locale,
      nativeName: locale,
      flag: '🌐',
      country: 'Unknown',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      tooltip: 'Change Language',
      onSelected: onLocaleChanged,
      itemBuilder: (context) {
        return [
          // Header
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select Language',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
              ],
            ),
          ),

          // Locale options
          ...supportedLocales.map((locale) {
            final info = _getLocaleInfo(locale);
            final isSelected = locale == currentLocale;

            return PopupMenuItem<String>(
              value: locale,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Flag
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        info.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Language name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.nativeName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            info.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Check icon
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            );
          }),
        ];
      },
      icon: Icon(
        Icons.language,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class LocaleInfo {
  final String name;
  final String nativeName;
  final String flag;
  final String country;

  const LocaleInfo({
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.country,
  });
}

// Example usage:
class LocaleSwitcherExample extends StatefulWidget {
  const LocaleSwitcherExample({super.key});

  @override
  State<LocaleSwitcherExample> createState() => _LocaleSwitcherExampleState();
}

class _LocaleSwitcherExampleState extends State<LocaleSwitcherExample> {
  String _currentLocale = 'en';
  final List<String> _supportedLocales = ['en', 'en_US', 'de', 'fr', 'es', 'ja'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locale Switcher Demo'),
        actions: [
          // Clean toolbar integration
          LocaleSwitcher(
            currentLocale: _currentLocale,
            supportedLocales: _supportedLocales,
            onLocaleChanged: (locale) {
              setState(() {
                _currentLocale = locale;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language changed to: $locale')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 64),
            const SizedBox(height: 16),
            Text(
              'Current Locale: $_currentLocale',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
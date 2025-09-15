
![License](https://img.shields.io/github/license/coolsamson7/velix)
![Dart](https://img.shields.io/badge/Dart-3.0-blue)
[![Docs](https://img.shields.io/badge/docs-online-blue?logo=github)](https://coolsamson7.github.io/velix/)
[![Flutter CI](https://github.com/coolsamson7/velix/actions/workflows/flutter.yaml/badge.svg)](https://github.com/coolsamson7/velix/actions/workflows/flutter.yaml)

<img width="320" height="320" alt="velix" src="https://github.com/user-attachments/assets/21141c08-9a34-4337-88af-173ad2f044a6" />

# Introduction

Velix is Dart/Flutter library implementing some of the core parts required in every Flutter application:
- type meta data
- specification and validation of type constraints
- general purpose mapping framework
- json mapper
- model-based two-way form data-binding
- i18n
- dependency injection container
- command pattern for ui actions

Check out some articles on Medium:

  - [General purpose mapper](https://medium.com/@andreas.ernst7/velix-introducing-a-powerful-and-expressive-general-purpose-mapping-and-validation-library-e27a56501604)
  - [Commands](https://medium.com/@andreas.ernst7/from-code-to-command-crafting-scalable-and-interceptable-commands-in-flutter-75ed90f136cb)
  - [Model driven Forms](https://medium.com/@andreas.ernst7/model-driven-forms-for-flutter-e0535659489a)


Detailed information can be found in the corresponding [Wiki](https://github.com/coolsamson7/velix/wiki).

# I18N

An i18n is implemented with more or less the same scope and api as popular libraries like `i18next`. but some additional features i haven't found anywhere else.
The solution is made up of two distinct elements.

A `LocaleManager` is responsible to keep track of the current locale.

It is constructed via

```Dart
LocaleManager(this._currentLocale, {List<Locale>? supportedLocales })
```

and can return the current locale via the `locale` property.
Being a `ChangeNotifier` - it can inform listeners about any changes of this property,

`I18N` is a class that is used to configure the setup. The constructor accepts the parameters:
- ` LocaleManager localeManager` the locale manager
- ` TranslationLoader loader` a loader that is used to load localizations
-  `Locale? fallbackLocale` a fallback locale that will be used for missing keys in the main locale.
-  `List<String>? preloadNamespaces` list of namespaces to preload
-  `List<Formatter>? formatters` list of additional fromatter that can be used in the interpolatin process.
-  `int cacheSize = 50` cache size fro prcomputed interpolation fucntions in a LRU cache

After initialization a string extension

```Dart
tr([Map<String,dynamic>? args])
```

can be used to translate keys that consist of a - ":" separated .- namespace and path and optional args.

**Example**

```Dart
"app:main.title".tr()
```

```Dart
"app:main.greeting".tr({"user": "Andi"})
```

Let's look at the different concepts.

## TranslationLoader

The class `TranslationLoader` is used to load translations. 

```Dart
abstract class TranslationLoader {
  /// load translations given a namespace and a list of locales
  /// [locales] list of [Locale]s that determine the overall result. Starting with the first locale, teh resulting map is computed, the following locales will act as fallbacks, in case of missing keys.
  Future<Map<String, dynamic>> load(List<Locale> locales, String namespace);
}
```

The result is a - possibly recursive - map contaning the localizations.

The argument is a list of locales, since we wan't to have a fallback mechanism in case of missing localization values in the main locale. 
This list is computed with the following logic:
- start with the main locale
- if the locale has a country code, continue wioth the language code
- continue with a possible fallback locale
- if the fallback locale has a country code, continue with it's language code

**Example**: Locale is "de_DE", fallback "en_US"

will result in: `["de_DE", "de", "en_US", "en"]`

Loaders should merge an overall result, starting in the order of the list by only adding values in case of missing entries. 

**AssetTranslationOrder**

The class `AssetTranslationOrder` is used to load localizations from assets.

Arguments are:
- `this.basePath = 'assets/locales'` base path for assets
- `Map<String, String>? namespacePackageMap` optional map that assigns package names to namespaces

**Example**

```Dart
{
  "validation": "velix"
}
```

tells the loader, that the namespace "validation" is stored in the assets of teh package "velix".

Translations are stored in json files under the locale dir.

**Example**

```Dart
assets/
   de/
      validation.json
```

## Interpolation

Translations can contain placeholders that will be replaced by supplied values. Different  possibilities exist:

**variable**

"hello {world}!" with arguments `{"world": "world"}` will result in "hello world!".

**variable with format**

"{value:number}"

will format numbers given the current locale ( influencing "," or "." in floating point numbers ) 

**variable with format and arguments**

"{price:currency(name: 'EUR')}"

Different formatters allow different parameters, with all formatters typically supporting `String laccle` as a locale code.

Implemented formatters are:

**number**

- `String locale`
- `int minimumFractionDigits` minimum number of digits
- `int maximumFractionDigits` maximum number of digits

**currency**

- `String locale`
- `String name` name of the currency

**date**

- `String locale`
- `String pattern` pattern accoring to the used formatting class `DateFormat`, e.g. `yMMMd`

Unil now, the parameters where part of the template itself. In order to be more flexible, they can also relate to dynamic parameters by prefixing the with "$".

**Example**:

Template is: "{price:currency(name: $currencyName)"

and is called with the args `{"price": 100, "currencyName": "EUR"}`

## Setup

A typical setup requires to initialize the main elements:

```Dart
 var localeManager = LocaleManager(Locale('en', "EN"), supportedLocales: [Locale('en', "EN"), Locale('de', "DE")]);
  var i18n = I18N(
      fallbackLocale: Locale("en", "EN"),
      localeManager: localeManager,
      loader: AssetTranslationLoader(
        namespacePackageMap: {
          "validation": "velix"
        }
      ),
      missingKeyHandler: (key) => '##$key##',
      preloadNamespaces: ["validation", "example"]
  );

  // load namespaces

  runApp(
    ChangeNotifierProvider.value(
      value: localeManager,
      child: TODOApp(i18n: i18n),
    ),
  );
```

and an application running as a locale consumer including some localizationDelegates:

```Dart
 ...
 child: Consumer<LocaleManager>(
        builder: (BuildContext context, LocaleManager localeManager, Widget? child) {
          return CupertinoApp(
            ...

            // localization

            localizationsDelegates: [I18nDelegate(i18n: i18n), GlobalCupertinoLocalizations.delegate,],
            supportedLocales: localeManager.supportedLocales,
            locale: localeManager.locale
          );
        }
        )
```
 
# Installation

The library is published on [pub.dev](https://pub.dev/packages/velix_i18n )

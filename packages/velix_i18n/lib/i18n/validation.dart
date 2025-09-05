import 'package:velix/validation/validation.dart';

import '../velix_i18n.dart';

class TypeViolationTranslationProvider extends TranslationProvider<TypeViolation> {
  // override

  @override
  String translate(instance) {
    return instance.message.isNotEmpty ?
    instance.message :
    Translator.tr("validation:${instance.type.toString().toLowerCase()}.${instance.name}",
        args: instance.params.map((key, value) => MapEntry(key, value.toString()),
        ));
  }
}
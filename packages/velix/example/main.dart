import 'package:velix/reflectable/reflectable.dart';

import 'main.types.g.dart';

@Dataclass()
class Money {
  // instance data

  @Attribute(type: "maxLength 7")
  final String currency;
  @Attribute(type: "greaterThan 0")
  final int value;

  const Money({required this.currency, required this.value});
}

void main() {
  // register types

  registerAllDescriptors();
  
  // 
  
  var price = Money(currency: "EUR", value: 1);
  
  var type = TypeDescriptor.forType(Money);

  var currency = type.get(price, "currency");
  var value = type.get(price, "value");

  var r = type.constructor!(currency: currency, value: value);
}
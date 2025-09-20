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

  registerTypes();
  
  // create some data
  
  var price = Money(currency: "EUR", value: 1);
  
  var type = TypeDescriptor.forType(Money);

  // call getters

  var currency = type.get(price, "currency");
  var value = type.get(price, "value");

  // call constructor

  var result = type.constructor!(currency: currency, value: -1);

  try {
    type.validate(result);
  }
  catch(e) {
    print(e);
  }
}
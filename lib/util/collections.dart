T? findElement<T>(List<T> list, bool Function(T element) test ) {
  for ( var element in list) {
    if ( test(element)) {
      return element;
    }
  }

  return null;
}

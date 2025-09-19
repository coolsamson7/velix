
import 'dart:async';

import 'package:velix/util/tracer.dart';
import 'package:velix_di/di/di.dart';

/// A simple message bus for pub/sub style communication.
@Injectable(scope: "environment", eager: false)
class MessageBus {
  // instance data

  final _streamController = StreamController<_Message>.broadcast();

  // public

  /// Publish a message on a given topic.
  void publish(String topic, [dynamic data]) {
    if ( Tracer.enabled)
      Tracer.trace("editor.bus", TraceLevel.high, " public '$topic', data=$data (${data.runtimeType}");


    _streamController.add(_Message(topic, data));
  }

  /// Subscribe to a topic.
  StreamSubscription<T> subscribe<T>(String topic, void Function(T) onData) {
    return _streamController.stream
        .where((msg) => msg.topic == topic && msg.data is T)
        .map((msg) => msg.data as T)
        .listen((event) {
      if ( Tracer.enabled)
        Tracer.trace("editor.bus", TraceLevel.high, " deliver '$topic', event=$event");

      onData(event);
    });
  }

  /// Dispose the bus.
  void dispose() {
    _streamController.close();
  }
}

class _Message {
  final String topic;
  final dynamic data;
  _Message(this.topic, this.data);
}
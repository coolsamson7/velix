
import 'dart:async';

import 'package:velix_di/di/di.dart';

/// A simple message bus for pub/sub style communication.
@Injectable(scope: "environment", eager: false)
class MessageBus {
  // instance data

  final _streamController = StreamController<_Message>.broadcast();

  // constructor

  MessageBus() {
    print("MessageBus");
  }

  // public

  /// Publish a message on a given topic.
  void publish(String topic, [dynamic data]) {
    print(
      "[MessageBus] publish: topic=$topic, data=$data (${data.runtimeType})",
    );

    _streamController.add(_Message(topic, data));
  }

  /// Subscribe to a topic.
  StreamSubscription<T> subscribe<T>(String topic, void Function(T) onData) {
    print("[MessageBus] subscribe: topic=$topic, type=$T");

    return _streamController.stream
        .where((msg) => msg.topic == topic && msg.data is T)
        .map((msg) => msg.data as T)
        .listen((event) {
      print("[MessageBus] deliver: topic=$topic, event=$event");
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
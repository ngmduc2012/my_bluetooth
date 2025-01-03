part of '../my_bluetooth.dart';


extension _StreamNewStreamWithInitialValue<T> on Stream<T> {
  Stream<T> newStreamWithInitialValue(T initialValue) {
    return transform(_NewStreamWithInitialValueTransformer(initialValue));
  }
}

extension Byte on String {
  List<int> get stringToBytes => utf8.encode(this);
}

extension MyBluetoothList on List<int>? {
  String get formatListAsHex {
    if (this == null) return '[]';
    // Chuyển đổi từng phần tử thành chuỗi hex và thêm vào danh sách
    List<String> hexList = this!.asMap().entries.map((entry) {
      int index = entry.key;
      int byte = entry.value;
      String hexValue =
          '0x${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}';
      return index >= 8 ? '$index:$hexValue' : hexValue;
    }).toList();

    // Kết hợp các phần tử thành một chuỗi định dạng
    return '[${hexList.join(', ')}]';
  }

  bool matchesInOrder(List<int?> listB) {
    if (this == null) return false;
    if (listB.isEmpty || this!.length < listB.length) return false;

    for (int i = 0; i < listB.length; i++) {
      if (this![i] != listB[i]) {
        return false;
      }
    }
    return true;
  }
  /*convert Ascii To String*/

  String get convertAsciiToString {
    if (this == null) return "";
    StringBuffer sb = StringBuffer();
    for (int value in this!) {
      sb.write(String.fromCharCode(value));
    }
    return sb.toString();
  }

  /*convert Ascii To String 2*/

  String get convertAsciiToString2 {
    if (this == null) return "";
    return ascii.decode(this!);
  }

  /*decode UTF8 To String */

  String get decodeUtf8ToString {
    if (this == null) return "";
   return utf8.decode(this!);
  }

}



// Helper for 'newStreamWithInitialValue' method for streams.
class _NewStreamWithInitialValueTransformer<T>
    extends StreamTransformerBase<T, T> {
  /// the initial value to push to the new stream
  final T initialValue;

  /// controller for the new stream
  late StreamController<T> controller;

  /// subscription to the original stream
  late StreamSubscription<T> subscription;

  /// new stream listener count
  var listenerCount = 0;

  _NewStreamWithInitialValueTransformer(this.initialValue);

  @override
  Stream<T> bind(Stream<T> stream) {
    if (stream.isBroadcast) {
      return _bind(stream, broadcast: true);
    } else {
      return _bind(stream);
    }
  }

  Stream<T> _bind(Stream<T> stream, {bool broadcast = false}) {
    /// Original Stream Subscription Callbacks
    ///

    /// When the original stream emits data, forward it to our new stream
    void onData(T data) {
      controller.add(data);
    }

    /// When the original stream is done, close our new stream
    void onDone() {
      controller.close();
    }

    /// When the original stream has an error, forward it to our new stream
    void onError(Object error) {
      controller.addError(error);
    }

    /// When a client listens to our new stream, emit the
    /// initial value and subscribe to original stream if needed
    void onListen() {
      // Emit the initial value to our new stream
      controller.add(initialValue);

      // listen to the original stream, if needed
      if (listenerCount == 0) {
        subscription = stream.listen(
          onData,
          onError: onError,
          onDone: onDone,
        );
      }

      // count listeners of the new stream
      listenerCount++;
    }

    ///  New Stream Controller Callbacks
    ///

    /// (Single Subscription Only) When a client pauses
    /// the new stream, pause the original stream
    void onPause() {
      subscription.pause();
    }

    /// (Single Subscription Only) When a client resumes
    /// the new stream, resume the original stream
    void onResume() {
      subscription.resume();
    }

    /// Called when a client cancels their
    /// subscription to the new stream,
    void onCancel() {
      // count listeners of the new stream
      listenerCount--;

      // when there are no more listeners of the new stream,
      // cancel the subscription to the original stream,
      // and close the new stream controller
      if (listenerCount == 0) {
        subscription.cancel();
        controller.close();
      }
    }

    /// Return New Stream

    // create a new stream controller
    if (broadcast) {
      controller = StreamController<T>.broadcast(
        onListen: onListen,
        onCancel: onCancel,
      );
    } else {
      controller = StreamController<T>(
        onListen: onListen,
        onPause: onPause,
        onResume: onResume,
        onCancel: onCancel,
      );
    }

    return controller.stream;
  }
}

class BmScanSettings {
  // final List<Guid> withServices;
  // final List<String> withRemoteIds;
  // final List<String> withNames;
  // final List<String> withKeywords;
  // final List<BmMsdFilter> withMsd;
  // final List<BmServiceDataFilter> withServiceData;
  // final bool continuousUpdates;
  // final int continuousDivisor;
  // final int androidScanMode;
  final bool androidUsesFineLocation;

  BmScanSettings({
    // required this.withServices,
    // required this.withRemoteIds,
    // required this.withNames,
    // required this.withKeywords,
    // required this.withMsd,
    // required this.withServiceData,
    // required this.continuousUpdates,
    // required this.continuousDivisor,
    // required this.androidScanMode,
    required this.androidUsesFineLocation,
  });

  Map<dynamic, dynamic> toMap() {
    final Map<dynamic, dynamic> data = {};
    // data['with_services'] = withServices.map((s) => s.str).toList();
    // data['with_remote_ids'] = withRemoteIds;
    // data['with_names'] = withNames;
    // data['with_keywords'] = withKeywords;
    // data['with_msd'] = withMsd.map((d) => d.toMap()).toList();
    // data['with_service_data'] = withServiceData.map((d) => d.toMap()).toList();
    // data['continuous_updates'] = continuousUpdates;
    // data['continuous_divisor'] = continuousDivisor;
    // data['android_scan_mode'] = androidScanMode;
    data['android_uses_fine_location'] = androidUsesFineLocation;
    return data;
  }
}

// ignore: unused_element
Stream<T> _mergeStreams<T>(List<Stream<T>> streams) {
  StreamController<T> controller = StreamController<T>();
  List<StreamSubscription<T>> subscriptions = [];

  void handleData(T data) {
    if (!controller.isClosed) {
      controller.add(data);
    }
  }

  void handleError(Object error, StackTrace stackTrace) {
    if (!controller.isClosed) {
      controller.addError(error, stackTrace);
    }
  }

  void handleDone() {
    for (var s in subscriptions) {
      s.cancel();
    }
    controller.close();
  }

  void subscribeToStream(Stream<T> stream) {
    final s =
        stream.listen(handleData, onError: handleError, onDone: handleDone);
    subscriptions.add(s);
  }

  streams.forEach(subscribeToStream);

  controller.onCancel = () async {
    await Future.wait(subscriptions.map((s) => s.cancel()));
  };

  return controller.stream;
}

// immediately starts listening to a broadcast stream and
// buffering it in a new single-subscription stream
class _BufferStream<T> {
  final Stream<T> _inputStream;
  late final StreamSubscription? _subscription;
  late final StreamController<T> _controller;
  late bool hasReceivedValue = false;

  _BufferStream.listen(this._inputStream) {
    _controller = StreamController<T>(
      onCancel: () {
        _subscription?.cancel();
      },
      onPause: () {
        _subscription?.pause();
      },
      onResume: () {
        _subscription?.resume();
      },
      onListen: () {}, // inputStream is already listened to
    );

    // immediately start listening to the inputStream
    _subscription = _inputStream.listen(
      (data) {
        hasReceivedValue = true;
        _controller.add(data);
      },
      onError: (e) {
        _controller.addError(e);
      },
      onDone: () {
        _controller.close();
      },
      cancelOnError: false,
    );
  }

  void close() {
    _subscription?.cancel();
    _controller.close();
  }

  Stream<T> get stream async* {
    yield* _controller.stream;
  }
}

// This is a reimplementation of BehaviorSubject from RxDart library.
class _StreamControllerReEmit<T> {
  T latestValue;

  final StreamController<T> _controller = StreamController<T>.broadcast();

  _StreamControllerReEmit({required T initialValue})
      : this.latestValue = initialValue;

  Stream<T> get stream {
    if (latestValue != null) {
      return _controller.stream.newStreamWithInitialValue(latestValue!);
    } else {
      return _controller.stream;
    }
  }

  T get value => latestValue;

  void add(T newValue) {
    latestValue = newValue;
    _controller.add(newValue);
  }

  void addError(Object error) {
    _controller.addError(error);
  }

  void listen(Function(T) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    onData(latestValue);
    _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Future<void> close() {
    return _controller.close();
  }
}

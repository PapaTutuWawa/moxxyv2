import "dart:async";

import "package:uuid/uuid.dart";
import "package:meta/meta.dart";
import "package:mutex/mutex.dart";

/// Interface to allow arbitrary data to be sent as long as it can be
/// JSON serialized/deserialized.
class JsonImplementation {
  JsonImplementation();

  Map<String, dynamic> toJson() => {};
  factory JsonImplementation.fromJson(Map<String, dynamic> json) {
    return JsonImplementation();
  }
}

/// Wrapper class that adds an ID to the data packet to be sent.
class DataWrapper<T extends JsonImplementation> {
  final String id;
  final T data;

  const DataWrapper(
    this.id,
    this.data
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "data": data.toJson()
  };

  DataWrapper reply(T newData) => const DataWrapper(id, newData);
}

/// This class is useful in contexts where data is sent between two parties, e.g. the
/// UI and the background service and a correlation between requests and responses is
/// to be enabled.
///
/// awaiting [sendData] will return a [Future] that will resolve to the reresponse when
/// received via [onData].
abstract class AwaitableDataSender<
  S extends JsonImplementation,
  R extends JsonImplementation
> {
  final Mutex _lock;
  final Map<String, Completer<R>> _awaitables;
  final Uuid _uuid;

  AwaitableDataSender() : _awaitables = {}, _uuid = const Uuid(), _lock = Mutex();

  @visibleForTesting
  Map<String, Completer> getAwaitables() => _awaitables;

  @visibleForTesting
  /// Called after an awaitable has been added.
  void onAdd();

  /// NOTE: Must be overwritten by the actual implementation
  @visibleForOverriding
  Future<void> sendDataImpl(DataWrapper data);
  
  /// Sends [data] using [sendDataImpl]. If [awaitable] is true, then a
  /// Future will be returned that can be used to await a response. If it
  /// is false, then null will be imediately resolved.
  Future<R?> sendData(S data, { bool awaitable = true, @visibleForTesting String? id }) async {
    final _id = id ?? _uuid.v4();
    await _lock.protect(() async {
        if (awaitable) {
          _awaitables[_id] = Completer();
          onAdd();
        }
        
        await sendDataImpl(
          DataWrapper<S>(
            _id,
            data
          )
        );
    });

    if (awaitable) {
      return _awaitables[_id]!.future;
    } else {
      return Future.value(null);
    }
  }

  /// Should be called when a [DataWrapper] has been received. Will resolve
  /// the promise received from [sendData].
  Future<bool> onData(DataWrapper<R> data) async {
    bool found = false;
    Completer? completer;
    await _lock.protect(() async {
        completer = _awaitables[data.id];
        if (completer != null) {
          _awaitables.remove(data.id);
          found = true;
        }
    });

    if (found) {
      completer!.complete(data.data);
    }
    
    return found;
  }
}
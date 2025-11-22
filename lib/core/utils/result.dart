/// A Result type for error handling
/// Represents either a success value (Ok) or an error (Err)
sealed class Result<T, E> {
  const Result();
  
  /// Check if this is a success result
  bool get isOk => this is Ok<T, E>;
  
  /// Check if this is an error result
  bool get isErr => this is Err<T, E>;
  
  /// Get the success value or throw if error
  T get value {
    if (this is Ok<T, E>) {
      return (this as Ok<T, E>).value;
    }
    throw StateError('Called value on an Err result');
  }
  
  /// Get the error value or throw if success
  E get error {
    if (this is Err<T, E>) {
      return (this as Err<T, E>).error;
    }
    throw StateError('Called error on an Ok result');
  }
  
  /// Map the success value
  Result<U, E> map<U>(U Function(T) fn) {
    if (this is Ok<T, E>) {
      return Ok(fn((this as Ok<T, E>).value));
    }
    return Err((this as Err<T, E>).error);
  }
  
  /// Map the error value
  Result<T, F> mapErr<F>(F Function(E) fn) {
    if (this is Err<T, E>) {
      return Err(fn((this as Err<T, E>).error));
    }
    return Ok((this as Ok<T, E>).value);
  }
  
  /// Pattern match on the result
  R when<R>({
    required R Function(T) ok,
    required R Function(E) error,
  }) {
    if (this is Ok<T, E>) {
      return ok((this as Ok<T, E>).value);
    }
    return error((this as Err<T, E>).error);
  }
  
  /// Factory constructor for success
  factory Result.ok(T value) => Ok(value);
  
  /// Factory constructor for error
  factory Result.error(E error) => Err(error);
}

/// Success result
class Ok<T, E> extends Result<T, E> {
  final T value;
  
  const Ok(this.value);
  
  @override
  String toString() => 'Ok($value)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ok<T, E> && value == other.value;
  
  @override
  int get hashCode => value.hashCode;
}

/// Error result
class Err<T, E> extends Result<T, E> {
  final E error;
  
  const Err(this.error);
  
  @override
  String toString() => 'Err($error)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Err<T, E> && error == other.error;
  
  @override
  int get hashCode => error.hashCode;
}

/// Extension methods for Result with Exception errors
extension ResultExceptionExtensions<T> on Result<T, Exception> {
  /// Get the value or throw the exception
  T getOrThrow() {
    return when(
      ok: (value) => value,
      error: (error) => throw error,
    );
  }
  
  /// Get the value or return a default
  T getOrDefault(T defaultValue) {
    return when(
      ok: (value) => value,
      error: (_) => defaultValue,
    );
  }
  
  /// Get the value or compute a default from the error
  T getOrElse(T Function(Exception) fn) {
    return when(
      ok: (value) => value,
      error: fn,
    );
  }
}

/// Extension methods for Future<Result>
extension FutureResultExtensions<T, E> on Future<Result<T, E>> {
  /// Convert a Future<Result> to a Future that throws on error
  Future<T> unwrap() async {
    final result = await this;
    if (result.isOk) {
      return result.value;
    }
    throw Exception('Result unwrap failed: ${result.error}');
  }
  
  /// Handle errors in a Future<Result>
  Future<Result<T, E>> catchError(E Function(Object) handler) async {
    try {
      return await this;
    } catch (error) {
      return Err(handler(error));
    }
  }
}

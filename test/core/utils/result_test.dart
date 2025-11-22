import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/core/utils/result.dart';

void main() {
  group('Result', () {
    group('basic functionality', () {
      test('Ok result isOk returns true', () {
        final result = Result<int, String>.ok(42);
        expect(result.isOk, true);
        expect(result.isErr, false);
      });
      
      test('Err result isErr returns true', () {
        final result = Result<int, String>.error('error');
        expect(result.isErr, true);
        expect(result.isOk, false);
      });
      
      test('Ok result returns value', () {
        final result = Result<int, String>.ok(42);
        expect(result.value, 42);
      });
      
      test('Err result returns error', () {
        final result = Result<int, String>.error('error');
        expect(result.error, 'error');
      });
      
      test('Ok result throws on error access', () {
        final result = Result<int, String>.ok(42);
        expect(() => result.error, throwsStateError);
      });
      
      test('Err result throws on value access', () {
        final result = Result<int, String>.error('error');
        expect(() => result.value, throwsStateError);
      });
    });
    
    group('map', () {
      test('map transforms Ok value', () {
        final result = Result<int, String>.ok(42);
        final mapped = result.map((value) => value * 2);
        
        expect(mapped.isOk, true);
        expect(mapped.value, 84);
      });
      
      test('map preserves Err', () {
        final result = Result<int, String>.error('error');
        final mapped = result.map((value) => value * 2);
        
        expect(mapped.isErr, true);
        expect(mapped.error, 'error');
      });
    });
    
    group('mapErr', () {
      test('mapErr transforms Err value', () {
        final result = Result<int, String>.error('error');
        final mapped = result.mapErr((error) => error.toUpperCase());
        
        expect(mapped.isErr, true);
        expect(mapped.error, 'ERROR');
      });
      
      test('mapErr preserves Ok', () {
        final result = Result<int, String>.ok(42);
        final mapped = result.mapErr((error) => error.toUpperCase());
        
        expect(mapped.isOk, true);
        expect(mapped.value, 42);
      });
    });
    
    group('when', () {
      test('when calls ok callback for Ok result', () {
        final result = Result<int, String>.ok(42);
        final output = result.when(
          ok: (value) => 'Value: $value',
          error: (error) => 'Error: $error',
        );
        
        expect(output, 'Value: 42');
      });
      
      test('when calls error callback for Err result', () {
        final result = Result<int, String>.error('failed');
        final output = result.when(
          ok: (value) => 'Value: $value',
          error: (error) => 'Error: $error',
        );
        
        expect(output, 'Error: failed');
      });
    });
    
    group('ResultExceptionExtensions', () {
      test('getOrThrow returns value for Ok', () {
        final result = Result<int, Exception>.ok(42);
        expect(result.getOrThrow(), 42);
      });
      
      test('getOrThrow throws for Err', () {
        final exception = Exception('test error');
        final result = Result<int, Exception>.error(exception);
        expect(() => result.getOrThrow(), throwsA(exception));
      });
      
      test('getOrDefault returns value for Ok', () {
        final result = Result<int, Exception>.ok(42);
        expect(result.getOrDefault(0), 42);
      });
      
      test('getOrDefault returns default for Err', () {
        final result = Result<int, Exception>.error(Exception('error'));
        expect(result.getOrDefault(0), 0);
      });
      
      test('getOrElse returns value for Ok', () {
        final result = Result<int, Exception>.ok(42);
        expect(result.getOrElse((e) => 0), 42);
      });
      
      test('getOrElse computes default for Err', () {
        final result = Result<int, Exception>.error(Exception('error'));
        expect(result.getOrElse((e) => -1), -1);
      });
    });
    
    group('FutureResultExtensions', () {
      test('unwrap returns value for Ok', () async {
        final future = Future.value(Result<int, String>.ok(42));
        final value = await future.unwrap();
        expect(value, 42);
      });
      
      test('unwrap throws for Err', () async {
        final future = Future.value(Result<int, String>.error('error'));
        expect(() => future.unwrap(), throwsA('error'));
      });
      
      test('catchError handles exceptions', () async {
        final future = Future<Result<int, String>>.error('exception');
        final result = await future.catchError((error) => 'caught: $error');
        
        expect(result.isErr, true);
        expect(result.error, 'caught: exception');
      });
    });
    
    group('equality', () {
      test('Ok results with same value are equal', () {
        final result1 = Result<int, String>.ok(42);
        final result2 = Result<int, String>.ok(42);
        
        expect(result1, result2);
        expect(result1.hashCode, result2.hashCode);
      });
      
      test('Err results with same error are equal', () {
        final result1 = Result<int, String>.error('error');
        final result2 = Result<int, String>.error('error');
        
        expect(result1, result2);
        expect(result1.hashCode, result2.hashCode);
      });
      
      test('Ok and Err results are not equal', () {
        final result1 = Result<int, String>.ok(42);
        final result2 = Result<int, String>.error('error');
        
        expect(result1, isNot(result2));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:documind_ai/core/utils/vector_utils.dart';

void main() {
  group('VectorUtils - cosineSimilarity Tests', () {
    test('Vectors of different lengths should throw ArgumentError', () {
      final a = [1.0, 2.0];
      final b = [1.0, 2.0, 3.0];
      expect(() => VectorUtils.cosineSimilarity(a, b), throwsArgumentError);
    });

    test('Identical vectors should have a similarity of 1.0', () {
      final a = [1.0, 0.0, 5.0];
      final b = [1.0, 0.0, 5.0];
      final similarity = VectorUtils.cosineSimilarity(a, b);
      expect(similarity, closeTo(1.0, 1e-9));
    });

    test('Opposite vectors should have a similarity of -1.0', () {
      final a = [1.0, -1.0, 2.0];
      final b = [-1.0, 1.0, -2.0];
      final similarity = VectorUtils.cosineSimilarity(a, b);
      expect(similarity, closeTo(-1.0, 1e-9));
    });

    test('Orthogonal vectors should have a similarity of 0.0', () {
      final a = [1.0, 0.0];
      final b = [0.0, 1.0];
      final similarity = VectorUtils.cosineSimilarity(a, b);
      expect(similarity, closeTo(0.0, 1e-9));
    });

    test('Vectors with zero norms should return 0.0 to prevent division by zero', () {
      final a = [0.0, 0.0];
      final b = [1.0, 2.0];
      final similarity1 = VectorUtils.cosineSimilarity(a, b);
      final similarity2 = VectorUtils.cosineSimilarity(b, a);
      final similarity3 = VectorUtils.cosineSimilarity(a, a);
      
      expect(similarity1, equals(0.0));
      expect(similarity2, equals(0.0));
      expect(similarity3, equals(0.0));
    });

    test('Standard similarity calculation verification', () {
      // a = [3.0, 4.0] (norm = 5.0)
      // b = [4.0, 3.0] (norm = 5.0)
      // dotProduct = 12.0 + 12.0 = 24.0
      // expected = 24.0 / 25.0 = 0.96
      final a = [3.0, 4.0];
      final b = [4.0, 3.0];
      final similarity = VectorUtils.cosineSimilarity(a, b);
      expect(similarity, closeTo(0.96, 1e-9));
    });
  });
}

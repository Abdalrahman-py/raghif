import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Pixel goldens are rasterised by the machine's own Skia/font stack, so the
/// same commit can render a few pixels differently on different CI runners —
/// `store_list_screen.png` flipped between green and red on byte-identical
/// trees with 0.002–0.005% diffs (56–135px out of 1080×2400).
///
/// This keeps the golden (and its "did I break the layout?" job) but ignores
/// noise: a real layout change is orders of magnitude bigger than
/// [maxDiffPercent].
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.maxDiffPercent = 0.1});

  /// Largest accepted difference, as a percentage of the image's pixels
  /// (the underlying `diffPercent` is a 0–1 fraction).
  final double maxDiffPercent;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed) {
      result.dispose();
      return true;
    }

    final bool withinTolerance = result.diffPercent * 100 <= maxDiffPercent;
    result.dispose();
    if (withinTolerance) return true;

    // Real difference: let the default comparator throw with its usual
    // "Pixel test failed …" output.
    return super.compare(imageBytes, golden);
  }
}

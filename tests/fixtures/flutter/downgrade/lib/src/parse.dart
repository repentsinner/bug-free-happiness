// The test does not import this file, so on the downgrade leg only the
// analyzer fails and the tests still pass.
import 'package:fixnum/fixnum.dart';

/// [text] as a 64-bit integer, or null when it is not one.
Int64? parse(String text) => Int64.tryParseInt(text);

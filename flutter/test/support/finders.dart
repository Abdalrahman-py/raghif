import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:raghif/core/widgets/labeled_field.dart';

/// The text input under a [LabeledField] whose visible label is [label].
Finder fieldByLabel(String label) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(LabeledField),
      ),
      matching: find.byType(TextField),
    );

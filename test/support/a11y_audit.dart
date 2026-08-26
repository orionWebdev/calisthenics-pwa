import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ein einzelner Verstoß im Semantics-Baum.
class A11yViolation {
  A11yViolation(this.kind, this.rect, this.label);

  final String kind;
  final Rect rect;
  final String label;

  @override
  String toString() {
    final size = '${rect.width.toStringAsFixed(0)}x'
        '${rect.height.toStringAsFixed(0)}';
    final at = '@${rect.left.toStringAsFixed(0)},'
        '${rect.top.toStringAsFixed(0)}';
    return '$kind  $size $at  ${label.isEmpty ? '(ohne Label)' : '"$label"'}';
  }
}

/// Zählt **alle** Verstöße im Semantics-Baum.
///
/// Die eingebauten Guidelines (`androidTapTargetGuideline`,
/// `labeledTapTargetGuideline`) brechen beim ersten Treffer ab. Für ein
/// Schuldenverzeichnis brauchen wir die vollständige Liste, deshalb dieser
/// eigene Durchlauf.
List<A11yViolation> auditSemantics(
  WidgetTester tester, {
  double minTapSize = 48.0,
}) {
  final violations = <A11yViolation>[];

  // pipelineOwner ist seit 3.10 veraltet; der dokumentierte Ersatz ist der
  // Baum ab rootPipelineOwner.
  // Achtung: rootPipelineOwner besitzt selbst einen SemanticsOwner, aber der
  // eigentliche Baum hängt an einem Kind. Wer nur auf `!= null` prüft, greift
  // den falschen und zählt stumm null Verstöße.
  SemanticsOwner? owner;
  void findOwner(PipelineOwner o) {
    if (owner == null && o.semanticsOwner?.rootSemanticsNode != null) {
      owner = o.semanticsOwner;
    }
    o.visitChildren(findOwner);
  }

  findOwner(tester.binding.rootPipelineOwner);
  final root = owner?.rootSemanticsNode;
  if (root == null) return violations;

  void visit(SemanticsNode node, Matrix4 parentTransform) {
    final transform =
        parentTransform.multiplied(node.transform ?? Matrix4.identity());
    final rect = MatrixUtils.transformRect(transform, node.rect);
    final data = node.getSemanticsData();

    final isTappable = data.hasAction(SemanticsAction.tap) ||
        data.hasAction(SemanticsAction.longPress);

    if (isTappable) {
      if (rect.width < minTapSize || rect.height < minTapSize) {
        violations.add(A11yViolation('tap-target', rect, data.label));
      }
      if (data.label.trim().isEmpty && data.tooltip.trim().isEmpty) {
        violations.add(A11yViolation('label', rect, ''));
      }
    }

    node.visitChildren((child) {
      visit(child, transform);
      return true;
    });
  }

  visit(root, Matrix4.identity());
  return violations;
}

/// Verdichtet eine Verstoßliste auf Zahlen je Art.
Map<String, int> countByKind(List<A11yViolation> violations) {
  final counts = <String, int>{};
  for (final v in violations) {
    counts[v.kind] = (counts[v.kind] ?? 0) + 1;
  }
  return counts;
}

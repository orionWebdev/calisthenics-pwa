import 'plan.dart';

abstract interface class PlanRepository {
  Stream<List<Plan>> watchPlans(String userId);
  Future<List<Plan>> fetchPlans(String userId);
}

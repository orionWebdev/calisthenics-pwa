import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/firestore_plan_repository.dart';
import '../domain/plan.dart';
import '../domain/plan_repository.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return FirestorePlanRepository(FirebaseFirestore.instance);
});

final plansProvider = StreamProvider<List<Plan>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(planRepositoryProvider).watchPlans(userId);
});

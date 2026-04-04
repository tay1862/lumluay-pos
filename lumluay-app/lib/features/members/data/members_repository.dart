import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class Member {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final double totalSpent;
  final int totalVisits;
  final DateTime? createdAt;

  const Member({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.totalSpent = 0,
    this.totalVisits = 0,
    this.createdAt,
  });

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        totalSpent: (j['totalSpent'] as num?)?.toDouble() ?? 0,
        totalVisits: (j['totalVisits'] as num?)?.toInt() ?? 0,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
      );
}

class MembersRepository {
  const MembersRepository(this._api);
  final ApiClient _api;

  Future<List<Member>> getMembers({String? search}) async {
    final resp = await _api.get('/members',
        queryParameters: {if (search != null && search.isNotEmpty) 'search': search});
    final list = resp is List ? resp : (resp is Map ? (resp['data'] as List? ?? []) : []);
    return list
        .map((e) => Member.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Member> createMember(Map<String, dynamic> data) async {
    final resp = await _api.post('/members', data: data);
    return Member.fromJson(resp as Map<String, dynamic>);
  }

  Future<Member> updateMember(String id, Map<String, dynamic> data) async {
    final resp = await _api.patch('/members/$id', data: data);
    return Member.fromJson(resp as Map<String, dynamic>);
  }

  Future<void> deleteMember(String id) async {
    await _api.delete('/members/$id');
  }
}

final membersRepositoryProvider = Provider<MembersRepository>(
  (ref) => MembersRepository(ref.watch(apiClientProvider)),
);

final membersSearchProvider = StateProvider<String>((ref) => '');

final membersListProvider = FutureProvider<List<Member>>((ref) {
  final search = ref.watch(membersSearchProvider);
  return ref.watch(membersRepositoryProvider).getMembers(search: search);
});

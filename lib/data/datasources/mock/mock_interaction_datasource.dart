import '../../models/enums.dart';
import '../../models/interaction.dart';
import '../contracts.dart';

/// In-memory mock used only when [AppConfig.useMockData] is true.
class MockInteractionDataSource implements InteractionDataSource {
  final List<FarmerInteraction> _items = [];

  @override
  Future<List<FarmerInteraction>> listMine({
    String? search,
    InteractionStatus? status,
  }) async {
    var items = List<FarmerInteraction>.from(_items);
    if (status != null) {
      items = items.where((e) => e.status == status).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      items = items
          .where(
            (e) =>
                e.farmerName.toLowerCase().contains(q) ||
                e.phoneNumber.contains(q) ||
                e.landLocation.toLowerCase().contains(q),
          )
          .toList();
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<FarmerInteraction> create(CreateInteractionRequest request) async {
    final now = DateTime.now();
    final item = FarmerInteraction(
      id: 'mock-${now.millisecondsSinceEpoch}',
      executiveId: 'mock-exec',
      farmerName: request.farmerName,
      phoneNumber: request.phoneNumber,
      landLocation: request.landLocation,
      acres: request.acres,
      currentCrop: request.currentCrop,
      plannedMonths: request.plannedMonths,
      status: request.status,
      notes: request.notes,
      createdAt: now,
      updatedAt: now,
    );
    _items.insert(0, item);
    return item;
  }

  @override
  Future<FarmerInteraction> update(
    String id,
    UpdateInteractionRequest request,
  ) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) {
      throw StateError('Interaction not found');
    }
    final current = _items[index];
    final updated = FarmerInteraction(
      id: current.id,
      executiveId: current.executiveId,
      farmerName: request.farmerName ?? current.farmerName,
      phoneNumber: request.phoneNumber ?? current.phoneNumber,
      landLocation: request.landLocation ?? current.landLocation,
      acres: request.acres ?? current.acres,
      currentCrop: request.currentCrop ?? current.currentCrop,
      plannedMonths: request.plannedMonths ?? current.plannedMonths,
      status: request.status ?? current.status,
      notes: request.notes ?? current.notes,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<FarmerInteraction?> getById(String id) async {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

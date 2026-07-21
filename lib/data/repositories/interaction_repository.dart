import '../datasources/contracts.dart';
import '../models/enums.dart';
import '../models/interaction.dart';

class InteractionRepository {
  InteractionRepository(this._dataSource);

  final InteractionDataSource _dataSource;

  Future<List<FarmerInteraction>> listMine({
    String? search,
    InteractionStatus? status,
  }) =>
      _dataSource.listMine(search: search, status: status);

  Future<FarmerInteraction> create(CreateInteractionRequest request) =>
      _dataSource.create(request);

  Future<FarmerInteraction> update(
    String id,
    UpdateInteractionRequest request,
  ) =>
      _dataSource.update(id, request);

  Future<FarmerInteraction?> getById(String id) => _dataSource.getById(id);
}

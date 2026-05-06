import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignupUseCase {
  final AuthRepository repository;

  SignupUseCase(this.repository);

  Future<UserEntity?> execute(String name, String email, String password, String role) async {
    return await repository.signup(name, email, password, role);
  }
}

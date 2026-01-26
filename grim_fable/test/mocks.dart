import 'package:mockito/annotations.dart';
import 'package:grim_fable/features/character/character_repository.dart';
import 'package:grim_fable/features/adventure/adventure_repository.dart';
import 'package:grim_fable/core/services/ai_service.dart';

@GenerateMocks([CharacterRepository, AdventureRepository, AIService])
void main() {}

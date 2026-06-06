Create a new exercise type for Ta'allam: $ARGUMENTS

Steps:
1. Add the new type to the ExerciseType enum in lib/features/lesson/domain/exercise_model.dart
2. Run: dart run build_runner build --delete-conflicting-outputs
3. Create lib/features/lesson/presentation/widgets/exercise_$ARGUMENTS.dart following this pattern:
   - StatefulWidget accepting (ExerciseModel exercise, void Function(bool) onAnswered)
   - Arabic text always wrapped in Directionality(textDirection: TextDirection.rtl)
   - FilledButton 'যাচাই করুন' disabled until answer selected
   - Show correct/wrong feedback using AppColors.correctBg / AppColors.wrongBg
4. Add a case in lib/features/lesson/presentation/widgets/exercise_engine.dart
5. Add the type to the CHECK constraint in a new Supabase migration
6. Update the SYSTEM_PROMPT in supabase/functions/process-content/index.ts so Gemini generates this type
7. git add + commit + push all files

JSON shape for correct_answer must be documented in a comment at the top of the widget file.

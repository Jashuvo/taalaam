Add a new Drift table column or Supabase schema field: $ARGUMENTS

Steps:
1. Add the column to the relevant table in lib/data/local/tables/
2. Bump schemaVersion by 1 in lib/data/local/database.dart
3. Add a migration case in the onUpgrade callback (ALTER TABLE ... ADD COLUMN ... DEFAULT ...)
4. Run: dart run build_runner build --delete-conflicting-outputs
5. Create a new SQL migration file in supabase/migrations/ (next number in sequence)
6. Run: supabase db push --linked
7. Update the Drift model's fromJson/toJson if needed (remember: camelCase keys in fromJson)
8. git add + commit + push

Check the current schemaVersion in database.dart before starting.

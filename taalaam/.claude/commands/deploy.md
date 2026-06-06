Deploy the edge function named: $ARGUMENTS

Steps:
1. Read the current file at supabase/functions/$ARGUMENTS/index.ts
2. Check for any obvious bugs (missing corsHeaders, no try/catch wrapper, missing AbortController on fetch calls)
3. Run: supabase functions deploy $ARGUMENTS --no-verify-jwt
4. Confirm deployment succeeded
5. git add + commit + push the function file

Always deploy with --no-verify-jwt since all functions do their own auth checks.

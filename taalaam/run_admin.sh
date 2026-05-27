#!/bin/bash
# Admin panel — http://localhost:8081
cd "$(dirname "$0")"

flutter run -d chrome -t lib/main_admin.dart \
  --web-port 8081 \
  --dart-define=SUPABASE_URL=https://xborpnxbdvstiabtevix.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhib3JwbnhiZHZzdGlhYnRldml4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MTk2MTcsImV4cCI6MjA5NTM5NTYxN30.idjyzlfd7RT_0csJkiI-AVPjlwJ4-dBCjvT9rM44yD4

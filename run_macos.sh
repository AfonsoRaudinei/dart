#!/bin/bash
# Script de execução SoloForte — macOS (Desktop Dev)
# Use este script para rodar no seu MacBook.

flutter run \
  -d macos \
  --dart-define=SUPABASE_URL=https://pyoejhhkjlrjijiviryq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5b2VqaGhramxyamlqaXZpcnlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNTI1MDQsImV4cCI6MjA2OTcyODUwNH0.2P5wKq7b6viMa9kutLOZADsqAvSZx6X8fbLZMlooG1U \
  --dart-define=ENV=development

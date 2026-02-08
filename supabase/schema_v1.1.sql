-- Create visit_sessions table
CREATE TABLE visit_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  sync_status TEXT NOT NULL DEFAULT 'pending',
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create occurrences table
CREATE TABLE occurrences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  visit_session_id UUID REFERENCES visit_sessions(id) ON DELETE SET NULL,
  geometry JSONB NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'pending',
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for visit_sessions
CREATE INDEX idx_visit_sessions_user_id ON visit_sessions(user_id);
CREATE INDEX idx_visit_sessions_sync_status ON visit_sessions(sync_status);
CREATE INDEX idx_visit_sessions_updated_at ON visit_sessions(updated_at);

-- Create indexes for occurrences
CREATE INDEX idx_occurrences_user_id ON occurrences(user_id);
CREATE INDEX idx_occurrences_visit_session_id ON occurrences(visit_session_id);
CREATE INDEX idx_occurrences_sync_status ON occurrences(sync_status);
CREATE INDEX idx_occurrences_updated_at ON occurrences(updated_at);
CREATE INDEX idx_occurrences_geometry ON occurrences USING GIN(geometry);

-- Enable RLS on visit_sessions
ALTER TABLE visit_sessions ENABLE ROW LEVEL SECURITY;

-- Enable RLS on occurrences
ALTER TABLE occurrences ENABLE ROW LEVEL SECURITY;

-- RLS policy for visit_sessions: users can only access their own records
CREATE POLICY visit_sessions_user_policy ON visit_sessions
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- RLS policy for occurrences: users can only access their own records
CREATE POLICY occurrences_user_policy ON occurrences
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Occurrences: vínculo opcional de cliente (alinhado ao app local v28)
ALTER TABLE occurrences
ADD COLUMN IF NOT EXISTS client_id UUID NULL REFERENCES clients(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_occurrences_client_id ON occurrences(client_id);

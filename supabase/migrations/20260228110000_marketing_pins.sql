CREATE TABLE IF NOT EXISTS marketing_pins (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_produto  TEXT NOT NULL,
  imagem_url    TEXT NOT NULL,
  roi_percent   NUMERIC(5,2) NOT NULL,
  plano         TEXT NOT NULL CHECK (plano IN ('ouro', 'prata', 'bronze')),
  lat           NUMERIC(10,7) NOT NULL,
  lng           NUMERIC(10,7) NOT NULL,
  ativo         BOOLEAN NOT NULL DEFAULT true,
  criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
  expira_em     TIMESTAMPTZ
);

ALTER TABLE marketing_pins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public read" ON marketing_pins
  FOR SELECT USING (ativo = true AND (expira_em IS NULL OR expira_em > now()));

-- Insert mock data
INSERT INTO marketing_pins (nome_produto, imagem_url, roi_percent, plano, lat, lng, ativo) VALUES
('Semente Top Vigor', 'https://picsum.photos/seed/semente/200', 12.5, 'ouro', -23.5505, -46.6333, true),
('Adubo Fosfatado', 'https://picsum.photos/seed/adubo/200', 8.0, 'prata', -23.5555, -46.6383, true),
('Trator 4x4', 'https://picsum.photos/seed/trator/200', 15.2, 'ouro', -23.5605, -46.6433, true),
('Herbicida Eficaz', 'https://picsum.photos/seed/herbicida/200', 5.5, 'bronze', -23.5455, -46.6283, true);

# ingest-soil-analysis

Endpoint server-to-server para o bridge do Caderno de Solo.

Deploy sem verificacao JWT do gateway, pois a funcao valida
`x-integration-key` pelo hash SHA-256 armazenado em
`public.external_analysis_integrations`:

```bash
supabase functions deploy ingest-soil-analysis --no-verify-jwt
```

O bridge envia `external_analysis_id`, o UUID real de `public.clients.id`,
`analysis_payload`, `updated_at`, coordenadas opcionais e `deleted_at` opcional.
`user_id` e `external_source` nunca sao aceitos como autoridade do request.

Exemplo de corpo:

```json
{
  "external_analysis_id": "analysis-123",
  "client_id": "11111111-1111-4111-8111-111111111111",
  "latitude": -10.25,
  "longitude": -48.32,
  "updated_at": "2026-06-21T12:00:00Z",
  "analysis_payload": {
    "laboratorio": "identificador-fornecido-pela-origem",
    "resultados": {}
  }
}
```

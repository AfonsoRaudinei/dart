import { Buffer } from "node:buffer";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type GeoJsonGeometry = {
  type: string;
  coordinates: unknown;
};

function isGeoJsonGeometry(value: unknown): value is GeoJsonGeometry {
  return (
    typeof value === "object" &&
    value !== null &&
    typeof (value as { type?: unknown }).type === "string" &&
    Array.isArray((value as { coordinates?: unknown }).coordinates)
  );
}

function bboxFromGeometry(geometry: GeoJsonGeometry): number[] | null {
  const values: number[] = [];
  const walk = (node: unknown) => {
    if (Array.isArray(node)) {
      if (
        node.length >= 2 &&
        typeof node[0] === "number" &&
        typeof node[1] === "number"
      ) {
        values.push(node[0], node[1]);
        return;
      }
      for (const child of node) walk(child);
    }
  };
  walk(geometry.coordinates);

  if (values.length < 2) return null;

  let minLon = Infinity;
  let minLat = Infinity;
  let maxLon = -Infinity;
  let maxLat = -Infinity;

  for (let i = 0; i < values.length; i += 2) {
    const lon = values[i];
    const lat = values[i + 1];
    if (lon < minLon) minLon = lon;
    if (lat < minLat) minLat = lat;
    if (lon > maxLon) maxLon = lon;
    if (lat > maxLat) maxLat = lat;
  }

  return [minLon, minLat, maxLon, maxLat];
}

/// Extensão geográfica da saída. Geometry, quando existe, só mascara.
function sentinelProcessBounds(
  bbox: number[],
  geometry?: GeoJsonGeometry,
) {
  const bounds: {
    bbox: number[];
    geometry?: GeoJsonGeometry;
    properties: { crs: string };
  } = {
    bbox,
    properties: {
      crs: "http://www.opengis.net/def/crs/EPSG/0/4326",
    },
  };
  if (geometry) bounds.geometry = geometry;
  return bounds;
}

/// Lado maior = maxSide. Proporção em graus, a mesma do LatLngBounds do card.
function outputSizeForBbox(
  bbox: number[],
  maxSide: number,
): { width: number; height: number } {
  const lonSpan = Math.max(bbox[2] - bbox[0], 1e-9);
  const latSpan = Math.max(bbox[3] - bbox[1], 1e-9);
  if (lonSpan >= latSpan) {
    return {
      width: maxSide,
      height: Math.max(1, Math.round(maxSide * (latSpan / lonSpan))),
    };
  }
  return {
    height: maxSide,
    width: Math.max(1, Math.round(maxSide * (lonSpan / latSpan))),
  };
}

// ── Evalscript amostra NDVI (UINT8) para estatísticas ───────────────────────
const NDVI_STATS_SAMPLE_EVALSCRIPT = `
//VERSION=3
function setup() {
  return { input: ["B04", "B08", "dataMask"], output: { bands: 1 } };
}
function evaluatePixel(sample) {
  if (sample.dataMask === 0) return [255];
  const denom = sample.B08 + sample.B04;
  if (denom === 0) return [255];
  let ndvi = (sample.B08 - sample.B04) / denom;
  ndvi = Math.max(-0.2, Math.min(1, ndvi));
  return [Math.round(((ndvi + 0.2) / 1.2) * 254)];
}
`;

type NdviStats = {
  ndviMin: number;
  ndviMax: number;
  ndviMean: number;
};

function decodeNdviFromEncodedByte(encoded: number): number | null {
  if (encoded >= 255) return null;
  return (encoded / 254) * 1.2 - 0.2;
}

function statsFromSamplePixels(data: Uint8Array): NdviStats | null {
  const values: number[] = [];
  for (let i = 0; i < data.length; i += 4) {
    const ndvi = decodeNdviFromEncodedByte(data[i]);
    if (ndvi == null) continue;
    values.push(ndvi);
  }
  if (values.length === 0) return null;
  const sum = values.reduce((acc, value) => acc + value, 0);
  return {
    ndviMin: Math.min(...values),
    ndviMax: Math.max(...values),
    ndviMean: sum / values.length,
  };
}

// ── Evalscript NDVI com colormap RdYlGn (Sentinel Hub) ──────────────────────
const NDVI_EVALSCRIPT = `
//VERSION=3
function setup() {
  return { input: ["B04", "B08", "dataMask"], output: { bands: 4 } };
}
function evaluatePixel(sample) {
  let ndvi = (sample.B08 - sample.B04) / (sample.B08 + sample.B04);
  if (sample.B08 + sample.B04 === 0) return [0.2, 0.2, 0.2, sample.dataMask];
  if (ndvi < 0)   return [0.5, 0.0, 0.0, sample.dataMask];
  if (ndvi < 0.2) return [1.0, 0.3, 0.0, sample.dataMask];
  if (ndvi < 0.4) return [1.0, 0.8, 0.0, sample.dataMask];
  if (ndvi < 0.6) return [0.6, 0.9, 0.2, sample.dataMask];
  return [0.1, 0.6, 0.1, sample.dataMask];
}
`;

const COMMERCIAL_API_BASE = "https://services.sentinel-hub.com/api/v1";
const CDSE_API_BASE = "https://sh.dataspace.copernicus.eu/api/v1";

type SentinelBackendId = "commercial" | "cdse";

type SentinelBackendConfig = {
  id: SentinelBackendId;
  apiBase: string;
  tokenUrl: string;
  clientId: string;
  clientSecret: string;
  staticToken: string;
};

/** Revisita Sentinel-2 ~5 dias; órbitas vizinhas podem cruzar em 1–2 dias. */
const SENTINEL_REVISIT_WINDOW_DAYS = 5;

type SentinelSceneCandidate = { date: string; cloudCover: number };

function sentinelSceneCloudCover(properties: Record<string, unknown>): number {
  const value = properties["eo:cloud_cover"];
  return typeof value === "number" ? value : 100;
}

function daysBetweenIsoDates(a: string, b: string): number {
  const msA = Date.parse(`${a}T12:00:00Z`);
  const msB = Date.parse(`${b}T12:00:00Z`);
  return Math.abs(msA - msB) / 86_400_000;
}

/** Uma cena por janela de revisita — menor `eo:cloud_cover`. */
function thinSentinelDatesByRevisit(
  candidates: SentinelSceneCandidate[],
): string[] {
  if (candidates.length === 0) return [];
  const sorted = [...candidates].sort((a, b) => b.date.localeCompare(a.date));
  const selected: SentinelSceneCandidate[] = [];

  for (const candidate of sorted) {
    const neighborIndex = selected.findIndex(
      (picked) =>
        daysBetweenIsoDates(picked.date, candidate.date) <
        SENTINEL_REVISIT_WINDOW_DAYS,
    );
    if (neighborIndex === -1) {
      selected.push(candidate);
      continue;
    }
    if (candidate.cloudCover < selected[neighborIndex].cloudCover) {
      selected[neighborIndex] = candidate;
    }
  }

  return selected
    .map((item) => item.date)
    .sort((a, b) => b.localeCompare(a));
}

// ── Sentinel Hub: buscar datas disponíveis ───────────────────────────────────
async function fetchSentinelDates(
  apiBase: string,
  bbox: number[],
  token: string,
  fromDate: string,
  toDate: string
): Promise<{ dates: string[]; catalogOk: boolean }> {
  const body = {
    bbox: bbox,
    datetime: `${fromDate}T00:00:00Z/${toDate}T23:59:59Z`,
    collections: ["sentinel-2-l2a"],
    limit: 50,
    filter: "eo:cloud_cover < 80",
    "filter-lang": "cql2-text",
  };

  const res = await fetch(`${apiBase}/catalog/1.0.0/search`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    console.error("Sentinel catalog error:", await res.text());
    return { dates: [], catalogOk: false };
  }

  const data = await res.json();
  const candidates: SentinelSceneCandidate[] = [];
  for (const feature of data.features ?? []) {
    const props = feature.properties as Record<string, unknown> | undefined;
    const dt = props?.datetime as string | undefined;
    if (!dt) continue;
    candidates.push({
      date: dt.substring(0, 10),
      cloudCover: sentinelSceneCloudCover(props ?? {}),
    });
  }
  const dates = thinSentinelDatesByRevisit(candidates);
  return {
    dates,
    catalogOk: true,
  };
}

// ── Sentinel Hub: buscar imagem NDVI em PNG base64 ──────────────────────────
async function fetchSentinelImage(
  apiBase: string,
  bbox: number[],
  token: string,
  date: string,
  geometry?: GeoJsonGeometry,
  cloudCoverageMax = 80
): Promise<{ base64: string; cloudCoverage: number } | null> {
  const bounds = sentinelProcessBounds(bbox, geometry);
  const size = outputSizeForBbox(bbox, 512);

  const body = {
    input: {
      bounds,
      data: [
        {
          type: "sentinel-2-l2a",
          dataFilter: {
            timeRange: {
              from: `${date}T00:00:00Z`,
              to: `${date}T23:59:59Z`,
            },
            maxCloudCoverage: cloudCoverageMax,
          },
        },
      ],
    },
    output: {
      width: size.width,
      height: size.height,
      responses: [
        {
          identifier: "default",
          format: { type: "image/png" },
        },
      ],
    },
    evalscript: NDVI_EVALSCRIPT,
  };

  const res = await fetch(`${apiBase}/process`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    console.error("Sentinel Hub process error:", await res.text());
    return null;
  }

  const buffer = await res.arrayBuffer();
  const bytes = new Uint8Array(buffer);
  const binary = bytes.reduce((acc, byte) => acc + String.fromCharCode(byte), "");
  const base64 = btoa(binary);

  return { base64, cloudCoverage: 0 };
}

async function fetchSentinelNdviStats(
  apiBase: string,
  bbox: number[],
  token: string,
  date: string,
  geometry?: GeoJsonGeometry,
  cloudCoverageMax = 80
): Promise<NdviStats | null> {
  const bounds = sentinelProcessBounds(bbox, geometry);
  const size = outputSizeForBbox(bbox, 48);

  const body = {
    input: {
      bounds,
      data: [
        {
          type: "sentinel-2-l2a",
          dataFilter: {
            timeRange: {
              from: `${date}T00:00:00Z`,
              to: `${date}T23:59:59Z`,
            },
            maxCloudCoverage: cloudCoverageMax,
          },
        },
      ],
    },
    output: {
      width: size.width,
      height: size.height,
      responses: [
        {
          identifier: "default",
          format: { type: "image/png" },
        },
      ],
    },
    evalscript: NDVI_STATS_SAMPLE_EVALSCRIPT,
  };

  const res = await fetch(`${apiBase}/process`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    console.error("Sentinel Hub stats error:", await res.text());
    return null;
  }

  try {
    const bytes = new Uint8Array(await res.arrayBuffer());
    const { PNG } = await import("npm:pngjs@7.0.0");
    // pngjs expects Node Buffer; Uint8Array alone breaks sync.read (readUInt32BE).
    const png = PNG.sync.read(Buffer.from(bytes));
    return statsFromSamplePixels(png.data);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Sentinel Hub stats PNG parse error:", message);
    return null;
  }
}

// ── Planet: buscar datas disponíveis ────────────────────────────────────────
async function fetchPlanetDates(
  bbox: number[],
  apiKey: string,
  fromDate: string,
  toDate: string
): Promise<string[]> {
  const geometry = {
    type: "Polygon",
    coordinates: [[
      [bbox[0], bbox[1]],
      [bbox[2], bbox[1]],
      [bbox[2], bbox[3]],
      [bbox[0], bbox[3]],
      [bbox[0], bbox[1]],
    ]],
  };

  const body = {
    item_types: ["PSScene"],
    filter: {
      type: "AndFilter",
      config: [
        {
          type: "GeometryFilter",
          field_name: "geometry",
          config: geometry,
        },
        {
          type: "DateRangeFilter",
          field_name: "acquired",
          config: { gte: `${fromDate}T00:00:00Z`, lte: `${toDate}T23:59:59Z` },
        },
        {
          type: "RangeFilter",
          field_name: "cloud_cover",
          config: { lte: 0.8 },
        },
      ],
    },
  };

  const encoded = btoa(`${apiKey}:`);
  const res = await fetch("https://api.planet.com/data/v1/quick-search", {
    method: "POST",
    headers: {
      Authorization: `Basic ${encoded}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) return [];

  const data = await res.json();
  const dates: string[] = [];
  for (const feature of data.features ?? []) {
    const dt = feature.properties?.acquired as string | undefined;
    if (dt) dates.push(dt.substring(0, 10));
  }
  return [...new Set(dates)].sort((a, b) => b.localeCompare(a));
}

// ── Planet: buscar thumbnail de item específico ──────────────────────────────
async function fetchPlanetThumbnail(
  bbox: number[],
  apiKey: string,
  date: string
): Promise<string | null> {
  const geometry = {
    type: "Polygon",
    coordinates: [[
      [bbox[0], bbox[1]],
      [bbox[2], bbox[1]],
      [bbox[2], bbox[3]],
      [bbox[0], bbox[3]],
      [bbox[0], bbox[1]],
    ]],
  };

  const body = {
    item_types: ["PSScene"],
    filter: {
      type: "AndFilter",
      config: [
        { type: "GeometryFilter", field_name: "geometry", config: geometry },
        {
          type: "DateRangeFilter",
          field_name: "acquired",
          config: {
            gte: `${date}T00:00:00Z`,
            lte: `${date}T23:59:59Z`,
          },
        },
        { type: "RangeFilter", field_name: "cloud_cover", config: { lte: 0.8 } },
      ],
    },
  };

  const encoded = btoa(`${apiKey}:`);
  const searchRes = await fetch("https://api.planet.com/data/v1/quick-search", {
    method: "POST",
    headers: {
      Authorization: `Basic ${encoded}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!searchRes.ok) return null;
  const searchData = await searchRes.json();
  const firstItem = searchData.features?.[0];
  if (!firstItem) return null;

  const thumbnailUrl =
    firstItem._links?.thumbnail ?? firstItem.links?.find((l: { rel: string; href: string }) => l.rel === "thumbnail")?.href;
  if (!thumbnailUrl) return null;

  const imgRes = await fetch(thumbnailUrl, {
    headers: { Authorization: `Basic ${encoded}` },
  });
  if (!imgRes.ok) return null;

  const buffer = await imgRes.arrayBuffer();
  const bytes = new Uint8Array(buffer);
  const binary = bytes.reduce((acc, byte) => acc + String.fromCharCode(byte), "");
  return btoa(binary);
}

type SentinelTokenCache = { token: string; expiresAtMs: number };
const sentinelTokenCaches = new Map<SentinelBackendId, SentinelTokenCache>();

function buildSentinelBackendConfigs(): SentinelBackendConfig[] {
  const preference = (Deno.env.get("NDVI_SENTINEL_PROVIDER") ?? "auto")
    .toLowerCase();

  const commercial: SentinelBackendConfig = {
    id: "commercial",
    apiBase: COMMERCIAL_API_BASE,
    tokenUrl:
      "https://services.sentinel-hub.com/auth/realms/main/protocol/openid-connect/token",
    clientId:
      Deno.env.get("SENTINEL_HUB_CLIENT_ID") ??
      Deno.env.get("SENTINEL_API_USER_ID") ??
      "",
    clientSecret: Deno.env.get("SENTINEL_HUB_CLIENT_SECRET") ?? "",
    staticToken:
      Deno.env.get("SENTINEL_HUB_TOKEN") ??
      Deno.env.get("SENTINEL_HUB_API_KEY") ??
      "",
  };
  if (!commercial.clientSecret) {
    commercial.clientSecret = Deno.env.get("SENTINEL_API_TOKEN") ?? "";
  }

  const cdse: SentinelBackendConfig = {
    id: "cdse",
    apiBase: CDSE_API_BASE,
    tokenUrl:
      "https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token",
    clientId: Deno.env.get("CDSE_CLIENT_ID") ?? "",
    clientSecret: Deno.env.get("CDSE_CLIENT_SECRET") ?? "",
    staticToken: "",
  };

  const isConfigured = (cfg: SentinelBackendConfig) =>
    (cfg.clientId.trim() && cfg.clientSecret.trim()) || cfg.staticToken.trim();

  const ordered: SentinelBackendConfig[] = [];
  const pushIfConfigured = (cfg: SentinelBackendConfig) => {
    if (isConfigured(cfg)) ordered.push(cfg);
  };

  if (preference === "cdse") {
    pushIfConfigured(cdse);
    pushIfConfigured(commercial);
  } else if (preference === "commercial") {
    pushIfConfigured(commercial);
    pushIfConfigured(cdse);
  } else if (cdse.clientId && cdse.clientSecret) {
    pushIfConfigured(cdse);
    pushIfConfigured(commercial);
  } else {
    pushIfConfigured(commercial);
    pushIfConfigured(cdse);
  }

  return ordered;
}

async function resolveAccessTokenForBackend(
  cfg: SentinelBackendConfig,
): Promise<{ token: string | null; authError: string | null }> {
  const clientId = cfg.clientId.trim();
  const clientSecret = cfg.clientSecret.trim();
  const staticToken = cfg.staticToken.trim();

  if (clientId && clientSecret) {
    const now = Date.now();
    const cached = sentinelTokenCaches.get(cfg.id);
    if (cached && cached.expiresAtMs > now + 60_000) {
      return { token: cached.token, authError: null };
    }

    const res = await fetch(cfg.tokenUrl, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "client_credentials",
        client_id: clientId,
        client_secret: clientSecret,
      }),
    });

    if (!res.ok) {
      const detail = await res.text();
      console.error(`Sentinel OAuth error (${cfg.id}):`, detail);
      if (staticToken) {
        return {
          token: staticToken,
          authError: `${cfg.id}_oauth_failed_using_static`,
        };
      }
      return { token: null, authError: `${cfg.id}_oauth_failed` };
    }

    const data = await res.json();
    const accessToken = data.access_token as string | undefined;
    if (!accessToken) {
      return {
        token: staticToken || null,
        authError: `${cfg.id}_oauth_empty_token`,
      };
    }
    const expiresIn = (data.expires_in as number) ?? 3600;
    sentinelTokenCaches.set(cfg.id, {
      token: accessToken,
      expiresAtMs: now + expiresIn * 1000,
    });
    return { token: accessToken, authError: null };
  }

  if (staticToken) {
    return { token: staticToken, authError: null };
  }

  return { token: null, authError: `${cfg.id}_credentials_missing` };
}

type SentinelFetchAttempt = {
  imageBase64: string | null;
  availableDates: string[];
  finalDate: string;
  ndviMin: number;
  ndviMax: number;
  ndviMean: number;
  cloudCoverage: number;
  degradedReason: string | null;
};

async function trySentinelBackends(
  backends: SentinelBackendConfig[],
  bbox: number[],
  geometry: GeoJsonGeometry | undefined,
  fromDate: string,
  toDate: string,
  requestedDate: string | undefined,
  defaultDate: string,
): Promise<SentinelFetchAttempt> {
  let lastReason: string | null = backends.length === 0
    ? "sentinel_credentials_missing"
    : null;

  for (const backend of backends) {
    const { token, authError } = await resolveAccessTokenForBackend(backend);
    if (!token) {
      lastReason = authError;
      continue;
    }

    const catalog = await fetchSentinelDates(
      backend.apiBase,
      bbox,
      token,
      fromDate,
      toDate,
    );

    if (!catalog.catalogOk) {
      lastReason = `${backend.id}_catalog_failed`;
      continue;
    }
    if (catalog.dates.length === 0) {
      lastReason = `${backend.id}_no_scenes`;
      continue;
    }

    const finalDate = requestedDate
      ? (catalog.dates.includes(requestedDate)
        ? requestedDate
        : catalog.dates[0])
      : catalog.dates[0];

    const result = await fetchSentinelImage(
      backend.apiBase,
      bbox,
      token,
      finalDate,
      geometry,
    );
    if (!result) {
      lastReason = `${backend.id}_process_failed`;
      continue;
    }

    let ndviMin = 0;
    let ndviMax = 0;
    let ndviMean = 0;
    const stats = await fetchSentinelNdviStats(
      backend.apiBase,
      bbox,
      token,
      finalDate,
      geometry,
    );
    if (stats) {
      ndviMin = stats.ndviMin;
      ndviMax = stats.ndviMax;
      ndviMean = stats.ndviMean;
    }

    return {
      imageBase64: result.base64,
      availableDates: catalog.dates,
      finalDate,
      ndviMin,
      ndviMax,
      ndviMean,
      cloudCoverage: result.cloudCoverage,
      degradedReason: null,
    };
  }

  return {
    imageBase64: null,
    availableDates: [],
    finalDate: defaultDate,
    ndviMin: 0,
    ndviMax: 0,
    ndviMean: 0,
    cloudCoverage: 0,
    degradedReason: lastReason,
  };
}

// ── Handler principal ────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método não permitido." }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    // ── 1. Parse e validação do body ────────────────────────────────────────
    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return new Response(
        JSON.stringify({ error: "Body JSON inválido." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const areaId = body.area_id as string | undefined;
    const geometry = isGeoJsonGeometry(body.geometry) ? body.geometry : undefined;
    const bodyBbox = body.bbox as number[] | undefined;
    const bbox = bodyBbox && bodyBbox.length === 4
      ? bodyBbox
      : geometry
        ? bboxFromGeometry(geometry)
        : null;
    const requestedDate = body.date as string | undefined;
    const source = (body.source as string | undefined) ?? "auto";

    if (!areaId || !bbox || bbox.length !== 4) {
      return new Response(
        JSON.stringify({ error: "area_id e bbox ou geometry são obrigatórios." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ── 2. Leitura de secrets ───────────────────────────────────────────────
    const sentinelBackends = buildSentinelBackendConfigs();
    const planetApiKey = Deno.env.get("PLANET_API_KEY") ?? "";
    let sentinelDegradedReason: string | null = null;

    // ── 3. Janela de datas: últimos 90 dias ────────────────────────────────
    const today = new Date();
    const toDate = today.toISOString().substring(0, 10);
    const fromDateObj = new Date(today);
    fromDateObj.setDate(fromDateObj.getDate() - 90);
    const fromDate = fromDateObj.toISOString().substring(0, 10);

    let imageBase64: string | null = null;
    let usedSource = "sentinel";
    let cloudCoverage = 0;
    let availableDates: string[] = [];
    let finalDate = requestedDate ?? toDate;
    let ndviMin = 0;
    let ndviMax = 0;
    let ndviMean = 0;

    // ── 4. Sentinel Hub / CDSE (primária) ───────────────────────────────────
    if (source === "sentinel" || source === "auto") {
      const attempt = await trySentinelBackends(
        sentinelBackends,
        bbox,
        geometry,
        fromDate,
        toDate,
        requestedDate,
        finalDate,
      );
      if (attempt.imageBase64) {
        imageBase64 = attempt.imageBase64;
        availableDates = attempt.availableDates;
        finalDate = attempt.finalDate;
        ndviMin = attempt.ndviMin;
        ndviMax = attempt.ndviMax;
        ndviMean = attempt.ndviMean;
        cloudCoverage = attempt.cloudCoverage;
        usedSource = "sentinel";
      } else {
        sentinelDegradedReason = attempt.degradedReason;
        if (attempt.availableDates.length > 0) {
          availableDates = attempt.availableDates;
        }
      }
    }

    // ── 5. Fallback: Planet (preview RGB — nao e NDVI) ─────────────────────
    if (!imageBase64 && (source === "planet" || source === "auto") && planetApiKey) {
      usedSource = "planet_preview";
      if (!sentinelDegradedReason && sentinelBackends.length === 0) {
        sentinelDegradedReason = "sentinel_credentials_missing";
      }
      const planetDates = await fetchPlanetDates(bbox, planetApiKey, fromDate, toDate);

      if (availableDates.length === 0) availableDates = planetDates;

      if (planetDates.length > 0) {
        finalDate = requestedDate
          ? (planetDates.includes(requestedDate) ? requestedDate : planetDates[0])
          : planetDates[0];
        imageBase64 = await fetchPlanetThumbnail(bbox, planetApiKey, finalDate);
      }
    }

    // ── 6. Resposta ─────────────────────────────────────────────────────────
    if (!imageBase64) {
      return new Response(
        JSON.stringify({
          error: "no_images_available",
          message: "Nenhuma imagem disponível para esta área e período.",
          sentinel_degraded_reason: sentinelDegradedReason,
        }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const responseBody = {
      area_id: areaId,
      date: finalDate,
      source: usedSource,
      is_ndvi: usedSource === "sentinel",
      image_base64: imageBase64,
      available_dates: availableDates,
      cloud_coverage: cloudCoverage,
      ndvi_min: ndviMin,
      ndvi_max: ndviMax,
      ndvi_mean: ndviMean,
      sentinel_degraded_reason: usedSource === "planet_preview"
        ? sentinelDegradedReason
        : null,
    };

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Erro interno.";
    console.error("ndvi-fetch error:", message);
    return new Response(
      JSON.stringify({ error: "internal_error", message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

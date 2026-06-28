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

// ── Sentinel Hub: buscar datas disponíveis ───────────────────────────────────
async function fetchSentinelDates(
  bbox: number[],
  token: string,
  fromDate: string,
  toDate: string
): Promise<string[]> {
  const body = {
    bbox: bbox,
    datetime: `${fromDate}T00:00:00Z/${toDate}T23:59:59Z`,
    collections: ["sentinel-2-l2a"],
    limit: 20,
    filter: "eo:cloud_cover < 80",
    "filter-lang": "cql2-text",
  };

  const res = await fetch(
    "https://services.sentinel-hub.com/api/v1/catalog/1.0.0/search",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    }
  );

  if (!res.ok) return [];

  const data = await res.json();
  const dates: string[] = [];
  for (const feature of data.features ?? []) {
    const dt = feature.properties?.datetime as string | undefined;
    if (dt) dates.push(dt.substring(0, 10));
  }
  // Deduplica e ordena decrescente
  return [...new Set(dates)].sort((a, b) => b.localeCompare(a));
}

// ── Sentinel Hub: buscar imagem NDVI em PNG base64 ──────────────────────────
async function fetchSentinelImage(
  bbox: number[],
  token: string,
  date: string,
  geometry?: GeoJsonGeometry,
  cloudCoverageMax = 80
): Promise<{ base64: string; cloudCoverage: number } | null> {
  const bounds = geometry
    ? {
        geometry,
        properties: {
          crs: "http://www.opengis.net/def/crs/EPSG/0/4326",
        },
      }
    : {
        bbox,
        properties: {
          crs: "http://www.opengis.net/def/crs/EPSG/0/4326",
        },
      };

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
      width: 512,
      height: 512,
      responses: [
        {
          identifier: "default",
          format: { type: "image/png" },
        },
      ],
    },
    evalscript: NDVI_EVALSCRIPT,
  };

  const res = await fetch(
    "https://services.sentinel-hub.com/api/v1/process",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    }
  );

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
  bbox: number[],
  token: string,
  date: string,
  geometry?: GeoJsonGeometry,
  cloudCoverageMax = 80
): Promise<NdviStats | null> {
  const bounds = geometry
    ? {
        geometry,
        properties: {
          crs: "http://www.opengis.net/def/crs/EPSG/0/4326",
        },
      }
    : {
        bbox,
        properties: {
          crs: "http://www.opengis.net/def/crs/EPSG/0/4326",
        },
      };

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
      width: 48,
      height: 48,
      responses: [
        {
          identifier: "default",
          format: { type: "image/png" },
        },
      ],
    },
    evalscript: NDVI_STATS_SAMPLE_EVALSCRIPT,
  };

  const res = await fetch(
    "https://services.sentinel-hub.com/api/v1/process",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    }
  );

  if (!res.ok) {
    console.error("Sentinel Hub stats error:", await res.text());
    return null;
  }

  const bytes = new Uint8Array(await res.arrayBuffer());
  const { PNG } = await import("npm:pngjs@7.0.0");
  const png = PNG.sync.read(bytes);
  return statsFromSamplePixels(png.data);
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
    // Suporta tanto SENTINEL_HUB_TOKEN quanto SENTINEL_HUB_API_KEY (alias)
    const sentinelToken =
      Deno.env.get("SENTINEL_HUB_TOKEN") ??
      Deno.env.get("SENTINEL_HUB_API_KEY") ??
      "";
    const planetApiKey = Deno.env.get("PLANET_API_KEY") ?? "";

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

    // ── 4. Sentinel Hub (primária) ─────────────────────────────────────────
    if ((source === "sentinel" || source === "auto") && sentinelToken) {
      availableDates = await fetchSentinelDates(bbox, sentinelToken, fromDate, toDate);

      if (availableDates.length > 0) {
        finalDate = requestedDate
          ? (availableDates.includes(requestedDate) ? requestedDate : availableDates[0])
          : availableDates[0];

        const result = await fetchSentinelImage(bbox, sentinelToken, finalDate, geometry);
        if (result) {
          imageBase64 = result.base64;
          cloudCoverage = result.cloudCoverage;
          usedSource = "sentinel";
          const stats = await fetchSentinelNdviStats(
            bbox,
            sentinelToken,
            finalDate,
            geometry,
          );
          if (stats) {
            ndviMin = stats.ndviMin;
            ndviMax = stats.ndviMax;
            ndviMean = stats.ndviMean;
          }
        }
      }
    }

    // ── 5. Fallback: Planet (preview RGB — nao e NDVI) ─────────────────────
    if (!imageBase64 && (source === "planet" || source === "auto") && planetApiKey) {
      usedSource = "planet_preview";
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

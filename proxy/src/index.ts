/**
 * gym-app-image-proxy — Cloudflare Worker
 *
 * Routes food image generation requests through this server-side proxy
 * so the OpenAI API key never exists inside the iOS/macOS client bundle.
 *
 * Required secrets (set via `wrangler secret put`):
 *   OPENAI_API_KEY — OpenAI key, stored only in Cloudflare's environment
 *   APP_TOKEN      — shared token validated in the X-App-Token request header
 *
 * Required binding (configured in wrangler.toml):
 *   RATE_LIMITER — Cloudflare Workers Rate Limiting binding (per Cloudflare location)
 *
 * Endpoint:
 *   POST /v1/image-generation
 *   Headers: X-App-Token: <APP_TOKEN>
 *   Body:    { "prompt": string, "requestID": string }
 *   200 OK:  { "imageData": string (base64), "mimeType": string, "promptUsed": string }
 *   400:     { "error": { "code": string, "message": string } }
 *   401:     { "error": { "code": string, "message": string } }
 *   429:     { "error": { "code": string, "message": string } }
 *   5xx:     { "error": { "code": string, "message": string } }
 */

// Cloudflare Workers Rate Limiting binding interface.
// Provided by the platform at runtime — enforcement is per Cloudflare location,
// not a single globally shared counter across all locations.
interface RateLimiter {
  limit(options: { key: string }): Promise<{ success: boolean }>;
}

export interface Env {
  OPENAI_API_KEY: string;
  APP_TOKEN: string;
  RATE_LIMITER: RateLimiter;
}

interface ClientRequest {
  prompt?: string;
  requestID?: string;
}

interface OpenAIImageItem {
  b64_json: string;
  revised_prompt?: string;
}

interface OpenAIResponse {
  data?: OpenAIImageItem[];
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // 1. Method + path
    if (request.method !== "POST" || url.pathname !== "/v1/image-generation") {
      return jsonError(404, "not_found", "Not Found");
    }

    // 2. X-App-Token authentication
    const appToken = request.headers.get("X-App-Token");
    if (!appToken || appToken !== env.APP_TOKEN) {
      return jsonError(401, "unauthorized", "Unauthorized");
    }

    // 3. Parse request body
    let body: ClientRequest;
    try {
      body = (await request.json()) as ClientRequest;
    } catch {
      return jsonError(400, "invalid_request", "Invalid JSON body");
    }

    // 4. Prompt validation
    if (typeof body.prompt !== "string") {
      return jsonError(400, "invalid_prompt", "Prompt must be a string");
    }
    const prompt = body.prompt.trim();
    if (!prompt) {
      return jsonError(400, "invalid_prompt", "Prompt is required and cannot be empty");
    }
    // Check raw length before trimming to prevent padding exploits
    if (body.prompt.length > 1000) {
      return jsonError(400, "prompt_too_long", "Prompt must be 1000 characters or fewer");
    }

    // 5. Rate limiting — Cloudflare Workers Rate Limiting binding (per location).
    // env.RATE_LIMITER.limit() enforces the limit per Cloudflare location;
    // this is NOT a single global counter. See wrangler.toml [[ratelimits]] RATE_LIMITER.
    // CF-Connecting-IP is set by Cloudflare to the real client IP on every
    // production request and cannot be spoofed by the client. In `wrangler dev`
    // it may be absent; "unknown" is used as a fallback bucket for local dev only.
    const clientIP = request.headers.get("CF-Connecting-IP") ?? "unknown";
    const { success } = await env.RATE_LIMITER.limit({ key: clientIP });
    if (!success) {
      return jsonError(429, "rate_limited", "Too many requests. Please try again later.");
    }

    // 6. Forward to OpenAI
    let openaiRes: Response;
    try {
      openaiRes = await fetch("https://api.openai.com/v1/images/generations", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${env.OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: "dall-e-3",
          prompt,
          n: 1,
          size: "1024x1024",
          quality: "standard",
          response_format: "b64_json",
        }),
      });
    } catch {
      return jsonError(502, "upstream_error", "Failed to reach image service");
    }

    if (!openaiRes.ok) {
      if (openaiRes.status === 401) {
        return jsonError(500, "service_failure", "Image service configuration error");
      }
      if (openaiRes.status === 429) {
        return jsonError(503, "service_failure", "Service temporarily unavailable");
      }
      return jsonError(502, "service_failure", "Image generation failed");
    }

    const openaiData = (await openaiRes.json()) as OpenAIResponse;
    const item = openaiData?.data?.[0];

    if (!item?.b64_json) {
      return jsonError(502, "service_failure", "Empty response from image service");
    }

    return new Response(
      JSON.stringify({
        imageData: item.b64_json,
        mimeType: "image/png",
        promptUsed: item.revised_prompt ?? prompt,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  },
};

function jsonError(status: number, code: string, message: string): Response {
  return new Response(JSON.stringify({ error: { code, message } }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

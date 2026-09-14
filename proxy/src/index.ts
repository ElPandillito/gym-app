/**
 * gym-app-image-proxy — Cloudflare Worker
 *
 * Routes food image generation requests through this server-side proxy
 * so the OpenAI API key never exists inside the iOS/macOS client bundle.
 *
 * Required secret (set via `wrangler secret put OPENAI_API_KEY`):
 *   OPENAI_API_KEY — your OpenAI key, stored only in Cloudflare's environment
 *
 * Endpoint:
 *   POST /v1/image-generation
 *   Body:    { "prompt": string, "requestID": string }
 *   200 OK:  { "imageData": string (base64), "mimeType": string, "promptUsed": string }
 *   400:     { "error": { "code": string, "message": string } }
 *   5xx:     { "error": { "code": string, "message": string } }
 */

export interface Env {
  OPENAI_API_KEY: string;
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

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method !== "POST" || url.pathname !== "/v1/image-generation") {
      return jsonError(404, "not_found", "Not Found");
    }

    // Parse request body
    let body: ClientRequest;
    try {
      body = (await request.json()) as ClientRequest;
    } catch {
      return jsonError(400, "invalid_request", "Invalid JSON body");
    }

    const prompt = body.prompt?.trim();
    if (!prompt) {
      return jsonError(400, "invalid_prompt", "Prompt is required and cannot be empty");
    }

    // Forward to OpenAI
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
        // Key misconfiguration — don't expose details to client
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

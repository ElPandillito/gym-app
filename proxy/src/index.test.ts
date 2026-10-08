// @ts-nocheck — vitest globals and Node.js types intentionally override workers-types here
import { describe, test, expect, beforeEach, vi } from "vitest";
import worker from "./index";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const VALID_TOKEN = "test-app-token";
const BASE_URL = "https://test.example.com";

const SUCCESS_OPENAI_BODY = JSON.stringify({
  data: [
    {
      b64_json: Buffer.from("fake-image-bytes").toString("base64"),
      revised_prompt: "A bowl of steamed rice",
    },
  ],
});

// Creates a fresh rate limiter mock that counts per-IP and allows up to 10/min.
// NOTE: The actual 10 req/min enforcement in production is done by Cloudflare's
// infrastructure per location, not by this counter. These tests verify that our
// Worker code correctly calls env.RATE_LIMITER.limit() and respects its { success }
// response. Per-location enforcement can only be validated in a real deployment.
function createCountingRateLimiter() {
  const counts = new Map<string, number>();
  // Pass the implementation directly to vi.fn() — this sets a default
  // implementation that is NOT cleared by vi.restoreAllMocks().
  return {
    limit: vi.fn(({ key }: { key: string }) => {
      const n = (counts.get(key) ?? 0) + 1;
      counts.set(key, n);
      return Promise.resolve({ success: n <= 10 });
    }),
  };
}

let rateLimiterMock = createCountingRateLimiter();
let mockEnv = {
  OPENAI_API_KEY: "test-openai-key",
  APP_TOKEN: VALID_TOKEN,
  RATE_LIMITER: rateLimiterMock,
};

beforeEach(() => {
  // Restore stubs (vi.stubGlobal etc.) from the previous test first,
  // then create fresh mocks so restoreAllMocks doesn't clear them.
  vi.restoreAllMocks();
  rateLimiterMock = createCountingRateLimiter();
  mockEnv = {
    OPENAI_API_KEY: "test-openai-key",
    APP_TOKEN: VALID_TOKEN,
    RATE_LIMITER: rateLimiterMock,
  };
});

function makeRequest(opts: {
  method?: string;
  path?: string;
  token?: string | null;
  body?: Record<string, unknown>;
  ip?: string;
  extraHeaders?: Record<string, string>;
}): Request {
  const {
    method = "POST",
    path = "/v1/image-generation",
    token = VALID_TOKEN,
    body = { prompt: "A bowl of rice", requestID: "test-id-123" },
    ip = "1.2.3.4",
    extraHeaders = {},
  } = opts;

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "CF-Connecting-IP": ip,
    ...extraHeaders,
  };
  if (token !== null) {
    headers["X-App-Token"] = token;
  }

  return new Request(`${BASE_URL}${path}`, {
    method,
    headers,
    body: JSON.stringify(body),
  });
}

function mockOpenAISuccess(): void {
  // Use mockImplementation (not mockResolvedValue) so each call gets a fresh
  // Response instance — a Response body stream can only be read once.
  vi.stubGlobal(
    "fetch",
    vi.fn().mockImplementation(() =>
      Promise.resolve(
        new Response(SUCCESS_OPENAI_BODY, {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
      )
    )
  );
}

// ---------------------------------------------------------------------------
// Authentication
// ---------------------------------------------------------------------------

describe("Authentication", () => {
  test("missing X-App-Token → 401", async () => {
    const res = await worker.fetch(makeRequest({ token: null }), mockEnv);
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.error.code).toBe("unauthorized");
  });

  test("wrong X-App-Token → 401", async () => {
    const res = await worker.fetch(
      makeRequest({ token: "definitely-wrong-token" }),
      mockEnv
    );
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.error.code).toBe("unauthorized");
  });

  test("401 response does not reveal token value or hint at existence", async () => {
    const res = await worker.fetch(makeRequest({ token: "wrong" }), mockEnv);
    const text = await res.text();
    expect(text).not.toContain(VALID_TOKEN);
    expect(text).not.toContain("APP_TOKEN");
  });

  test("correct X-App-Token → proceeds to processing (200)", async () => {
    mockOpenAISuccess();
    const res = await worker.fetch(makeRequest({ token: VALID_TOKEN }), mockEnv);
    expect(res.status).toBe(200);
  });
});

// ---------------------------------------------------------------------------
// Prompt validation
// ---------------------------------------------------------------------------

describe("Prompt validation", () => {
  test("prompt exactly 1000 chars → accepted (200)", async () => {
    mockOpenAISuccess();
    const req = makeRequest({ body: { prompt: "A".repeat(1000), requestID: "t" } });
    const res = await worker.fetch(req, mockEnv);
    expect(res.status).toBe(200);
  });

  test("prompt 1001 chars → 400 with prompt_too_long", async () => {
    const req = makeRequest({ body: { prompt: "A".repeat(1001), requestID: "t" } });
    const res = await worker.fetch(req, mockEnv);
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error.code).toBe("prompt_too_long");
  });

  test("empty prompt → 400", async () => {
    const req = makeRequest({ body: { prompt: "", requestID: "t" } });
    const res = await worker.fetch(req, mockEnv);
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error.code).toBe("invalid_prompt");
  });

  test("whitespace-only prompt → 400", async () => {
    const req = makeRequest({ body: { prompt: "   ", requestID: "t" } });
    const res = await worker.fetch(req, mockEnv);
    expect(res.status).toBe(400);
  });

  test("non-string prompt (number) → 400, OpenAI not called, rate limiter not called", async () => {
    const mockFetch = vi.fn();
    vi.stubGlobal("fetch", mockFetch);
    const limitSpy = vi.fn();
    const env = { ...mockEnv, RATE_LIMITER: { limit: limitSpy } };

    const req = makeRequest({ body: { prompt: 123, requestID: "t" } });
    const res = await worker.fetch(req, env);

    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error.code).toBe("invalid_prompt");
    expect(mockFetch).not.toHaveBeenCalled();
    expect(limitSpy).not.toHaveBeenCalled();
  });
});

// ---------------------------------------------------------------------------
// Rate limiting — Cloudflare Workers Rate Limiting binding
//
// These tests verify Worker code behaviour relative to the binding's decisions.
// The actual per-location enforcement is done by Cloudflare's platform and can
// only be validated in a real deployment.
// ---------------------------------------------------------------------------

describe("Rate limiting", () => {
  test("first 10 requests from same IP → all allowed (binding returns success:true)", async () => {
    mockOpenAISuccess();
    for (let i = 0; i < 10; i++) {
      const res = await worker.fetch(makeRequest({ ip: "10.0.0.1" }), mockEnv);
      expect(res.status).toBe(200);
    }
    expect(rateLimiterMock.limit).toHaveBeenCalledTimes(10);
  });

  test("11th request from same IP → 429 rate_limited (binding returns success:false)", async () => {
    mockOpenAISuccess();
    for (let i = 0; i < 10; i++) {
      await worker.fetch(makeRequest({ ip: "10.0.0.1" }), mockEnv);
    }
    const res = await worker.fetch(makeRequest({ ip: "10.0.0.1" }), mockEnv);
    expect(res.status).toBe(429);
    const json = await res.json();
    expect(json.error.code).toBe("rate_limited");
  });

  test("different IPs have independent rate limit buckets", async () => {
    mockOpenAISuccess();
    for (let i = 0; i < 10; i++) {
      await worker.fetch(makeRequest({ ip: "10.0.0.1" }), mockEnv);
    }
    // IP A is exhausted — IP B should still succeed
    const res = await worker.fetch(makeRequest({ ip: "10.0.0.2" }), mockEnv);
    expect(res.status).toBe(200);
  });

  test("window reset — binding returning success:true again allows request", async () => {
    // Simulate: first call rate-limited, second call allowed (window expired)
    const limitMock = vi.fn()
      .mockResolvedValueOnce({ success: false })   // rate limited
      .mockResolvedValue({ success: true });        // window reset → allowed
    const env = { ...mockEnv, RATE_LIMITER: { limit: limitMock } };

    const blocked = await worker.fetch(makeRequest({ ip: "10.0.0.3" }), env);
    expect(blocked.status).toBe(429);

    mockOpenAISuccess();
    const allowed = await worker.fetch(makeRequest({ ip: "10.0.0.3" }), env);
    expect(allowed.status).toBe(200);
  });

  test("binding is called with CF-Connecting-IP as key, not X-Forwarded-For", async () => {
    // An attacker may send X-Forwarded-For to try to bypass rate limiting.
    // The Worker must use CF-Connecting-IP (set by Cloudflare, not by the client).
    mockOpenAISuccess();
    const limitSpy = vi.fn().mockResolvedValue({ success: true });
    const env = { ...mockEnv, RATE_LIMITER: { limit: limitSpy } };

    const req = makeRequest({
      ip: "10.0.0.1",
      extraHeaders: { "X-Forwarded-For": "1.1.1.1" },
    });
    await worker.fetch(req, env);

    expect(limitSpy).toHaveBeenCalledWith({ key: "10.0.0.1" });
    expect(limitSpy).not.toHaveBeenCalledWith({ key: "1.1.1.1" });
  });

  test("rate limiter not called on auth failure — saves infrastructure cost", async () => {
    const limitSpy = vi.fn();
    const env = { ...mockEnv, RATE_LIMITER: { limit: limitSpy } };
    await worker.fetch(makeRequest({ token: null }), env);
    expect(limitSpy).not.toHaveBeenCalled();
  });

  test("rate limiter not called on invalid prompt", async () => {
    const limitSpy = vi.fn();
    const env = { ...mockEnv, RATE_LIMITER: { limit: limitSpy } };
    await worker.fetch(
      makeRequest({ body: { prompt: "A".repeat(1001), requestID: "t" } }),
      env
    );
    expect(limitSpy).not.toHaveBeenCalled();
  });
});

// ---------------------------------------------------------------------------
// Existing success contract
// ---------------------------------------------------------------------------

describe("Success contract", () => {
  test("valid request returns correct response shape", async () => {
    mockOpenAISuccess();
    const res = await worker.fetch(makeRequest({}), mockEnv);
    expect(res.status).toBe(200);
    expect(res.headers.get("Content-Type")).toBe("application/json");

    const json = await res.json();
    expect(typeof json.imageData).toBe("string");
    expect(json.mimeType).toBe("image/png");
    expect(typeof json.promptUsed).toBe("string");
  });

  test("auth validation runs before OpenAI — no upstream call on 401", async () => {
    const mockFetch = vi.fn();
    vi.stubGlobal("fetch", mockFetch);

    await worker.fetch(makeRequest({ token: null }), mockEnv);
    expect(mockFetch).not.toHaveBeenCalled();
  });

  test("prompt validation runs before OpenAI — no upstream call on 400", async () => {
    const mockFetch = vi.fn();
    vi.stubGlobal("fetch", mockFetch);

    await worker.fetch(
      makeRequest({ body: { prompt: "A".repeat(1001), requestID: "t" } }),
      mockEnv
    );
    expect(mockFetch).not.toHaveBeenCalled();
  });

  test("rate limit rejection runs before OpenAI — no upstream call on 429", async () => {
    const mockFetch = vi.fn();
    vi.stubGlobal("fetch", mockFetch);

    const limitMock = vi.fn().mockResolvedValue({ success: false });
    const env = { ...mockEnv, RATE_LIMITER: { limit: limitMock } };

    await worker.fetch(makeRequest({}), env);
    expect(mockFetch).not.toHaveBeenCalled();
  });
});

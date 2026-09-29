// Stick relay: keeps the Fish Audio and OpenRouter keys on the server, never in the app.
//
// The app calls   https://<project>.supabase.co/functions/v1/relay/<provider>/<path>
// with the project's public anon key. The relay adds the provider key and forwards only
// the few calls Stick makes. It stores nothing: request and response bodies stream through.
//
//   POST   /relay/fish/model                     clone a voice (multipart sample)
//   DELETE /relay/fish/model/<id>                delete a voice clone
//   POST   /relay/fish/v1/tts                    speak a line with a voice clone
//   POST   /relay/openrouter/api/v1/chat/completions   rewrite a call line (free models only)
//
// Secrets: FISH_AUDIO_KEY, OPENROUTER_KEY (Supabase › Edge Functions › Secrets).

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

type Route = {
  method: string;
  pattern: RegExp;
  upstream: string;
  secret: string;
  maxBytes: number;
};

const routes: Route[] = [
  { method: "POST", pattern: /^\/fish\/model$/, upstream: "https://api.fish.audio", secret: "FISH_AUDIO_KEY", maxBytes: 12_000_000 },
  { method: "DELETE", pattern: /^\/fish\/model\/[A-Za-z0-9_-]{1,64}$/, upstream: "https://api.fish.audio", secret: "FISH_AUDIO_KEY", maxBytes: 0 },
  { method: "POST", pattern: /^\/fish\/v1\/tts$/, upstream: "https://api.fish.audio", secret: "FISH_AUDIO_KEY", maxBytes: 20_000 },
  { method: "POST", pattern: /^\/openrouter\/api\/v1\/chat\/completions$/, upstream: "https://openrouter.ai", secret: "OPENROUTER_KEY", maxBytes: 60_000 },
];

// Headers the app may send through. Everything else (cookies, the Supabase JWT…) stays here.
const forwardedHeaders = ["content-type", "accept", "model", "http-referer", "x-title"];

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const path = url.pathname.replace(/^\/relay/, "");
  const route = routes.find((r) => r.method === req.method && r.pattern.test(path));
  // 400, not 404: a missing route must never look like a provider answer.
  if (!route) return json(400, { error: "unsupported_route" });

  const key = Deno.env.get(route.secret);
  if (!key) return json(503, { error: "relay_not_configured" });

  const body = req.method === "DELETE" ? undefined : new Uint8Array(await req.arrayBuffer());
  if (body && body.byteLength > route.maxBytes) return json(413, { error: "too_large" });

  if (route.secret === "OPENROUTER_KEY" && body) {
    // Only the free models Stick uses: a leaked anon key can't run up a bill.
    try {
      const model = JSON.parse(new TextDecoder().decode(body)).model;
      if (typeof model !== "string" || !model.endsWith(":free")) return json(400, { error: "model_not_allowed" });
    } catch {
      return json(400, { error: "invalid_json" });
    }
  }

  const headers = new Headers({ Authorization: `Bearer ${key}` });
  for (const name of forwardedHeaders) {
    const value = req.headers.get(name);
    if (value) headers.set(name, value);
  }

  const upstreamPath = path.replace(/^\/(fish|openrouter)/, "");
  const upstream = await fetch(route.upstream + upstreamPath, { method: req.method, headers, body });
  // Deleting a voice that no longer exists is a success: it's gone either way.
  if (req.method === "DELETE" && upstream.status === 404) return new Response(null, { status: 204 });
  return new Response(upstream.body, {
    status: upstream.status,
    headers: { "Content-Type": upstream.headers.get("Content-Type") ?? "application/octet-stream" },
  });
});

function json(status: number, value: unknown): Response {
  return new Response(JSON.stringify(value), { status, headers: { "Content-Type": "application/json" } });
}

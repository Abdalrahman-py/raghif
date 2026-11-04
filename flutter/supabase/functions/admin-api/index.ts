import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { type Deps, handle } from "./core.ts";

// Admin panel back end for the actions that need the service key: creating a
// bakery (auth user + profile + store), resetting a PIN, and the status
// changes that must also sign someone out. See core.ts for the rules.
//
// verify_jwt stays ON (the default): the caller must at least hold a valid
// Supabase session; core.ts then requires that session to be an administrator.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const noSession = { autoRefreshToken: false, persistSession: false };

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, { auth: noSession });

const deps: Deps = {
  // deno-lint-ignore no-explicit-any
  admin: admin as any,
  asUser: (jwt) =>
    // deno-lint-ignore no-explicit-any
    createClient(SUPABASE_URL, ANON_KEY, {
      auth: noSession,
      global: { headers: { Authorization: `Bearer ${jwt}` } },
    }) as any,
  randomInt: (max) => {
    // Rejection sampling so every value is equally likely.
    const limit = 256 - (256 % max);
    const buf = new Uint8Array(1);
    for (;;) {
      crypto.getRandomValues(buf);
      if (buf[0] < limit) return buf[0] % max;
    }
  },
};

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function reply(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      // A response can carry a PIN: never cache it.
      "Cache-Control": "no-store",
      ...CORS,
    },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return reply(405, { error: "method not allowed" });

  // deno-lint-ignore no-explicit-any
  let body: any;
  try {
    body = await req.json();
  } catch {
    return reply(400, { error: "invalid JSON body" });
  }

  const out = await handle(req.headers, body, deps);
  return reply(out.status, out.body);
});

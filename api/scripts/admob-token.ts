/**
 * Gets the AdMob refresh token the admin dashboard reads earnings with.
 *
 *   npm run admob-token            # reads ADMOB_CLIENT_ID / _SECRET from .env
 *   ADMOB_CLIENT_ID=… ADMOB_CLIENT_SECRET=… npm run admob-token
 *
 * AdMob has no service accounts, so the earnings can only be read as the Google
 * account that owns the ad units. This prints a sign-in URL, listens on
 * localhost for Google's redirect, swaps the code for a refresh token and
 * prints it. Put that in ADMOB_REFRESH_TOKEN. See "The admin dashboard" in the
 * README — in particular, publish the OAuth consent screen first, or Google
 * expires the token after seven days.
 */
import { createServer } from 'node:http';

const clientId = process.env.ADMOB_CLIENT_ID ?? '';
const clientSecret = process.env.ADMOB_CLIENT_SECRET ?? '';
const port = Number(process.env.ADMOB_OAUTH_PORT ?? 8787);

if (!clientId || !clientSecret) {
  console.error('usage: ADMOB_CLIENT_ID=… ADMOB_CLIENT_SECRET=… npm run admob-token');
  process.exit(2);
}

const redirectUri = `http://localhost:${port}/`;
const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?${new URLSearchParams({
  client_id: clientId,
  redirect_uri: redirectUri,
  response_type: 'code',
  scope: 'https://www.googleapis.com/auth/admob.readonly',
  // offline + consent: without both, Google returns an access token only, or
  // skips the refresh token because this account already approved once.
  access_type: 'offline',
  prompt: 'consent',
})}`;

console.log('\nOpen this in the browser, signed in as the Google account that owns AdMob:\n');
console.log(authUrl);
console.log(`\nWaiting for the redirect on ${redirectUri} …\n`);

const code = await new Promise<string>((resolve, reject) => {
  const server = createServer((req, res) => {
    const url = new URL(req.url ?? '/', redirectUri);
    const got = url.searchParams.get('code');
    const error = url.searchParams.get('error');
    res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8' });
    res.end(got ? 'Done — back to the terminal.' : `Sign-in failed: ${error ?? 'no code'}`);
    server.close();
    if (got) resolve(got);
    else reject(new Error(error ?? 'no code in the redirect'));
  });
  server.listen(port);
  server.on('error', reject);
});

const res = await fetch('https://oauth2.googleapis.com/token', {
  method: 'POST',
  headers: { 'content-type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({ client_id: clientId, client_secret: clientSecret, code, redirect_uri: redirectUri, grant_type: 'authorization_code' }).toString(),
});
const body = (await res.json()) as { refresh_token?: string; error_description?: string; error?: string };
if (!res.ok || !body.refresh_token) {
  console.error(`\nGoogle refused the code: ${body.error_description ?? body.error ?? res.status}`);
  process.exit(1);
}

console.log('\nADMOB_REFRESH_TOKEN=' + body.refresh_token + '\n');
console.log('Keep it like a password: it reads the AdMob account until revoked.\n');

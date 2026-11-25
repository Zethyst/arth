import { loadConfig } from './config.js';
import { buildApp } from './app.js';
import { connectMongo, disconnectMongo } from './db/connect.js';
import { mongoStore } from './services/mongo-store.js';
import { mongoCache, withMemory } from './cache/cache.js';
import { OpenAIProvider } from './llm/openai.js';
import { disabledVerifier, firebaseVerifier } from './auth/verifier.js';
import { firebaseApp, parseServiceAccount } from './auth/firebase-app.js';
import { disabledPusher, fcmPusher } from './push/pusher.js';
import { parseCloudinaryUrl } from './lib/cloudinary.js';
import { mongoAccountStore } from './services/mongo-accounts.js';
import { mongoCommunityStore } from './services/mongo-community.js';
import { mongoCouponStore } from './services/mongo-coupons.js';
import { disabledBilling, revenueCatBilling } from './billing/revenuecat.js';
import { admobNetwork, disabledAds, disabledPurchaseMetrics, revenueCatMetrics } from './billing/income.js';
import { firebaseLoginRemover } from './auth/verifier.js';
import { mongoSeedSource } from './routes/seed.js';
import { SeedFileCache } from './services/seed-file.js';

const config = loadConfig();
const serviceAccount = parseServiceAccount(config.FIREBASE_SERVICE_ACCOUNT);
const fbApp = config.FIREBASE_PROJECT_ID ? firebaseApp(config.FIREBASE_PROJECT_ID, serviceAccount) : null;
// Built from Mongo on first use; warmed once connected (below).
const seedFile = new SeedFileCache(mongoSeedSource(config.SEED_LIMIT), {
  log: { info: (obj, msg) => app.log.info(obj, msg), warn: (obj, msg) => app.log.warn(obj, msg) },
});
const app = buildApp({
  logLevel: config.LOG_LEVEL,
  store: mongoStore,
  cache: withMemory(mongoCache),
  llm: new OpenAIProvider(config.OPENAI_API_KEY),
  config,
  seedLimit: config.SEED_LIMIT,
  seedFile,
  ...(fbApp ? { removeLogin: firebaseLoginRemover(fbApp) } : {}),
  billing: {
    billing: config.REVENUECAT_SECRET_KEY ? revenueCatBilling(config.REVENUECAT_SECRET_KEY) : disabledBilling,
    webhookAuth: config.REVENUECAT_WEBHOOK_AUTH,
  },
  // What the admin dashboard shows as income. Each half is read live from the
  // network that holds the money, and each is off until its keys are set.
  income: {
    currency: config.INCOME_CURRENCY.toUpperCase(),
    ads:
      config.ADMOB_PUBLISHER_ID && config.ADMOB_CLIENT_ID && config.ADMOB_CLIENT_SECRET && config.ADMOB_REFRESH_TOKEN
        ? admobNetwork({
            publisherId: config.ADMOB_PUBLISHER_ID,
            clientId: config.ADMOB_CLIENT_ID,
            clientSecret: config.ADMOB_CLIENT_SECRET,
            refreshToken: config.ADMOB_REFRESH_TOKEN,
          })
        : disabledAds,
    purchases:
      config.REVENUECAT_PROJECT_ID && config.REVENUECAT_METRICS_KEY
        ? revenueCatMetrics({ projectId: config.REVENUECAT_PROJECT_ID, secretKey: config.REVENUECAT_METRICS_KEY })
        : disabledPurchaseMetrics,
  },
  rateLimits: { lookups: config.RATE_LIMIT_LOOKUPS, llm: config.RATE_LIMIT_LLM, prefetch: config.RATE_LIMIT_PREFETCH },
  accounts: {
    store: mongoAccountStore,
    verifier: fbApp ? firebaseVerifier(fbApp) : disabledVerifier,
    pusher: fbApp && serviceAccount ? fcmPusher(fbApp) : disabledPusher,
    cloudinary: parseCloudinaryUrl(config.CLOUDINARY_URL),
  },
  // Without a Firebase project nobody can sign in, so AI stays open.
  enforceQuota: config.FIREBASE_PROJECT_ID !== '',
  community: mongoCommunityStore,
  coupons: mongoCouponStore,
  limits: {
    free: config.AI_FREE_LIMIT,
    proMonthly: config.AI_PRO_MONTHLY,
    superMonthly: config.AI_SUPER_MONTHLY,
    freeAccountsPerDevice: config.AI_FREE_ACCOUNTS_PER_DEVICE,
    adBonus: config.AI_AD_BONUS,
    adBonusPerDay: config.AI_AD_BONUS_PER_DAY,
  },
});

try {
  await connectMongo(config.MONGODB_URI);
  app.log.info({ uri: config.MONGODB_URI.replace(/\/\/.*@/, '//***@') }, 'mongo connected');
  seedFile.warm();
  await app.listen({ port: config.PORT, host: config.HOST });
} catch (err) {
  app.log.fatal({ err }, 'failed to start');
  process.exit(1);
}

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, async () => {
    app.log.info({ signal }, 'shutting down');
    await app.close();
    await disconnectMongo();
    process.exit(0);
  });
}

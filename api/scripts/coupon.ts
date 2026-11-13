/**
 * Discount codes, from the command line.
 *
 * A coupon does not set a price. It names a cheaper offer the stores already
 * hold — a Google Play base-plan offer tag, an App Store promotional-offer id
 * — and decides who may buy at it. Create the offer in Play Console / App
 * Store Connect first, then point a code at it here.
 *
 *   npm run coupon -- create MAYUR40 --tier pro --android pro_yearly_40off \
 *       --label "40% off the first year" --label-hi "पहले साल 40% छूट" \
 *       --max 1 --days 30 --note "WhatsApp, asked for 500-700/yr"
 *
 *   npm run coupon -- list
 *   npm run coupon -- show MAYUR40
 *   npm run coupon -- off MAYUR40          # stop it working, keep the record
 *   npm run coupon -- on MAYUR40
 *
 * --for <uid|email|phone> locks the code to one reader; repeatable.
 */
import { loadConfig } from '../src/config.js';
import { connectMongo, disconnectMongo } from '../src/db/connect.js';
import { CouponModel, CouponRedemptionModel } from '../src/db/models/index.js';
import { UserModel } from '../src/db/models/account.js';
import { normalizeCode } from '../src/services/coupons.js';

const argv = process.argv.slice(2);
const [command, codeArg] = argv;

function flag(name: string): string | undefined {
  const i = argv.indexOf(`--${name}`);
  return i === -1 ? undefined : argv[i + 1];
}
function flags(name: string): string[] {
  const out: string[] = [];
  for (let i = 0; i < argv.length; i++) if (argv[i] === `--${name}` && argv[i + 1]) out.push(argv[i + 1]!);
  return out;
}

const usage = `usage:
  npm run coupon -- create <CODE> --tier <pro|super> [--android <offerTag>] [--ios <discountId>]
                    [--period monthly|yearly] [--label <text>] [--label-hi <text>]
                    [--max <n>] [--days <n>] [--for <uid|email|phone>]... [--note <text>]
  npm run coupon -- list | show <CODE> | on <CODE> | off <CODE>`;

if (!command || !['create', 'list', 'show', 'on', 'off'].includes(command)) {
  console.error(usage);
  process.exit(2);
}

const config = loadConfig();
await connectMongo(config.MONGODB_URI);
try {
  if (command === 'list') {
    const docs = await CouponModel.find({}).sort({ createdAt: -1 }).lean();
    if (docs.length === 0) console.log('no coupons yet');
    for (const c of docs) {
      const cap = c.maxRedemptions === null ? '∞' : String(c.maxRedemptions);
      const when = c.expiresAt ? new Date(c.expiresAt).toISOString().slice(0, 10) : 'no end';
      console.log(`${c.active ? ' ' : '×'} ${c._id.padEnd(16)} ${c.tier.padEnd(5)} ${String(c.redeemed).padStart(3)}/${cap.padEnd(4)} until ${when}  ${c.note}`);
    }
  } else {
    const code = normalizeCode(codeArg ?? '');
    if (!code) {
      console.error(usage);
      process.exit(2);
    }

    if (command === 'create') {
      const tier = flag('tier');
      if (tier !== 'pro' && tier !== 'super') {
        console.error('--tier must be pro or super');
        process.exit(2);
      }
      const period = flag('period') ?? null;
      if (period !== null && period !== 'monthly' && period !== 'yearly') {
        console.error('--period must be monthly or yearly');
        process.exit(2);
      }
      const android = flag('android') ?? '';
      const ios = flag('ios') ?? '';
      if (!android && !ios) {
        console.error('give at least one of --android <offerTag> / --ios <discountId>: a code with neither unlocks nothing');
        process.exit(2);
      }
      // --for takes whatever identifies the reader; store the uid.
      const uids: string[] = [];
      for (const who of flags('for')) {
        const user = await UserModel.findOne({ $or: [{ _id: who }, { email: who }, { phone: who }] }).lean();
        if (!user) {
          console.error(`no user matches ${who} — they appear after their first sign-in`);
          process.exit(1);
        }
        uids.push(user._id);
      }
      const days = Number(flag('days') ?? '');
      const max = Number(flag('max') ?? '');
      const now = Date.now();
      const doc = {
        tier,
        period,
        androidOfferTag: android,
        iosDiscountId: ios,
        label: flag('label') ?? '',
        labelHi: flag('label-hi') ?? '',
        maxRedemptions: Number.isFinite(max) && max > 0 ? max : null,
        uids,
        expiresAt: Number.isFinite(days) && days > 0 ? now + days * 86_400_000 : null,
        active: true,
        note: flag('note') ?? '',
        updatedAt: now,
      };
      await CouponModel.updateOne({ _id: code }, { $set: doc, $setOnInsert: { createdAt: now, redeemed: 0 } }, { upsert: true });
      console.log(`${code} → ${tier}${period ? ` (${period} only)` : ''}`);
      if (android) console.log(`  Play offer tag      ${android}`);
      if (ios) console.log(`  App Store discount  ${ios}`);
      console.log(`  uses                ${doc.maxRedemptions ?? 'unlimited'}`);
      console.log(`  ends                ${doc.expiresAt ? new Date(doc.expiresAt).toISOString() : 'never'}`);
      if (uids.length) console.log(`  only for            ${uids.join(', ')}`);
    } else if (command === 'show') {
      const c = await CouponModel.findById(code).lean();
      if (!c) {
        console.error(`no coupon ${code}`);
        process.exit(1);
      }
      console.log(JSON.stringify(c, null, 2));
      const used = await CouponRedemptionModel.find({ code }).sort({ at: 1 }).lean();
      for (const r of used) console.log(`  used by ${r.uid} at ${new Date(r.at).toISOString()}`);
    } else {
      const active = command === 'on';
      const res = await CouponModel.updateOne({ _id: code }, { $set: { active, updatedAt: Date.now() } });
      if (res.matchedCount === 0) {
        console.error(`no coupon ${code}`);
        process.exit(1);
      }
      console.log(`${code} is now ${active ? 'on' : 'off'}`);
    }
  }
} finally {
  await disconnectMongo();
}

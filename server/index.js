const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const express = require('express');
const OpenAI = require('openai');
const { GoogleAuth } = require('google-auth-library');
let apn = null;
try {
  apn = require('apn');
} catch (_) {
  apn = null;
}

const app = express();

function loadLocalEnvFile() {
  const filePath = path.join(__dirname, '.env');
  if (!fs.existsSync(filePath)) {
    return;
  }

  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) {
      continue;
    }

    const index = line.indexOf('=');
    if (index <= 0) {
      continue;
    }

    const key = line.slice(0, index).trim();
    const value = line.slice(index + 1).trim();
    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

loadLocalEnvFile();

const PORT = Number.parseInt(process.env.PORT || '', 10) || 3000;
const SESSION_TTL_MS =
  Number.parseInt(process.env.SESSION_TTL_MS || '', 10) ||
  1000 * 60 * 60 * 12;
const OAUTH_STATE_TTL_MS =
  Number.parseInt(process.env.OAUTH_STATE_TTL_MS || '', 10) ||
  1000 * 60 * 10;
const OAUTH_REDIRECT_URI =
  process.env.MAIL_OAUTH_REDIRECT_URI ||
  `http://localhost:${PORT}/api/mail/oauth/callback`;
const STORE_DIR = path.join(__dirname, '.data');
const STORE_FILE = path.join(STORE_DIR, 'mail_accounts.json');
const SUBSCRIPTION_STORE_FILE = path.join(STORE_DIR, 'subscriptions.json');
const STRIPE_EVENT_STORE_FILE = path.join(STORE_DIR, 'stripe_events.json');
const KEYNEST_BACKUP_STORE_FILE = path.join(STORE_DIR, 'keynest_backups.json');
const KEYNEST_PUSH_STORE_FILE = path.join(STORE_DIR, 'keynest_push_devices.json');
const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const PLUS_MONTHLY_PRICE_YEN =
  Number.parseInt(process.env.PLUS_MONTHLY_PRICE_YEN || '', 10) || 800;
const PLUS_YEARLY_PRICE_YEN =
  Number.parseInt(process.env.PLUS_YEARLY_PRICE_YEN || '', 10) || 8000;
const ALLOW_PASSWORD_LOGIN =
  String(process.env.ALLOW_PASSWORD_LOGIN || '')
    .trim()
    .toLowerCase() === 'true';
const ENABLE_BILLING_STUB =
  String(process.env.ENABLE_BILLING_STUB || '')
    .trim()
    .toLowerCase() === 'true';
const STRIPE_SECRET_KEY = String(process.env.STRIPE_SECRET_KEY || '').trim();
const STRIPE_PUBLIC_KEY = String(process.env.STRIPE_PUBLIC_KEY || '').trim();
const STRIPE_PRICE_ID_MONTHLY = String(
  process.env.STRIPE_PRICE_ID_MONTHLY || '',
).trim();
const STRIPE_PRICE_ID_YEARLY = String(
  process.env.STRIPE_PRICE_ID_YEARLY || '',
).trim();
const STRIPE_SUCCESS_URL = String(process.env.STRIPE_SUCCESS_URL || '').trim();
const STRIPE_CANCEL_URL = String(process.env.STRIPE_CANCEL_URL || '').trim();
const SUBSCRIPTION_WEBHOOK_SECRET = String(
  process.env.SUBSCRIPTION_WEBHOOK_SECRET || '',
).trim();
const STRIPE_WEBHOOK_TOLERANCE_SEC =
  Number.parseInt(process.env.STRIPE_WEBHOOK_TOLERANCE_SEC || '', 10) || 300;
const STRIPE_EVENT_HISTORY_LIMIT =
  Number.parseInt(process.env.STRIPE_EVENT_HISTORY_LIMIT || '', 10) || 2000;

const SECRET_KEY = crypto
  .createHash('sha256')
  .update(
    String(
      process.env.MAIL_SESSION_SECRET ||
        process.env.SESSION_ENCRYPTION_KEY ||
        'venemo-local-dev-secret-change-me',
    ),
  )
  .digest();

const mailDependencies = {
  loaded: false,
  error: null,
  ImapFlow: null,
  simpleParser: null,
  nodemailer: null,
};

const MAIL_PROVIDERS = {
  gmail: {
    imapHost: 'imap.gmail.com',
    imapPort: 993,
    smtpHost: 'smtp.gmail.com',
    smtpPort: 465,
    smtpSecure: true,
    sentMailbox: '[Gmail]/Sent Mail',
    draftMailbox: '[Gmail]/Drafts',
    trashMailbox: '[Gmail]/Trash',
  },
  yahoo: {
    imapHost: 'imap.mail.yahoo.com',
    imapPort: 993,
    smtpHost: 'smtp.mail.yahoo.com',
    smtpPort: 465,
    smtpSecure: true,
    sentMailbox: 'Sent',
    draftMailbox: 'Draft',
    trashMailbox: 'Trash',
  },
  outlook: {
    imapHost: 'outlook.office365.com',
    imapPort: 993,
    smtpHost: 'smtp.office365.com',
    smtpPort: 587,
    smtpSecure: false,
    sentMailbox: 'Sent Items',
    draftMailbox: 'Drafts',
    trashMailbox: 'Deleted Items',
  },
};

const OAUTH_PROVIDERS = {
  gmail: {
    authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
    tokenEndpoint: 'https://oauth2.googleapis.com/token',
    defaultScopes: [
      'openid',
      'email',
      'profile',
      'https://mail.google.com/',
    ],
    extraAuthParams: {
      access_type: 'offline',
      prompt: 'consent',
      include_granted_scopes: 'true',
    },
  },
  yahoo: {
    authorizationEndpoint: 'https://api.login.yahoo.com/oauth2/request_auth',
    tokenEndpoint: 'https://api.login.yahoo.com/oauth2/get_token',
    defaultScopes: ['openid', 'email', 'profile', 'mail-r', 'mail-w'],
    extraAuthParams: {},
  },
  outlook: {
    authorizationEndpoint:
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
    tokenEndpoint: 'https://login.microsoftonline.com/common/oauth2/v2.0/token',
    defaultScopes: [
      'openid',
      'email',
      'profile',
      'offline_access',
      'https://outlook.office.com/IMAP.AccessAsUser.All',
      'https://outlook.office.com/SMTP.Send',
    ],
    extraAuthParams: {
      response_mode: 'query',
    },
  },
};

const mailSessions = new Map();
const oauthStates = new Map();

const corsOrigins = String(process.env.CORS_ORIGINS || '')
  .split(',')
  .map((item) => item.trim())
  .filter(Boolean);

app.use(
  cors(
    corsOrigins.length > 0
      ? {
          origin(origin, callback) {
            if (!origin || corsOrigins.includes(origin)) {
              return callback(null, true);
            }
            return callback(new Error('CORS blocked'));
          },
        }
      : undefined,
  ),
);
app.use(
  express.json({
    limit: '25mb',
    verify(req, _res, buf) {
      if (
        req?.originalUrl &&
        String(req.originalUrl).startsWith('/api/subscription/webhook/stripe')
      ) {
        req.rawBody = buf.toString('utf8');
      }
    },
  }),
);

function toHttpError(status, message, code) {
  const error = new Error(message);
  error.status = status;
  if (code) {
    error.code = code;
  }
  return error;
}

function responseStatusByError(error, fallback = 500) {
  if (Number.isInteger(error?.status)) {
    return error.status;
  }
  if (error?.code === 'MAIL_BRIDGE_DEPENDENCY_MISSING') {
    return 503;
  }
  return fallback;
}

function encryptText(value) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', SECRET_KEY, iv);
  const encrypted = Buffer.concat([
    cipher.update(String(value), 'utf8'),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();
  return `${iv.toString('base64')}.${tag.toString('base64')}.${encrypted.toString('base64')}`;
}

function decryptText(cipherText) {
  const [ivBase64, tagBase64, dataBase64] = String(cipherText || '').split('.');
  if (!ivBase64 || !tagBase64 || !dataBase64) {
    throw new Error('暗号化データが不正です');
  }

  const iv = Buffer.from(ivBase64, 'base64');
  const tag = Buffer.from(tagBase64, 'base64');
  const data = Buffer.from(dataBase64, 'base64');

  const decipher = crypto.createDecipheriv('aes-256-gcm', SECRET_KEY, iv);
  decipher.setAuthTag(tag);
  const plain = Buffer.concat([decipher.update(data), decipher.final()]);
  return plain.toString('utf8');
}

function encryptJson(value) {
  return encryptText(JSON.stringify(value));
}

function decryptJson(cipherText) {
  return JSON.parse(decryptText(cipherText));
}

function getOpenAIClient() {
  const apiKey = String(process.env.OPENAI_API_KEY || '').trim();
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY が未設定です');
  }
  return new OpenAI({ apiKey });
}

function normalizeProvider(provider) {
  const key = String(provider || '').toLowerCase().trim();
  if (!Object.hasOwn(MAIL_PROVIDERS, key)) {
    throw new Error('provider は gmail / yahoo / outlook を指定してください');
  }
  return key;
}

function toInt(value, fallback) {
  const parsed = Number.parseInt(String(value ?? ''), 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function mailboxName(session, mailbox) {
  const box = String(mailbox || 'inbox').toLowerCase();
  if (box === 'sent') return session.config.sentMailbox;
  if (box === 'draft') return session.config.draftMailbox || 'Drafts';
  if (box === 'trash') return session.config.trashMailbox;
  return 'INBOX';
}

function decodeMimeWordPayload(payload, encoding) {
  const mode = String(encoding || 'B').toUpperCase();
  if (mode === 'B') {
    try {
      const normalized = String(payload || '')
        .replaceAll('_', '/')
        .replaceAll('-', '+');
      const padding = normalized.length % 4;
      const padded =
        padding === 0 ? normalized : `${normalized}${'='.repeat(4 - padding)}`;
      return Buffer.from(padded, 'base64');
    } catch (_) {
      return null;
    }
  }

  // Quoted-printable variant used in encoded-word headers.
  const source = String(payload || '').replaceAll('_', ' ');
  const bytes = [];
  for (let i = 0; i < source.length; i += 1) {
    const ch = source[i];
    if (ch === '=' && i + 2 < source.length) {
      const hex = source.slice(i + 1, i + 3);
      const parsed = Number.parseInt(hex, 16);
      if (Number.isFinite(parsed)) {
        bytes.push(parsed);
        i += 2;
        continue;
      }
    }
    bytes.push(ch.charCodeAt(0));
  }
  return Buffer.from(bytes);
}

function decodeBytesByCharset(bytes, charset) {
  const normalized = String(charset || 'utf-8').toLowerCase().trim();
  const aliases = {
    utf8: 'utf-8',
    'x-sjis': 'shift_jis',
    sjis: 'shift_jis',
    ms932: 'shift_jis',
    cp932: 'shift_jis',
    eucjp: 'euc-jp',
    euc_jp: 'euc-jp',
    iso2022jp: 'iso-2022-jp',
    usascii: 'us-ascii',
  };
  const decoderCharset =
    aliases[normalized.replaceAll('-', '').replaceAll('_', '')] || normalized;

  try {
    return new TextDecoder(decoderCharset, { fatal: false }).decode(bytes);
  } catch (_) {
    try {
      return new TextDecoder('utf-8', { fatal: false }).decode(bytes);
    } catch (_) {
      return bytes.toString('latin1');
    }
  }
}

function decodeMimeHeaderValue(value) {
  const source = String(value || '');
  if (!source.trim()) return '';

  const encodedWord = /=\?([^?]+)\?([bBqQ])\?([^?]*)\?=/g;
  if (!encodedWord.test(source)) {
    return repairMojibake(source);
  }
  encodedWord.lastIndex = 0;

  const decoded = source.replace(encodedWord, (_full, charset, encoding, payload) => {
    const decodedBytes = decodeMimeWordPayload(payload, encoding);
    if (!decodedBytes) {
      return _full;
    }
    return decodeBytesByCharset(decodedBytes, charset);
  });
  return repairMojibake(decoded);
}

function repairMojibake(input) {
  const text = String(input || '').trim();
  if (!text) return '';
  if (!/[ÃÂâ€™â€œâ€â€¢�]/.test(text)) {
    return text;
  }
  try {
    const repaired = Buffer.from(text, 'latin1').toString('utf8');
    return isBetterDecodedCandidate(text, repaired) ? repaired : text;
  } catch (_) {
    return text;
  }
}

function isBetterDecodedCandidate(original, candidate) {
  const score = (value) =>
    (String(value).match(/�/g) || []).length * 4 +
    (String(value).match(/[ÃÂâ€™â€œâ€â€¢]/g) || []).length * 2;
  return score(candidate) < score(original);
}

function toFromString(addresses) {
  if (!Array.isArray(addresses) || addresses.length === 0) return '';
  return addresses
    .map((item) => {
      if (!item) return '';
      const name = decodeMimeHeaderValue(item.name || '');
      if (name && item.address) return `${name} <${item.address}>`;
      if (item.address) return item.address;
      if (name) return name;
      return item.name || '';
    })
    .filter(Boolean)
    .join(', ');
}

function getMailDependencies() {
  if (mailDependencies.loaded) {
    return mailDependencies;
  }

  mailDependencies.loaded = true;
  try {
    mailDependencies.ImapFlow = require('imapflow').ImapFlow;
    mailDependencies.simpleParser = require('mailparser').simpleParser;
    mailDependencies.nodemailer = require('nodemailer');
  } catch (error) {
    mailDependencies.error = error;
  }
  return mailDependencies;
}

function ensureMailBridgeReady() {
  const deps = getMailDependencies();
  if (deps.error) {
    throw toHttpError(
      503,
      `MAIL_BRIDGE_DEPENDENCY_MISSING: ${deps.error.message}`,
      'MAIL_BRIDGE_DEPENDENCY_MISSING',
    );
  }
  return deps;
}

function ensureStoreFile() {
  if (!fs.existsSync(STORE_DIR)) {
    fs.mkdirSync(STORE_DIR, { recursive: true });
  }
  if (!fs.existsSync(STORE_FILE)) {
    fs.writeFileSync(STORE_FILE, '[]', 'utf8');
  }
}

function readAccountStore() {
  ensureStoreFile();
  try {
    const raw = fs.readFileSync(STORE_FILE, 'utf8');
    const decoded = JSON.parse(raw);
    if (!Array.isArray(decoded)) {
      return [];
    }
    return decoded.filter((item) => item && typeof item === 'object');
  } catch (_) {
    return [];
  }
}

function writeAccountStore(items) {
  ensureStoreFile();
  fs.writeFileSync(STORE_FILE, JSON.stringify(items, null, 2), 'utf8');
}

function ensureSubscriptionStoreFile() {
  if (!fs.existsSync(STORE_DIR)) {
    fs.mkdirSync(STORE_DIR, { recursive: true });
  }
  if (!fs.existsSync(SUBSCRIPTION_STORE_FILE)) {
    fs.writeFileSync(
      SUBSCRIPTION_STORE_FILE,
      JSON.stringify({ subscriptions: {}, transactions: [] }, null, 2),
      'utf8',
    );
  }
}

function readSubscriptionStore() {
  ensureSubscriptionStoreFile();
  try {
    const raw = fs.readFileSync(SUBSCRIPTION_STORE_FILE, 'utf8');
    const decoded = JSON.parse(raw);
    const subscriptions =
      decoded?.subscriptions &&
      typeof decoded.subscriptions === 'object' &&
      !Array.isArray(decoded.subscriptions)
        ? decoded.subscriptions
        : {};
    const transactions = Array.isArray(decoded?.transactions)
      ? decoded.transactions
      : [];
    return { subscriptions, transactions };
  } catch (_) {
    return { subscriptions: {}, transactions: [] };
  }
}

function writeSubscriptionStore(value) {
  ensureSubscriptionStoreFile();
  const subscriptions =
    value?.subscriptions &&
    typeof value.subscriptions === 'object' &&
    !Array.isArray(value.subscriptions)
      ? value.subscriptions
      : {};
  const transactions = Array.isArray(value?.transactions)
    ? value.transactions
    : [];
  fs.writeFileSync(
    SUBSCRIPTION_STORE_FILE,
    JSON.stringify({ subscriptions, transactions }, null, 2),
    'utf8',
  );
}

function ensureStripeEventStoreFile() {
  if (!fs.existsSync(STORE_DIR)) {
    fs.mkdirSync(STORE_DIR, { recursive: true });
  }
  if (!fs.existsSync(STRIPE_EVENT_STORE_FILE)) {
    fs.writeFileSync(
      STRIPE_EVENT_STORE_FILE,
      JSON.stringify({ processed: [] }, null, 2),
      'utf8',
    );
  }
}

function readStripeEventStore() {
  ensureStripeEventStoreFile();
  try {
    const raw = fs.readFileSync(STRIPE_EVENT_STORE_FILE, 'utf8');
    const decoded = JSON.parse(raw);
    const processed = Array.isArray(decoded?.processed)
      ? decoded.processed.filter(
          (item) => item && typeof item === 'object' && String(item.id || ''),
        )
      : [];
    return { processed };
  } catch (_) {
    return { processed: [] };
  }
}

function writeStripeEventStore(store) {
  ensureStripeEventStoreFile();
  const processed = Array.isArray(store?.processed) ? store.processed : [];
  fs.writeFileSync(
    STRIPE_EVENT_STORE_FILE,
    JSON.stringify({ processed }, null, 2),
    'utf8',
  );
}

function isStripeEventProcessed(eventId) {
  const id = String(eventId || '').trim();
  if (!id) return false;
  const store = readStripeEventStore();
  return store.processed.some((item) => String(item.id || '') === id);
}

function markStripeEventProcessed(eventId, eventType = '') {
  const id = String(eventId || '').trim();
  if (!id) return;
  const store = readStripeEventStore();
  if (store.processed.some((item) => String(item.id || '') === id)) {
    return;
  }
  store.processed.push({
    id,
    type: String(eventType || '').trim(),
    processedAt: new Date().toISOString(),
  });
  if (store.processed.length > STRIPE_EVENT_HISTORY_LIMIT) {
    store.processed = store.processed.slice(-STRIPE_EVENT_HISTORY_LIMIT);
  }
  writeStripeEventStore(store);
}

function parseStripeSignatureHeader(header) {
  const tokens = String(header || '')
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean);
  let timestamp = '';
  const signatures = [];

  for (const token of tokens) {
    const eqIndex = token.indexOf('=');
    if (eqIndex <= 0 || eqIndex === token.length - 1) {
      continue;
    }
    const key = token.slice(0, eqIndex).trim();
    const value = token.slice(eqIndex + 1).trim();
    if (key === 't') {
      timestamp = value;
    }
    if (key === 'v1') {
      signatures.push(value);
    }
  }

  return { timestamp, signatures };
}

function verifyStripeWebhookSignature(rawBody, signatureHeader, secret) {
  const payload = String(rawBody || '');
  const header = String(signatureHeader || '').trim();
  const endpointSecret = String(secret || '').trim();

  if (!endpointSecret) return;
  if (!header || !payload) {
    throw toHttpError(401, 'Stripe署名の検証に失敗しました');
  }

  const { timestamp, signatures } = parseStripeSignatureHeader(header);
  const ts = Number.parseInt(timestamp, 10);
  if (!Number.isFinite(ts) || signatures.length === 0) {
    throw toHttpError(401, 'Stripe署名ヘッダーが不正です');
  }

  const nowSec = Math.floor(Date.now() / 1000);
  if (Math.abs(nowSec - ts) > STRIPE_WEBHOOK_TOLERANCE_SEC) {
    throw toHttpError(401, 'Stripe署名の有効期限が切れています');
  }

  const signedPayload = `${timestamp}.${payload}`;
  const expected = crypto
    .createHmac('sha256', endpointSecret)
    .update(signedPayload, 'utf8')
    .digest('hex');
  const expectedBuffer = Buffer.from(expected, 'hex');

  const matched = signatures.some((signature) => {
    if (!/^[0-9a-fA-F]+$/.test(signature)) {
      return false;
    }
    const actualBuffer = Buffer.from(signature, 'hex');
    return (
      actualBuffer.length === expectedBuffer.length &&
      crypto.timingSafeEqual(actualBuffer, expectedBuffer)
    );
  });

  if (!matched) {
    throw toHttpError(401, 'Stripe署名が一致しません');
  }
}

function normalizeBillingCycle(value) {
  return String(value || '').trim().toLowerCase() === 'yearly'
    ? 'yearly'
    : 'monthly';
}

function normalizeBillingCycleForContract(value, contractType = 'individual') {
  const cycle = normalizeBillingCycle(value);
  if (normalizeContractType(contractType) === 'business') {
    return 'yearly';
  }
  return cycle;
}

function normalizeContractType(value) {
  return String(value || '').trim().toLowerCase() === 'business'
    ? 'business'
    : 'individual';
}

function normalizeSeatCount(value, contractType = 'individual') {
  const normalizedContract = normalizeContractType(contractType);
  if (normalizedContract !== 'business') {
    return 1;
  }
  const seats = Number.parseInt(String(value || ''), 10);
  if (Number.isFinite(seats) && seats >= 40) {
    return 40;
  }
  return 20;
}

function discountPercentBySeatCount(seatCount, contractType = 'individual') {
  if (normalizeContractType(contractType) !== 'business') {
    return 0;
  }
  return normalizeSeatCount(seatCount, 'business') >= 40 ? 20 : 15;
}

function normalizeSubscriptionStatus(value) {
  const status = String(value || '').trim().toLowerCase();
  if (['active', 'canceled', 'expired', 'past_due'].includes(status)) {
    return status;
  }
  return 'inactive';
}

function normalizePlan(value) {
  return String(value || '').trim().toLowerCase() === 'plus' ? 'plus' : 'free';
}

function normalizeIsoDate(value) {
  if (!value) return '';
  const parsed = Date.parse(String(value));
  if (!Number.isFinite(parsed)) return '';
  return new Date(parsed).toISOString();
}

function toSubscriptionKey(provider, email) {
  const p = String(provider || '').trim().toLowerCase();
  const e = String(email || '').trim().toLowerCase();
  return `${p}:${e}`;
}

function fallbackSubscription(session) {
  return {
    key: toSubscriptionKey(session?.provider, session?.email),
    provider: String(session?.provider || '').trim().toLowerCase(),
    email: String(session?.email || '').trim().toLowerCase(),
    plan: 'free',
    status: 'inactive',
    billingCycle: 'monthly',
    source: 'none',
    productId: '',
    contractType: 'individual',
    seatCount: 1,
    discountPercent: 0,
    expiresAt: '',
    createdAt: '',
    updatedAt: '',
  };
}

function isPlusActive(subscription) {
  if (!subscription) return false;
  if (normalizePlan(subscription.plan) !== 'plus') return false;
  if (normalizeSubscriptionStatus(subscription.status) !== 'active') return false;
  const expiresAt = normalizeIsoDate(subscription.expiresAt);
  if (!expiresAt) return true;
  return Date.parse(expiresAt) > Date.now();
}

function getSubscriptionBySession(session) {
  const safeFallback = fallbackSubscription(session);
  const key = safeFallback.key;
  if (!key || key === ':') {
    return safeFallback;
  }

  const store = readSubscriptionStore();
  const current = store.subscriptions[key];
  if (!current || typeof current !== 'object') {
    return safeFallback;
  }

  const merged = {
    ...safeFallback,
    ...current,
    key,
  };

  if (
    merged.plan === 'plus' &&
    merged.status === 'active' &&
    merged.expiresAt &&
    Date.parse(merged.expiresAt) <= Date.now()
  ) {
    merged.status = 'expired';
    merged.plan = 'free';
    merged.updatedAt = new Date().toISOString();
    store.subscriptions[key] = merged;
    writeSubscriptionStore(store);
  }

  return merged;
}

function toSubscriptionResponse(subscription) {
  const contractType = normalizeContractType(subscription?.contractType);
  const seatCount = normalizeSeatCount(subscription?.seatCount, contractType);
  const discountPercent = discountPercentBySeatCount(seatCount, contractType);
  const normalized = {
    key: String(subscription?.key || ''),
    provider: String(subscription?.provider || ''),
    email: String(subscription?.email || ''),
    plan: normalizePlan(subscription?.plan),
    status: normalizeSubscriptionStatus(subscription?.status),
    billingCycle: normalizeBillingCycleForContract(
      subscription?.billingCycle,
      contractType,
    ),
    source: String(subscription?.source || 'none'),
    productId: String(subscription?.productId || ''),
    contractType,
    seatCount,
    discountPercent,
    expiresAt: normalizeIsoDate(subscription?.expiresAt),
    createdAt: normalizeIsoDate(subscription?.createdAt),
    updatedAt: normalizeIsoDate(subscription?.updatedAt),
  };
  return {
    ...normalized,
    plusActive: isPlusActive(normalized),
  };
}

function upsertSubscriptionBySession(session, patch, transaction) {
  const current = getSubscriptionBySession(session);
  const nowIso = new Date().toISOString();
  const contractType = normalizeContractType(
    patch?.contractType ?? current.contractType,
  );
  const seatCount = normalizeSeatCount(
    patch?.seatCount ?? current.seatCount,
    contractType,
  );
  const discountPercent = discountPercentBySeatCount(seatCount, contractType);
  const next = {
    ...current,
    ...patch,
    key: current.key,
    provider: current.provider,
    email: current.email,
    plan: normalizePlan(patch?.plan ?? current.plan),
    status: normalizeSubscriptionStatus(patch?.status ?? current.status),
    billingCycle: normalizeBillingCycleForContract(
      patch?.billingCycle ?? current.billingCycle,
      contractType,
    ),
    source: String(patch?.source ?? current.source ?? 'none'),
    productId: String(patch?.productId ?? current.productId ?? ''),
    contractType,
    seatCount,
    discountPercent,
    expiresAt: normalizeIsoDate(patch?.expiresAt ?? current.expiresAt),
    createdAt: current.createdAt || nowIso,
    updatedAt: nowIso,
  };

  const store = readSubscriptionStore();
  store.subscriptions[next.key] = next;
  if (transaction && typeof transaction === 'object') {
    store.transactions.push({
      id: crypto.randomUUID(),
      at: nowIso,
      key: next.key,
      provider: next.provider,
      email: next.email,
      source: next.source,
      productId: next.productId,
      billingCycle: next.billingCycle,
      contractType: next.contractType,
      seatCount: next.seatCount,
      discountPercent: next.discountPercent,
      plan: next.plan,
      status: next.status,
      expiresAt: next.expiresAt,
      raw: transaction,
    });
    if (store.transactions.length > 5000) {
      store.transactions = store.transactions.slice(-5000);
    }
  }
  writeSubscriptionStore(store);
  return next;
}

function determineBillingCycleByProductId(productId) {
  const id = String(productId || '').toLowerCase();
  if (id.includes('year')) return 'yearly';
  if (id.includes('annual')) return 'yearly';
  return 'monthly';
}

function ensureKeyNestBackupStoreFile() {
  if (!fs.existsSync(STORE_DIR)) {
    fs.mkdirSync(STORE_DIR, { recursive: true });
  }
  if (!fs.existsSync(KEYNEST_BACKUP_STORE_FILE)) {
    fs.writeFileSync(KEYNEST_BACKUP_STORE_FILE, '{}', 'utf8');
  }
}

function readKeyNestBackupStore() {
  ensureKeyNestBackupStoreFile();
  try {
    const raw = fs.readFileSync(KEYNEST_BACKUP_STORE_FILE, 'utf8');
    const decoded = JSON.parse(raw);
    if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
      return {};
    }
    return decoded;
  } catch (_) {
    return {};
  }
}

function writeKeyNestBackupStore(items) {
  ensureKeyNestBackupStoreFile();
  fs.writeFileSync(
    KEYNEST_BACKUP_STORE_FILE,
    JSON.stringify(items, null, 2),
    'utf8',
  );
}

function ensureKeyNestPushStoreFile() {
  if (!fs.existsSync(STORE_DIR)) {
    fs.mkdirSync(STORE_DIR, { recursive: true });
  }
  if (!fs.existsSync(KEYNEST_PUSH_STORE_FILE)) {
    fs.writeFileSync(KEYNEST_PUSH_STORE_FILE, '{}', 'utf8');
  }
}

function readKeyNestPushStore() {
  ensureKeyNestPushStoreFile();
  try {
    const raw = fs.readFileSync(KEYNEST_PUSH_STORE_FILE, 'utf8');
    const decoded = JSON.parse(raw);
    if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
      return {};
    }
    return decoded;
  } catch (_) {
    return {};
  }
}

function writeKeyNestPushStore(items) {
  ensureKeyNestPushStoreFile();
  fs.writeFileSync(KEYNEST_PUSH_STORE_FILE, JSON.stringify(items, null, 2), 'utf8');
}

let apnProviderCache = null;
let fcmAuthClientPromise = null;
let fcmAccessTokenCache = {
  token: '',
  expiresAtMs: 0,
};

function resolveApnConfig() {
  const teamId = String(process.env.APNS_TEAM_ID || '').trim();
  const keyId = String(process.env.APNS_KEY_ID || '').trim();
  const bundleId = String(process.env.APNS_BUNDLE_ID || '').trim();
  const keyPath = String(process.env.APNS_AUTH_KEY_PATH || '').trim();
  const keyBase64 = String(process.env.APNS_AUTH_KEY_BASE64 || '').trim();

  if (!teamId || !keyId || !bundleId || (!keyPath && !keyBase64)) {
    return null;
  }

  const key = keyBase64 ? Buffer.from(keyBase64, 'base64') : keyPath;
  return {
    teamId,
    keyId,
    bundleId,
    key,
    production:
      String(process.env.APNS_PRODUCTION || '').trim() === '1' ||
      String(process.env.APNS_PRODUCTION || '').trim().toLowerCase() ===
        'true',
  };
}

function getApnProvider() {
  if (!apn) {
    return null;
  }

  if (apnProviderCache) {
    return apnProviderCache;
  }

  const config = resolveApnConfig();
  if (!config) {
    return null;
  }

  apnProviderCache = new apn.Provider({
    token: {
      key: config.key,
      keyId: config.keyId,
      teamId: config.teamId,
    },
    production: config.production,
  });

  return apnProviderCache;
}

async function sendFcmPush({ token, title, body, data }) {
  const projectId = resolveFcmProjectId();
  const accessToken = await getFcmAccessToken();
  const normalizedData = {};
  for (const [key, value] of Object.entries(data || {})) {
    normalizedData[key] = String(value ?? '');
  }

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: title || 'KeyNest',
            body: body || 'サインイン確認',
          },
          data: normalizedData,
          android: {
            priority: 'HIGH',
            notification: {
              sound: 'default',
              channel_id: 'keynest_auth',
            },
          },
          apns: {
            headers: {
              'apns-priority': '10',
            },
            payload: {
              aps: {
                sound: 'default',
              },
            },
          },
        },
      }),
    },
  );

  const payload = await response.text();
  if (!response.ok) {
    throw new Error(`FCM v1送信エラー: ${response.status} ${payload}`);
  }
  return { provider: 'fcm-v1', payload };
}

function resolveFcmServiceAccount() {
  const jsonRaw = String(process.env.FCM_SERVICE_ACCOUNT_JSON || '').trim();
  const base64Raw = String(process.env.FCM_SERVICE_ACCOUNT_BASE64 || '').trim();
  const pathRaw = String(process.env.FCM_SERVICE_ACCOUNT_PATH || '').trim();

  if (jsonRaw) {
    try {
      const parsed = JSON.parse(jsonRaw);
      if (parsed && typeof parsed === 'object') {
        return parsed;
      }
    } catch (_) {}
    throw new Error('FCM_SERVICE_ACCOUNT_JSON のJSON解析に失敗しました');
  }

  if (base64Raw) {
    try {
      const decoded = Buffer.from(base64Raw, 'base64').toString('utf8');
      const parsed = JSON.parse(decoded);
      if (parsed && typeof parsed === 'object') {
        return parsed;
      }
    } catch (_) {}
    throw new Error('FCM_SERVICE_ACCOUNT_BASE64 の解析に失敗しました');
  }

  if (pathRaw) {
    try {
      const filePath = path.isAbsolute(pathRaw)
        ? pathRaw
        : path.join(__dirname, pathRaw);
      const raw = fs.readFileSync(filePath, 'utf8');
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed === 'object') {
        return parsed;
      }
    } catch (_) {}
    throw new Error('FCM_SERVICE_ACCOUNT_PATH のJSON読み込みに失敗しました');
  }

  return null;
}

function resolveFcmProjectId() {
  const fromEnv = String(process.env.FCM_PROJECT_ID || '').trim();
  if (fromEnv) {
    return fromEnv;
  }
  const serviceAccount = resolveFcmServiceAccount();
  const fromSa = String(serviceAccount?.project_id || '').trim();
  if (fromSa) {
    return fromSa;
  }
  throw new Error('FCM_PROJECT_ID または service account の project_id が必要です');
}

async function getFcmAuthClient() {
  if (fcmAuthClientPromise) {
    return fcmAuthClientPromise;
  }

  const credentials = resolveFcmServiceAccount();
  if (!credentials) {
    throw new Error(
      'FCMサービスアカウントが未設定です（FCM_SERVICE_ACCOUNT_JSON / BASE64 / PATH）',
    );
  }

  const auth = new GoogleAuth({
    credentials,
    scopes: [FCM_SCOPE],
  });

  fcmAuthClientPromise = auth.getClient();
  return fcmAuthClientPromise;
}

async function getFcmAccessToken() {
  const now = Date.now();
  if (
    fcmAccessTokenCache.token &&
    fcmAccessTokenCache.expiresAtMs > now + 30 * 1000
  ) {
    return fcmAccessTokenCache.token;
  }

  const client = await getFcmAuthClient();
  const tokenValue = await client.getAccessToken();
  const accessToken = String(tokenValue?.token || tokenValue || '').trim();
  if (!accessToken) {
    throw new Error('FCMアクセストークン取得に失敗しました');
  }

  const expiresAtMs =
    Number(client.credentials?.expiry_date || 0) || now + 50 * 60 * 1000;

  fcmAccessTokenCache = {
    token: accessToken,
    expiresAtMs,
  };

  return accessToken;
}

function getPushConfigStatus() {
  let fcmReady = false;
  let fcmMessage = '';
  try {
    const projectId = resolveFcmProjectId();
    const serviceAccount = resolveFcmServiceAccount();
    fcmReady = Boolean(serviceAccount && projectId);
    fcmMessage = projectId;
  } catch (error) {
    fcmMessage = error.message;
  }

  const apnsReady = Boolean(getApnProvider());
  return {
    fcmReady,
    fcmMessage,
    apnsReady,
  };
}

async function sendApnsPush({ apnsToken, title, body, data }) {
  const provider = getApnProvider();
  const config = resolveApnConfig();
  if (!provider || !config) {
    throw new Error('APNs設定が不足しています');
  }

  const note = new apn.Notification();
  note.topic = config.bundleId;
  note.sound = 'default';
  note.alert = {
    title: title || 'KeyNest',
    body: body || 'サインイン確認',
  };
  note.payload = data || {};

  const result = await provider.send(note, apnsToken);
  if (result.failed && result.failed.length > 0) {
    const message = result.failed
      .map((item) => item?.response?.reason || item?.error?.message || 'unknown')
      .join(', ');
    throw new Error(`APNs送信エラー: ${message}`);
  }
  return { provider: 'apns', payload: JSON.stringify(result.sent || []) };
}

async function sendPushToDevice(device, { title, body, data }) {
  const platform = String(device.platform || '').toLowerCase();
  const apnsToken = String(device.apnsToken || '').trim();
  const fcmToken = String(device.token || '').trim();

  if (platform === 'ios' && apnsToken) {
    try {
      return await sendApnsPush({ apnsToken, title, body, data });
    } catch (error) {
      if (!fcmToken) {
        throw error;
      }
      const fallback = await sendFcmPush({ token: fcmToken, title, body, data });
      return {
        provider: `${fallback.provider} (apns-fallback)`,
        payload: fallback.payload,
      };
    }
  }

  if (!fcmToken) {
    throw new Error('送信先トークンが未登録です');
  }

  return sendFcmPush({ token: fcmToken, title, body, data });
}

function findAccountById(accountId) {
  const accounts = readAccountStore();
  return accounts.find((item) => item.id === accountId) || null;
}

function findAccountByProviderEmail(provider, email) {
  const normalizedEmail = String(email || '').trim().toLowerCase();
  const accounts = readAccountStore();
  return (
    accounts.find(
      (item) =>
        item.provider === provider &&
        String(item.email || '').trim().toLowerCase() === normalizedEmail,
    ) || null
  );
}

function saveAccount(updatedAccount) {
  const accounts = readAccountStore();
  const index = accounts.findIndex((item) => item.id === updatedAccount.id);
  if (index >= 0) {
    accounts[index] = updatedAccount;
  } else {
    accounts.push(updatedAccount);
  }
  writeAccountStore(accounts);
}

function deleteAccountById(accountId) {
  const accounts = readAccountStore();
  const filtered = accounts.filter((item) => item.id !== accountId);
  writeAccountStore(filtered);
}

function getOAuthEnv(provider) {
  const upper = provider.toUpperCase();
  const clientId = String(
    process.env[`MAIL_OAUTH_${upper}_CLIENT_ID`] ||
      process.env[`OAUTH_${upper}_CLIENT_ID`] ||
      '',
  ).trim();
  const clientSecret = String(
    process.env[`MAIL_OAUTH_${upper}_CLIENT_SECRET`] ||
      process.env[`OAUTH_${upper}_CLIENT_SECRET`] ||
      '',
  ).trim();
  const scopesRaw = String(
    process.env[`MAIL_OAUTH_${upper}_SCOPES`] ||
      process.env[`OAUTH_${upper}_SCOPES`] ||
      '',
  ).trim();

  const scopes = scopesRaw
    ? scopesRaw
        .split(/[\s,]+/)
        .map((value) => value.trim())
        .filter(Boolean)
    : OAUTH_PROVIDERS[provider].defaultScopes;

  return { clientId, clientSecret, scopes };
}

function getOAuthConfig(provider) {
  const base = OAUTH_PROVIDERS[provider];
  if (!base) {
    throw toHttpError(400, `OAuth未対応のproviderです: ${provider}`);
  }

  const env = getOAuthEnv(provider);
  if (!env.clientId || !env.clientSecret) {
    throw toHttpError(
      500,
      `${provider} のOAuthクライアント設定が不足しています（MAIL_OAUTH_${provider.toUpperCase()}_CLIENT_ID / CLIENT_SECRET）`,
    );
  }

  return {
    ...base,
    clientId: env.clientId,
    clientSecret: env.clientSecret,
    scopes: env.scopes,
  };
}

function createOAuthState(payload) {
  const state = crypto.randomBytes(24).toString('hex');
  oauthStates.set(state, {
    ...payload,
    createdAt: Date.now(),
  });
  return state;
}

function consumeOAuthState(state) {
  const key = String(state || '').trim();
  if (!key) {
    return null;
  }

  const value = oauthStates.get(key) || null;
  if (!value) {
    return null;
  }

  oauthStates.delete(key);

  const ageMs = Date.now() - (value.createdAt || 0);
  if (ageMs > OAUTH_STATE_TTL_MS) {
    return null;
  }
  return value;
}

function buildOAuthAuthorizeUrl(provider, state) {
  const oauth = getOAuthConfig(provider);
  const params = new URLSearchParams({
    response_type: 'code',
    client_id: oauth.clientId,
    redirect_uri: OAUTH_REDIRECT_URI,
    scope: oauth.scopes.join(' '),
    state,
  });

  for (const [key, value] of Object.entries(oauth.extraAuthParams || {})) {
    params.set(key, String(value));
  }

  return `${oauth.authorizationEndpoint}?${params.toString()}`;
}

function parseOAuthTokenResponse(response) {
  const accessToken = String(response.access_token || '').trim();
  if (!accessToken) {
    throw new Error('access_token を取得できませんでした');
  }

  const refreshToken = String(response.refresh_token || '').trim();
  const idToken = String(response.id_token || '').trim();
  const expiresIn = Number(response.expires_in || 3600);
  return {
    accessToken,
    refreshToken,
    idToken,
    expiresIn: Number.isFinite(expiresIn) ? expiresIn : 3600,
  };
}

async function exchangeOAuthCode(provider, code) {
  const oauth = getOAuthConfig(provider);
  const params = new URLSearchParams({
    grant_type: 'authorization_code',
    code: String(code || '').trim(),
    client_id: oauth.clientId,
    client_secret: oauth.clientSecret,
    redirect_uri: OAUTH_REDIRECT_URI,
  });

  const headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  if (provider === 'yahoo') {
    const basic = Buffer.from(`${oauth.clientId}:${oauth.clientSecret}`).toString(
      'base64',
    );
    headers.Authorization = `Basic ${basic}`;
  }

  const response = await fetch(oauth.tokenEndpoint, {
    method: 'POST',
    headers,
    body: params,
  });

  const raw = await response.text();
  let data;
  try {
    data = JSON.parse(raw);
  } catch (_) {
    data = {};
  }

  if (!response.ok) {
    const message =
      data?.error_description || data?.error || `token exchange failed: ${raw}`;
    throw new Error(message);
  }

  return parseOAuthTokenResponse(data);
}

async function refreshOAuthAccessToken(provider, refreshToken) {
  const oauth = getOAuthConfig(provider);
  const params = new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: String(refreshToken || '').trim(),
    client_id: oauth.clientId,
    client_secret: oauth.clientSecret,
  });

  if (provider === 'outlook') {
    params.set('scope', oauth.scopes.join(' '));
  }

  const headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  if (provider === 'yahoo') {
    const basic = Buffer.from(`${oauth.clientId}:${oauth.clientSecret}`).toString(
      'base64',
    );
    headers.Authorization = `Basic ${basic}`;
  }

  const response = await fetch(oauth.tokenEndpoint, {
    method: 'POST',
    headers,
    body: params,
  });

  const raw = await response.text();
  let data;
  try {
    data = JSON.parse(raw);
  } catch (_) {
    data = {};
  }

  if (!response.ok) {
    const message =
      data?.error_description || data?.error || `token refresh failed: ${raw}`;
    throw new Error(message);
  }

  return parseOAuthTokenResponse(data);
}

function decodeJwtPayload(idToken) {
  const raw = String(idToken || '').trim();
  if (!raw || !raw.includes('.')) {
    return null;
  }

  const parts = raw.split('.');
  if (parts.length < 2) {
    return null;
  }

  const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
  const padding = payload.length % 4;
  const padded = padding ? payload + '='.repeat(4 - padding) : payload;

  try {
    const text = Buffer.from(padded, 'base64').toString('utf8');
    const decoded = JSON.parse(text);
    return decoded && typeof decoded === 'object' ? decoded : null;
  } catch (_) {
    return null;
  }
}

function emailFromJwt(idToken) {
  const payload = decodeJwtPayload(idToken);
  if (!payload) {
    return '';
  }

  const candidates = [
    payload.email,
    payload.preferred_username,
    payload.upn,
    payload.unique_name,
  ];

  const email = candidates
    .map((value) => String(value || '').trim())
    .find((value) => value.includes('@'));

  return email || '';
}

async function fetchOAuthProfileEmail(provider, accessToken) {
  const token = String(accessToken || '').trim();
  if (!token) {
    return '';
  }

  const headers = {
    Authorization: `Bearer ${token}`,
  };

  try {
    if (provider === 'gmail') {
      const response = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
        headers,
      });
      if (!response.ok) return '';
      const data = await response.json();
      return String(data.email || '').trim();
    }

    if (provider === 'yahoo') {
      const response = await fetch(
        'https://api.login.yahoo.com/openid/v1/userinfo',
        { headers },
      );
      if (!response.ok) return '';
      const data = await response.json();
      return String(data.email || '').trim();
    }

    if (provider === 'outlook') {
      const response = await fetch('https://graph.microsoft.com/v1.0/me', {
        headers,
      });
      if (!response.ok) return '';
      const data = await response.json();
      const email = String(
        data.mail || data.userPrincipalName || data.preferred_username || '',
      ).trim();
      return email;
    }
  } catch (_) {
    return '';
  }

  return '';
}

async function resolveOAuthEmail(provider, tokenPayload) {
  const fromIdToken = emailFromJwt(tokenPayload.idToken);
  if (fromIdToken) {
    return fromIdToken;
  }

  const fromProfile = await fetchOAuthProfileEmail(provider, tokenPayload.accessToken);
  if (fromProfile) {
    return fromProfile;
  }

  throw new Error('OAuthからメールアドレスを取得できませんでした');
}

function upsertOAuthAccount({
  provider,
  email,
  refreshToken,
  accessToken,
  expiresIn,
}) {
  const normalizedEmail = String(email || '').trim().toLowerCase();
  if (!normalizedEmail) {
    throw new Error('メールアドレスが空です');
  }

  const now = Date.now();
  const expiresAt = now + Math.max(Number(expiresIn || 3600), 60) * 1000;
  const current = findAccountByProviderEmail(provider, normalizedEmail);

  const account = {
    id: current?.id || crypto.randomUUID(),
    provider,
    email: normalizedEmail,
    refreshTokenEnc: refreshToken
      ? encryptText(refreshToken)
      : current?.refreshTokenEnc || '',
    accessTokenEnc: accessToken ? encryptText(accessToken) : '',
    accessTokenExpiresAt: expiresAt,
    createdAt: current?.createdAt || now,
    updatedAt: now,
  };

  if (!account.refreshTokenEnc) {
    throw new Error('refresh_token を取得できませんでした（同意画面で再承認が必要です）');
  }

  saveAccount(account);
  return account;
}

function createMailSession(sessionPayload) {
  const token = crypto.randomUUID();
  mailSessions.set(token, {
    payload: encryptJson(sessionPayload),
    createdAt: Date.now(),
  });
  return token;
}

function buildPasswordSession(provider, email, password) {
  return {
    provider,
    email: String(email || '').trim(),
    authMode: 'password',
    password: String(password || '').trim(),
    config: MAIL_PROVIDERS[provider],
  };
}

function buildOAuthSession(account) {
  return {
    provider: account.provider,
    email: account.email,
    authMode: 'oauth',
    accountId: account.id,
    config: MAIL_PROVIDERS[account.provider],
  };
}

function getMailSession(req) {
  const token = req.header('X-Mail-Session');
  if (!token) {
    return null;
  }

  const entry = mailSessions.get(token) || null;
  if (!entry) {
    return null;
  }

  const ageMs = Date.now() - (entry.createdAt || 0);
  if (ageMs > SESSION_TTL_MS) {
    mailSessions.delete(token);
    return null;
  }

  try {
    return {
      token,
      payload: decryptJson(entry.payload),
    };
  } catch (_) {
    mailSessions.delete(token);
    return null;
  }
}

function mailSessionRequired(req, res, next) {
  const session = getMailSession(req);
  if (!session) {
    return res.status(401).json({
      error: 'メールセッションが無効です。再ログインしてください',
    });
  }

  req.mailSessionToken = session.token;
  req.mailSession = session.payload;
  return next();
}

function withSubscription(req, _res, next) {
  req.subscription = toSubscriptionResponse(getSubscriptionBySession(req.mailSession));
  return next();
}

function plusRequired(req, res, next) {
  const subscription = req.subscription
    ? req.subscription
    : toSubscriptionResponse(getSubscriptionBySession(req.mailSession));
  if (subscription.plusActive) {
    req.subscription = subscription;
    return next();
  }

  return res.status(402).json({
    error: 'このAI機能は Venemo Plus 契約が必要です',
    code: 'PLUS_REQUIRED',
    subscription,
  });
}

async function resolveSessionAuth(session) {
  if (session.authMode === 'password') {
    const password = String(session.password || '').trim();
    if (!password) {
      throw toHttpError(401, 'パスワードセッションが無効です');
    }
    return {
      user: session.email,
      password,
    };
  }

  if (session.authMode !== 'oauth') {
    throw toHttpError(401, '不正なセッション形式です');
  }

  const account = findAccountById(session.accountId);
  if (!account) {
    throw toHttpError(401, 'OAuthアカウントが見つかりません');
  }

  let accessToken = '';
  if (account.accessTokenEnc) {
    try {
      accessToken = decryptText(account.accessTokenEnc);
    } catch (_) {
      accessToken = '';
    }
  }

  const willExpireSoon =
    !account.accessTokenExpiresAt ||
    Number(account.accessTokenExpiresAt) <= Date.now() + 60 * 1000;

  if (!accessToken || willExpireSoon) {
    if (!account.refreshTokenEnc) {
      throw toHttpError(401, 'OAuthリフレッシュトークンが見つかりません');
    }

    const refreshToken = decryptText(account.refreshTokenEnc);
    const refreshed = await refreshOAuthAccessToken(account.provider, refreshToken);

    const updated = {
      ...account,
      accessTokenEnc: encryptText(refreshed.accessToken),
      accessTokenExpiresAt:
        Date.now() + Math.max(Number(refreshed.expiresIn || 3600), 60) * 1000,
      updatedAt: Date.now(),
    };

    if (refreshed.refreshToken) {
      updated.refreshTokenEnc = encryptText(refreshed.refreshToken);
    }

    saveAccount(updated);
    accessToken = refreshed.accessToken;
  }

  return {
    user: account.email,
    accessToken,
  };
}

async function createImapClient(session) {
  const { ImapFlow } = ensureMailBridgeReady();
  const auth = await resolveSessionAuth(session);

  const authConfig = auth.accessToken
    ? {
        user: auth.user,
        accessToken: auth.accessToken,
        method: 'XOAUTH2',
      }
    : {
        user: auth.user,
        pass: auth.password,
      };

  return new ImapFlow({
    host: session.config.imapHost,
    port: session.config.imapPort,
    secure: true,
    auth: authConfig,
    logger: false,
  });
}

async function withImapClient(session, handler) {
  const client = await createImapClient(session);
  await client.connect();
  try {
    return await handler(client);
  } finally {
    await client.logout();
  }
}

async function createSmtpTransport(session) {
  const { nodemailer } = ensureMailBridgeReady();
  const auth = await resolveSessionAuth(session);

  const authConfig = auth.accessToken
    ? {
        type: 'OAuth2',
        user: auth.user,
        accessToken: auth.accessToken,
      }
    : {
        user: auth.user,
        pass: auth.password,
      };

  return nodemailer.createTransport({
    host: session.config.smtpHost,
    port: session.config.smtpPort,
    secure: session.config.smtpSecure,
    auth: authConfig,
  });
}

async function listEmails(session, mailbox, maxResults) {
  return withImapClient(session, async (client) => {
    const mailboxPath = mailboxName(session, mailbox);
    await client.mailboxOpen(mailboxPath);

    const total = client.mailbox.exists || 0;
    if (total === 0) {
      return [];
    }

    const limit = Math.min(Math.max(maxResults, 1), 200);
    const start = Math.max(total - limit + 1, 1);
    const range = `${start}:${total}`;
    const emails = [];

    for await (const message of client.fetch(range, {
      uid: true,
      envelope: true,
      flags: true,
      internalDate: true,
      size: true,
    })) {
      const from = toFromString(message.envelope?.from || []);
      const to = toFromString(message.envelope?.to || []);
      const cc = toFromString(message.envelope?.cc || []);
      const subjectRaw = message.envelope?.subject || '(件名なし)';
      const subject = decodeMimeHeaderValue(subjectRaw) || '(件名なし)';
      const date = message.internalDate || new Date();
      const isUnread = !(message.flags && message.flags.has('\\Seen'));
      const snippetSource = `${subject} ${from}`.trim();
      const snippet =
        snippetSource.length > 140
          ? `${snippetSource.slice(0, 140)}...`
          : snippetSource;

      emails.push({
        id: String(message.uid),
        from,
        to,
        cc,
        subject,
        body: '',
        date: date.toISOString(),
        isUnread,
        snippet,
      });
    }

    return emails.reverse();
  });
}

function stripHtmlToPlain(source) {
  const html = String(source || '').trim();
  if (!html) return '';
  return html
    .replace(/<!--[\s\S]*?-->/g, ' ')
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, ' ')
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, ' ')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/(p|div|li|tr|h[1-6])>/gi, '\n')
    .replace(/<li[^>]*>/gi, '• ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/g, "'")
    .replace(/&zwnj;|&#8204;|&#x200c;/gi, '')
    .replace(/\u200c|\u200b/g, '')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/[ \t\r\f\v]+/g, ' ')
    .trim();
}

function hasRenderableHtml(htmlSource) {
  const html = String(htmlSource || '').trim();
  if (!html) return false;
  const bodyOnly = html
    .replace(/<!--[\s\S]*?-->/g, ' ')
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, ' ')
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, ' ')
    .replace(/<head[^>]*>[\s\S]*?<\/head>/gi, ' ');

  if (/<img[^>]+src=["']https?:\/\//i.test(bodyOnly)) {
    return true;
  }
  if (/<img[^>]+src=["']cid:/i.test(bodyOnly)) {
    return true;
  }
  if (/<(table|svg|video|audio|canvas)\b/i.test(bodyOnly)) {
    return true;
  }
  const plain = stripHtmlToPlain(bodyOnly).trim();
  return plain.length > 3;
}

function pickBestHtmlCandidate(primaryHtml, fallbackHtml) {
  const primary = String(primaryHtml || '').trim();
  const fallback = String(fallbackHtml || '').trim();
  if (primary) {
    return primary;
  }
  const fallbackOk = hasRenderableHtml(fallback);

  if (fallbackOk) return fallback;
  return '';
}

async function readEmailBodyParts(session, id, mailbox) {
  const { simpleParser } = ensureMailBridgeReady();
  return withImapClient(session, async (client) => {
    const mailboxPath = mailboxName(session, mailbox);
    await client.mailboxOpen(mailboxPath);

    const uid = toInt(id, 0);
    if (uid <= 0) {
      throw new Error('message id が不正です');
    }

    const message = await client.fetchOne(uid, { source: true }, { uid: true });
    if (!message || !message.source) {
      return { plain: '', html: '', preferred: '' };
    }

    const parsed = await simpleParser(message.source);
    const htmlRaw =
      typeof parsed.html === 'string'
        ? parsed.html
        : Buffer.isBuffer(parsed.html)
          ? parsed.html.toString('utf8')
          : '';
    const textAsHtml =
      typeof parsed.textAsHtml === 'string' ? parsed.textAsHtml : '';
    const plain = typeof parsed.text === 'string' ? parsed.text : '';
    const html = pickBestHtmlCandidate(htmlRaw, textAsHtml);
    const preferred = html || textAsHtml || plain || '';
    const safePlain = plain || stripHtmlToPlain(preferred);
    const safeHtml = html;
    return {
      plain: safePlain,
      html: safeHtml,
      preferred,
    };
  });
}

function encodeBase64WithWrap(input) {
  const bytes = Buffer.isBuffer(input)
    ? input
    : Buffer.from(String(input || ''), 'utf8');
  const encoded = bytes.toString('base64');
  const lines = [];
  for (let i = 0; i < encoded.length; i += 76) {
    lines.push(encoded.slice(i, i + 76));
  }
  return lines.join('\r\n');
}

function sanitizeHeader(value, fallback = '') {
  const text = String(value ?? fallback).replace(/[\r\n]+/g, ' ').trim();
  return text || fallback;
}

function buildDraftMimeMessage({
  from,
  to,
  cc,
  bcc,
  subject,
  body,
}) {
  const lines = [];
  lines.push(`From: ${sanitizeHeader(from, 'unknown@example.com')}`);
  if (String(to || '').trim()) lines.push(`To: ${sanitizeHeader(to)}`);
  if (String(cc || '').trim()) lines.push(`Cc: ${sanitizeHeader(cc)}`);
  if (String(bcc || '').trim()) lines.push(`Bcc: ${sanitizeHeader(bcc)}`);
  lines.push(`Subject: ${sanitizeHeader(subject, '(下書き)')}`);
  lines.push(`Date: ${new Date().toUTCString()}`);
  lines.push('MIME-Version: 1.0');
  lines.push('Content-Type: text/plain; charset=utf-8');
  lines.push('Content-Transfer-Encoding: base64');
  lines.push('');
  lines.push(encodeBase64WithWrap(String(body || '')));
  lines.push('');
  return lines.join('\r\n');
}

async function saveDraft(session, { from, to, cc, bcc, subject, body }) {
  return withImapClient(session, async (client) => {
    const targetMailbox = session.config.draftMailbox || 'Drafts';
    try {
      await client.mailboxOpen(targetMailbox);
    } catch (_) {
      try {
        await client.mailboxCreate(targetMailbox);
        await client.mailboxOpen(targetMailbox);
      } catch (error) {
        throw new Error(`下書きフォルダを開けません: ${error.message}`);
      }
    }

    const raw = buildDraftMimeMessage({
      from: String(from || '').trim() || session.email,
      to,
      cc,
      bcc,
      subject,
      body,
    });
    const result = await client.append(
      targetMailbox,
      Buffer.from(raw, 'utf8'),
      ['\\Draft'],
    );

    return {
      mailbox: targetMailbox,
      uid: result?.uid || null,
      uidValidity: result?.uidValidity || null,
    };
  });
}

async function updateReadFlag(session, id, unread) {
  return withImapClient(session, async (client) => {
    await client.mailboxOpen('INBOX');
    const uid = toInt(id, 0);
    if (uid <= 0) {
      throw new Error('message id が不正です');
    }

    if (unread) {
      await client.messageFlagsRemove(uid, ['\\Seen'], { uid: true });
    } else {
      await client.messageFlagsAdd(uid, ['\\Seen'], { uid: true });
    }
  });
}

async function moveToTrash(session, id) {
  return withImapClient(session, async (client) => {
    await client.mailboxOpen('INBOX');
    const uid = toInt(id, 0);
    if (uid <= 0) {
      throw new Error('message id が不正です');
    }

    await client.messageMove(uid, session.config.trashMailbox, { uid: true });
  });
}

async function fetchUnreadCount(session) {
  return withImapClient(session, async (client) => {
    const status = await client.status('INBOX', { unseen: true });
    return status.unseen || 0;
  });
}

async function generateAiText({
  systemPrompt,
  userPrompt,
  temperature = 0.5,
  maxTokens = 800,
}) {
  const openai = getOpenAIClient();
  const completion = await openai.chat.completions.create({
    model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ],
    temperature,
    max_tokens: maxTokens,
  });
  return (completion.choices?.[0]?.message?.content || '').trim();
}

function stripePriceIdByCycle(billingCycle) {
  return normalizeBillingCycle(billingCycle) === 'yearly'
    ? STRIPE_PRICE_ID_YEARLY
    : STRIPE_PRICE_ID_MONTHLY;
}

function buildPlanPricing({
  billingCycle,
  contractType = 'individual',
  seatCount = 1,
}) {
  const normalizedContractType = normalizeContractType(contractType);
  const normalizedCycle = normalizeBillingCycleForContract(
    billingCycle,
    normalizedContractType,
  );
  const normalizedSeatCount = normalizeSeatCount(
    seatCount,
    normalizedContractType,
  );
  const discountPercent = discountPercentBySeatCount(
    normalizedSeatCount,
    normalizedContractType,
  );
  const baseUnitAmountYen =
    normalizedCycle === 'yearly' ? PLUS_YEARLY_PRICE_YEN : PLUS_MONTHLY_PRICE_YEN;
  const discountedUnitAmountYen =
    normalizedContractType === 'business'
      ? Math.max(
          1,
          Math.round((baseUnitAmountYen * (100 - discountPercent)) / 100),
        )
      : baseUnitAmountYen;
  const totalAmountYen = discountedUnitAmountYen * normalizedSeatCount;
  return {
    contractType: normalizedContractType,
    billingCycle: normalizedCycle,
    seatCount: normalizedSeatCount,
    discountPercent,
    baseUnitAmountYen,
    discountedUnitAmountYen,
    totalAmountYen,
  };
}

function stripeConfigured() {
  return Boolean(
    STRIPE_SECRET_KEY && STRIPE_PRICE_ID_MONTHLY && STRIPE_PRICE_ID_YEARLY,
  );
}

async function createStripeCheckoutSession({
  session,
  billingCycle,
  contractType,
  seatCount,
  discountPercent,
  successUrl,
  cancelUrl,
}) {
  if (!stripeConfigured()) {
    throw toHttpError(
      501,
      'Stripe未設定です（STRIPE_SECRET_KEY / STRIPE_PRICE_ID_MONTHLY / STRIPE_PRICE_ID_YEARLY）',
    );
  }

  const pricing = buildPlanPricing({
    billingCycle,
    contractType,
    seatCount,
  });
  const priceId =
    pricing.contractType === 'business'
      ? ''
      : stripePriceIdByCycle(pricing.billingCycle);
  const key = toSubscriptionKey(session.provider, session.email);
  const quantity = String(pricing.seatCount);
  const params = new URLSearchParams({
    mode: 'subscription',
    success_url: successUrl,
    cancel_url: cancelUrl,
    'line_items[0][quantity]': quantity,
    client_reference_id: key,
    customer_email: String(session.email || '').trim().toLowerCase(),
    'metadata[subscription_key]': key,
    'metadata[mail_provider]': String(session.provider || ''),
    'metadata[mail_email]': String(session.email || '').trim().toLowerCase(),
    'metadata[billing_cycle]': pricing.billingCycle,
    'metadata[contract_type]': pricing.contractType,
    'metadata[seat_count]': String(pricing.seatCount),
    'metadata[discount_percent]': String(pricing.discountPercent),
    'metadata[base_unit_amount_yen]': String(pricing.baseUnitAmountYen),
    'metadata[discounted_unit_amount_yen]': String(
      pricing.discountedUnitAmountYen,
    ),
    'metadata[total_amount_yen]': String(pricing.totalAmountYen),
    'metadata[app]': 'venemo',
    'subscription_data[metadata][subscription_key]': key,
    'subscription_data[metadata][mail_provider]': String(session.provider || ''),
    'subscription_data[metadata][mail_email]': String(session.email || '')
      .trim()
      .toLowerCase(),
    'subscription_data[metadata][billing_cycle]': pricing.billingCycle,
    'subscription_data[metadata][contract_type]': pricing.contractType,
    'subscription_data[metadata][seat_count]': String(pricing.seatCount),
    'subscription_data[metadata][discount_percent]': String(
      pricing.discountPercent,
    ),
    'subscription_data[metadata][base_unit_amount_yen]': String(
      pricing.baseUnitAmountYen,
    ),
    'subscription_data[metadata][discounted_unit_amount_yen]': String(
      pricing.discountedUnitAmountYen,
    ),
    'subscription_data[metadata][total_amount_yen]': String(
      pricing.totalAmountYen,
    ),
    'subscription_data[metadata][app]': 'venemo',
  });
  if (priceId) {
    params.set('line_items[0][price]', priceId);
  } else {
    // 法人契約は割引後単価で実請求するため、Checkoutごとに価格データを生成する。
    params.set('line_items[0][price_data][currency]', 'jpy');
    params.set(
      'line_items[0][price_data][unit_amount]',
      String(pricing.discountedUnitAmountYen),
    );
    params.set('line_items[0][price_data][recurring][interval]', 'year');
    params.set('line_items[0][price_data][product_data][name]', 'Venemo Plus');
    params.set(
      'line_items[0][price_data][product_data][description]',
      `Business ${pricing.seatCount} seats (${pricing.discountPercent}% OFF)`,
    );
  }

  const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: params.toString(),
  });

  const text = await response.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch (_) {
    data = null;
  }

  if (!response.ok) {
    const errorMessage =
      data?.error?.message || `Stripe checkout作成に失敗しました: ${text}`;
    throw toHttpError(502, errorMessage);
  }

  if (!data?.id || !data?.url) {
    throw toHttpError(502, 'Stripe checkoutレスポンスが不正です');
  }

  return {
    checkoutSessionId: String(data.id),
    checkoutUrl: String(data.url),
    billingCycle: pricing.billingCycle,
    productId:
      priceId ||
      `venemo.plus.business.${pricing.billingCycle}.${pricing.seatCount}.${pricing.discountPercent}`,
    contractType: pricing.contractType,
    seatCount: pricing.seatCount,
    discountPercent: pricing.discountPercent,
    chargedUnitAmountYen: pricing.discountedUnitAmountYen,
    chargedTotalAmountYen: pricing.totalAmountYen,
  };
}

function applyStripeEventToSubscription(eventDataObject) {
  const object = eventDataObject && typeof eventDataObject === 'object'
    ? eventDataObject
    : {};
  const metadata =
    object.metadata && typeof object.metadata === 'object' ? object.metadata : {};
  const provider = String(metadata.mail_provider || '').trim().toLowerCase();
  const email = String(
    metadata.mail_email || object.customer_email || '',
  ).trim().toLowerCase();

  if (!provider || !email) {
    throw toHttpError(
      400,
      'Stripeイベントに mail_provider / mail_email メタデータがありません',
    );
  }

  const sessionLike = { provider, email };
  const productId = String(
    object.plan?.id ||
      object.items?.data?.[0]?.price?.id ||
      object.display_items?.[0]?.plan?.id ||
      '',
  ).trim();
  const currentPeriodEndSec = Number(
    object.current_period_end ||
      object.expires_at ||
      object.subscription_details?.current_period_end ||
      0,
  );
  const expiresAt =
    Number.isFinite(currentPeriodEndSec) && currentPeriodEndSec > 0
      ? new Date(currentPeriodEndSec * 1000).toISOString()
      : '';
  const status = String(object.status || '').toLowerCase();
  const activeStatus = status === 'active' || status === 'trialing';
  const normalizedStatus = activeStatus ? 'active' : 'canceled';
  const plan = activeStatus ? 'plus' : 'free';
  const contractType = normalizeContractType(metadata.contract_type);
  const billingCycle = normalizeBillingCycleForContract(
    metadata.billing_cycle
      ? normalizeBillingCycle(metadata.billing_cycle)
      : determineBillingCycleByProductId(productId),
    contractType,
  );
  const seatCount = normalizeSeatCount(metadata.seat_count, contractType);
  const discountPercent = discountPercentBySeatCount(seatCount, contractType);

  const next = upsertSubscriptionBySession(
    sessionLike,
    {
      plan,
      status: normalizedStatus,
      billingCycle,
      source: 'stripe',
      productId,
      contractType,
      seatCount,
      discountPercent,
      expiresAt,
    },
    { provider: 'stripe', eventObject: object },
  );

  return toSubscriptionResponse(next);
}

function renderOAuthResultPage({ targetOrigin = '*', payload }) {
  const target = String(targetOrigin || '*').trim() || '*';
  const messageText = JSON.stringify(payload || {}).replace(/</g, '\\u003c');

  return `<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Venemo OAuth</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #f5f5f7; color: #1d1d1f; display:flex; align-items:center; justify-content:center; height:100vh; margin:0; }
    .panel { background:#fff; border:1px solid rgba(0,0,0,0.08); border-radius:10px; padding:20px 24px; max-width:420px; }
    .title { font-size:16px; font-weight:600; margin-bottom:8px; }
    .sub { font-size:13px; color:#6e6e73; line-height:1.5; }
  </style>
</head>
<body>
  <div class="panel">
    <div class="title">Venemo 認証完了</div>
    <div class="sub">このウィンドウは自動で閉じます。閉じない場合は手動で閉じてください。</div>
  </div>
  <script>
    (function() {
      var payload = ${JSON.stringify(messageText)};
      var targetOrigin = ${JSON.stringify(target)};
      try {
        if (window.opener && !window.opener.closed) {
          window.opener.postMessage(payload, targetOrigin);
        }
      } catch (e) {
        try {
          window.opener && window.opener.postMessage(payload, '*');
        } catch (_) {}
      }
      setTimeout(function() { window.close(); }, 120);
    })();
  </script>
</body>
</html>`;
}

app.get('/api/health', (_req, res) => {
  const deps = getMailDependencies();
  const providers = {};
  for (const provider of Object.keys(OAUTH_PROVIDERS)) {
    try {
      getOAuthConfig(provider);
      providers[provider] = true;
    } catch (_) {
      providers[provider] = false;
    }
  }

  res.json({
    ok: true,
    service: 'venemo-mail-bridge',
    timestamp: new Date().toISOString(),
    mailBridgeReady: !deps.error,
    hasOpenAIKey: Boolean(process.env.OPENAI_API_KEY),
    oauthConfigured: providers,
    billing: {
      plusMonthlyPriceYen: PLUS_MONTHLY_PRICE_YEN,
      plusYearlyPriceYen: PLUS_YEARLY_PRICE_YEN,
      stripeConfigured: stripeConfigured(),
    },
  });
});

app.get('/api/system/providers', (_req, res) => {
  const deps = getMailDependencies();
  const oauthEnabled = {};
  for (const provider of Object.keys(MAIL_PROVIDERS)) {
    try {
      getOAuthConfig(provider);
      oauthEnabled[provider] = true;
    } catch (_) {
      oauthEnabled[provider] = false;
    }
  }

  res.json({
    providers: Object.keys(MAIL_PROVIDERS),
    oauthEnabled,
    passwordLoginEnabled: ALLOW_PASSWORD_LOGIN,
    mailBridgeReady: !deps.error,
    dependencyError: deps.error ? deps.error.message : null,
  });
});

app.get('/api/subscription/config', (_req, res) => {
  const corporateDiscounts = [
    { seatCount: 20, discountPercent: 15 },
    { seatCount: 40, discountPercent: 20 },
  ];
  res.json({
    plus: {
      monthlyPriceYen: PLUS_MONTHLY_PRICE_YEN,
      yearlyPriceYen: PLUS_YEARLY_PRICE_YEN,
      corporateDiscounts,
      stripeEnabled: stripeConfigured(),
      stripePublicKey: STRIPE_PUBLIC_KEY || null,
      products: {
        stripeMonthlyPriceId: STRIPE_PRICE_ID_MONTHLY || null,
        stripeYearlyPriceId: STRIPE_PRICE_ID_YEARLY || null,
        iosMonthlyProductId:
          String(process.env.IOS_PLUS_MONTHLY_PRODUCT_ID || '').trim() ||
          'venemo.plus.monthly',
        iosYearlyProductId:
          String(process.env.IOS_PLUS_YEARLY_PRODUCT_ID || '').trim() ||
          'venemo.plus.yearly',
        androidMonthlyProductId:
          String(process.env.ANDROID_PLUS_MONTHLY_PRODUCT_ID || '').trim() ||
          'venemo.plus.monthly',
        androidYearlyProductId:
          String(process.env.ANDROID_PLUS_YEARLY_PRODUCT_ID || '').trim() ||
          'venemo.plus.yearly',
      },
    },
  });
});

app.post('/api/subscription/status', mailSessionRequired, withSubscription, (req, res) => {
  return res.json({
    ok: true,
    subscription: req.subscription,
  });
});

app.post('/api/subscription/dev/activate', mailSessionRequired, (req, res) => {
  const contractType = normalizeContractType(req.body?.contractType);
  const cycle = normalizeBillingCycleForContract(
    req.body?.billingCycle || 'monthly',
    contractType,
  );
  const seatCount = normalizeSeatCount(req.body?.seatCount, contractType);
  const discountPercent = discountPercentBySeatCount(seatCount, contractType);
  const expiresAt = new Date(
    Date.now() +
      (cycle === 'yearly' ? 370 : 32) * 24 * 60 * 60 * 1000,
  ).toISOString();

  const next = upsertSubscriptionBySession(
    req.mailSession,
    {
      plan: 'plus',
      status: 'active',
      billingCycle: cycle,
      source: 'dev',
      productId: `dev.plus.${cycle}`,
      contractType,
      seatCount,
      discountPercent,
      expiresAt,
    },
    { reason: 'manual dev activation' },
  );

  return res.json({
    ok: true,
    subscription: toSubscriptionResponse(next),
  });
});

app.post('/api/subscription/dev/cancel', mailSessionRequired, (req, res) => {
  const next = upsertSubscriptionBySession(
    req.mailSession,
    {
      plan: 'free',
      status: 'canceled',
      source: 'dev',
      productId: '',
      contractType: 'individual',
      seatCount: 1,
      discountPercent: 0,
      expiresAt: '',
    },
    { reason: 'manual dev cancel' },
  );
  return res.json({
    ok: true,
    subscription: toSubscriptionResponse(next),
  });
});

app.post('/api/subscription/web/checkout', mailSessionRequired, async (req, res) => {
  try {
    const contractType = normalizeContractType(req.body?.contractType);
    const billingCycle = normalizeBillingCycleForContract(
      req.body?.billingCycle || 'monthly',
      contractType,
    );
    const seatCount = normalizeSeatCount(req.body?.seatCount, contractType);
    const discountPercent = discountPercentBySeatCount(seatCount, contractType);
    const successUrl =
      String(req.body?.successUrl || '').trim() ||
      STRIPE_SUCCESS_URL ||
      'http://localhost:8080/#/settings?billing=success';
    const cancelUrl =
      String(req.body?.cancelUrl || '').trim() ||
      STRIPE_CANCEL_URL ||
      'http://localhost:8080/#/settings?billing=cancel';

    const checkout = await createStripeCheckoutSession({
      session: req.mailSession,
      billingCycle,
      contractType,
      seatCount,
      discountPercent,
      successUrl,
      cancelUrl,
    });

    return res.json({
      ok: true,
      ...checkout,
    });
  } catch (error) {
    return res.status(responseStatusByError(error, 500)).json({
      error: error.message,
    });
  }
});

app.post('/api/subscription/webhook/stripe', (req, res) => {
  try {
    if (SUBSCRIPTION_WEBHOOK_SECRET) {
      const stripeSignature = String(req.header('stripe-signature') || '').trim();
      if (stripeSignature) {
        verifyStripeWebhookSignature(
          String(req.rawBody || ''),
          stripeSignature,
          SUBSCRIPTION_WEBHOOK_SECRET,
        );
      } else {
        // ローカル検証用途: Stripeヘッダーがない場合のみ独自ヘッダーを許可。
        const sentSecret = String(req.header('X-Venemo-Webhook-Secret') || '').trim();
        if (sentSecret !== SUBSCRIPTION_WEBHOOK_SECRET) {
          return res.status(401).json({ error: 'webhook secret mismatch' });
        }
      }
    }

    const event = req.body && typeof req.body === 'object' ? req.body : {};
    const eventId = String(event.id || '').trim();
    const type = String(event.type || '').trim();
    const object = event.data?.object;
    if (!type || !object) {
      return res.status(400).json({ error: 'invalid stripe webhook payload' });
    }
    if (eventId && isStripeEventProcessed(eventId)) {
      return res.json({ ok: true, duplicate: true, eventId, type });
    }

    const handledTypes = new Set([
      'checkout.session.completed',
      'customer.subscription.created',
      'customer.subscription.updated',
      'customer.subscription.deleted',
      'invoice.payment_succeeded',
      'invoice.payment_failed',
    ]);
    if (!handledTypes.has(type)) {
      markStripeEventProcessed(eventId, type);
      return res.json({ ok: true, ignored: true, type });
    }

    let statusObject = object;
    if (type.startsWith('invoice.') && object.subscription_details) {
      statusObject = {
        ...object.subscription_details,
        metadata: {
          ...(object.subscription_details.metadata || {}),
          ...(object.metadata || {}),
        },
        customer_email: object.customer_email,
      };
    }

    const subscription = applyStripeEventToSubscription(statusObject);
    markStripeEventProcessed(eventId, type);
    return res.json({ ok: true, type, subscription });
  } catch (error) {
    return res.status(responseStatusByError(error, 500)).json({
      error: error.message,
    });
  }
});

app.post('/api/subscription/apple/verify', mailSessionRequired, (req, res) => {
  if (!ENABLE_BILLING_STUB) {
    return res.status(501).json({
      error:
        'Apple課金検証は未設定です。ENABLE_BILLING_STUB=true で開発用スタブを有効化してください。',
    });
  }

  const transactionId = String(req.body?.transactionId || '').trim();
  const productId = String(req.body?.productId || '').trim();
  const contractType = normalizeContractType(req.body?.contractType);
  const billingCycle = normalizeBillingCycleForContract(
    req.body?.billingCycle || determineBillingCycleByProductId(productId),
    contractType,
  );
  const seatCount = normalizeSeatCount(req.body?.seatCount, contractType);
  const discountPercent = discountPercentBySeatCount(seatCount, contractType);

  if (!transactionId || !productId) {
    return res
      .status(400)
      .json({ error: 'transactionId と productId は必須です' });
  }

  const expiresAt = new Date(
    Date.now() +
      (billingCycle === 'yearly' ? 370 : 32) * 24 * 60 * 60 * 1000,
  ).toISOString();

  const next = upsertSubscriptionBySession(
    req.mailSession,
    {
      plan: 'plus',
      status: 'active',
      source: 'apple',
      billingCycle,
      productId,
      contractType,
      seatCount,
      discountPercent,
      expiresAt,
    },
    {
      provider: 'apple',
      transactionId,
      originalTransactionId: String(req.body?.originalTransactionId || '').trim(),
      receiptSample: String(req.body?.receiptData || '').trim().slice(0, 32),
      verificationMode: 'server-stub',
    },
  );

  return res.json({
    ok: true,
    verification: 'stub',
    subscription: toSubscriptionResponse(next),
  });
});

app.post('/api/subscription/google/verify', mailSessionRequired, (req, res) => {
  if (!ENABLE_BILLING_STUB) {
    return res.status(501).json({
      error:
        'Google課金検証は未設定です。ENABLE_BILLING_STUB=true で開発用スタブを有効化してください。',
    });
  }

  const purchaseToken = String(req.body?.purchaseToken || '').trim();
  const productId = String(req.body?.productId || '').trim();
  const contractType = normalizeContractType(req.body?.contractType);
  const billingCycle = normalizeBillingCycleForContract(
    req.body?.billingCycle || determineBillingCycleByProductId(productId),
    contractType,
  );
  const seatCount = normalizeSeatCount(req.body?.seatCount, contractType);
  const discountPercent = discountPercentBySeatCount(seatCount, contractType);

  if (!purchaseToken || !productId) {
    return res
      .status(400)
      .json({ error: 'purchaseToken と productId は必須です' });
  }

  const expiresAt = new Date(
    Date.now() +
      (billingCycle === 'yearly' ? 370 : 32) * 24 * 60 * 60 * 1000,
  ).toISOString();

  const next = upsertSubscriptionBySession(
    req.mailSession,
    {
      plan: 'plus',
      status: 'active',
      source: 'google',
      billingCycle,
      productId,
      contractType,
      seatCount,
      discountPercent,
      expiresAt,
    },
    {
      provider: 'google',
      purchaseToken: `${purchaseToken.slice(0, 8)}...`,
      orderId: String(req.body?.orderId || '').trim(),
      verificationMode: 'server-stub',
    },
  );

  return res.json({
    ok: true,
    verification: 'stub',
    subscription: toSubscriptionResponse(next),
  });
});

app.post('/api/keynest/backup/save', (req, res) => {
  try {
    const encryptedPayload = String(req.body.encryptedPayload || '').trim();
    if (!encryptedPayload) {
      return res.status(400).json({ error: 'encryptedPayload は必須です' });
    }

    const inputBackupId = String(req.body.backupId || '').trim();
    const backupId = inputBackupId || `kn_${crypto.randomBytes(6).toString('hex')}`;
    const nowIso = new Date().toISOString();
    const store = readKeyNestBackupStore();
    const previous = store[backupId] || {};

    store[backupId] = {
      backupId,
      encryptedPayload,
      createdAt: previous.createdAt || nowIso,
      updatedAt: nowIso,
    };

    writeKeyNestBackupStore(store);
    return res.json({
      ok: true,
      backupId,
      updatedAt: nowIso,
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.post('/api/keynest/backup/load', (req, res) => {
  try {
    const backupId = String(req.body.backupId || '').trim();
    if (!backupId) {
      return res.status(400).json({ error: 'backupId は必須です' });
    }

    const store = readKeyNestBackupStore();
    const item = store[backupId];
    if (!item) {
      return res.status(404).json({ error: '指定したバックアップが見つかりません' });
    }

    return res.json({
      ok: true,
      backupId,
      encryptedPayload: item.encryptedPayload || '',
      updatedAt: item.updatedAt || null,
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.post('/api/keynest/push/register', (req, res) => {
  try {
    const deviceId = String(req.body.deviceId || '').trim();
    const token = String(req.body.token || '').trim();
    const apnsToken = String(req.body.apnsToken || '').trim();
    const platform = String(req.body.platform || '').trim().toLowerCase();

    if (!deviceId) {
      return res.status(400).json({ error: 'deviceId は必須です' });
    }
    if (!token && !apnsToken) {
      return res.status(400).json({ error: 'token または apnsToken は必須です' });
    }

    const store = readKeyNestPushStore();
    const nowIso = new Date().toISOString();
    const previous = store[deviceId] || {};

    store[deviceId] = {
      deviceId,
      platform: platform || previous.platform || 'unknown',
      token: token || previous.token || '',
      apnsToken: apnsToken || previous.apnsToken || '',
      createdAt: previous.createdAt || nowIso,
      updatedAt: nowIso,
    };

    writeKeyNestPushStore(store);
    return res.json({
      ok: true,
      deviceId,
      platform: store[deviceId].platform,
      updatedAt: nowIso,
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.post('/api/keynest/push/send-test', async (req, res) => {
  try {
    const deviceId = String(req.body.deviceId || '').trim();
    const title = String(req.body.title || 'KeyNest Test').trim();
    const body = String(req.body.body || 'Push通知のテストです').trim();

    if (!deviceId) {
      return res.status(400).json({ error: 'deviceId は必須です' });
    }

    const store = readKeyNestPushStore();
    const device = store[deviceId];
    if (!device) {
      return res.status(404).json({ error: 'deviceId が見つかりません' });
    }

    const result = await sendPushToDevice(device, {
      title,
      body,
      data: {
        type: 'keynest-test',
        sentAt: new Date().toISOString(),
      },
    });

    return res.json({
      ok: true,
      deviceId,
      provider: result.provider,
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.get('/api/mail/oauth/start', async (req, res) => {
  try {
    const provider = normalizeProvider(req.query.provider);
    const origin = String(req.query.origin || '').trim() || '*';
    const state = createOAuthState({ provider, origin });
    const authorizeUrl = buildOAuthAuthorizeUrl(provider, state);
    return res.redirect(authorizeUrl);
  } catch (error) {
    return res
      .status(responseStatusByError(error, 400))
      .send(`OAuth開始に失敗しました: ${error.message}`);
  }
});

app.get('/api/mail/oauth/callback', async (req, res) => {
  const errorCode = String(req.query.error || '').trim();
  const errorDescription = String(req.query.error_description || '').trim();
  const state = String(req.query.state || '').trim();
  const code = String(req.query.code || '').trim();

  const statePayload = consumeOAuthState(state);
  const targetOrigin = statePayload?.origin || '*';

  if (errorCode) {
    const html = renderOAuthResultPage({
      targetOrigin,
      payload: {
        type: 'venemo-oauth-result',
        ok: false,
        error: errorDescription || errorCode,
      },
    });
    return res.status(200).type('html').send(html);
  }

  if (!statePayload || !statePayload.provider) {
    const html = renderOAuthResultPage({
      targetOrigin,
      payload: {
        type: 'venemo-oauth-result',
        ok: false,
        error: 'state が無効です。ログインをやり直してください。',
      },
    });
    return res.status(200).type('html').send(html);
  }

  if (!code) {
    const html = renderOAuthResultPage({
      targetOrigin,
      payload: {
        type: 'venemo-oauth-result',
        ok: false,
        error: '認可コードが取得できませんでした。',
      },
    });
    return res.status(200).type('html').send(html);
  }

  const provider = statePayload.provider;

  try {
    const tokenPayload = await exchangeOAuthCode(provider, code);
    const email = await resolveOAuthEmail(provider, tokenPayload);

    const account = upsertOAuthAccount({
      provider,
      email,
      refreshToken: tokenPayload.refreshToken,
      accessToken: tokenPayload.accessToken,
      expiresIn: tokenPayload.expiresIn,
    });

    const session = buildOAuthSession(account);
    let unreadCount = 0;
    try {
      unreadCount = await fetchUnreadCount(session);
    } catch (_) {
      unreadCount = 0;
    }

    const token = createMailSession(session);
    const subscription = toSubscriptionResponse(getSubscriptionBySession(session));
    const html = renderOAuthResultPage({
      targetOrigin,
      payload: {
        type: 'venemo-oauth-result',
        ok: true,
        token,
        email: account.email,
        provider: account.provider,
        accountId: account.id,
        unreadCount,
        plusActive: subscription.plusActive ? 'true' : 'false',
        subscriptionPlan: subscription.plan,
      },
    });
    return res.status(200).type('html').send(html);
  } catch (error) {
    const html = renderOAuthResultPage({
      targetOrigin,
      payload: {
        type: 'venemo-oauth-result',
        ok: false,
        error: `OAuthログインに失敗しました: ${error.message}`,
      },
    });
    return res.status(200).type('html').send(html);
  }
});

app.post('/api/mail/login', async (req, res) => {
  try {
    if (!ALLOW_PASSWORD_LOGIN) {
      return res.status(410).json({
        error:
          'パスワードログインは無効です。OAuthでログインしてください（/api/mail/oauth/start）。',
      });
    }

    const provider = normalizeProvider(req.body.provider);
    const email = String(req.body.email || '').trim();
    const password = String(req.body.password || '').trim();

    if (!email || !password) {
      return res.status(400).json({
        error: 'メールアドレスとアプリパスワードを入力してください',
      });
    }

    const session = buildPasswordSession(provider, email, password);
    const unreadCount = await fetchUnreadCount(session);
    const token = createMailSession(session);
    const subscription = toSubscriptionResponse(getSubscriptionBySession(session));

    return res.json({
      token,
      email,
      provider,
      unreadCount,
      authMode: 'password',
      subscription,
    });
  } catch (error) {
    console.error('❌ メールログインエラー:', error.message);
    return res.status(responseStatusByError(error, 401)).json({
      error: `ログインに失敗しました: ${error.message}`,
    });
  }
});

app.post('/api/mail/oauth/restore', async (req, res) => {
  try {
    const provider = normalizeProvider(req.body.provider);
    const accountId = String(req.body.accountId || '').trim();
    const email = String(req.body.email || '').trim().toLowerCase();

    const account = accountId
      ? findAccountById(accountId)
      : findAccountByProviderEmail(provider, email);

    if (!account || account.provider !== provider) {
      return res.status(404).json({
        error: '保存済みOAuthアカウントが見つかりません',
      });
    }

    const session = buildOAuthSession(account);
    let unreadCount = 0;
    try {
      unreadCount = await fetchUnreadCount(session);
    } catch (_) {
      unreadCount = 0;
    }

    const token = createMailSession(session);
    const subscription = toSubscriptionResponse(getSubscriptionBySession(session));
    return res.json({
      ok: true,
      token,
      email: account.email,
      provider: account.provider,
      accountId: account.id,
      unreadCount,
      authMode: 'oauth',
      subscription,
    });
  } catch (error) {
    return res
      .status(responseStatusByError(error, 500))
      .json({ error: error.message });
  }
});

app.post('/api/mail/session', mailSessionRequired, async (req, res) => {
  try {
    const session = req.mailSession;
    let email = session.email;

    if (session.authMode === 'oauth') {
      const account = findAccountById(session.accountId);
      if (!account) {
        mailSessions.delete(req.mailSessionToken);
        return res.status(401).json({
          error: 'OAuthアカウントが見つかりません。再ログインしてください',
        });
      }
      email = account.email;
    }

    let unreadCount = 0;
    try {
      unreadCount = await fetchUnreadCount(session);
    } catch (_) {
      unreadCount = 0;
    }

    return res.json({
      ok: true,
      email,
      provider: session.provider,
      unreadCount,
      authMode: session.authMode || 'password',
      accountId: session.authMode === 'oauth' ? session.accountId || '' : '',
      subscription: toSubscriptionResponse(getSubscriptionBySession(session)),
    });
  } catch (error) {
    return res.status(responseStatusByError(error, 500)).json({
      error: error.message,
    });
  }
});

app.post('/api/mail/logout', mailSessionRequired, async (req, res) => {
  const token = req.mailSessionToken;
  const forgetAccount = req.body?.forgetAccount === true;

  if (forgetAccount && req.mailSession.authMode === 'oauth') {
    try {
      deleteAccountById(req.mailSession.accountId);
    } catch (_) {}
  }

  if (token) {
    mailSessions.delete(token);
  }
  return res.json({ ok: true });
});

app.post('/api/mail/list', mailSessionRequired, async (req, res) => {
  try {
    const mailbox = String(req.body.mailbox || 'inbox').toLowerCase();
    const maxResults = toInt(req.body.maxResults, 50);
    const emails = await listEmails(req.mailSession, mailbox, maxResults);
    return res.json({ emails });
  } catch (error) {
    console.error('❌ メール一覧取得エラー:', error.message);
    return res
      .status(responseStatusByError(error, 500))
      .json({ error: error.message });
  }
});

app.post('/api/mail/search', mailSessionRequired, async (req, res) => {
  try {
    const query = String(req.body.query || '').trim().toLowerCase();
    if (!query) {
      return res.json({ emails: [] });
    }

    const maxResults = toInt(req.body.maxResults, 100);
    const emails = await listEmails(req.mailSession, 'inbox', 200);
    const filtered = emails
      .filter((mail) => {
        const text =
          `${mail.from} ${mail.to || ''} ${mail.cc || ''} ${mail.subject} ${mail.snippet}`.toLowerCase();
        return text.includes(query);
      })
      .slice(0, Math.min(Math.max(maxResults, 1), 200));

    return res.json({ emails: filtered });
  } catch (error) {
    console.error('❌ メール検索エラー:', error.message);
    return res
      .status(responseStatusByError(error, 500))
      .json({ error: error.message });
  }
});

app.post('/api/mail/body', mailSessionRequired, async (req, res) => {
  try {
    const id = req.body.id;
    const mailbox = String(req.body.mailbox || 'inbox').toLowerCase();
    const parts = await readEmailBodyParts(req.mailSession, id, mailbox);
    return res.json({
      body: parts.preferred || parts.plain || '',
      plain: parts.plain || '',
      html: parts.html || '',
      preferred: parts.preferred || '',
    });
  } catch (error) {
    console.error('❌ 本文取得エラー:', error.message);
    return res
      .status(responseStatusByError(error, 500))
      .json({ error: error.message });
  }
});

app.post('/api/mail/read', mailSessionRequired, async (req, res) => {
  try {
    const id = req.body.id;
    const unread = req.body.unread === true;
    await updateReadFlag(req.mailSession, id, unread);
    return res.json({ ok: true });
  } catch (error) {
    console.error('❌ 既読状態更新エラー:', error.message);
    return res
      .status(responseStatusByError(error, 500))
      .json({ error: error.message });
  }
});

app.post('/api/mail/trash', mailSessionRequired, async (req, res) => {
  try {
    await moveToTrash(req.mailSession, req.body.id);
    return res.json({ ok: true });
  } catch (error) {
    console.error('❌ ゴミ箱移動エラー:', error.message);
    return res
      .status(responseStatusByError(error, 500))
      .json({ error: error.message });
  }
});

app.post('/api/mail/unread', mailSessionRequired, async (req, res) => {
  try {
    const unreadCount = await fetchUnreadCount(req.mailSession);
    return res.json({ unreadCount });
  } catch (error) {
    console.error('❌ 未読件数取得エラー:', error.message);
    return res
      .status(responseStatusByError(error, 500))
      .json({ error: error.message });
  }
});

app.post('/api/mail/send', mailSessionRequired, async (req, res) => {
  try {
    const from = String(req.body.from || '').trim();
    const to = String(req.body.to || '').trim();
    const cc = String(req.body.cc || '').trim();
    const bcc = String(req.body.bcc || '').trim();
    const subject = String(req.body.subject || '').trim();
    const body = String(req.body.body || '').trim();
    const bodyHtml = String(req.body.bodyHtml || '').trim();
    const attachmentsInput = Array.isArray(req.body.attachments)
      ? req.body.attachments
      : [];

    if (!to || !subject || (!body && !bodyHtml)) {
      return res.status(400).json({ error: '宛先・件名・本文は必須です' });
    }

    const attachments = attachmentsInput
      .map((item) => {
        const filename =
          String(item?.filename || 'attachment.bin').trim() || 'attachment.bin';
        const mimeType =
          String(item?.mimeType || 'application/octet-stream').trim() ||
          'application/octet-stream';
        const data = String(item?.data || '').trim();
        if (!data) return null;
        try {
          return {
            filename,
            content: Buffer.from(data, 'base64'),
            contentType: mimeType,
          };
        } catch (_) {
          return null;
        }
      })
      .filter(Boolean);

    const transporter = await createSmtpTransport(req.mailSession);
    await transporter.sendMail({
      from: from || req.mailSession.email,
      to,
      cc: cc || undefined,
      bcc: bcc || undefined,
      subject,
      text: body || undefined,
      html: bodyHtml || undefined,
      attachments: attachments.length > 0 ? attachments : undefined,
    });

    return res.json({ ok: true });
  } catch (error) {
    console.error('❌ メール送信エラー:', error.message);
    return res
      .status(responseStatusByError(error, 500))
      .json({ error: error.message });
  }
});

app.post('/api/mail/draft', mailSessionRequired, async (req, res) => {
  try {
    const from = String(req.body.from || '').trim();
    const to = String(req.body.to || '').trim();
    const cc = String(req.body.cc || '').trim();
    const bcc = String(req.body.bcc || '').trim();
    const subject = String(req.body.subject || '').trim();
    const body = String(req.body.body || '').trim();

    if (!to && !cc && !bcc && !subject && !body) {
      return res.status(400).json({ error: '下書き内容が空です' });
    }

    const saved = await saveDraft(req.mailSession, {
      from,
      to,
      cc,
      bcc,
      subject,
      body,
    });
    return res.json({ ok: true, ...saved });
  } catch (error) {
    console.error('❌ 下書き保存エラー:', error.message);
    return res
      .status(responseStatusByError(error, 500))
      .json({ error: error.message });
  }
});

app.post('/api/ai/generate-text', mailSessionRequired, withSubscription, plusRequired, async (req, res) => {
  try {
    const prompt = String(req.body.prompt || '').trim();
    if (!prompt) {
      return res.status(400).json({ error: 'prompt は必須です' });
    }

    const text = await generateAiText({
      systemPrompt:
        'あなたはプロフェッショナルなビジネスメールアシスタントです。日本語で簡潔・丁寧に生成してください。',
      userPrompt: prompt,
      temperature: 0.7,
      maxTokens: 800,
    });
    return res.json({ text });
  } catch (error) {
    console.error('❌ AIテキスト生成エラー:', error.message);
    return res.status(500).json({ error: error.message });
  }
});

app.post('/api/ai/generate-reply', mailSessionRequired, withSubscription, plusRequired, async (req, res) => {
  try {
    const emailContent = String(req.body.emailContent || '').trim();
    const userSummary = String(req.body.userSummary || '').trim();
    if (!emailContent) {
      return res.status(400).json({ error: 'emailContent は必須です' });
    }

    const prompt = userSummary
      ? `以下のメールに対して、ユーザー指示を優先して返信文を作成してください。\n\n【元メール】\n${emailContent}\n\n【ユーザー指示】\n${userSummary}\n\n返信本文のみを日本語で出力してください。`
      : `以下のメールに対して、丁寧な返信文を日本語で作成してください。\n\n【元メール】\n${emailContent}\n\n返信本文のみを出力してください。`;

    const text = await generateAiText({
      systemPrompt:
        'あなたはプロフェッショナルなメール返信アシスタントです。返信本文のみを出力してください。',
      userPrompt: prompt,
      temperature: 0.5,
      maxTokens: 800,
    });
    return res.json({ text });
  } catch (error) {
    console.error('❌ AI返信生成エラー:', error.message);
    return res.status(500).json({ error: error.message });
  }
});

app.post('/api/ai/improve-reply', mailSessionRequired, withSubscription, plusRequired, async (req, res) => {
  try {
    const reply = String(req.body.reply || '').trim();
    if (!reply) {
      return res.status(400).json({ error: 'reply は必須です' });
    }

    const text = await generateAiText({
      systemPrompt:
        'あなたはプロフェッショナルなメール編集者です。文意を保ちつつ、読みやすく丁寧に改善してください。',
      userPrompt: `以下の返信文を改善してください。\n\n${reply}`,
      temperature: 0.7,
      maxTokens: 800,
    });
    return res.json({ text });
  } catch (error) {
    console.error('❌ AI改善エラー:', error.message);
    return res.status(500).json({ error: error.message });
  }
});

app.post('/api/generate-reply', mailSessionRequired, withSubscription, plusRequired, async (req, res) => {
  try {
    const emailSubject = String(req.body.emailSubject || '').trim();
    const emailBody = String(req.body.emailBody || '').trim();
    const senderName = String(req.body.senderName || '').trim();
    if (!emailBody) {
      return res.status(400).json({ error: 'emailBody は必須です' });
    }

    const text = await generateAiText({
      systemPrompt:
        'あなたはプロフェッショナルなメール返信アシスタントです。丁寧で簡潔な日本語のビジネスメール返信文を生成してください。',
      userPrompt: `以下のメールに対する返信文を生成してください。\n\n件名: ${emailSubject}\n送信者: ${senderName}\n本文:\n${emailBody}`,
      temperature: 0.7,
      maxTokens: 500,
    });
    return res.json({ reply: text, text });
  } catch (error) {
    console.error('❌ AI返信生成エラー:', error.message);
    return res.status(500).json({ error: 'AI返信の生成に失敗しました' });
  }
});

app.listen(PORT, () => {
  const deps = getMailDependencies();
  const pushConfig = getPushConfigStatus();
  const oauthEnabled = {};
  for (const provider of Object.keys(MAIL_PROVIDERS)) {
    try {
      getOAuthConfig(provider);
      oauthEnabled[provider] = true;
    } catch (_) {
      oauthEnabled[provider] = false;
    }
  }

  console.log('🚀 バックエンドサーバーが起動しました');
  console.log(`   URL: http://localhost:${PORT}`);
  console.log(`   OAuth Redirect: ${OAUTH_REDIRECT_URI}`);
  console.log('   エンドポイント:');
  console.log('   - GET  /api/health');
  console.log('   - GET  /api/system/providers');
  console.log('   - GET  /api/subscription/config');
  console.log('   - POST /api/subscription/status');
  console.log('   - POST /api/subscription/dev/activate');
  console.log('   - POST /api/subscription/dev/cancel');
  console.log('   - POST /api/subscription/web/checkout');
  console.log('   - POST /api/subscription/webhook/stripe');
  console.log('   - POST /api/subscription/apple/verify');
  console.log('   - POST /api/subscription/google/verify');
  console.log('   - POST /api/keynest/backup/save');
  console.log('   - POST /api/keynest/backup/load');
  console.log('   - POST /api/keynest/push/register');
  console.log('   - POST /api/keynest/push/send-test');
  console.log('   - GET  /api/mail/oauth/start');
  console.log('   - GET  /api/mail/oauth/callback');
  console.log('   - POST /api/mail/login');
  console.log('   - POST /api/mail/oauth/restore');
  console.log('   - POST /api/mail/session');
  console.log('   - POST /api/mail/logout');
  console.log('   - POST /api/mail/list');
  console.log('   - POST /api/mail/search');
  console.log('   - POST /api/mail/body');
  console.log('   - POST /api/mail/read');
  console.log('   - POST /api/mail/trash');
  console.log('   - POST /api/mail/unread');
  console.log('   - POST /api/mail/send');
  console.log('   - POST /api/mail/draft');
  console.log('   - POST /api/ai/generate-text (Plus + session required)');
  console.log('   - POST /api/ai/generate-reply (Plus + session required)');
  console.log('   - POST /api/ai/improve-reply (Plus + session required)');
  console.log(`   OAuth enabled: ${JSON.stringify(oauthEnabled)}`);
  console.log(`   Password login enabled: ${ALLOW_PASSWORD_LOGIN}`);
  console.log(`   Billing stub enabled: ${ENABLE_BILLING_STUB}`);
  console.log(
    `   Push config: ${JSON.stringify({
      fcmReady: pushConfig.fcmReady,
      fcmProject: pushConfig.fcmReady ? pushConfig.fcmMessage : null,
      apnsReady: pushConfig.apnsReady,
    })}`,
  );
  if (!pushConfig.fcmReady) {
    console.warn(`⚠️ FCM未設定: ${pushConfig.fcmMessage}`);
  }
  if (!pushConfig.apnsReady) {
    console.warn('⚠️ APNs未設定: iOSはFCM経由のみで送信します');
  }

  if (deps.error) {
    console.warn(
      `⚠️ Mail bridge 依存が不足しています（AI API は利用可）: ${deps.error.message}`,
    );
  }
});

setInterval(() => {
  const now = Date.now();

  for (const [token, session] of mailSessions.entries()) {
    const ageMs = now - (session.createdAt || 0);
    if (ageMs > SESSION_TTL_MS) {
      mailSessions.delete(token);
    }
  }

  for (const [state, data] of oauthStates.entries()) {
    const ageMs = now - (data.createdAt || 0);
    if (ageMs > OAUTH_STATE_TTL_MS) {
      oauthStates.delete(state);
    }
  }
}, 60 * 1000);

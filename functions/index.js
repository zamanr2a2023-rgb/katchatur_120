const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const Stripe = require("stripe");

initializeApp();

const db = getFirestore();
const stripeSecret = defineSecret("STRIPE_SECRET_KEY");
const webhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

const SUCCESS_URL =
  "https://bajatzu.app/donate-success?session_id={CHECKOUT_SESSION_ID}";
const CANCEL_URL = "https://bajatzu.app/donate-cancel";

// IMPORTANT: keep this server-side validation to avoid trusting Flutter values.
const MIN_DONATION_EUR = 1; // €1.00
const MAX_DONATION_EUR = 500; // €500.00 (adjust if you want)

function toStripeCurrency(symbol) {
  const value = `${symbol || "eur"}`.trim().toLowerCase();
  if (value === "€" || value === "eur") return "eur";
  if (value === "$" || value === "usd") return "usd";
  if (value === "£" || value === "gbp") return "gbp";
  if (/^[a-z]{3}$/.test(value)) return value;
  return "eur";
}

function toUnitAmount(amount) {
  const n = Number(amount);
  if (!Number.isFinite(n) || n < 1) {
    throw new HttpsError("invalid-argument", "Enter a valid donation amount.");
  }
  return Math.round(n * 100);
}

async function saveDonation({
  sessionId,
  paymentIntentId,
  uid,
  email,
  displayName,
  amount,
  currency,
  status,
}) {
  // Prevent rewriting createdAt repeatedly on webhook retries.
  const ref = db.collection("donations").doc(sessionId);
  const existing = await ref.get().catch(() => null);
  const createdAtValue =
    existing && existing.exists ? undefined : FieldValue.serverTimestamp();

  const data = {
    stripeSessionId: sessionId,
    paymentIntentId: paymentIntentId || null,
    uid: uid || null,
    email: email || null,
    displayName: displayName || null,
    amount,
    currency,
    paymentStatus: status,
    provider: "stripe",
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (createdAtValue) data.createdAt = createdAtValue;

  await ref.set(data, { merge: true });
}

exports.createCheckoutSession = onCall(
  {
    region: "europe-west1",
    secrets: [stripeSecret],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Please sign in to donate.");
    }

    try {
      const secretKey = `${stripeSecret.value() || ""}`.trim();
      if (!secretKey || secretKey.includes("YOUR_STRIPE")) {
        throw new HttpsError(
          "failed-precondition",
          "Stripe is not configured yet. Add your Stripe secret key.",
        );
      }
      const keyPrefix = secretKey.slice(0, 8);
      if (!/^sk_(test|live)_/.test(secretKey) && !/^rk_(test|live)_/.test(secretKey)) {
        throw new HttpsError(
          "failed-precondition",
          `Wrong Stripe key (starts with "${keyPrefix}"). Copy Secret key from Stripe Dashboard → Developers → API keys → Reveal. It must start with sk_test_ or sk_live_.`,
        );
      }

      const stripe = new Stripe(secretKey);
      const amountEur = Number(request.data?.amount);
      if (!Number.isFinite(amountEur)) {
        throw new HttpsError("invalid-argument", "Enter a valid donation amount.");
      }
      if (amountEur < MIN_DONATION_EUR || amountEur > MAX_DONATION_EUR) {
        throw new HttpsError(
          "invalid-argument",
          `Donation must be between €${MIN_DONATION_EUR} and €${MAX_DONATION_EUR}.`,
        );
      }
      const currency = toStripeCurrency(request.data?.currency);
      if (currency !== "eur") {
        throw new HttpsError("invalid-argument", "Only EUR donations are allowed.");
      }
      const amount = toUnitAmount(amountEur);
      const user = request.auth;

      const session = await stripe.checkout.sessions.create({
        mode: "payment",
        success_url: SUCCESS_URL,
        cancel_url: CANCEL_URL,
        customer_email: user.token.email || undefined,
        payment_method_types: ["card"],
        line_items: [
          {
            quantity: 1,
            price_data: {
              currency,
              unit_amount: amount,
              product_data: {
                name: "Bajatzu chef donation",
                description: "Support the Bajatzu kitchen team",
              },
            },
          },
        ],
        metadata: {
          uid: user.uid,
          email: user.token.email || "",
          displayName: user.token.name || "",
        },
      });

      try {
        await saveDonation({
          sessionId: session.id,
          uid: user.uid,
          email: user.token.email || "",
          displayName: user.token.name || "",
          amount: amount / 100,
          currency,
          status: "pending",
        });
      } catch (firestoreError) {
        console.error("saveDonation failed", firestoreError);
      }

      if (!session.url) {
        throw new HttpsError("internal", "Stripe did not return a checkout URL.");
      }

      return {
        sessionId: session.id,
        url: session.url,
      };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("createCheckoutSession failed", error);
      const message = `${error?.message || ""}`;
      if (/invalid api key|invalid key|no api key/i.test(message)) {
        throw new HttpsError(
          "failed-precondition",
          "Wrong Stripe key. Use the Secret key from Stripe Dashboard (starts with sk_test_ or sk_live_), not the publishable key.",
        );
      }
      throw new HttpsError(
        "internal",
        message || "Could not start Stripe checkout. Please try again.",
      );
    }
  }
);

exports.confirmDonation = onCall(
  {
    region: "europe-west1",
    secrets: [stripeSecret],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Please sign in to donate.");
    }

    const sessionId = `${request.data?.sessionId || ""}`.trim();
    if (!sessionId) {
      throw new HttpsError("invalid-argument", "Missing checkout session.");
    }

    const stripe = new Stripe(stripeSecret.value());
    const session = await stripe.checkout.sessions.retrieve(sessionId);

    if (session.metadata?.uid && session.metadata.uid !== request.auth.uid) {
      throw new HttpsError("permission-denied", "This donation belongs to another account.");
    }

    // IMPORTANT: Do not mark donations as paid here.
    // Firestore authoritative writes must come from the Stripe webhook only.
    const paid = session.payment_status === "paid";

    return {
      paid,
      // client can show UI success, but Firestore paid status comes from webhook.
    };
  }
);

exports.stripeWebhook = onRequest(
  {
    region: "europe-west1",
    secrets: [stripeSecret, webhookSecret],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    const stripe = new Stripe(stripeSecret.value());
    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        req.headers["stripe-signature"],
        webhookSecret.value()
      );
    } catch (error) {
      res.status(400).send(`Webhook error: ${error.message}`);
      return;
    }

    if (event.type === "checkout.session.completed") {
      const session = event.data.object;
      const paid = session.payment_status === "paid";
      const paymentIntentId =
        typeof session.payment_intent === "string"
          ? session.payment_intent
          : session.payment_intent?.id;

      await saveDonation({
        sessionId: session.id,
        paymentIntentId: paymentIntentId || null,
        uid: session.metadata?.uid || null,
        email: session.metadata?.email || session.customer_email || null,
        displayName: session.metadata?.displayName || null,
        amount: (session.amount_total || 0) / 100,
        currency: session.currency || "eur",
        status: paid ? "paid" : "pending",
      });
    }

    res.json({ received: true });
  }
);

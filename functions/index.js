const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

/**
 * Sends a nudge notification to a duo partner.
 * Rate limit: 5 nudges per duo per day.
 */
exports.sendDuoNudge = functions.https.onCall(async (data, context) => {
  // 1. Validate Authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Only authenticated users can send nudges."
    );
  }

  const { partnerName, partnerUid } = data;
  const senderUid = context.auth.uid;
  const senderName = context.auth.token.name || "Your partner";

  if (!partnerUid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Partner UID is required."
    );
  }

  // 2. Fetch Partner's FCM Token
  const partnerDoc = await db.collection("users").doc(partnerUid).get();
  if (!partnerDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Partner not found.");
  }

  const fcmToken = partnerDoc.data().fcmToken;
  if (!fcmToken) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Partner hasn't enabled notifications."
    );
  }

  // 3. Rate Limiting (deterministic duo ID)
  const duoId = senderUid < partnerUid 
    ? `${senderUid}_${partnerUid}` 
    : `${partnerUid}_${senderUid}`;
  
  const duoRef = db.collection("duos").doc(duoId);
  const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD

  return db.runTransaction(async (transaction) => {
    const duoSnapshot = await transaction.get(duoRef);
    if (!duoSnapshot.exists) {
      throw new functions.https.HttpsError("failed-precondition", "Duo record not found.");
    }

    const duoData = duoSnapshot.data();
    const nudgeStats = duoData.nudgeStats || {};
    const dailyCount = nudgeStats.lastDate === today ? (nudgeStats.count || 0) : 0;

    if (dailyCount >= 5) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Max 5 nudges per day reached for this duo."
      );
    }

    // 4. Send FCM Message
    const message = {
      token: fcmToken,
      notification: {
        title: `${senderName} is cheering you on!`,
        body: "Your duo partner sent you a nudge. Keep going!",
      },
      data: {
        screen: "duo",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "tandem_main",
          color: "#7C5CFF",
        },
      },
    };

    await admin.messaging().send(message);

    // 5. Update Nudge Count
    transaction.update(duoRef, {
      nudgeStats: {
        lastDate: today,
        count: dailyCount + 1,
      },
    });

    return { success: true, count: dailyCount + 1 };
  });
});

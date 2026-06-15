const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");

admin.initializeApp();

const db = admin.firestore();

exports.sendNotification = onDocumentCreated(
  {
    document: "notifications/{notificationId}",
    region: "asia-southeast2",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notification = snapshot.data();
    const recipientId = notification.recipientId;

    if (!recipientId) {
      await markNotification(event.params.notificationId, {
        fcmStatus: "failed",
        fcmError: "Missing recipientId",
      });
      return;
    }

    const userRef = db.collection("users").doc(recipientId);
    const userSnapshot = await userRef.get();
    if (!userSnapshot.exists) {
      await markNotification(event.params.notificationId, {
        fcmStatus: "failed",
        fcmError: "Recipient user not found",
      });
      return;
    }

    const user = userSnapshot.data() || {};
    const tokens = unique([
      ...(Array.isArray(user.fcmTokens) ? user.fcmTokens : []),
      user.fcmToken,
    ]).filter(Boolean);

    if (tokens.length === 0) {
      await markNotification(event.params.notificationId, {
        fcmStatus: "failed",
        fcmError: "Recipient has no FCM token",
      });
      logger.warn("Notification skipped: no FCM token", {
        recipientId,
        notificationId: event.params.notificationId,
      });
      return;
    }

    const title = notification.title || "FoodBridge";
    const body = notification.body || "";
    const payloadData = toStringMap({
      notificationId: event.params.notificationId,
      type: notification.type,
      ...(notification.data || {}),
    });

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {title, body},
      data: payloadData,
      android: {
        priority: "high",
        notification: {
          sound: "default",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    const invalidTokens = collectInvalidTokens(response, tokens);
    if (invalidTokens.length > 0) {
      await removeInvalidTokens(userRef, user.fcmToken, invalidTokens);
    }

    await markNotification(event.params.notificationId, {
      fcmStatus: response.failureCount === 0 ? "sent" : "partial_failed",
      fcmSentAt: admin.firestore.FieldValue.serverTimestamp(),
      fcmSuccessCount: response.successCount,
      fcmFailureCount: response.failureCount,
      fcmInvalidTokenCount: invalidTokens.length,
      fcmTokenCount: tokens.length,
    });
  },
);

exports.checkFoodPostExpiry = onSchedule(
  {
    schedule: "every 30 minutes",
    region: "asia-southeast2",
    timeZone: "Asia/Jakarta",
  },
  async () => {
    const now = new Date();
    const expiringSoon = new Date(now.getTime() + 2 * 60 * 60 * 1000);

    const snapshot = await db
      .collection("food_posts")
      .where("status", "==", "available")
      .get();

    if (snapshot.empty) {
      logger.info("No available food posts to check.");
      return;
    }

    const batch = db.batch();
    let updateCount = 0;
    let notificationCount = 0;

    snapshot.docs.forEach((doc) => {
      const post = doc.data();
      const expiredAt = toDate(post.expiredAt);
      if (!expiredAt) return;

      if (expiredAt <= now) {
        batch.update(doc.ref, {
          status: "expired",
          expiredNotificationSentAt:
            post.expiredNotificationSentAt ||
            admin.firestore.FieldValue.serverTimestamp(),
        });
        updateCount += 1;

        if (!post.expiredNotificationSentAt) {
          const notificationRef = db.collection("notifications").doc();
          batch.set(notificationRef, {
            recipientId: post.donorId,
            senderId: "system",
            senderName: "FoodBridge",
            type: "food_expired",
            title: "Makanan Kedaluwarsa",
            body: `${post.title || "Postingan makanan"} sudah melewati waktu kedaluwarsa.`,
            data: {
              foodId: doc.id,
              donorId: post.donorId,
            },
            deliveredAt: null,
            readAt: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          notificationCount += 1;
        }

        return;
      }

      if (expiredAt <= expiringSoon && !post.expiringNotificationSentAt) {
        batch.update(doc.ref, {
          expiringNotificationSentAt:
            admin.firestore.FieldValue.serverTimestamp(),
        });

        const notificationRef = db.collection("notifications").doc();
        batch.set(notificationRef, {
          recipientId: post.donorId,
          senderId: "system",
          senderName: "FoodBridge",
          type: "food_expiring_soon",
          title: "Makanan Hampir Kedaluwarsa",
          body: `${post.title || "Postingan makanan"} akan kedaluwarsa kurang dari 2 jam lagi.`,
          data: {
            foodId: doc.id,
            donorId: post.donorId,
          },
          deliveredAt: null,
          readAt: null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        updateCount += 1;
        notificationCount += 1;
      }
    });

    if (updateCount === 0 && notificationCount === 0) {
      logger.info("No expiry updates needed.");
      return;
    }

    await batch.commit();
    logger.info("Food post expiry check completed.", {
      updateCount,
      notificationCount,
    });
  },
);

function collectInvalidTokens(response, tokens) {
  const invalidTokens = [];

  response.responses.forEach((result, index) => {
    if (result.success) return;

    const code = result.error && result.error.code;
    logger.warn("FCM send failed", {
      tokenIndex: index,
      code,
      message: result.error && result.error.message,
    });

    if (
      code === "messaging/invalid-registration-token" ||
      code === "messaging/registration-token-not-registered"
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  return invalidTokens;
}

async function removeInvalidTokens(userRef, currentToken, invalidTokens) {
  const cleanup = {
    fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
  };

  if (currentToken && invalidTokens.includes(currentToken)) {
    cleanup.fcmToken = admin.firestore.FieldValue.delete();
  }

  await userRef.update(cleanup);
}

async function markNotification(notificationId, fields) {
  await db.collection("notifications").doc(notificationId).set(
    {
      ...fields,
      fcmUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

function unique(values) {
  return [...new Set(values)];
}

function toStringMap(data) {
  return Object.entries(data || {}).reduce((result, [key, value]) => {
    if (value === undefined || value === null) return result;
    result[key] = typeof value === "object" ? JSON.stringify(value) : `${value}`;
    return result;
  }, {});
}

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getDatabase } = require("firebase-admin/database");

initializeApp();
const db = getFirestore();
const rtdb = getDatabase();

exports.sendNotificationOnOutOfArea = onDocumentUpdated(
  {
    document: "Patient/{patientId}",
    region: "southamerica-east1"
  },
  async (event) => {
    const patientId = event.params.patientId;
    console.log("Função disparada para patientId:", patientId);

    const afterFirestore = event.data.after.data();
    if (!afterFirestore) {
      console.error("Dados do paciente ausentes no evento.");
      return;
    }

    const status = afterFirestore.status;
    const code = afterFirestore.code;
    if (!code) {
      console.error("Paciente sem code para buscar no RTDB.");
      return;
    }

    // Buscar dados no Realtime Database
    const snapshot = await rtdb.ref(`locations/${code}`).get();
    const afterRealtime = snapshot.exists() ? snapshot.val() : {};
    console.log("afterRealtime:", afterRealtime);

    const battery = afterRealtime?.battery ?? 0;
    const speed = afterRealtime?.speed ?? 0;
    const latitude = afterRealtime?.latitude ?? null;
    const longitude = afterRealtime?.longitude ?? null;
    const isUnknown = status === "unknown";

    // Condições de alerta
    const isOutOfArea = status === "outOfArea";
    const lowBattery = battery < 25;
    const highSpeed = speed > 2;
    const noLocation = latitude === null || longitude === null || afterFirestore.locationAvailable === false;

    const userIds = Array.isArray(afterFirestore.userId) ? afterFirestore.userId : [];
    if (userIds.length === 0) {
      console.error("Nenhum userId encontrado no paciente.");
      return;
    }

    console.log("status:", status);
    console.log("battery:", battery);
    console.log("speed:", speed);
    console.log("latitude:", latitude, "longitude:", longitude);
    console.log("isOutOfArea:", isOutOfArea, "lowBattery:", lowBattery, "highSpeed:", highSpeed, "noLocation:", noLocation);

    for (const userId of userIds) {
      try {
        const notifDoc = await db.collection("users_notifications").doc(userId).get();
        if (!notifDoc.exists) continue;
        const token = notifDoc.data().notification_token;
        if (!token) continue;

        const alerts = [];
        if (isOutOfArea && !noLocation && !isUnknown) {
        alerts.push({
          title: "⚠️ Fora da área segura",
          body: `O monitorado ${afterFirestore.name} está fora da área segura.`
        });
}

        if (lowBattery) alerts.push({
          title: "⚠️ Bateria baixa",
          body: `O monitorado ${afterFirestore.name} está com bateria baixa (${battery}%).`
        });
        if (highSpeed) alerts.push({
          title: "⚠️ Alta velocidade",
          body: `O monitorado ${afterFirestore.name} está se movendo a ${speed} km/h.`
        });
        if (noLocation || isUnknown) {
          alerts.push({
            title: "⚠️ Localização indisponível",
            body: `Não foi possível obter a localização atual do monitorado ${afterFirestore.name}.`
          });
}

        for (const alert of alerts) {
          await getMessaging().send({
            token,
            android: { priority: "high" },
            notification: {
              title: alert.title,
              body: alert.body,
            },
            data: { patientId, status },
          });
          console.log(`Notificação enviada para ${userId}: ${alert.title}`);
        }
      } catch (error) {
        console.error("Erro ao enviar notificação para userId:", userId, error);

        if (
          error.code === "messaging/registration-token-not-registered" ||
          error.code === "messaging/invalid-argument"
        ) {
          await db.collection("users_notifications").doc(userId).update({
            notification_token: admin.firestore.FieldValue.delete(),
          });
          console.log(`Token inválido removido para userId: ${userId}`);
        }
      }
    }
  }
);

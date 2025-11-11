const { onValueWritten } = require("firebase-functions/v2/database");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();


/**
 * RTDB → locations/{code}
 * - Bateria: notificar quando <25 e valor mudar (sem duplicar)
 * - Velocidade: notificar quando cruzar de <=2 → >2
 */
exports.onLocationUpdate = onValueWritten(
  {
    ref: "locations/{code}",
    location: "southamerica-east1", // RTDB: usar "location"
  },
  async (event) => {
    const before = event.data.before.val();
    const after = event.data.after.val();
    if (!after) return;

    const code = event.params.code;

    const batteryBefore = before?.battery ?? null;
    const batteryNow = after.battery ?? null;

    const speedBefore = before?.speed ?? null;
    const speedNow = after.speed ?? null;

    //
    // 🔋 BATERIA — Notificar se mudou E for < 25
    //
    if (batteryNow !== null && batteryNow < 25 && batteryNow !== batteryBefore) {
      const patientSnap = await db.collection("Patient")
        .where("code", "==", code)
        .limit(1)
        .get();
      if (patientSnap.empty) return;

      const patientRef = patientSnap.docs[0].ref;
      const name = patientSnap.docs[0].data().name ?? "Monitorado";

      // Evitar duplicação usando Firestore
      const shouldNotify = await db.runTransaction(async (tx) => {
        const doc = await tx.get(patientRef);
        const last = doc.data()?.lastBatteryNotified ?? null;

        if (last === batteryNow) return false;

        tx.update(patientRef, { lastBatteryNotified: batteryNow });
        return true;
      });

      if (shouldNotify) {
        await notify(code, "Bateria baixa", `${name} está com ${batteryNow}% de bateria.`);
      }
    }

    //
    // 🚀 VELOCIDADE — disparar só quando cruza limite
    //
    if (
      speedBefore !== null &&
      speedNow !== null &&
      speedBefore <= 2 &&
      speedNow > 2
    ) {
      const patientSnap = await db.collection("Patient").where("code", "==", code).limit(1).get();
      if (!patientSnap.empty) {
        const name = patientSnap.docs[0].data().name ?? "Monitorado";
        await notify(code, "Alta velocidade", `${name} está a ${speedNow} km/h.`);
      }
    }
  }
);


/**
 * 🔄 Função genérica para enviar notificações (sem duplicar)
 * → Usa *data only* (não usa notification:) para evitar duplicidade
 */
async function notify(code, title, body) {
  const patientQ = await db.collection("Patient").where("code", "==", code).limit(1).get();
  if (patientQ.empty) return;

  const patient = patientQ.docs[0].data();
  const userIds = Array.isArray(patient.userId) ? patient.userId : [];
  if (userIds.length === 0) return;

  for (const uid of userIds) {
    const notifDoc = await db.collection("users_notifications").doc(uid).get();
    if (!notifDoc.exists) continue;

    const token = notifDoc.data().notification_token;
    if (!token) continue;

    await messaging.send({
      token,
      data: {
        tipo: "geral",
        title,
        body,
      },
      android: {
        priority: "high",
      },
    });
  }
}


/**
 * Firestore → Patient/{patientId}
 * - Fora da área / Dentro da área
 * - Localização indisponível (locationAvailable mudou para false)
 */
exports.sendOutOfAreaNotification = onDocumentUpdated(
  {
    document: "Patient/{patientId}",
    region: "southamerica-east1",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;

    const name = after.name ?? "Monitorado";
    const userIds = Array.isArray(after.userId) ? after.userId : [];
    if (userIds.length === 0) return;

    let title = "";
    let body = "";

    // Estado da cerca
    if (before.status !== after.status) {
      if (after.status === "outOfArea") {
        title = "Fora da área segura";
        body = `${name} saiu da área segura.`;
      } else if (after.status === "active") {
        title = "De volta à área segura";
        body = `${name} voltou para a área segura.`;
      }
    }

    // Localização indisponível
    if (before.locationAvailable !== after.locationAvailable && after.locationAvailable === false) {
      title = "Localização indisponível";
      body = `Não foi possível obter a localização de ${name}.`;
    }

    if (!title) return;

    for (const uid of userIds) {
      const notifDoc = await db.collection("users_notifications").doc(uid).get();
      if (!notifDoc.exists) continue;
      const token = notifDoc.data().notification_token;
      if (!token) continue;

      await messaging.send({
        token,
        data: {
          tipo: "geral",
          title,
          body,
        },
        android: {
          priority: "high",
        },
      });
    }
  }
);


/**
 * 🚨 Emergência — canal especial com som
 */
exports.sendNotificationOnEmergency = onDocumentUpdated(
  {
    document: "Patient/{patientId}",
    region: "southamerica-east1",
  },
  async (event) => {
    const beforeData = event.data.before.data() || {};
    const afterData = event.data.after.data() || {};
    if (beforeData.emergency || !afterData.emergency) return;

    const patientName = afterData.name ?? "Monitorado";
    const userIds = Array.isArray(afterData.userId) ? afterData.userId : [];
    if (userIds.length === 0) return;

    for (const uid of userIds) {
      const doc = await db.collection("users_notifications").doc(uid).get();
      if (!doc.exists) continue;
      const token = doc.data().notification_token;
      if (!token) continue;

      await messaging.send({
        token,
        data: {
          tipo: "emergencia",
          title: "🚨 Emergência detectada!",
          body: `${patientName} acionou o alerta de emergência.`,
        },
        android: { priority: "high" },
      });
    }
  }
);

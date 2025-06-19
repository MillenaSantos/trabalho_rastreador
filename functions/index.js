const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

exports.sendNotificationOnOutOfArea = onDocumentUpdated(
  {
    document: "Patient/{patientId}",
    region: "southamerica-east1"
  },
  async (event) => {
    console.log("Função disparada para patientId:", event.params.patientId);

    const after = event.data.after.data();

    if (after.status !== "outOfArea") {
      console.log("Status novo não é 'outOfArea', não envia notificação.");
      return;
    }

    const userId = after.userId;
    if (!userId) {
      console.error("userId não encontrado no documento do paciente.");
      return;
    }

    const notifDoc = await db.collection("users_notifications").doc(userId).get();
    if (!notifDoc.exists) {
      console.error(`users_notifications não encontrado para userId: ${userId}`);
      return;
    }

    const token = notifDoc.data().notification_token;
    if (!token) {
      console.error("Token de notificação ausente.");
      return;
    }

    const message = {
      token: token,
      notification: {
        title: "⚠️ Alerta de Localização",
        body: `O paciente ${after.name} está fora da área segura.`,
      },
      data: {
        patientId: event.params.patientId,
        status: after.status,
      },
    };

    try {
      await getMessaging().send(message);
      console.log(`Notificação enviada para userId: ${userId}`);
    } catch (error) {
      console.error("Erro ao enviar notificação:", error);
    }
  }
);

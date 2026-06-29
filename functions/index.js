const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Вызывается из приложения при создании заказа
exports.sendOrderNotification = functions.https.onCall(async (data, context) => {
  const { orderId, orderTitle, city, budget, type, tokens } = data;

  if (!tokens || tokens.length === 0) {
    return { success: false, message: 'Нет получателей' };
  }

  const title = type === 'request' ? 'Новый заказ' : 'Новое предложение';
  const body = `${orderTitle} в г. ${city}. Бюджет: ${budget} ₽`;

  const payload = {
    notification: { title, body },
    data: { orderId, type },
  };

  try {
    const response = await admin.messaging().sendToDevice(tokens, payload);
    return { success: true, results: response.results };
  } catch (error) {
    console.error('Ошибка отправки уведомлений:', error);
    throw new functions.https.HttpsError('internal', 'Не удалось отправить уведомления');
  }
});

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const sendChatMsgToEveryone1 = functions.https.onCall(async (data, context) => {
	const msg = data.msg;
	const senderName = data.senderName;
	const senderId = data.senderId;

	const senderTopic = (await admin.firestore().collection("players").doc(senderId).get()).get("roomId");

	var msgToSend = {
		"notification": {
			"title": "Chat Msg"
		},
		"data": {
			"sender": senderName,
			"msg": msg
		}
	}

	await admin.messaging().sendToTopic(senderTopic, msgToSend);
});
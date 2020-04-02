import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const readyPlayer1 = functions.region("europe-west1").https.onCall(async (data, context) => {
	const roomId = data.roomId;

	if(await (await admin.firestore().collection("roomsTurnData").doc(roomId).get()).get("readyPlayers") === 3)
	{
		let startMsg = {
			"notification": {
				"title": "Start",
				"body": "Everyone is ready. Start!"
			}
		};

		await admin.messaging().sendToTopic(roomId, startMsg);
	}

	await admin.firestore().collection("roomsTurnData").doc(roomId).update({"readyPlayers": admin.firestore.FieldValue.increment(1)});
});
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const addLeftPlayer1 = functions.https.onCall(async (data, context) => {
	const playerId = data.playerId;
	const roomId = data.roomId;

	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);

	await roomDataRef.update({"players": admin.firestore.FieldValue.arrayRemove(playerId)});
	await roomDataRef.update({"leftPlayers": admin.firestore.FieldValue.arrayUnion(playerId)});

	const playerToken = (await admin.firestore().collection("tokens").doc(playerId).get()).get("token");

 	await admin.messaging().unsubscribeFromTopic(playerToken, roomId);
	await roomDataRef.update({"subscribedTokens": admin.firestore.FieldValue.arrayRemove(playerToken)});

	if((await roomDataRef.get()).get("leftPlayers").length >= 2)
	{
		await admin.firestore().collection("roomsTurnData").doc(roomId).update({"finishedPlayers": 2});
	}
})
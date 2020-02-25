import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const sendTeamGameInvitation1 = functions.https.onCall(async (data, context) => {
	const senderName = data.senderName;
	const senderId = data.senderId;
	const friendId = data.friendId;

	const friendToken = await (await admin.firestore().collection("tokens").doc(friendId).get()).get("token");

	var msg = {
		"notification": {
			"title": "Team Invitation",
		},
		"data": {
			"senderName": senderName,
			"senderId": senderId,
		}
	};

	await admin.messaging().sendToDevice(friendToken, msg);
});
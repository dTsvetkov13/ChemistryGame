import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const acceptTeamInvitation1 = functions.region("europe-west1").https.onCall(async (data, context) => {
	const receiverId = data.receiverId;
	const receiverToken = (await admin.firestore().collection("tokens").doc(receiverId).get()).get("token");
	const senderName = data.senderName;

	var teamInvitationAcceptedMsg = {
		"notification": {
			"title": "Team Invation Accepted",
			"body": senderName + " accepted your invitation!"
		},
	}

	await admin.messaging().sendToDevice(receiverToken, teamInvitationAcceptedMsg);
})
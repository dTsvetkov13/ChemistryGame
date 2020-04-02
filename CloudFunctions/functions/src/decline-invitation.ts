import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const declineInvitation1 = functions.region("europe-west1").https.onCall(async (data, context) => {
	const userId = data.userId;
	const friendUsername = data.friendUsername;
	const friendUid = await (await admin.auth().getUserByEmail(friendUsername + "@domain.com")).uid;

	await admin.firestore().collection("invitations").doc(userId)
	.update({"invitations": admin.firestore.FieldValue.arrayRemove(friendUid)});
})
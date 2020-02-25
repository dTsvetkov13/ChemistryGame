import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const addFriend1 = functions.https.onCall(async (data, context) => {
	const friendUsername = data.friendUsername;
	const userId = data.userId;
	const friendUid = await (await admin.auth().getUserByEmail(friendUsername + "@domain.com")).uid;

	await admin.firestore().collection("invitations").doc(friendUid).get().then(async (doc) => {
		if(doc.exists)
		{
			await admin.firestore().collection("invitations").doc(friendUid)
			.update({"invitations": admin.firestore.FieldValue.arrayUnion(userId)});
		}
		else
		{
			await admin.firestore().collection("invitations").doc(friendUid)
			.set({"invitations": admin.firestore.FieldValue.arrayUnion(userId)});
		}
	})
});
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const acceptInvitation1 = functions.region("europe-west1").https.onCall(async (data, context) => {
	const userId = data.userId;
	const friendUsername = data.friendUsername;
	const friendId = await (await admin.auth().getUserByEmail(friendUsername + "@domain.com")).uid;
	
	await admin.firestore().collection("invitations").doc(userId)
	.update({"invitations": admin.firestore.FieldValue.arrayRemove(friendId)});

	await admin.firestore().collection("friends").doc(userId).get().then(async (doc) => {
		if(doc.exists)
		{
			await admin.firestore().collection("friends").doc(userId)
			.update({"friends": admin.firestore.FieldValue.arrayUnion(friendId)});
		}
		else
		{
			await admin.firestore().collection("friends").doc(userId)
			.set({"friends": admin.firestore.FieldValue.arrayUnion(friendId)});
		}
	})

	await admin.firestore().collection("friends").doc(friendId).get().then(async (doc) => {
		if(doc.exists)
		{
			await admin.firestore().collection("friends").doc(friendId)
			.update({"friends": admin.firestore.FieldValue.arrayUnion(userId)});
		}
		else
		{
			await admin.firestore().collection("friends").doc(friendId)
			.set({"friends": admin.firestore.FieldValue.arrayUnion(userId)});
		}
	})
})
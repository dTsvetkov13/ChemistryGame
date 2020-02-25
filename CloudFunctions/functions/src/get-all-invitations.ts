import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const getAllInvitations1 = functions.https.onCall(async (data, context) => {
	const userId = data.userId;

	let result = new Array<string>();

	const invitations = (await admin.firestore().collection("invitations").doc(userId).get()).get("invitations");

	for(let i = 0; i < invitations.length; i++)
	{
		const email = (await admin.auth().getUser(invitations[i])).email;
		const username = email?.split("@")[0];

		if(username !== undefined) result.push(username);
	}

	return result;
})
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const getOnlineFriends1 = functions.region("europe-west1").https.onCall(async (data, context) => {
	const userId = data.userId;

	let result = new Array<{name: string, id: string}>();

	const friends = (await admin.firestore().collection("friends").doc(userId).get()).get("friends");

	if(friends === undefined)
	{
		return false;
	}

	for(let i = 0; i < friends.length; i++)
	{
		const user = (await admin.auth().getUser(friends[i]));
		
		const email = user.email;
		const username = email?.split("@")[0];

		const id = user.uid;

		if(username !== undefined) result.push({name: username, id: id});
	}

	return result;
})
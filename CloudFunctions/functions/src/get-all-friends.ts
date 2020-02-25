import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const getAllFriends1 = functions.https.onCall(async (data, context) => {
	const userId = data.userId;

	let result = new Array<{username: string, singleGameWins: string, teamGameWins: string}>();

	const friends = (await admin.firestore().collection("friends").doc(userId).get()).get("friends");

	if(friends === undefined)
	{
		return result;
	}

	for(let i = 0; i < friends.length; i++)
	{
		// const email = (await admin.auth().getUser(friends[i])).email;
		// const username = email?.split("@")[0];
		const tempUsers = (await admin.firestore().collection("users").doc(friends[i]).get());

		result.push({username: tempUsers.get("username"),
						singleGameWins: tempUsers.get("singleGameWins").toString(),
						teamGameWins: tempUsers.get("teamGameWins").toString()});

		// if(username !== undefined) result.push(username);
	}

	return result;
})
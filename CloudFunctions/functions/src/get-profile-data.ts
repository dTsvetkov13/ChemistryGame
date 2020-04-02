import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const getProfileData1 = functions.region("europe-west1").https.onCall(async (data, context) => {
	const userId = data.userId;

	const userRef = admin.firestore().collection("users").doc(userId);

	const userName = (await userRef.get()).get("username");
	const singleGameWins = (await userRef.get()).get("singleGameWins");
	const teamGameWins = (await userRef.get()).get("teamGameWins");

	return {
		"userName": userName,
		"singleGameWins": singleGameWins.toString(),
		"teamGameWins": teamGameWins.toString()
	};
});
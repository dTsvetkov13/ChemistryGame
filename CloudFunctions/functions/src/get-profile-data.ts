import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const getProfileData1 = functions.https.onCall(async (data, context) => {
	const userId = data.userId;
	// const userToken = data.userToken;

	const userRef = admin.firestore().collection("users").doc(userId);

	const userName = (await userRef.get()).get("username");
	const singleGameWins = (await userRef.get()).get("singleGameWins");
	const teamGameWins = (await userRef.get()).get("teamGameWins");

	// var profileData = {
	// 	"notification": {
	// 		"title": "Profile Data"
	// 	},
	// 	"data": {
	// 		"userName": userName,
	// 		"singleGameWins": singleGameWins.toString(),
	// 		"teamGameWins": teamGameWins.toString()
	// 	}
	// }

	// await admin.messaging().sendToDevice(userToken, profileData);

	return {
		"userName": userName,
		"singleGameWins": singleGameWins.toString(),
		"teamGameWins": teamGameWins.toString()
	};
});
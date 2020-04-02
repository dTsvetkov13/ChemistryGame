import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const updateCurrToken1 = functions.region("europe-west1").https.onCall(async (data, context) => {
	const userId = data.userId;
	const userToken = data.userToken;

	await admin.firestore().collection("tokens").doc(userId).set({"token": userToken});
});
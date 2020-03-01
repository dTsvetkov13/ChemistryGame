import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const updateUser1 = functions.https.onCall(async (data, context) => {
	const id = data.id ? data.id : null;
	const username = data.username ? data.username.toString() : null;
	const singleGameWins = (data.singleGameWins || data.singleGameWins === 0) ? data.singleGameWins : null;
	const teamGameWins = (data.teamGameWins || data.singleGameWins === 0)? data.teamGameWins : null;
	const email = data.email;

	if(id === null) {
		console.log("Id is null!");
	}

	if(username !== null) {
		await admin.firestore().collection("users").doc(id.toString()).set({"username" : username});
		console.log("Username success");
	}
	else {
		console.log("Username = null");
	}

	if(email !== null) {
		await admin.firestore().collection("users").doc(id.toString()).update({"email" : email});
		console.log("Email success");
	}
	else {
		console.log("Email = null");
	}
	
	if(singleGameWins !== null) {
		await admin.firestore().collection("users").doc(id.toString()).update({"singleGameWins" : singleGameWins});
		console.log("SingleGameWins success");
	}
	else {
		console.log("Invalid singleGameWins");
	}
	
	if(teamGameWins !== null) {
		await admin.firestore().collection("users").doc(id.toString()).update({"teamGameWins" : teamGameWins});
		console.log("TeamGameWins success");
	}
	else {
		console.log("Invalid teamGameWins");
	}

	console.log("Successful");
	return "Successful";
})
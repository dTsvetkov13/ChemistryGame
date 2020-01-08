import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
admin.initializeApp()

//export const helloWorld = functions.https.onRequest((request, response) => {
//		response.send("Hello from Firebase!");
//});

export const writeToDb = functions.https.onCall(async (data, context) => {
	const name = data.data ? data.data : 'World';
	await admin.firestore().collection("users").doc("ids").set({name : name});
    return "Item added!"
})

export const readFromDb = functions.https.onCall((data, context) => {
    return "Item added!"
})

export const updateUser = functions.https.onCall(async (data, context) => {
	const id = data.id ? data.id : null;
	const username = data.username ? data.username.toString() : null;
	const singleGameWins = (data.singleGameWins || data.singleGameWins == 0) ? data.singleGameWins : null;
	const teamGameWins = (data.teamGameWins || data.singleGameWins == 0)? data.teamGameWins : null;
	
	if(id === null) return "Invalid id"
	

	if(username !== null) {
		await admin.firestore().collection("users").doc(id.toString()).update({"username" : username});
		console.log("Username success");
	}
	else {
		console.log("Username = null");
	}
	
	if(singleGameWins !== null) {
		await admin.firestore().collection("users").doc(id.toString()).update({"singleGameWins" : singleGameWins});
		console.log("SingleGameWins success");
	}
	else {
		console.log("Invalid first");
	}
	
	if(teamGameWins !== null) {
		await admin.firestore().collection("users").doc(id.toString()).update({"teamGameWins" : teamGameWins});
		console.log("TeamGameWins success");
	}
	else {
		console.log("Invalid second");
	}
	
	//TODO: adding friends

	console.log("Successful");
	return "Successful";
})
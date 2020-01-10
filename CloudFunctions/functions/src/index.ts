import * as functions from 'firebase-functions';
//import {UUID} from '../node_modules/uuid-generator-ts';
import * as admin from 'firebase-admin';
admin.initializeApp();

export const updateUser = functions.https.onCall(async (data, context) => {
	const id = data.id ? data.id : null;
	const username = data.username ? data.username.toString() : null;
	const singleGameWins = (data.singleGameWins || data.singleGameWins === 0) ? data.singleGameWins : null;
	const teamGameWins = (data.teamGameWins || data.singleGameWins === 0)? data.teamGameWins : null;
	
	if(id === null) {
		console.log("Id is null!");
		return "Invalid id";
	} 
	

	if(username !== null) {
		await admin.firestore().collection("users").doc(id.toString()).set({"username" : username});
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

export const createRoom = functions.https.onCall(async (data, context) => {
	const gameType = data.gameType ? data.gameType.toString() : "SingleGame"; //improve here

	//const roomId = new UUID().getDashFreeUUID();

	const roomId = 113; //TODO : create UUID

	const roomRef = admin.firestore().collection("rooms").doc(roomId.toString());

	await roomRef.set({"gameType": gameType});

	console.log("Got Data");

	switch (gameType) {
		case "SingleGame":
			const playerId = data.playerId ? data.playerId.toString() : "";

			await roomRef.update({"freeSeats": 3});

			await roomRef.update({"players": {[playerId]: {"points": 0}}});
			break;
		case "TeamGame":
			const firstPlayerId = data.firstPlayerId.toString();
			const secondPlayerId = data.secondPlayerId.toString();

			await roomRef.set({"teams": {"firstTeam": {[firstPlayerId]: {"points": 0}, [secondPlayerId] : {"points": 0}}}});

			await roomRef.update({"freeSeats": 2});
			break;
		default:
			break;
	}

	return "Created Room";
})

export const updateRoom = functions.https.onCall(async (data, context) => {
	const gameType = data.gameType.toString();
	const roomId = data.roomId.toString();

	const roomRef = await admin.firestore().collection("rooms").doc(roomId);

	switch (gameType) {
		case "SingleGame":
			const playerId = data.playerId.toString();

			await roomRef.update({["players." + playerId] : {"points": 0}});

			await roomRef.update({freeSeats : admin.firestore.FieldValue.increment(-1)});
			break;
		case "TeamGame":
			const firstPlayerId = data.firstPlayerId.toString();
			const secondPlayerId = data.secondPlayerId.toString();

			await roomRef.update({"teams.secondTeam": {[firstPlayerId]: {"points": 0}, [secondPlayerId] : {"points": 0}}});

			await roomRef.update({"freeSeats": 0});
			break;
		default:
			break;
	}

})
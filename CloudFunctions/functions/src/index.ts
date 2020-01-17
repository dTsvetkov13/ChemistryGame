import * as functions from 'firebase-functions';
//import {UUID} from '../node_modules/uuid-generator-ts';
import * as admin from 'firebase-admin';
//import { DataSnapshot } from 'firebase-functions/lib/providers/database';
//const serviceAccount = require("../../../App/chemistry_game/android/app/google-services.json");
const serviceAccount = require("../chemistrygame-cd3a6-firebase-adminsdk-cd58r-855bee1b82");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://chemistrygame-cd3a6.firebaseio.com"
});

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

	const roomId = data.roomId; //TODO : create UUID

	const roomRef = admin.firestore().collection("rooms").doc(roomId.toString());
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId.toString());

	await roomRef.set({"gameType": gameType});

	console.log("Got Data");

	switch (gameType) {
		case "SingleGame":
			const playerId = data.playerId ? data.playerId.toString() : "";
			const playerToken = data.token ? data.token : "";

			await roomRef.update({"freeSeats": 3});

			//await roomDataRef.update({"players": {[playerId]: {"points": 0}}});
			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion(playerId)});
			
			console.log("Token: " + playerToken);
					await admin.messaging().subscribeToTopic(playerToken, roomId.toString())
					.then(function(response) {
						console.log('Successfully subscribed to topic:', response);
						//console.log('Successfully subscribed to topic:', response.errors[0].error);
					})
					.catch(function(error) {
						console.log('Error subscribing to topic:', error);
					});

			const message = {
				"notification": {
					"body": "Successfully Created Room"
				},
			};



			await admin.messaging().sendToTopic(roomId.toString(), message)
				.then((response) => {
					console.log("Successfully sent : " + response);
				})
				.catch((error) => {
					console.log("Error with Messaging : " + error);
				});
				
			console.log("Successfully Created Room");

			break;
		case "TeamGame":
			const firstPlayerId = data.firstPlayerId.toString();
			const secondPlayerId = data.secondPlayerId.toString();

			//await roomDataRef.set({"teams": {"firstTeam": {[firstPlayerId]: {"points": 0}, [secondPlayerId] : {"points": 0}}}});
			
			await roomDataRef.set({"firstTeam": admin.firestore.FieldValue.arrayUnion(firstPlayerId)});
			await roomDataRef.update({"firstTeam": admin.firestore.FieldValue.arrayUnion(secondPlayerId)});

			await roomRef.update({"freeSeats": 2});

			//TODO: Subscribe to topic with tokens received from the players

			/*admin.messaging().subscribeToTopic([firstPlayerId, secondPlayerId], roomId.toString())
				.then(function(response) {
					console.log('Successfully subscribed to topic:', response);
				})
				.catch(function(error) {
					console.log('Error subscribing to topic:', error);
				});*/

			break;
		default:
			break;
	}

	return "Created Room";
})

exports.listenersToRoomFreeSeats = functions.firestore
    .document('rooms/{freeSeats}')
    .onUpdate((change, context) => {
		const data = change.after.exists ? change.after.data() : {freeSeats: 3};
	
		const freeSeats = data !== undefined ? data.freeSeats : 5;

		if(freeSeats === 0)
		{
			//Start game
			//Send to the topic StartMessage
			console.log("Start the Game");
		}
		else
		{
			console.log("Dont start the Game");
		}
    });

export const updateRoom = functions.https.onCall(async (data, context) => {
	const gameType = data.gameType.toString();
	const roomId = data.roomId.toString();

	const roomRef = await admin.firestore().collection("rooms").doc(roomId);
	const roomDataRef = await admin.firestore().collection("roomsData").doc(roomId);

	switch (gameType) {
		case "SingleGame":
			const playerId = data.playerId.toString();

			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion(playerId)});

			await roomRef.update({freeSeats : admin.firestore.FieldValue.increment(-1)});
			break;
		case "TeamGame":
			const firstPlayerId = data.firstPlayerId.toString();
			const secondPlayerId = data.secondPlayerId.toString();

			await roomDataRef.update({"secondTeam": admin.firestore.FieldValue.arrayUnion(firstPlayerId)});
			await roomDataRef.update({"secondTeam": admin.firestore.FieldValue.arrayUnion(secondPlayerId)});

			await roomRef.update({"freeSeats": 0});
			break;
		default:
			break;
	}
})

export const leaveRoom = functions.https.onCall(async (data, context) => { //NOT TESTED
	const roomId = data.roomId.toString();
	const roomRef = await admin.firestore().collection("rooms").doc(roomId);
	const roomDataRef = await admin.firestore().collection("roomsData").doc(roomId);
	const gameType = data.gameType.toString();

	switch (gameType) {
		case "SingleGame":
			const playerId = data.playerId.toString();

			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayRemove(playerId)});

			await roomRef.update({freeSeats : admin.firestore.FieldValue.increment(1)});

			break;
		case "TeamGame":
			//const firstPlayerId = data.firstPlayerId.toString();
			//const secondPlayerId = data.secondPlayerId.toString();

			//await roomRef.delete({"teams.secondTeam" : {"points": 0}}}); //, [secondPlayerId] : {"points": 0}

			//TODO: delete 2 players

			await roomRef.update({"freeSeats": admin.firestore.FieldValue.increment(2)});
			break;
		default:
			break;
	}
})

export const findRoom = functions.https.onCall(async (data, context) => {
	const gameType = data.gameType.toString();

	const roomsRef = admin.firestore().collection("rooms");

	console.log("first");

	const appropriateRooms = roomsRef.where("freeSeats", ">", 0); //.where("gameType", "==", gameType).where("gameType", "==", gameType)

	console.log("well - ");

	await appropriateRooms.get().then(function (querySnapshot) {
		console.log("size : " + querySnapshot.size);
		querySnapshot.forEach(function(doc) {
			console.log(doc.id + " + " + doc.data); //HERE FAIL
			if(doc.data().gameType === gameType)
			{
				switch(gameType) {
					case "SingleGame":
						//join this room
						break;
					case "TeamGame":
						//the 2 players join the room
						break;
					default:
				}
			}
		});
	});

	console.log("Successful");

	return "Successful";
})

export const startGame = functions.https.onCall(async(data, context) => {
	const roomId = data.roomId;
	console.log("Room Id : " + roomId)
	const gameType = data.gameType;
	const roomRef = admin.firestore().collection("rooms").doc(roomId.toString());
	let requiredFinishedPlayers;

	let nextTurn = 0;

	console.log("Before players");

	//configurePlayers
	//Dealing


	switch (gameType) {
		case "SingleGame":
			requiredFinishedPlayers = 2;
			break;
		case "TeamGame":
			requiredFinishedPlayers = 1;
		default:
			break;
	}

	while(await (await roomRef.get()).get("finishedPlayers") !== requiredFinishedPlayers) {
		
		console.log("In while")

		await roomRef.update(
			{"finishedPlayers": admin.firestore.FieldValue.increment(1)}
		)
		
		const message = {
			"notification" : {
				"body": "Player on turn : " + nextTurn
			}	
		}

		await admin.messaging().sendToTopic(roomId.toString(), message);

		if(nextTurn === 3) nextTurn = 0;
		else nextTurn++;

		console.log("Next turn : " + nextTurn);
	}
})

export const configurePlayers = functions.https.onCall(async (data, context) => {
	const roomId = data.roomId.toString();
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	const playersRef = admin.firestore().collection("players");
	const usersRef = admin.firestore().collection("users");

	const playersCount = 1;

	for(let i = 0; i < playersCount; i++)
	{
		const playerId = (await roomDataRef.get()).get("players")[i.toString()];
		await playersRef.doc(playerId.toString()).set({"name": (await usersRef.doc(playerId.toString()).get()).get("username")});

		console.log("Player id : " + playerId);
	}

	return "Successfully configured players";
})

export const dealing = functions.https.onCall(async(data, context) => {
	const roomId = data.roomId.toString();
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	const playersRef = admin.firestore().collection("players");
	const playerIds = [];
	const cardsToDeal = 1; //TODO: change to n
	const playersCount = 1; //TODO: change to 4

	let elementCards = ["H2", "O2", "Cu", "Cl", "Al", "Ar"]; //TODO: get them from somewhere
	let compoundCards = ["H2O", "H2O", "H2O", "H2O", "H2O"]; //TODO: get them from somewhere

	for(let i = 0; i < playersCount; i++)
	{
		playerIds[i] = (await roomDataRef.get()).get("players")[i.toString()];
	}

	let playerIndex = 0;

	for(let i = 0; i < playersCount * cardsToDeal; i++)
	{
		await playersRef.doc(playerIds[playerIndex]).update({"elementCards": admin.firestore.FieldValue.arrayUnion(elementCards[i])});
		await playersRef.doc(playerIds[playerIndex]).update({"compoundCards": admin.firestore.FieldValue.arrayUnion(compoundCards[i])});

		console.log("Cards added");

		if(playerIndex === 3) playerIndex = 0;
		else playerIndex++;
	}

	await roomDataRef.update({"lastCard": elementCards[playersCount * cardsToDeal]});

	await elementCards.splice(0, playersCount * cardsToDeal + 1);

	await roomDataRef.update({"deck": elementCards});

	return "Successfully dealing";
})
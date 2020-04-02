import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
const uuidv4 = require('uuid/v4');

export const findRoom1 = functions.region("europe-west1").https.onCall(async (data, context) => {
	const gameType = data.gameType.toString();

	const roomsRef = admin.firestore().collection("rooms");

	const appropriateRooms = roomsRef.where("freeSeats", ">", 0);

	let foundRoom = false;

	await appropriateRooms.get().then(function (querySnapshot) {
		querySnapshot.forEach(async function(doc) {
			if(foundRoom) return; 

			if(doc.data().gameType === gameType && !foundRoom)
			{
				foundRoom = true;

				switch(gameType) {
					case "SingleGame":
						await updateRoom(data, doc.id); //TODO: Check if the join was successful
						return;
					case "TeamGame":
						await updateRoom(data, doc.id);
						return;
					default:
				}
			}
		});
	});

	//Create a room;

	if(!foundRoom)
	{
		console.log("Create room");	
		await createRoom(data);
	}

	return "Successful";
})

async function createRoom(data: any) {
	const gameType = data.gameType ? data.gameType.toString() : "SingleGame"; //improve here

	const roomId = await uuidv4();

	const roomRef = admin.firestore().collection("rooms").doc(roomId.toString());
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId.toString());

	await roomRef.set({"gameType": gameType});

	const joinMsg = {
		"notification": {
			"title": "Join Room",
			"body": "You joined a room"
		}
	};

	switch (gameType) {
		case "SingleGame":
			const playerId = data.playerId ? data.playerId.toString() : "";
			const playerToken = data.playerToken ? data.playerToken : "";

			await roomRef.update({"freeSeats": 3});

			await roomDataRef.set({"players": admin.firestore.FieldValue.arrayUnion(playerId)});

			await admin.messaging().subscribeToTopic(playerToken, roomId.toString())
				.then(async function(response) {
					console.log('Successfully subscribed to topic:', response);
					await roomDataRef.update({"subscribedTokens": admin.firestore.FieldValue.arrayUnion(playerToken)});
				})
				.catch(function(error) {
					console.log('Error subscribing to topic:', error);
				});

			await admin.messaging().sendToDevice(playerToken, joinMsg)
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
			const firstPlayerToken = data.firstPlayerToken;

			const secondPlayerToken = (await admin.firestore().collection("tokens").doc(secondPlayerId).get()).get("token");
			
			await roomDataRef.set({"players": admin.firestore.FieldValue.arrayUnion(firstPlayerId)});
			
			await roomDataRef.update({"firstTeamPlayerTemp": secondPlayerId});

			await roomRef.update({"freeSeats": 2});

			admin.messaging().subscribeToTopic(firstPlayerToken, roomId.toString())
			.then(async function(response) {
				console.log('Successfully subscribed to topic:', response);
				await roomDataRef.update({"subscribedTokens": admin.firestore.FieldValue.arrayUnion(firstPlayerToken)});
			})
			.catch(function(error) {
				console.log('Error subscribing to topic:', error);
			});

			admin.messaging().subscribeToTopic(secondPlayerToken, roomId.toString())
				.then(async function(response) {
					console.log('Successfully subscribed to topic:', response);
					await roomDataRef.update({"subscribedTokens": admin.firestore.FieldValue.arrayUnion(secondPlayerToken)});
				})
				.catch(function(error) {
					console.log('Error subscribing to topic:', error);
				});
			
			await admin.messaging().sendToDevice(firstPlayerToken, joinMsg)
				.then((response) => {
					console.log("Successfully sent : " + response);
				})
				.catch((error) => {
					console.log("Error with Messaging : " + error);
				});

			await admin.messaging().sendToDevice(secondPlayerToken, joinMsg)
				.then((response) => {
					console.log("Successfully sent : " + response);
				})
				.catch((error) => {
					console.log("Error with Messaging : " + error);
				});
			
			break;
		default:
			break;
	}

	return "Created Room";
};

async function updateRoom(data: any, roomId : string) {
	const gameType = data.gameType.toString();

	const roomRef = await admin.firestore().collection("rooms").doc(roomId);
	const roomDataRef = await admin.firestore().collection("roomsData").doc(roomId);

	const joinMsg = {
		"notification": {
			"title": "Join Room",
			"body": "You joined a room"
		}
	};

	switch (gameType) {
		case "SingleGame":
			const playerId = data.playerId.toString();
			const playerToken = data.playerToken;
			
			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion(playerId)});

			await admin.messaging().subscribeToTopic(playerToken, roomId.toString()).then(async function(response) {
				console.log('Successfully subscribed to topic:', response);
				await roomDataRef.update({"subscribedTokens": admin.firestore.FieldValue.arrayUnion(playerToken)});
			})
			.catch(function(error) {
				console.log('Error subscribing to topic:', error);
			});;

			await roomRef.update({freeSeats : admin.firestore.FieldValue.increment(-1)});

			await admin.messaging().sendToDevice(playerToken, joinMsg);

			console.log("After sending message");

			break;
		case "TeamGame":
			const firstPlayerId = data.firstPlayerId.toString();
			const secondPlayerId = data.secondPlayerId.toString();
			const firstPlayerToken = data.firstPlayerToken;

			const secondPlayerToken = (await admin.firestore().collection("tokens").doc(secondPlayerId).get()).get("token");
			
			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion(firstPlayerId)});

			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion((await roomDataRef.get()).get("firstTeamPlayerTemp"))});

			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion(secondPlayerId)});

			await roomDataRef.update({
				"firstTeamPlayerTemp": admin.firestore.FieldValue.delete()
			});

			await roomRef.update({"freeSeats": 0});

			admin.messaging().subscribeToTopic(firstPlayerToken, roomId.toString())
				.then(async function(response) {
					console.log('Successfully subscribed to topic:', response);
					await roomDataRef.update({"subscribedTokens": admin.firestore.FieldValue.arrayUnion(firstPlayerToken)});
				})
				.catch(function(error) {
					console.log('Error subscribing to topic:', error);
				});

			admin.messaging().subscribeToTopic(secondPlayerToken, roomId.toString())
				.then(async function(response) {
					console.log('Successfully subscribed to topic:', response);
					await roomDataRef.update({"subscribedTokens": admin.firestore.FieldValue.arrayUnion(secondPlayerToken)});
				})
				.catch(function(error) {
					console.log('Error subscribing to topic:', error);
				});
			
			await admin.messaging().sendToDevice(firstPlayerToken, joinMsg)
				.then((response) => {
					console.log("Successfully sent : " + response);
				})
				.catch((error) => {
					console.log("Error with Messaging : " + error);
				});

			await admin.messaging().sendToDevice(secondPlayerToken, joinMsg)
				.then((response) => {
					console.log("Successfully sent : " + response);
				})
				.catch((error) => {
					console.log("Error with Messaging : " + error);
				});

			break;
		default:
			break;
	}
}
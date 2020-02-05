import * as functions from 'firebase-functions';
// import {UUID} from '../node_modules/uuid-generator-ts';
const uuidv4 = require('uuid/v4');
import * as admin from 'firebase-admin';
// import { DataSnapshot } from 'firebase-functions/lib/providers/database';
//import { DataSnapshot } from 'firebase-functions/lib/providers/database';
//import { DataSnapshot } from 'firebase-functions/lib/providers/database';
//const serviceAccount = require("../../../App/chemistry_game/android/app/google-services.json");
const serviceAccount = require("../chemistrygame-cd3a6-firebase-adminsdk-cd58r-855bee1b82");
const WolframAlphaAPI = require('wolfram-alpha-api');
const waApi = WolframAlphaAPI("Q9UK6A-A6767WAL27");

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

// export const createRoom = functions.https.onCall(async (data, context) => {
async function createRoom(data: any) {
	const gameType = data.gameType ? data.gameType.toString() : "SingleGame"; //improve here

	// const roomId = new UUID().getDashFreeUUID();
	// const roomId = uuidv4();

	// const roomId = data.roomId; //TODO : create UUID
	const roomId = await uuidv4();

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

			const joinMsg = {
				"notification": {
					"title": "Join Room",
					"body": "You joined a room"
				}
			};



			await admin.messaging().sendToTopic(roomId.toString(), joinMsg)
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
};

export const addValue = functions.https.onCall(async (data, context) => {
	const name = data.name;
	const uuid = await uuidv4();

	const playerRef = admin.firestore().collection("players").doc("48");

	console.log((await playerRef.get()).get("cards").length);
	
	await playerRef.update({"cards": admin.firestore.FieldValue.arrayUnion({name: name, uuid: uuid})});

	console.log((await playerRef.get()).get("cards").length);
})

async function addNewElementCard(name: string, playerId: string)
{
	const uuid = await uuidv4();

	await admin.firestore().collection("players").doc(playerId).update({"elementCards": admin.firestore.FieldValue.arrayUnion({name: name, uuid: uuid})});

	return {name: name, uuid: uuid};
}

async function addNewCompoundCard(name: string, playerId: string)
{
	const uuid = await uuidv4();

	await admin.firestore().collection("players").doc(playerId).update({"compoundCards": admin.firestore.FieldValue.arrayUnion({name: name, uuid: uuid})});

	return {name: name, uuid: uuid};
}

/*async function removeElementCardFromPlayer(name: string, uuid: string, playerId: string)
{
	await admin.firestore().collection("players").doc(playerId).update({"elementCards": admin.firestore.FieldValue.arrayRemove({name: name, uuid: uuid})});
}

async function removeCompoundCardFromPlayer(name: string, uuid: string, playerId: string)
{
	await admin.firestore().collection("players").doc(playerId).update({"compoundCards": admin.firestore.FieldValue.arrayRemove({name: name, uuid: uuid})});
}*/


export const getValue = functions.https.onCall(async (data, context) => {
	//const name = data.name;
	//const uuid = data.uuid;

	const card = (await admin.firestore().collection("players").doc("48").get()).get("cards")[0];

	console.log(card.Name + " + ID : " + card.Uuid);
})

export const deleteValue = functions.https.onCall(async (data, context) => {
	const name = data.name;
	const uuid = data.uuid;

	const playerRef = admin.firestore().collection("players").doc("48");

	console.log((await playerRef.get()).get("cards").length);
	
	await playerRef.update({"cards": admin.firestore.FieldValue.arrayRemove({Name: name, Uuid: uuid})});

	console.log((await playerRef.get()).get("cards").length);
})

exports.listenersToRoomFreeSeats = functions.firestore
    .document('/rooms/{roomId}')
    .onUpdate(async (change, context) => {
		const data = change.after.exists ? change.after.data() : {freeSeats: 3};
	
		const freeSeats = data !== undefined ? data.freeSeats : 3;

		if(freeSeats === 0)
		{

			//await delay(6000);

			//Start game
			//Send to the topic StartMessage
			

			//Set the nextTurn
			
			//TODO: update nextTurn again to 0;

			//await delay(6000);

			const playersNames = await configurePlayers({roomId: change.after.id});
			await dealing({roomId: change.after.id});		

			const lastCard = await (await admin.firestore().collection("roomsData").doc(change.after.id).get()).get("lastCard");
			let lastCardData = "";

			await admin.firestore().collection("roomsData").doc(change.after.id).update({"gameFinished": true});

			lastCardData = await getCardData(lastCard);
			

			var startMsg = {
				"notification": {
					"title": "Game Started",
					"body": "The Game has started"
				},
				"data": {
					"roomId": change.after.id.toString(),
					"playersNames": playersNames.toString(),
					"lastCard": lastCardData
				}
			}

			await admin.messaging().sendToTopic(change.after.id.toString(), startMsg);

			const roomTurnDataRef = admin.firestore().collection("roomsTurnData").doc(change.after.id.toString());

			
			await roomTurnDataRef.set({"finishedPlayers": 2});
			await roomTurnDataRef.update({"nextTurn": -1});
			await roomTurnDataRef.update({"finishedTurnPlayer": 5});
			await roomTurnDataRef.update({"readyPlayers": 0}); //Change to 0;
			await admin.firestore().collection("roomsData").doc(change.after.id).update({"gameFinished": false});
			await roomTurnDataRef.update({"finishedPlayers": admin.firestore.FieldValue.increment(-1)}); //TODO: change to -2

			console.log("Start the Game");
		}
		else
		{
			console.log("Dont start the Game");
		}
	}
);

export const getPlayerCards = functions.https.onCall(async (data, context) => {
	const playerId = data.playerId.toString();
	const playerToken = data.playerToken.toString();

	const playerRef = admin.firestore().collection("players").doc(playerId);

	const elementCardsCount = (await playerRef.get()).get("elementCards").length;
	const compoundCardsCount = (await playerRef.get()).get("compoundCards").length;
	const playerName = (await playerRef.get()).get("name");

	let compoundCardsString = "";

	let elementDataTemp = "";

	let elementCardsString = "";

	for(let i = 0; i < elementCardsCount; i++)
	{
		elementDataTemp = (await playerRef.get()).get("elementCards")[i].name;
		let elementCardId = (await playerRef.get()).get("elementCards")[i].uuid;

		elementCardsString += elementCardId.toString()+ "," + await getCardData((elementDataTemp)) + "\n";
	}

	let compoundCardTemp;

	for(let i = 0; i < compoundCardsCount; i++)
	{
		compoundCardTemp = (await playerRef.get()).get("compoundCards")[i]
		compoundCardsString += compoundCardTemp.name + "," + compoundCardTemp.uuid + "\n"; 
	}

	// console.log("Element cards: " + elementCardsString);
	// console.log("Compound cards: " + compoundCards.toString());

	var playerCards = {
		"notification": {
			"title": "Player Cards",
		},
		"data": {
			"elementCards": elementCardsString,
			"compoundCards": compoundCardsString,
			"playerName": playerName,
		}
	};

	console.log("Player id: " + playerId);
	console.log("Element cards: " + elementCardsString);
	console.log("Compound Cards : " + compoundCardsString);

	await admin.messaging().sendToDevice(playerToken, playerCards);
})

async function getCardData(name: string)
{
	const cardRef = admin.firestore().collection("elementCards").doc(name);
	let cardData = name;

	await cardRef.get().then((doc: any) => {
		if(doc.exists)
		{
			cardData += "," + doc.data().group + "," + doc.data().period;
		}
	})

	return cardData;
}

export const getDeckCard = functions.https.onCall(async(data, context) => {
	const playerId = data.playerId;
	const roomId = data.roomId;
	const playerToken = data.playerToken;

	const roomsTurnDataRef = await admin.firestore().collection("roomsTurnData").doc(roomId);
	const playerOnTurnIndex = await (await roomsTurnDataRef.get()).get("nextTurn");
	const roomsData = await admin.firestore().collection("roomsData").doc(roomId).get();

	if(playerId === (await roomsData.get("players")[playerOnTurnIndex]))
	{	
		await roomsTurnDataRef.update({"finishedTurnPlayer": playerId});
		console.log("Player is on turn");
		const roomsDataRef = admin.firestore().collection("roomsData").doc(roomId);
		
		let cardToGiveName;

		if(!(await roomsData.get("deck").length > 0))
		{
			const deck = await generateNewDeck();
			cardToGiveName = deck[0];
			await roomsDataRef.update({"deck": deck});
		}
		else
		{
			cardToGiveName = await (roomsData).get("deck")[0];
		}

		const cardData = await addNewElementCard(cardToGiveName, playerId);

		await roomsDataRef.update({"deck": admin.firestore.FieldValue.arrayRemove(cardToGiveName)});

		const cardToGiveData = cardData.uuid + "," + await getCardData(cardToGiveName);

		var getDeckCardMsg = {
			"notification": {
				"title": "Receive Deck Card",
				"body": "You successfully received a card from the deck"
			},
			"data": {
				"cardToGiveData": cardToGiveData
			}
		};

		await admin.messaging().sendToDevice(playerToken, getDeckCardMsg);
	}
})

//TODO: Check if this functions is used
export const getElementCardsData = functions.https.onCall(async (data, context) => {
	const elementCardsRef = await admin.firestore().collection("elementCards");

	let cardsData = new Map<String, any>();

	await elementCardsRef.get().then(function(querySnapshot) {
		querySnapshot.forEach(function(doc) {
			console.log(doc.id, " => ", doc.data());
			cardsData.set(doc.id, doc.data());
		})
	});

	console.log("Cards Data: " + cardsData);

	console.log("Before result");

	return cardsData;
})

export const readyPlayer = functions.https.onCall(async (data, context) => {
	const roomId = data.roomId;

	if(await (await admin.firestore().collection("roomsTurnData").doc(roomId).get()).get("readyPlayers") === 3)
	{
		let startMsg = {
			"notification": {
				"title": "Start",
				"body": "Everyone is ready. Start!"
			}
		};

		await admin.messaging().sendToTopic(roomId, startMsg);
	}

	await admin.firestore().collection("roomsTurnData").doc(roomId).update({"readyPlayers": admin.firestore.FieldValue.increment(1)});
});

//Listen to nextTurn, call nextTurn() and change the nextTurn

exports.listenersToRoomTurnData = functions.firestore
	.document('roomsTurnData/{roomId}')
	.onUpdate(async (change, context) => {
		const data = change.after.data();

		const nextTurn = data !== undefined ? data.nextTurn : 10;

		let requiredFinishedPlayers;

		if(((await admin.firestore().collection("roomsData").doc(change.after.id).get()).get("gameFinished")))
		{
			console.log("The game is already finished");
			return;
		}

		if(await (await admin.firestore().collection("roomsTurnData").doc(change.after.id).get()).get("readyPlayers") < 4)
		{
			console.log("Not every player is ready!");
			return;
		}

		switch (await (await admin.firestore().collection("rooms").doc(change.after.id).get()).get("gameType")) {
			case "SingleGame":
				requiredFinishedPlayers = 2;
				break;
			case "TeamGame":
				requiredFinishedPlayers = 1;
			default:
				requiredFinishedPlayers = 2;
				break;
		}

		if((await admin.firestore().collection("roomsTurnData").doc(change.after.id).get()).get("finishedPlayers") >= requiredFinishedPlayers)
		{
			//TODO: Send message that the game has finished
			/*var gameFinishedMsg = {
				"notification": {
					"title": "Game Finished",
					"body": "The game has finished"
				}
			}

			await admin.messaging().sendToTopic(change.after.id.toString(), gameFinishedMsg);*/
			await admin.firestore().collection("roomsData").doc(change.after.id).update({"gameFinished": true});
			await finishGame(change.after.id);

			console.log("Game Finished");
			return;
		}

		// console.log(change.after.id);
		
		if(nextTurn === -1)
		{
			await admin.firestore().collection("roomsTurnData").doc(change.after.id).update({"nextTurn": admin.firestore.FieldValue.increment(1)});
			return;
		}

		// console.log((await admin.firestore().collection("roomsData").doc(change.after.id).get()).get("deck")[0]);

		const dataBefore = change.before.data();

		const nextTurnBefore = dataBefore !== undefined ? dataBefore.nextTurn : 10;

		console.log("NextTurn : " + nextTurn + ", before : " + nextTurnBefore);

		if(nextTurn !== 10 && nextTurnBefore !== 10 && nextTurnBefore !== nextTurn)
		{
			const playerId = (await admin.firestore().collection("roomsData").doc(change.after.id).get()).get("players")[nextTurn];
			const playerName = (await admin.firestore().collection("players").doc(playerId).get()).get("name");
			console.log("player : " + playerId);

			const nextTurnMsg = {
				"notification" : {
					"title": "Player Turn",
					"body": playerName + " is on turn!",
				},
				"data": {
					"playerId": playerId
				}
			}
	
			await admin.messaging().sendToTopic(change.after.id.toString(), nextTurnMsg);

			await playerTurn(playerId.toString(), change.after.id);

			const nextPlayer = nextTurn === 3 ? 0 : nextTurn + 1;

			await admin.firestore().collection("roomsTurnData").doc(change.after.id).update({"nextTurn": nextPlayer})
			console.log("Next Turn : " + nextPlayer.toString());
			
			//TODO: delete this
			/*await admin.firestore().collection("roomsTurnData").doc(change.after.id).update(
				{"finishedPlayers": admin.firestore.FieldValue.increment(1)}
			);*/
		}
	}
);

async function finishGame(roomId: string)
{
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	const finishedPlayersCount = 1;
	var finishedPlayerIds = new Array<string>();
	const playersCount = 4;

	for(let i = 0; i < finishedPlayersCount; i++)
	{
		finishedPlayerIds.push(await (await roomDataRef.get()).get("finishedPlayerIds")[i]);
		await admin.firestore().collection("players").doc(finishedPlayerIds[i]).update({"points": admin.firestore.FieldValue.increment(100 - (i * 50))});
	}

	console.log("After adding points");

	var playerData: {points: number; name: string; id: string}[] = new Array<{points: number; name: string; id: string}>();

	for(let i = 0; i < playersCount; i++)
	{
		const playerId = await (await roomDataRef.get()).get("players")[i];
		const playerRef = admin.firestore().collection("players").doc(playerId);
		const playerName = (await playerRef.get()).get("name");
		const playerPoints = (await playerRef.get()).get("points");
		playerData.push({name: playerName, points: playerPoints, id: playerId})
	}

	console.log("After getting data: " + playerData);

	var sortedPlayerData: {points: number; name: string; id: string}[] = playerData.sort((p1, p2) => {
		console.log("Compare: " + p1.name + ": " + p1.points + " === " + p2.name + ": " + p2.points);
		
		if(p1.points > p2.points) return -1;
		else if(p1.points < p2.points) return 1;
		else
		{
			if(p1.id === finishedPlayerIds[0])
			{
				return -1;
			}
			else if(p2.id === finishedPlayerIds[0])
			{
				return 1;
			}
			else return 0;
		}

	});

	console.log("Ranking");

	for(let i = 0; i < playersCount; i++)
	{
		console.log(sortedPlayerData[i].name);
	}

	var gameFinishedMsg = {
		"notification": {
			"title": "Game Finished",
			"body": "The game has finished"
		},
		"data": {
			"firstPlace": sortedPlayerData[0].name + "," + sortedPlayerData[0].points.toString(),
			"secondPlace": sortedPlayerData[1].name + "," + sortedPlayerData[1].points.toString(),
			"thirdPlace": sortedPlayerData[2].name + "," + sortedPlayerData[2].points.toString(),
			"fourthPlace": sortedPlayerData[3].name + "," + sortedPlayerData[3].points.toString(),
		}
	}

	await admin.messaging().sendToTopic(roomId, gameFinishedMsg);
	
	const roomsDataRef = admin.firestore().collection("roomsData").doc(roomId)

	for(let i = 0; i < (await roomsDataRef.get()).get("subscribedTokens").length; i++)
	{
		await admin.messaging().unsubscribeFromTopic(await (await roomsDataRef.get()).get("subscribedTokens")[i], roomId);
	}

	switch(await (await admin.firestore().collection("rooms").doc(roomId).get()).get("gameType"))
	{
		case("SingleGame"):
			await admin.firestore().collection("users").doc(sortedPlayerData[0].id)
				.update({"singleGameWins": admin.firestore.FieldValue.increment(1)});
			break;
		case("TeamGame"):
			//TODO: create the team game
			// await admin.firestore().collection("users").doc(sortedPlayerData[0].id)
				// .update({"teamGameWins": admin.firestore.FieldValue.increment(1)});
			break
	}

	for(let i = 0; i < await (await roomDataRef.get()).get("players").length; i++)
	{
		admin.firestore().collection("players").doc((await roomDataRef.get()).get("players")[i]).delete()
		.then(function() {
			console.log("Document successfully deleted!");
		}).catch(function(error) {
			console.error("Error removing document: ", error);
		});
	}

	console.log("End");

	//TODO: Delete the player docs
}

export const getProfileData = functions.https.onCall(async (data, context) => {
	const userId = data.userId;
	const userToken = data.userToken;

	const userRef = admin.firestore().collection("users").doc(userId);

	const userName = (await userRef.get()).get("username");
	const singleGameWins = (await userRef.get()).get("singleGameWins");
	const teamGameWins = (await userRef.get()).get("teamGameWins");

	var profileData = {
		"notification": {
			"title": "Profile Data"
		},
		"data": {
			"userName": userName,
			"singleGameWins": singleGameWins.toString(),
			"teamGameWins": teamGameWins.toString()
		}
	}

	await admin.messaging().sendToDevice(userToken, profileData);
});

// export const updateRoom = functions.https.onCall(async (data, context) => {
async function updateRoom(data: any, roomId : string) {
	const gameType = data.gameType.toString();
	//const roomId = data.roomId.toString();
	const playerToken = data.playerToken;

	const roomRef = await admin.firestore().collection("rooms").doc(roomId);
	const roomDataRef = await admin.firestore().collection("roomsData").doc(roomId);

	const randomNumber = await uuidv4();
	const second = await uuidv4();

	console.log("First: " + randomNumber);
	console.log("Second: " + second);
 
	console.log("Before the gameType: " + roomId);

	switch (gameType) {
		case "SingleGame":
			const playerId = data.playerId.toString();

			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion(playerId)});

			console.log("Before sending message");

			var joinRoomMsg = {
				"notification": {
					"title": "Join Room",
					"body": "You joined a room"
				}
			}

			await admin.messaging().sendToDevice(playerToken, joinRoomMsg);
			await admin.messaging().subscribeToTopic(playerToken, roomId.toString()).then(async function(response) {
				console.log('Successfully subscribed to topic:', response);
				await roomDataRef.update({"subscribedTokens": admin.firestore.FieldValue.arrayUnion(playerToken)});
				//console.log('Successfully subscribed to topic:', response.errors[0].error);
			})
			.catch(function(error) {
				console.log('Error subscribing to topic:', error);
			});;

			await roomRef.update({freeSeats : admin.firestore.FieldValue.increment(-1)});

			console.log("After sending message");

			break;
		case "TeamGame":
			const firstPlayerId = data.firstPlayerId.toString();
			const secondPlayerId = data.secondPlayerId.toString();

			await roomDataRef.update({"secondTeam": admin.firestore.FieldValue.arrayUnion(firstPlayerId)});
			await roomDataRef.update({"secondTeam": admin.firestore.FieldValue.arrayUnion(secondPlayerId)});

			await roomRef.update({"freeSeats": 0});

			//Send msgs to the players

			break;
		default:
			break;
	}
}

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

	let foundRoom = false;

	await appropriateRooms.get().then(function (querySnapshot) {
		console.log("size : " + querySnapshot.size);
		querySnapshot.forEach(async function(doc) {
			if(foundRoom) return; 

			console.log(doc.id + " + " + doc.data); //HERE FAIL
			if(doc.data().gameType === gameType && !foundRoom)
			{
				console.log("In the room check");

				switch(gameType) {
					case "SingleGame":
						console.log("Update Room");
						foundRoom = true;
						await updateRoom(data, doc.id); //Check if the join was successful
							
						//join this room
						return;
					case "TeamGame":
						//the 2 players join the room
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

function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}

async function playerHasTheseCards(playerId: string, leftSideCards: any, rightSideCards: any)
{
	const playerRef = await admin.firestore().collection("players").doc(playerId);
	const elementCards = (await playerRef.get()).get("elementCards");
	const elementCardsCount = (await playerRef.get()).get("elementCards").length;
	const compoundCards = (await playerRef.get()).get("compoundCards");
	const compoundCardsCount = (await playerRef.get()).get("compoundCards").length;

	let matching = 0;

	for(let i = 0; i < elementCardsCount; i++)
	{
		for(let j = 0; j < leftSideCards.length; j++)
		{
			console.log("Left card : " + leftSideCards[j]["name"] + " : " + elementCards[i].name);
			if(leftSideCards[j]["name"] === elementCards[i].name && leftSideCards[j]["uuid"] === elementCards[i].uuid)
			{
				matching++;
				continue;
			}
		}

		for(let j = 0; j < rightSideCards.length; j++)
		{
			console.log("Right card : " + rightSideCards[j]["name"]);
			if(rightSideCards[j]["name"] === elementCards[i].name && rightSideCards[j]["uuid"] === elementCards[i].uuid)
			{
				matching++;
				continue;
			}
		}
	}

	for(let i = 0; i < compoundCardsCount; i++)
	{
		for(let j = 0; j < leftSideCards.length; j++)
		{
			console.log("Left card : " + leftSideCards[j]["name"] + " : " + compoundCards[i].name);
			if(leftSideCards[j]["name"] === compoundCards[i].name && leftSideCards[j]["uuid"] === compoundCards[i].uuid)
			{
				matching++;
				continue;
			}
		}

		for(let j = 0; j < rightSideCards.length; j++)
		{
			console.log("Right card : " + rightSideCards[j].values);
			if(rightSideCards[j]["name"] === compoundCards[i].name && rightSideCards[j]["uuid"] === compoundCards[i].uuid)
			{
				matching++;
				continue;
			}
		}
	}

	console.log("Matching : " + matching + ", required: " + (rightSideCards.length + leftSideCards.length).toString());

	if(matching === (rightSideCards.length + leftSideCards.length))
	{
		return true;
	}
	else
	{
		return false;
	}
}

export const completeReaction = functions.https.onCall(async (data, context) => {
	const playerId = data.playerId.toString();
	const leftSideCards = data.leftSideCards ? data.leftSideCards : [];
	const rightSideCards = data.rightSideCards ? data.rightSideCards : [];
	const playerToken = data.playerToken;

	console.log("leftSideSize : " + leftSideCards.length + ", cards : " + leftSideCards);

	if(!await playerHasTheseCards(playerId, leftSideCards, rightSideCards))
	{
		console.log("Player doesnt have these cards");
		//send message that he doesnt have these cards
		var failedMsg = {
			"notification": {
				"title": "Complete Reaction Failed",
				"body": "You do not have all these cards"
			},
		};

		await admin.messaging().sendToDevice(playerToken, failedMsg);
		return;
	}

	let leftSideString = "";

	if(leftSideCards.length === 0 || rightSideCards.length === 0)
	{
		var emptySideMsg = {
			"notification": {
				"title": "Empty Side",
				"body": "One of the sides is empty"
			}
		};

		console.log("Empty side");

		await admin.messaging().sendToDevice(playerToken, emptySideMsg);
		return;
	}

	leftSideString += leftSideCards[0].name;

	for(let i = 1; i < leftSideCards.length; i++)
	{
		leftSideString += " + " + leftSideCards[i].name;
	}

	console.log("String : " + leftSideString);

	let rightSideString = "";

	rightSideString += rightSideCards[0].name;

	for(let i = 1; i < rightSideCards.length; i++)
	{
		rightSideString += " + " + rightSideCards[i].name;
	}

	console.log("String : " + rightSideString);

	await waApi.getFull({
		input: leftSideString + " -> " + rightSideString,
		includepodid: 'ReactionList:ChemicalReactionData',
		podstate: 'ReactionList:ChemicalReactionData__Show formulas',
		format: 'plaintext',
	// }).then(console.log);
	}).then(async (queryresult: any) => {
		if(queryresult.numpods !== 0)
		{
			console.log(queryresult.pods[0].subpods[0].plaintext);

			if(queryresult.pods[0].subpods[0].plaintext === '(data not available)')
			{
				console.log("No such a reaction");
				//return no such a reaction

				var incorrectReactionMsg = {
					"notification": {
						"title": "Complete Reaction Failed",
						"body": "Incorrect reaction!"
					},
				};
		
				await admin.messaging().sendToDevice(playerToken, incorrectReactionMsg);
				return;
			}
			else
			{
				var receivedString = queryresult.pods[0].subpods[0].plaintext;
				var splitted = receivedString.split("\n")[0].split(" ");
				console.log(splitted);

				//The first one should be the in the cards
				let nextReactant = false;
				let newCardsCount = 0;
				let newCard = true;
				let newCards = [];

				for(let i = 1; i < splitted.length; i++)
				{
					if(nextReactant)
					{
						const currReactant = splitted[i].split("_")[0];

						console.log(i+1 + ": " + currReactant);
						nextReactant = false;
						newCard = true;

						for(let j = 1; j < leftSideCards.length; j++)
						{
							if(leftSideCards[j].name === currReactant)
							{
								console.log("There is it in the left side");
								newCard = false;
							}
						}
						
						for(let j = 1; j < rightSideCards.length; j++)
						{
							if(rightSideCards[j].name === currReactant)
							{
								console.log("There is it in the right side");
								newCard = false;
							}
						}

						if(newCard)
						{
							newCards.push(currReactant);
							newCardsCount++;
						}

						continue;
					}

					if(splitted[i] === '+')
					{
						nextReactant = true;
						continue;
					}
					else
					{
						nextReactant = false;
						continue;
					}
				}

				console.log("newCardsCount : " + newCardsCount);

				if(newCardsCount === 1)
				{
					console.log("Add this card: " + newCards);

					let cardData = "";

					//Deleting cards

					await deleteCardsFromPlayer(playerId, leftSideCards, rightSideCards);
					console.log("Deleted cards");

					//Check the newCard if it is compound or element

					cardData = await addNewCardToPlayer(playerId, newCards[0]);
					console.log("Added new card");

					var correctMsgWithData = {
						"notification": {
							"title": "Complete Reaction Successed",
							"body": "Correct reaction with one missing reactant"
						},
						"data": {
							"cardToAdd": cardData.toString(),
						}
					};

					await admin.messaging().sendToDevice(playerToken, correctMsgWithData);
					//const roomId = (await admin.firestore().collection("players").doc(playerId).get()).get("roomId");
					//await finishGame(roomId);
					//TODO: maybe add bonus points
					return;
				}
				else
				{
					//Fill more cards
					var fillMoreCardsMsg = {
						"notification": {
							"title": "Complete Reaction Failed",
							"body": "You need to fill more cards in the reaction!"
						},
					};
			
					await admin.messaging().sendToDevice(playerToken, fillMoreCardsMsg);
					return;
				}
			}
		}
		else
		{
			console.log("Bonus points");

			// console.log(queryresult.pods[1]);

			var correctMsgWithoutData = {
				"notification": {
					"title": "Complete Reaction Successed",
					"body": "Correct reaction"
				}
			};
	
			await admin.messaging().sendToDevice(playerToken, correctMsgWithoutData);

			//Deleting cards

			await deleteCardsFromPlayer(playerId, leftSideCards, rightSideCards);

			console.log("After deleting");

			await admin.firestore().collection("players").doc(playerId).update({"points": admin.firestore.FieldValue.increment(20)});
			
			if((await admin.firestore().collection("players").doc(playerId).get()).get("elementCards").length <= 0)
			{
				const roomId = await (await admin.firestore().collection("players").doc(playerId).get()).get("roomId");
				await admin.firestore().collection("roomsTurnData").doc(roomId).update({"finishedPlayers": admin.firestore.FieldValue.increment(1)});
				await admin.firestore().collection("roomsData").doc(roomId).update({"finishedPlayerIds": admin.firestore.FieldValue.arrayUnion(playerId)});
			}

			//remove the cards from the player
			//add bonus points
			
		}
	}).catch(console.error)
	//If numpods is equel to 0, there is such a reaction
})

async function addNewCardToPlayer(playerId: string, newCard: any)
{
	var upperCases = 0;
	let cardData = "";

	for(let i = 0; i < newCard.length; i++)
	{
		if(newCard[i] === newCard[i].toUpperCase())
		{
			upperCases++;
		}
	}

	if(upperCases >= 2)
	{
		console.log("Compound Found");
		cardData = newCard.toString();
	}
	else
	{
		// await admin.firestore().collection("elementCards").doc(newCard.toString()).get().then(async (doc: any) => {
		// 	console.log("DOC DATA : " + doc.data());
		// 	if(doc.exists)
		// 	{
		// 		cardData += doc.data().symbol;
		// 		cardData += "," + doc.data().group + "," + doc.data().period;
		// 	}
		// });
		cardData = await getCardData(newCard);
	}

	console.log("Card Data: " + cardData);

	let newCardUuid;

	if(upperCases >= 2)
	{
		// await admin.firestore().collection("players").doc(playerId).update({"compoundCards": admin.firestore.FieldValue.arrayUnion(newCard.toString())});	
		// await admin.firestore().collection("players").doc(playerId).update({"compoundCardsCount": admin.firestore.FieldValue.increment(1)});
		const data = await addNewCompoundCard(newCard, playerId);
		newCardUuid = data.uuid;
	}
	else
	{
		console.log("Element card");
		// await admin.firestore().collection("players").doc(playerId).update({"elementCards": admin.firestore.FieldValue.arrayUnion(newCard.toString())});
		// await admin.firestore().collection("players").doc(playerId).update({"elementCardsCount": admin.firestore.FieldValue.increment(1)});
		const data = await addNewElementCard(newCard, playerId);
		newCardUuid = data.uuid;
	}

	console.log("Before return");

	cardData = newCardUuid + "," + cardData;

	return cardData;
}

async function deleteCardsFromPlayer(playerId: string, leftSideCards: any, rightSideCards: any)
{
	//var upperCases = 0;

	for(let i = 0; i < leftSideCards.length; i++)
	{
		await admin.firestore().collection("players").doc(playerId).update({"elementCards": admin.firestore.FieldValue.arrayRemove(leftSideCards[i])})
		await admin.firestore().collection("players").doc(playerId).update({"compoundCards": admin.firestore.FieldValue.arrayRemove(leftSideCards[i])})
		
		//upperCases = 0;

		/*for(let j = 0; j < leftSideCards[i].length; j++)
		{
			if(leftSideCards[i][j] === leftSideCards[i][j].toUpperCase() && isNaN(Number(leftSideCards[i][j])))
			{
				upperCases++;
			}

			if(upperCases >= 2) break;
		}

		if(upperCases >= 2)
		{
			await admin.firestore().collection("players").doc(playerId).update({"compoundCardsCount": admin.firestore.FieldValue.increment(-1)});
		}
		else
		{
			await admin.firestore().collection("players").doc(playerId).update({"elementCardsCount": admin.firestore.FieldValue.increment(-1)});
		}*/
	}

	for(let i = 0; i < rightSideCards.length; i++)
	{
		await admin.firestore().collection("players").doc(playerId).update({"elementCards": admin.firestore.FieldValue.arrayRemove(rightSideCards[i])})
		await admin.firestore().collection("players").doc(playerId).update({"compoundCards": admin.firestore.FieldValue.arrayRemove(rightSideCards[i])})
		
		/*upperCases = 0;

		for(let j = 0; j < rightSideCards[i].length; j++)
		{
			if(rightSideCards[i][j] === rightSideCards[i][j].toUpperCase() && isNaN(Number(rightSideCards[i][j])))
			{
				upperCases++;
			}

			if(upperCases >= 2) break;
		}

		if(upperCases >= 2)
		{
			await admin.firestore().collection("players").doc(playerId).update({"compoundCardsCount": admin.firestore.FieldValue.increment(-1)});
		}
		else
		{
			await admin.firestore().collection("players").doc(playerId).update({"elementCardsCount": admin.firestore.FieldValue.increment(-1)});
		}*/
	}
}

export const placeCard = functions.https.onCall(async (data, context) => {
	
	const playerId = data.playerId.toString();
	const cardName = data.cardName;
	const cardUuid = data.cardUuid;
	const roomId = data.roomId.toString();
	const playerToken = data.playerToken;

	const playerRef = admin.firestore().collection("players").doc(playerId);
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	const playerData = await playerRef.get();
	const elementCardsCount = playerData.get("elementCards").length;
	const roomData = await roomDataRef.get();
	const roomTurnDataRef = await admin.firestore().collection("roomsTurnData").doc(roomId);

	const playerOnTurnIndex = await (await roomTurnDataRef.get()).get("nextTurn");

	if(!(playerId === await roomData.get("players")[playerOnTurnIndex]))
	{
		var notYourTurnMsg = {
			"notification": {
				"title": "Not Your Turn",
				"body": "It is not your turn"
			}
		}

		await admin.messaging().sendToDevice(playerToken, notYourTurnMsg);
		return;
	}

	for(let i = 0; i < elementCardsCount; i++)
	{
		if((await playerRef.get()).get("elementCards")[i].name === cardName 
			&& (await playerRef.get()).get("elementCards")[i].uuid === cardUuid)
		{
			const elementCardsRef = await admin.firestore().collection("elementCards");
			const lastCardData = await (await elementCardsRef.doc((await roomDataRef.get()).get("lastCard"))).get();
			const currentCardData = await (await elementCardsRef.doc(cardName)).get();
			
			console.log("Player has the card");

			if((lastCardData.get("group") === currentCardData.get("group")) 
				|| (lastCardData.get("period") === currentCardData.get("period")))
			{
				await roomTurnDataRef.update({"finishedTurnPlayer": playerId});
				
				console.log("The group or the period coincide")
				await roomDataRef.update({"lastCard": cardName});
				
				await playerRef.update({"elementCards": admin.firestore.FieldValue.arrayRemove({name: cardName, uuid: cardUuid})});
				// await playerRef.update({"elementCardsCount": admin.firestore.FieldValue.increment(-1)});

				if((await playerRef.get()).get("elementCards").length === 0)
				{
					await roomTurnDataRef.update({"finishedPlayers": admin.firestore.FieldValue.increment(1)});
					await roomDataRef.update({"finishedPlayerIds": admin.firestore.FieldValue.arrayUnion(playerId)});
				}

				const newLastCard = await getCardData(cardName);

				var newLastCardMsg = {
					"notification": {
						"title": "New Last Card",
						"body": "There is a new last card"
					},
					"data": {
						"newLastCard": newLastCard
					}
				}

				await admin.messaging().sendToTopic(roomId, newLastCardMsg);

				//TODO: Send update player elementCards data;
				var placedCardMsg = {
					"notification": {
						"title": "Placed Card",
						"body": "You have placed card successfully"
					}
				};

				await admin.messaging().sendToDevice(playerToken, placedCardMsg);

				//await admin.firestore().collection("roomsTurnData").doc(roomId).update({"finishedTurnPlayer": playerId});

				return true;
			}
			else
			{
				var cannnotPlaceCardMsg = {
					"notification": {
						"title": "Cannot Place Card",
						"body": "This card do not match"
					}
				}

				await admin.messaging().sendToDevice(playerToken, cannnotPlaceCardMsg);

				console.log("The group and the period do not coincide")
				return false;
			}
		}
	}

	var incorrectCardMsg = {
		"notification": {
			"title": "Incorrect card",
			"body": "You do not have this card"
		}
	}

	await admin.messaging().sendToDevice(playerToken, incorrectCardMsg);

	//TODO: Send msg that the player does not have the card

	console.log("End of the function");
	return false;
})

exports.callWolframApi = functions.https.onCall(async (data, context) => {
	const name = data.cardName;
	let plaintext;

	await waApi.getFull({
		input: name,
		// includepodid: 'Input',
		// podstate: 'Elemental2:ElementData__More',
		format: 'plaintext',
	// }).then(console.log).catch(console.error)
	}).then((queryresult: any) => {
		console.log(queryresult.pods[0].subpods[0].plaintext);
		plaintext = queryresult.pods[0].subpods[0].plaintext;
		// console.log(queryresult)
	}).catch(console.error)

	let groupAndPeriod : any;

	await waApi.getFull({
		input: plaintext + " group and period",
		includepodid: 'Result',
		// podstate: 'Elemental2:ElementData__More',
		format: 'plaintext',
	// }).then(console.log).catch(console.error)
	}).then((queryresult: any) => {
		// console.log(queryresult);
		console.log(queryresult.pods[0].subpods[0].plaintext)
		groupAndPeriod = queryresult.pods[0].subpods[0].plaintext;
	}).catch(console.error)

	console.log("Group and period : " + groupAndPeriod[0]);
	
	let spacesCount = 0;
	let group = "";
	let period = "";

	for(let i = 0; groupAndPeriod[i]; i++)
	{
		if(groupAndPeriod[i] === ' ')
		{
			spacesCount++;
			continue;
		} 
		if(spacesCount === 2 && group === "")
		{
			group += groupAndPeriod[i];
			if(groupAndPeriod[i+1] !== ' ')
			{
				group += groupAndPeriod[i];
				i++;
				console.log("Here : " + groupAndPeriod[i+1]);
			}
		}
		else if(spacesCount === 5)
		{
			period += groupAndPeriod[i];
		}
		console.log(groupAndPeriod[i]);
	}

	console.log("Group : " + group + " Period : " + period);

	console.log("Wolfram 1");
})

function shuffleArray(array: any[]) {
    for (var i = array.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var temp = array[i];
        array[i] = array[j];
        array[j] = temp;
	}
	
	return array;
}

async function generateNewDeck()
{
	var deck = new Array<string>();

	await admin.firestore().collection("elementCards").get()
		.then(function(querySnapshot)  {
			querySnapshot.forEach(function (doc) {
				console.log(doc.data().symbol);
				deck.push(doc.data().symbol);
			});
		})

	deck = shuffleArray(deck);
	
	return deck;
}

async function playerTurn(playerId : string, roomId : string) {
	const seconds = 15;

	const roomTurnData = await admin.firestore().collection("roomsTurnData").doc(roomId).get();
	const playerOnTurnIndex = await (await roomTurnData).get("nextTurn");
	const playerOnTurn = await (await admin.firestore().collection("roomsData").doc(roomId).get()).get("players")[playerOnTurnIndex];

	for(let i = 0; i < seconds; i++)
	{
		await delay(1000);
		console.log("Sec : " + [i+1]);

		if((await admin.firestore().collection("roomsTurnData").doc(roomId).get()).get("finishedTurnPlayer") === playerOnTurn)
		{
			console.log("Player has made his move");
			return;
		}
	}

	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	const roomData = await roomDataRef.get();

	let cardFromDeck;

	if(await roomData.get("deck").length <= 0)
	{
		let deck = await generateNewDeck();
		
		cardFromDeck = deck[0];
		await roomDataRef.update({"deck": deck});
		console.log("Deck size: " + roomData.get("deck").length);
	}
	else
	{
		cardFromDeck = await (roomData).get("deck")[0];
	}

	console.log("Deck size: " + roomData.get("deck").length);
	
	
	await roomDataRef.update({"deck": admin.firestore.FieldValue.arrayRemove(cardFromDeck)});
	const cardData = await addNewElementCard(cardFromDeck, playerId);

	const cardToAddData = cardData.uuid + "," + await getCardData(cardFromDeck);
	const playerName = await (await admin.firestore().collection("players").doc(playerId).get()).get("name");

	var missedTurnMsg = {
		"notification": {
			"title": "Missed Turn",
			"body": playerName + " have missed their turn"
		},
		"data": {
			"playerId": playerId, //TODO: find a solution to sendToDevice and to delete this line
			"cardToAdd": cardToAddData.toString()
		}
	}

	await admin.messaging().sendToTopic(roomId, missedTurnMsg);
	await admin.firestore().collection("roomsTurnData").doc(roomId).update({"finishedTurnPlayer": playerId});

	return;
}

export const startGame = functions.https.onCall(async(data, context) => {
	//await playerHasTheseCards("", [""], []);
	
	const roomId = data.roomId.toString();
	console.log("Room Id : " + roomId)
	const gameType = data.gameType;
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	let playerIds = [];
	let playerNames = [];
	const playersCount = 1;

	let requiredFinishedPlayers;
	let nextTurn = 0;

	console.log("Before players");

	for(let i = 0; i < playersCount; i++)
	{
		playerIds[i] = (await roomDataRef.get()).get("players")[i];
		playerNames[i] = (await (await admin.firestore().collection("players").doc(playerIds[i]).get()).get("name"));
		console.log("First");
	}

	//configurePlayers
	await configurePlayers(data);
	//Dealing
	await dealing(data);

	//TODO: SendToTopic the data of all players and the order
	const playersDataMsg = {
		"notification" : {
			"title": "Game Started",
			"body": playerNames.toString() //players data (names)
		}	
	}

	await admin.messaging().sendToTopic(roomId, playersDataMsg);

	switch (gameType) {
		case "SingleGame":
			requiredFinishedPlayers = 2;
			break;
		case "TeamGame":
			requiredFinishedPlayers = 1;
		default:
			break;
	}

	while(await (await roomDataRef.get()).get("finishedPlayers") !== requiredFinishedPlayers) {
		
		console.log("In while")

		await roomDataRef.update(
			{"finishedPlayers": admin.firestore.FieldValue.increment(1)}
		);

		await playerTurn(playerIds[nextTurn].toString(), roomId.toString());

		const nextTurnMsg = {
			"notification" : {
				"title": "Next Turn",
				"body": "Player on turn: " + playerIds[nextTurn],
			}	
		}

		await admin.messaging().sendToTopic(roomId.toString(), nextTurnMsg);

		if(nextTurn === playersCount - 1) nextTurn = 0;
		else nextTurn++;

		console.log("Next turn : " + playerIds[nextTurn]);
	}
})

async function configurePlayers (data : any) {
	const roomId = data.roomId.toString();
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	const playersRef = admin.firestore().collection("players");
	const usersRef = admin.firestore().collection("users");

	const playersCount = 4;
	let playerNames = [];

	for(let i = 0; i < playersCount; i++)
	{
		const playerId = (await roomDataRef.get()).get("players")[i];
		await playersRef.doc(playerId.toString()).set({"name": (await usersRef.doc(playerId.toString()).get()).get("username")});
		await playersRef.doc(playerId.toString()).update({"roomId": roomId});
		await playersRef.doc(playerId.toString()).update({"points": 0});
		playerNames[i] = (await (await admin.firestore().collection("players").doc(playerId).get()).get("name"));
		console.log("Player id : " + playerId);
	}

	/*var playersDataMsg = {
		"notification": {
			"title": "Players Data",
			"body": playerNames.toString()
		}
	};

	await admin.messaging().sendToTopic(roomId, playersDataMsg);*/

	return playerNames;
}

async function dealing (data: any) {
	const roomId = data.roomId.toString();
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	// const playersRef = admin.firestore().collection("players");
	const playerIds = [];
	const elementCardsToDeal = 1;
	const compoundCardsToDeal = 2; //TODO: change to n
	const playersCount = 4; //TODO: change to 4

	//let elementCards = ["H2", "O2", "Cu", "Cl", "Al", "Ar", "H2", "B", "Na", "H2", "H2", "H2", "H2", "Al", "Be"]; //TODO: get them from somewhere
	
	const elementCards = await generateNewDeck();
	
	let compoundCards = ["H2O", "H2O", "H2O", "H2O", "NaCl", "NaCl", "NaCl", "NaCl", "NaCl"]; //TODO: get them from somewhere

	for(let i = 0; i < playersCount; i++)
	{
		playerIds[i] = (await roomDataRef.get()).get("players")[i.toString()];
	}

	let playerIndex = 0;

	for(let i = 0; i < playersCount * elementCardsToDeal; i++)
	{
		// await playersRef.doc(playerIds[playerIndex]).update({"elementCards": admin.firestore.FieldValue.arrayUnion(elementCards[i])});
		await addNewElementCard(elementCards[i], playerIds[playerIndex]);

		console.log("Cards added");

		if(playerIndex === 3) playerIndex = 0;
		else playerIndex++;
	}

	playerIndex = 0;

	for(let i = 0; i < playersCount * compoundCardsToDeal; i++)
	{
		// await playersRef.doc(playerIds[playerIndex]).update({"compoundCards": admin.firestore.FieldValue.arrayUnion(compoundCards[i])});
		await addNewCompoundCard(compoundCards[i], playerIds[playerIndex]);

		if(playerIndex === 3) playerIndex = 0;
		else playerIndex++;
	}

	await roomDataRef.update({"lastCard": elementCards[playersCount * elementCardsToDeal]});
	
	await elementCards.splice(0, playersCount * elementCardsToDeal + 1);
	
	await roomDataRef.update({"deck": elementCards});
	// await roomDataRef.update({"deckCardsCount": elementCards.length});

	// for(let i = 0; i < playersCount; i++)
	// {
	// 	await playersRef.doc(playerIds[i]).update({"elementCardsCount": elementCardsToDeal});
	// 	await playersRef.doc(playerIds[i]).update({"compoundCardsCount": compoundCardsToDeal});
	// }

	return "Successfully dealing";
}
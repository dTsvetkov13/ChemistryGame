import * as functions from 'firebase-functions';
//import {UUID} from '../node_modules/uuid-generator-ts';
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

export const createRoom = functions.https.onCall(async (data, context) => {
	const gameType = data.gameType ? data.gameType.toString() : "SingleGame"; //improve here

	//const roomId = new UUID().getDashFreeUUID();

	const roomId = data.roomId; //TODO : create UUID

	const roomRef = admin.firestore().collection("rooms").doc(roomId.toString());
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId.toString());
	const roomTurnDataRef = admin.firestore().collection("roomsTurnData").doc(roomId.toString());

	await roomRef.set({"gameType": gameType});
	await roomTurnDataRef.set({"finishedPlayers": 0});
	await roomTurnDataRef.update({"finishedTurnPlayer": 5});

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
})

exports.listenersToRoomFreeSeats = functions.firestore
    .document('/rooms/{roomId}')
    .onUpdate(async (change, context) => {
		const data = change.after.exists ? change.after.data() : {freeSeats: 3};
	
		const freeSeats = data !== undefined ? data.freeSeats : 3;

		if(freeSeats === 0)
		{

			await delay(6000);

			//Start game
			//Send to the topic StartMessage
			

			//Set the nextTurn
			await admin.firestore().collection("roomsTurnData").doc(change.after.id).update({"nextTurn": 0});
			//TODO: update nextTurn again to 0;

			await delay(6000);

			const playersNames = await configurePlayers({roomId: change.after.id});
			await dealing({roomId: change.after.id});		

			const lastCard = await (await admin.firestore().collection("roomsData").doc(change.after.id).get()).get("lastCard");
			let lastCardData = "";

			await admin.firestore().collection("elementCards").doc(lastCard).get().then(async (doc : any) => {
				if(doc.exists) {
					lastCardData += lastCard + "," + doc.data().group + "," + doc.data().period;
				}
			});
			

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

	const elementCardsCount = (await playerRef.get()).get("elementCardsCount");
	const compoundCardsCount = (await playerRef.get()).get("compoundCardsCount");
	const playerName = (await playerRef.get()).get("name");

	let compoundCards = [];

	let elementSymbolTemp = "";

	let elementCardsString = "";

	for(let i = 0; i < elementCardsCount; i++)
	{
		elementSymbolTemp = (await playerRef.get()).get("elementCards")[i];
	
		await admin.firestore().collection("elementCards").doc(elementSymbolTemp).get().then(async (doc : any) => {
			console.log("DOC DATA : " + doc.data());
			if(doc.exists)
			{
				elementCardsString += elementSymbolTemp + "," + doc.data().group + "," + doc.data().period + "\n";
			}
		});
	}

	for(let i = 0; i < compoundCardsCount; i++)
	{
		compoundCards[i] = (await playerRef.get()).get("compoundCards")[i]; 
	}

	var playerCards = {
		"notification": {
			"title": "Player Cards",
		},
		"data": {
			"elementCards": elementCardsString,
			"compoundCards": compoundCards.toString(),
			"playerName": playerName,
		}
	};

	console.log("Player id: " + playerId);
	console.log("Element cards: " + elementCardsString);
	console.log("Compound Cards : " + compoundCards);

	await admin.messaging().sendToDevice(playerToken, playerCards);
})

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

//Listen to nextTurn, call nextTurn() and change the nextTurn

exports.listenersToRoomTurnData = functions.firestore
	.document('roomsTurnData/{roomId}')
	.onUpdate(async (change, context) => {
		const data = change.after.data();

		const nextTurn = data !== undefined ? data.nextTurn : 10;

		let requiredFinishedPlayers;

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
			var gameFinishedMsg = {
				"notification": {
					"title": "Game Finished",
					"body": "The game has finished"
				}
			}

			await admin.messaging().sendToTopic(change.after.id.toString(), gameFinishedMsg);

			console.log("Game Finished");
			return;
		}

		console.log(change.after.id);
		
		console.log((await admin.firestore().collection("roomsData").doc(change.after.id).get()).get("deck")[0]);

		const dataBefore = change.before.data();

		const nextTurnBefore = dataBefore !== undefined ? dataBefore.nextTurn : 10;

		console.log("NextTurn : " + nextTurn + ", before : " + nextTurnBefore);

		if(nextTurn !== 10 && nextTurnBefore !== 10 && nextTurnBefore !== nextTurn)
		{
			const player = data !== undefined ? (await admin.firestore().collection("roomsData").doc(change.after.id).get()).get("players")[nextTurn] : 10;

			console.log("player : " + player);

			const nextTurnMsg = {
				"notification" : {
					"title": "Player Turn",
					"body": player,
				}	
			}
	
			await admin.messaging().sendToTopic(change.after.id.toString(), nextTurnMsg);

			await playerTurn(player.toString(), change.after.id);

			const nextPlayer = nextTurn === 3 ? 0 : 0;

			await admin.firestore().collection("roomsTurnData").doc(change.after.id).update({"nextTurn": nextPlayer})
			console.log("Next Turn :" + nextPlayer.toString());
			
			await admin.firestore().collection("roomsTurnData").doc(change.after.id).update(
				{"finishedPlayers": admin.firestore.FieldValue.increment(1)}
			);
		}
	});

// export const updateRoom = functions.https.onCall(async (data, context) => {
async function updateRoom(data: any, roomId : string) {
	const gameType = data.gameType.toString();
	//const roomId = data.roomId.toString();
	const playerToken = data.playerToken;

	const roomRef = await admin.firestore().collection("rooms").doc(roomId);
	const roomDataRef = await admin.firestore().collection("roomsData").doc(roomId);

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

	if(!foundRoom) console.log("Create room");

	return "Successful";
})

function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}

async function playerHasTheseCards(playerId: string, leftSideCards: Array<String>, rightSideCards: Array<String>)
{
	const playerRef = await admin.firestore().collection("players").doc(playerId);
	const elementCards = (await playerRef.get()).get("elementCards");
	const elementCardsCount = (await playerRef.get()).get("elementCardsCount");
	const compoundCards = (await playerRef.get()).get("compoundCards");
	const compoundCardsCount = (await playerRef.get()).get("compoundCardsCount");

	let matching = 0;

	for(let i = 0; i < elementCardsCount; i++)
	{
		for(let j = 0; j < leftSideCards.length; j++)
		{
			if(leftSideCards[j] === elementCards[i])
			{
				matching++;
				continue;
			}
		}

		for(let j = 0; j < rightSideCards.length; j++)
		{
			if(rightSideCards[j] === elementCards[i])
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
			if(leftSideCards[j] === compoundCards[i])
			{
				matching++;
				continue;
			}
		}

		for(let j = 0; j < rightSideCards.length; j++)
		{
			if(rightSideCards[j] === compoundCards[i])
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
	}

	let leftSideString = "";

	if(leftSideCards.length) leftSideString += leftSideCards[0];

	//TODO: CHECK THE LENGHT OF The cards

	for(let i = 1; i < leftSideCards.length; i++)
	{
		leftSideString += " + " + leftSideCards[i];
	}

	console.log("String : " + leftSideString);

	let rightSideString = "";

	if(rightSideCards.length) rightSideString += rightSideCards[0];

	for(let i = 1; i < rightSideCards.length; i++)
	{
		rightSideString += " + " + rightSideCards[i];
	}

	console.log("String : " + rightSideString);

	await waApi.getFull({
		input: leftSideString + " -> " + rightSideString,
		includepodid: 'ReactionList:ChemicalReactionData',
		podstate: 'ReactionList:ChemicalReactionData__Show formulas',
		format: 'plaintext',
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
							if(leftSideCards[j] === currReactant)
							{
								console.log("There is it in the left side");
								newCard = false;
							}
						}
						
						for(let j = 1; j < rightSideCards.length; j++)
						{
							if(rightSideCards[j] === currReactant)
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

					cardData = await addNewCardToPlayer(playerId, newCards);
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
					
					//TODO: maybe add bonus points
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
				}
			}
		}
		else
		{
			console.log("Bonus points");

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

			//remove the cards from the player
			//add bonus points
			await admin.firestore().collection("players").doc(playerId).update({"points": admin.firestore.FieldValue.increment(20)});
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
		await admin.firestore().collection("elementCards").doc(newCard.toString()).get().then(async (doc: any) => {
			console.log("DOC DATA : " + doc.data());
			if(doc.exists)
			{
				cardData += doc.data().symbol;
				cardData += "," + doc.data().group + "," + doc.data().period;
			}
		});
	}

	if(upperCases >= 2)
	{
		await admin.firestore().collection("players").doc(playerId).update({"compoundCards": admin.firestore.FieldValue.arrayUnion(newCard)});	
	}
	else
	{
		await admin.firestore().collection("players").doc(playerId).update({"elementCards": admin.firestore.FieldValue.arrayUnion(newCard)});
	}

	return cardData;
}

async function deleteCardsFromPlayer(playerId: string, leftSideCards: any, rightSideCards: any)
{
	var upperCases = 0;

	for(let i = 0; i < leftSideCards.length; i++)
	{
		await admin.firestore().collection("players").doc(playerId).update({"elementCards": admin.firestore.FieldValue.arrayRemove(leftSideCards[i])})
		await admin.firestore().collection("players").doc(playerId).update({"compoundCards": admin.firestore.FieldValue.arrayRemove(leftSideCards[i])})
		
		upperCases = 0;

		for(let j = 0; j < leftSideCards[i].length; j++)
		{
			if(leftSideCards[i][j] === leftSideCards[i][j].toUpperCase())
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
		}
	}

	for(let i = 0; i < rightSideCards.length; i++)
	{
		await admin.firestore().collection("players").doc(playerId).update({"elementCards": admin.firestore.FieldValue.arrayRemove(rightSideCards[i])})
		await admin.firestore().collection("players").doc(playerId).update({"compoundCards": admin.firestore.FieldValue.arrayRemove(rightSideCards[i])})
		
		upperCases = 0;

		for(let j = 0; j < rightSideCards[i].length; j++)
		{
			if(rightSideCards[i][j] === rightSideCards[i][j].toUpperCase())
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
		}
	}

	if((await admin.firestore().collection("players").doc(playerId).get()).get("elementCardsCount") <= 0)
	{
		const roomId = await (await admin.firestore().collection("players").doc(playerId).get()).get("roomId");
		await admin.firestore().collection("roomsTurnData").doc(roomId).update({"finishedPlayers": admin.firestore.FieldValue.increment(1)});
	}
}

export const placeCard = functions.https.onCall(async (data, context) => {
	const playerId = data.playerId.toString();
	const cardName = data.cardName;
	const roomId = data.roomId.toString();

	const playerRef = admin.firestore().collection("players").doc(playerId);
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	const elementCardsCount = (await playerRef.get()).get("elementCardsCount");

	//TODO: CHECK FIRST IF THE PLAYER IS ON TURN

	for(let i = 0; i < elementCardsCount; i++)
	{
		if((await playerRef.get()).get("elementCards")[i] === cardName)
		{
			const elementCardsRef = await admin.firestore().collection("elementCards");
			const lastCardRef = (await elementCardsRef.doc((await roomDataRef.get()).get("lastCard")));
			const currentCardRef = (await elementCardsRef.doc(cardName));
			
			console.log("Player has the card");

			if(((await lastCardRef.get()).get("group") === (await currentCardRef.get()).get("group")) 
				|| ((await lastCardRef.get()).get("period") === (await currentCardRef.get()).get("period")))
			{
				console.log("The group or the period coincide")
				await roomDataRef.update({"lastCard": cardName});
				await playerRef.update({"elementCards": admin.firestore.FieldValue.arrayRemove(cardName)});
				await playerRef.update({"elementCardsCount": admin.firestore.FieldValue.increment(-1)});

				if((await playerRef.get()).get("elementCardsCount") === 0)
				{
					await admin.firestore().collection("roomsTurnData").doc(roomId).update({"finishedPlayers": admin.firestore.FieldValue.increment(1)});
				}

				await admin.firestore().collection("roomsTurnData").doc(roomId).update({"finishedTurnPlayer": playerId});

				//TODO: Send update player elementCards data;
				var placedCardMsg = {
					"notification": {
						"title": "Placed Card",
						"body": "You have placed card successfully"
					}
				};

				await admin.messaging().sendToTopic(roomId, placedCardMsg);

				return true;
			}
			else
			{
				console.log("The group or the period do not coincide")
				return false;
			}
		}
	}

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

async function playerTurn(playerId : string, roomId : string) {
	const seconds = 5;

	const roomTurnDataRef = admin.firestore().collection("roomsTurnData").doc(roomId);

	for(let i = 0; i < seconds; i++)
	{
		await delay(1000);
		console.log("Sec : " + [i+1]);

		if((await roomTurnDataRef.get()).get("finishedTurnPlayer") === await (await roomTurnDataRef.get()).get("nextTurn"))
		{
			console.log("Player has made his move");
			return;
		}
	}
	
	var missedTurnMsg = {
		"notification": {
			"title": "Missed Turn",
			"body": "You have missed your turn"
		}
	}

	await admin.messaging().sendToDevice(await (await admin.firestore().collection("players").doc(playerId).get()).get("roomId"), missedTurnMsg);

	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);

	const cardFromDeck = await (await roomDataRef.get()).get("deck")[0];
	await roomDataRef.update({"deck": admin.firestore.FieldValue.arrayRemove(cardFromDeck)});
	await roomDataRef.update({"deckCardsCount": admin.firestore.FieldValue.increment(-1)});
	await admin.firestore().collection("players").doc(playerId).update({"elementCards": admin.firestore.FieldValue.arrayUnion(cardFromDeck)});
	await admin.firestore().collection("players").doc(playerId).update({"elementCardsCount": admin.firestore.FieldValue.increment(1)});

	return;
}

export const startGame = functions.https.onCall(async(data, context) => {
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
		const playerId = (await roomDataRef.get()).get("players")[i.toString()];
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
	const playersRef = admin.firestore().collection("players");
	const playerIds = [];
	const elementCardsToDeal = 2;
	const compoundCardsToDeal = 2; //TODO: change to n
	const playersCount = 4; //TODO: change to 4

	let elementCards = ["H2", "O2", "Cu", "Cl", "Al", "Ar", "B", "Na", "Al", "Be"]; //TODO: get them from somewhere
	let compoundCards = ["H2O", "H2O", "H2O", "H2O", "NaCl", "NaCl", "NaCl", "NaCl", "NaCl"]; //TODO: get them from somewhere

	for(let i = 0; i < playersCount; i++)
	{
		playerIds[i] = (await roomDataRef.get()).get("players")[i.toString()];
	}

	let playerIndex = 0;

	for(let i = 0; i < playersCount * elementCardsToDeal; i++)
	{
		await playersRef.doc(playerIds[playerIndex]).update({"elementCards": admin.firestore.FieldValue.arrayUnion(elementCards[i])});
		

		console.log("Cards added");

		if(playerIndex === 3) playerIndex = 0;
		else playerIndex++;
	}

	for(let i = 0; i < playersCount * compoundCardsToDeal; i++)
	{
		await playersRef.doc(playerIds[playerIndex]).update({"compoundCards": admin.firestore.FieldValue.arrayUnion(compoundCards[i])});

		if(playerIndex === 3) playerIndex = 0;
		else playerIndex++;
	}

	await roomDataRef.update({"lastCard": elementCards[playersCount * elementCardsToDeal]});
	
	await elementCards.splice(0, playersCount * elementCardsToDeal + 1);
	
	await roomDataRef.update({"deck": elementCards});
	await roomDataRef.update({"deckCardsCount": elementCards.length});

	for(let i = 0; i < playersCount; i++)
	{
		await playersRef.doc(playerIds[i]).update({"elementCardsCount": elementCardsToDeal});
		await playersRef.doc(playerIds[i]).update({"compoundCardsCount": compoundCardsToDeal});
	}

	return "Successfully dealing";
}
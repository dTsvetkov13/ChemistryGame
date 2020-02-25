import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

import {getCardData, addNewElementCard, addNewCompoundCard} from "./utils";

export const listenersToRoomFreeSeats1 = functions.firestore
    .document('/rooms/{roomId}')
    .onUpdate(async (change, context) => {
		const data = change.after.exists ? change.after.data() : {freeSeats: 3};
	
		const freeSeats = data !== undefined ? data.freeSeats : 3;

		if(freeSeats === 0)
		{
			const playersNames = await configurePlayers({roomId: change.after.id});
			await dealing({roomId: change.after.id});		

			const lastCard = await (await admin.firestore().collection("roomCardsData").doc(change.after.id).get()).get("lastCard");
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

			console.log("Id: " + change.after.id.toString());

			await admin.messaging().sendToTopic(change.after.id.toString(), startMsg).then((response) => {
				console.log("Resp: " + response);
			})
			.catch((error) => {
				console.log("Error: " + error);
			});

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
		const playerData = await usersRef.doc(playerId.toString()).get();
		await playersRef.doc(playerId.toString()).set({"name": playerData.get("username")});
		await playersRef.doc(playerId.toString()).update({"roomId": roomId});
		await playersRef.doc(playerId.toString()).update({"points": 0});
		playerNames[i] = playerData.get("username");
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
	const elementCardsToDeal = 2;
	const compoundCardsToDeal = 2; //TODO: change to n
	const playersCount = 4; //TODO: change to 4

	let elementCards = ["H", "O2", "Cu", "Cl", "Al", "Ar", "H", "Na", "H", "H", "H", "H", "Al", "Be"]; //TODO: get them from somewhere
	
	// const elementCards = await generateNewDeck();
	
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

	const roomCardsDataRef = admin.firestore().collection("roomCardsData").doc(roomId);

	await roomCardsDataRef.set({"lastCard": elementCards[playersCount * elementCardsToDeal]});
	
	await elementCards.splice(0, playersCount * elementCardsToDeal + 1);
	
	await roomCardsDataRef.update({"deck": elementCards});
	// await roomDataRef.update({"deckCardsCount": elementCards.length});

	// for(let i = 0; i < playersCount; i++)
	// {
	// 	await playersRef.doc(playerIds[i]).update({"elementCardsCount": elementCardsToDeal});
	// 	await playersRef.doc(playerIds[i]).update({"compoundCardsCount": compoundCardsToDeal});
	// }

	return "Successfully dealing";
}
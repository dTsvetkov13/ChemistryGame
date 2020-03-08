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

			const roomDataRef = admin.firestore().collection("roomsData").doc(change.after.id);

			await roomDataRef.update({"gameFinished": true});
			await roomDataRef.update({"gameType": change.after.data()?.gameType});

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

			await admin.messaging().sendToTopic(change.after.id.toString(), startMsg)
			.then((response) => {
				console.log("Resp: " + response);
			})
			.catch((error) => {
				console.log("Error: " + error);
			});

			const roomTurnDataRef = admin.firestore().collection("roomsTurnData").doc(change.after.id.toString());
			
			await roomTurnDataRef.set({"finishedPlayers": 2});
			await roomTurnDataRef.update({"nextTurn": -1});
			await roomTurnDataRef.update({"finishedTurnPlayer": 5});
			await roomTurnDataRef.update({"readyPlayers": 0});
			await roomDataRef.update({"gameFinished": false});
			await roomTurnDataRef.update({"finishedPlayers": admin.firestore.FieldValue.increment(-1)}); //TODO: change to -2

			console.log("Start the Game");

			admin.firestore().collection("rooms").doc(change.after.id).delete()
			.then(function() {
				console.log("Room successfully deleted!");
			}).catch(function(error) {
				console.error("Error removing room: ", error);
			});
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
	const playerIds = [];
	const elementCardsToDeal = 2;
	const compoundCardsToDeal = 2; //TODO: change to n
	const playersCount = 4; //TODO: change to 4

	let elementCards = ["Na", "Na", "Na", "Na", "Mg", "Mg", "Mg", "Mg", "P", "", "Al", "P", "Si", "S", "", "Si", "Al", "S", "P", "", "P", "S", "Al", "Si", "", "S", "Si", "P", "Al"]; //Hardcoded for test
	
	// const elementCards = await generateNewDeck();
	
	let compoundCards = ["NaCl", "NaCl", "NaCl", "NaCl", "MgCl2", "MgCl2", "MgCl2", "MgCl2"]; //Hardcoded for test

	for(let i = 0; i < playersCount; i++)
	{
		playerIds[i] = (await roomDataRef.get()).get("players")[i.toString()];
	}

	let playerIndex = 0;

	for(let i = 0; i < playersCount * elementCardsToDeal; i++)
	{
		await addNewElementCard(elementCards[i], playerIds[playerIndex]);

		if(playerIndex === 3) playerIndex = 0;
		else playerIndex++;
	}

	playerIndex = 0;

	for(let i = 0; i < playersCount * compoundCardsToDeal; i++)
	{
		await addNewCompoundCard(compoundCards[i], playerIds[playerIndex]);

		if(playerIndex === playersCount - 1) playerIndex = 0;
		else playerIndex++;
	}

	const roomCardsDataRef = admin.firestore().collection("roomCardsData").doc(roomId);

	await roomCardsDataRef.set({"lastCard": elementCards[playersCount * elementCardsToDeal]});
	
	await elementCards.splice(0, playersCount * elementCardsToDeal + 1);
	
	await roomCardsDataRef.update({"deck": elementCards});

	return "Successfully dealing";
}
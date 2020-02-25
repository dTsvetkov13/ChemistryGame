import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {getCardData, addNewElementCard, generateNewDeck } from "./utils";

export const listenersToRoomTurnData1 = functions.firestore
	.document('roomsTurnData/{roomId}')
	.onUpdate(async (change, context) => {
		const data = change.after.data();

		const nextTurn = data !== undefined ? data.nextTurn : 10;

		let requiredFinishedPlayers;

		const roomData = await admin.firestore().collection("roomsData").doc(change.after.id).get();

		if((roomData).get("gameFinished"))
		{
			console.log("The game is already finished");
			return;
		}

		const roomsTurnData = await admin.firestore().collection("roomsTurnData").doc(change.after.id).get();

		if(await (roomsTurnData).get("readyPlayers") < 4)
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

		if((roomsTurnData).get("finishedPlayers") >= requiredFinishedPlayers)
		{
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
			const playerId = (roomData).get("players")[nextTurn];
			const playerName = (await admin.firestore().collection("players").doc(playerId).get()).get("name");
			console.log("player : " + playerId);

			const nextTurnMsg = {
				"notification" : {
					"title": "Player Turn",
					"body": playerName + " is on turn!",
				},
				"data": {
					"playerId": playerId,
					"playerName": playerName
				}
			}
	
			await admin.messaging().sendToTopic(change.after.id.toString(), nextTurnMsg);

			await playerTurn(playerId.toString(), change.after.id);

			const nextPlayer = nextTurn === (roomData.get("players").length - 1) ? 0 : nextTurn + 1;

			await admin.firestore().collection("roomsTurnData").doc(change.after.id).update({"nextTurn": nextPlayer})
			console.log("Next Turn : " + nextPlayer.toString());
		}
	}
);

async function finishGame(roomId: string)
{
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);

	const roomData = await roomDataRef.get();
	const finishedPlayers = roomData.get("finishedPlayerIds");

	for(let i = 0; i < finishedPlayers.length; i++)
	{
		await admin.firestore().collection("players").doc(finishedPlayers[i]).update({"points": admin.firestore.FieldValue.increment(100 - (i * 50))});
	}

	console.log("After adding points");

	var playerData: {points: number; name: string; id: string}[] = new Array<{points: number; name: string; id: string}>();

	for(let i = 0; i < finishedPlayers.length; i++)
	{
		const playerId = finishedPlayers[i];
		const playerRef = admin.firestore().collection("players").doc(playerId);
		const playerDataTemp = await playerRef.get();
		const playerName = (playerDataTemp).get("name");
		const playerPoints = (playerDataTemp).get("points");
		playerData.push({name: playerName, points: playerPoints, id: playerId});
	}

	const players = roomData.get("players");

	for(let i = 0; i < players.length; i++)
	{
		const playerId = players[i];
		const playerRef = admin.firestore().collection("players").doc(playerId);
		const playerDataTemp = await playerRef.get();
		const playerName = (playerDataTemp).get("name");
		const playerPoints = (playerDataTemp).get("points");
		playerData.push({name: playerName, points: playerPoints, id: playerId});
	}

	console.log("After getting data: " + playerData);

	var sortedPlayerData: {points: number; name: string; id: string}[] = playerData.sort((p1, p2) => {
		console.log("Compare: " + p1.name + ": " + p1.points + " === " + p2.name + ": " + p2.points);
		
		if(p1.points > p2.points) return -1;
		else if(p1.points < p2.points) return 1;
		else
		{
			if(p1.id === finishedPlayers[0])
			{
				return -1;
			}
			else if(p2.id === finishedPlayers[0])
			{
				return 1;
			}
			else return 0;
		}

	});

	const leftPlayers = roomData.get("leftPlayers");

	for(let i = 0; i < leftPlayers.length; i++)
	{
		const playerId = players[i];
		const playerRef = admin.firestore().collection("players").doc(playerId);
		const playerDataTemp = await playerRef.get();
		const playerName = (playerDataTemp).get("name");
		const playerPoints = (playerDataTemp).get("points");
		sortedPlayerData.push({name: playerName, points: playerPoints, id: playerId});
	}

	console.log("Ranking");

	for(let i = 0; i < 4; i++)
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

	for(let i = 0; i < roomData.get("subscribedTokens").length; i++)
	{
		await admin.messaging().unsubscribeFromTopic(await (roomData).get("subscribedTokens")[i], roomId);
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

	for(let i = 0; i < await sortedPlayerData.length; i++)
	{
		admin.firestore().collection("players").doc(sortedPlayerData[i].id).delete()
		.then(function() {
			console.log("Document successfully deleted!");
		}).catch(function(error) {
			console.error("Error removing document: ", error);
		});
	}

	console.log("End");
}

function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
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

	const roomCardsDataRef = admin.firestore().collection("roomCardsData").doc(roomId);
	const roomCardsData = await roomCardsDataRef.get();

	let cardFromDeck;

	if(await roomCardsData.get("deck").length <= 0)
	{
		let deck = await generateNewDeck();
		
		cardFromDeck = deck[0];
		await roomCardsDataRef.update({"deck": deck});
		console.log("Deck size: " + roomCardsData.get("deck").length);
	}
	else
	{
		cardFromDeck = await (roomCardsData).get("deck")[0];
	}

	console.log("Deck size: " + roomCardsData.get("deck").length);
	
	
	await roomCardsDataRef.update({"deck": admin.firestore.FieldValue.arrayRemove(cardFromDeck)});
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
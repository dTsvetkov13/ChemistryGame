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

		switch (await (await admin.firestore().collection("roomsData").doc(change.after.id).get()).get("gameType")) {
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
		
		if(nextTurn === -1)
		{
			await admin.firestore().collection("roomsTurnData").doc(change.after.id).update({"nextTurn": admin.firestore.FieldValue.increment(1)});
			return;
		}

		const dataBefore = change.before.data();

		const nextTurnBefore = dataBefore !== undefined ? dataBefore.nextTurn : 10;

		console.log("NextTurn : " + nextTurn + ", before : " + nextTurnBefore);

		if(nextTurn !== 10 && nextTurnBefore !== 10 && nextTurnBefore !== nextTurn)
		{
			const playerId = (roomData).get("players")[nextTurn];
			const playerName = (await admin.firestore().collection("players").doc(playerId).get()).get("name");

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
		}
	}
);

async function finishGame(roomId: string)
{
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);

	const roomData = await roomDataRef.get();
	const finishedPlayers = roomData.get("finishedPlayerIds");

	if(finishedPlayers !== undefined)
	{
		for(let i = 0; i < finishedPlayers.length; i++)
		{
			await admin.firestore().collection("players").doc(finishedPlayers[i]).update({"points": admin.firestore.FieldValue.increment(100 - (i * 50))});
		}
	}

	var playerData: {points: number; name: string; id: string}[] = new Array<{points: number; name: string; id: string}>();

	if(finishedPlayers !== undefined)
	{
		for(let i = 0; i < finishedPlayers.length; i++)
		{
			const playerId = finishedPlayers[i];
			const playerRef = admin.firestore().collection("players").doc(playerId);
			const playerDataTemp = await playerRef.get();
			const playerName = (playerDataTemp).get("name");
			const playerPoints = (playerDataTemp).get("points");
			playerData.push({name: playerName, points: playerPoints, id: playerId});
		}
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

	switch(await (await admin.firestore().collection("roomsData").doc(roomId).get()).get("gameType"))
	{
		case("SingleGame"):

			playerData = playerData.sort((p1, p2) => {
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
		
			if(leftPlayers !== undefined)
			{
				for(let i = 0; i < leftPlayers.length; i++)
				{
					const playerId = players[i];
					const playerRef = admin.firestore().collection("players").doc(playerId);
					const playerDataTemp = await playerRef.get();
					const playerName = (playerDataTemp).get("name");
					const playerPoints = (playerDataTemp).get("points");
					playerData.push({name: playerName, points: playerPoints, id: playerId});
				}
			}
		
			let gameFinishedMsg = {
				"notification": {
					"title": "Single Game Finished",
					"body": "The game has finished"
				},
				"data": {
					"firstPlace": playerData[0].name + "," + playerData[0].points.toString(),
					"secondPlace": playerData[1].name + "," + playerData[1].points.toString(),
					"thirdPlace": playerData[2].name + "," + playerData[2].points.toString(),
					"fourthPlace": playerData[3].name + "," + playerData[3].points.toString(),
				}
			}
		
			await admin.messaging().sendToTopic(roomId, gameFinishedMsg);

			await admin.firestore().collection("users").doc(playerData[0].id)
				.update({"singleGameWins": admin.firestore.FieldValue.increment(1)});
			break;
		case("TeamGame"):

			let firstTeamPoints = 0;
			let secondTeamPoints = 0;

			for(let i = 0; i < playerData.length; i++)
			{
				if(i % 2 === 0)
				{
					firstTeamPoints += playerData[i].points;
				}
				else
				{
					secondTeamPoints += playerData[i].points;
				}
			}

			if(roomData.get("firstTeamWon"))
			{
				firstTeamPoints += 50;
			}
			else
			{
				secondTeamPoints += 50;
			}

			if(firstTeamPoints > secondTeamPoints)
			{
				let gameFinishedMsg2 = {
					"notification": {
						"title": "Team Game Finished",
						"body": "The game has finished"
					},
					"data": {
						"player1": playerData[0].name + "," + firstTeamPoints.toString(),
						"player2": playerData[2].name + "," + firstTeamPoints.toString(),
						"player3": playerData[1].name + "," + secondTeamPoints.toString(),
						"player4": playerData[3].name + "," + secondTeamPoints.toString(),
					}
				}

				await admin.messaging().sendToTopic(roomId, gameFinishedMsg2);

				await admin.firestore().collection("users").doc(playerData[0].id)
					.update({"teamGameWins": admin.firestore.FieldValue.increment(1)});
				await admin.firestore().collection("users").doc(playerData[2].id)
					.update({"teamGameWins": admin.firestore.FieldValue.increment(1)});
			}
			else
			{
				let gameFinishedMsg1 = {
					"notification": {
						"title": "Team Game Finished",
						"body": "The game has finished"
					},
					"data": {
						"player1": playerData[1].name + "," + secondTeamPoints.toString(),
						"player2": playerData[3].name + "," + secondTeamPoints.toString(),
						"player3": playerData[0].name + "," + firstTeamPoints.toString(),
						"player4": playerData[2].name + "," + firstTeamPoints.toString(),
					}
				}

				await admin.messaging().sendToTopic(roomId, gameFinishedMsg1);
			}

			await admin.firestore().collection("users").doc(playerData[1].id)
					.update({"teamGameWins": admin.firestore.FieldValue.increment(1)});
				await admin.firestore().collection("users").doc(playerData[3].id)
					.update({"teamGameWins": admin.firestore.FieldValue.increment(1)});
			break
	}

	const subscribedTokens = await roomData.get("subscribedTokens");

	for(let i = 0; i < subscribedTokens.length; i++)
	{
		await admin.messaging().unsubscribeFromTopic(subscribedTokens[i], roomId);
	}

	for(let i = 0; i < await playerData.length; i++)
	{
		admin.firestore().collection("players").doc(playerData[i].id).delete()
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
	}
	else
	{
		cardFromDeck = await (roomCardsData).get("deck")[0];
	}
	
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
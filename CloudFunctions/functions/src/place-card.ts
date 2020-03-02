import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendFinishedPlayerMsg, getCardData } from "./utils";

export const placeCard1 = functions.https.onCall(async (data, context) => {
	const playerId = data.playerId.toString();
	const cardName = data.cardName;
	const cardUuid = data.cardUuid;
	const roomId = data.roomId.toString();
	const playerToken = data.playerToken;

	const playerRef = admin.firestore().collection("players").doc(playerId);
	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
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

	const roomCardsDataRef = admin.firestore().collection("roomCardsData").doc(roomId);

	//Check if the player has the card. For now it is not in use
	// for(let i = 0; i < elementCardsCount; i++)
	// {
		// if((playerData).get("elementCards")[i].name === cardName 
			// && (playerData).get("elementCards")[i].uuid === cardUuid)
		// {
			const elementCardsRef = await admin.firestore().collection("elementCards");
			const lastCardData = await (await elementCardsRef.doc((await roomCardsDataRef.get()).get("lastCard"))).get();
			const currentCardData = await (await elementCardsRef.doc(cardName)).get();

			if((lastCardData.get("group") === currentCardData.get("group")) 
				|| (lastCardData.get("period") === currentCardData.get("period")))
			{
				await roomTurnDataRef.update({"finishedTurnPlayer": playerId});
				
				console.log("The group or the period coincide")
				await roomCardsDataRef.update({"lastCard": cardName});
				
				await playerRef.update({"elementCards": admin.firestore.FieldValue.arrayRemove({name: cardName, uuid: cardUuid})});

				if((await playerRef.get()).get("elementCards").length === 0)
				{
					if(roomData.get("gameType") === "TeamGame")
					{
						if(playerOnTurnIndex % 2 === 0)
						{
							await roomDataRef.update({"firstTeamWon": true});
						}
						else
						{
							await roomDataRef.update({"firstTeamWon": false});
						}

						await roomTurnDataRef.update({"finishedPlayers": admin.firestore.FieldValue.increment(1)});
					}
					else
					{
						await roomTurnDataRef.update({"finishedPlayers": admin.firestore.FieldValue.increment(1)});
						await roomDataRef.update({"finishedPlayerIds": admin.firestore.FieldValue.arrayUnion(playerId)});
						await roomDataRef.update({"players": admin.firestore.FieldValue.arrayRemove(playerId)});

						await sendFinishedPlayerMsg(playerToken);
					}
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

				return true;
			}
			else
			{
				console.log("The group and the period do not coincide")
				return false;
			}
		// }
	// }

	/*var incorrectCardMsg = {
		"notification": {
			"title": "Incorrect card",
			"body": "You do not have this card"
		}
	}

	await admin.messaging().sendToDevice(playerToken, incorrectCardMsg);*/
})
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
	// const playerData = await playerRef.get();
	// const elementCardsCount = playerData.get("elementCards").length;
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

	// for(let i = 0; i < elementCardsCount; i++)
	// {
		// if((playerData).get("elementCards")[i].name === cardName 
			// && (playerData).get("elementCards")[i].uuid === cardUuid)
		// {
			const elementCardsRef = await admin.firestore().collection("elementCards");
			const lastCardData = await (await elementCardsRef.doc((await roomCardsDataRef.get()).get("lastCard"))).get();
			const currentCardData = await (await elementCardsRef.doc(cardName)).get();
			
			console.log("Player has the card");

			if((lastCardData.get("group") === currentCardData.get("group")) 
				|| (lastCardData.get("period") === currentCardData.get("period")))
			{
				await roomTurnDataRef.update({"finishedTurnPlayer": playerId});
				
				console.log("The group or the period coincide")
				await roomCardsDataRef.update({"lastCard": cardName});
				
				await playerRef.update({"elementCards": admin.firestore.FieldValue.arrayRemove({name: cardName, uuid: cardUuid})});
				// await playerRef.update({"elementCardsCount": admin.firestore.FieldValue.increment(-1)});

				// var placedCardMsg = {
				// 	"notification": {
				// 		"title": "Placed Card",
				// 		"body": "You have placed card successfully"
				// 	}
				// };

				// await admin.messaging().sendToDevice(playerToken, placedCardMsg);

				if((await playerRef.get()).get("elementCards").length === 0)
				{
					await roomTurnDataRef.update({"finishedPlayers": admin.firestore.FieldValue.increment(1)});
					await roomDataRef.update({"finishedPlayerIds": admin.firestore.FieldValue.arrayUnion(playerId)});
					await roomDataRef.update({"players": admin.firestore.FieldValue.arrayRemove(playerId)});

					await sendFinishedPlayerMsg(playerToken);
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

				//await admin.firestore().collection("roomsTurnData").doc(roomId).update({"finishedTurnPlayer": playerId});

				return true;
			}
			else
			{
				// var cannnotPlaceCardMsg = {
				// 	"notification": {
				// 		"title": "Cannot Place Card",
				// 		"body": "This card do not match"
				// 	}
				// }

				// await admin.messaging().sendToDevice(playerToken, cannnotPlaceCardMsg);

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

	await admin.messaging().sendToDevice(playerToken, incorrectCardMsg);

	//TODO: Send msg that the player does not have the card

	console.log("End of the function");
	return false;*/
})
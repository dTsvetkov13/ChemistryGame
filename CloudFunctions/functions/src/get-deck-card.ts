import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { addNewElementCard, generateNewDeck, getCardData } from './utils';

export const getDeckCard1 = functions.https.onCall(async(data, context) => {
	const playerId = data.playerId;
	const roomId = data.roomId;
	
	const roomsTurnDataRef = await admin.firestore().collection("roomsTurnData").doc(roomId);
	
	const roomCardsDataRef = admin.firestore().collection("roomCardsData").doc(roomId);
	const roomCardsData = await roomCardsDataRef.get();
	const roomsData = await admin.firestore().collection("roomsData").doc(roomId).get();
	const playerOnTurnIndex = await (await roomsTurnDataRef.get()).get("nextTurn");

	if(playerId === (await roomsData.get("players")[playerOnTurnIndex]))
	{		
		let cardToGiveName;

		if(!(await roomCardsData.get("deck").length > 0))
		{
			const deck = await generateNewDeck();
			cardToGiveName = deck[0];
			await roomCardsDataRef.update({"deck": deck});
		}
		else
		{
			cardToGiveName = await (roomCardsData).get("deck")[0];
		}

		await roomsTurnDataRef.update({"finishedTurnPlayer": playerId});

		const cardData = await addNewElementCard(cardToGiveName, playerId);

		await roomCardsDataRef.update({"deck": admin.firestore.FieldValue.arrayRemove(cardToGiveName)});

		const cardToGiveData = cardData.uuid + "," + await getCardData(cardToGiveName);

		return cardToGiveData;
	}
	else {
		return false;
	}
})
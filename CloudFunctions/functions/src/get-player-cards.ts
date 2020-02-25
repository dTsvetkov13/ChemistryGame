import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
// import * as utils from './utils';
import {getCardData} from "./utils";

export const getPlayerCards1 = functions.https.onCall(async (data, context) => {
	const playerId = data.playerId.toString();
	// const playerToken = data.playerToken.toString();

	const playerRef = admin.firestore().collection("players").doc(playerId);
	const playerData = await playerRef.get();

	const elementCardsCount = (playerData).get("elementCards").length;
	const compoundCardsCount = (playerData).get("compoundCards").length;
	const playerName = (playerData).get("name");

	let compoundCardsString = "";

	let elementDataTemp = "";

	let elementCardsString = "";

	for(let i = 0; i < elementCardsCount; i++)
	{
		elementDataTemp = (playerData).get("elementCards")[i].name;
		let elementCardId = (playerData).get("elementCards")[i].uuid;

		elementCardsString += elementCardId.toString()+ "," + await getCardData((elementDataTemp)) + "\n";
	}

	let compoundCardTemp;

	for(let i = 0; i < compoundCardsCount; i++)
	{
		compoundCardTemp = (playerData).get("compoundCards")[i]
		compoundCardsString += compoundCardTemp.name + "," + compoundCardTemp.uuid + "\n"; 
	}

	// console.log("Element cards: " + elementCardsString);
	// console.log("Compound cards: " + compoundCards.toString());

	// var playerCards = {
	// 	"notification": {
	// 		"title": "Player Cards",
	// 	},
	// 	"data": {
	// 		"elementCards": elementCardsString,
	// 		"compoundCards": compoundCardsString,
	// 		"playerName": playerName,
	// 	}
	// };

	console.log("Player id: " + playerId);
	console.log("Element cards: " + elementCardsString);
	console.log("Compound Cards : " + compoundCardsString);

	return {
		"elementCards": elementCardsString,
		"compoundCards": compoundCardsString,
		"playerName": playerName
	};

	// await admin.messaging().sendToDevice(playerToken, playerCards);
})
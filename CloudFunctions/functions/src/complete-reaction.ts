import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { addNewElementCard, getCardData, sendFinishedPlayerMsg, addNewCompoundCard } from './utils';

// const WolframAlphaAPI = require('wolfram-alpha-api');
// const waApi = WolframAlphaAPI("Q9UK6A-A6767WAL27");

//Hardcoded for test
export const completeReaction1 = functions.https.onCall(async (data, context) => {
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

	// let leftSideString = "";

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

	if((leftSideCards.length >= 3 && rightSideCards.length === 1)
		|| (leftSideCards.length === 1 && rightSideCards.length >= 3))
	{
		console.log("No such a reaction");
	
		let incorrectReactionMsg = {
			"notification": {
				"title": "Complete Reaction Failed",
				"body": "Incorrect reaction!"
			},
		};
		
		await admin.messaging().sendToDevice(playerToken, incorrectReactionMsg);
		return;
	}

	let newCard = "";

	if(leftSideCards.length === 1 && rightSideCards.length === 1)
	{
		if((leftSideCards[0].name === "Na" && rightSideCards[0].name === "NaCl")
			|| (leftSideCards[0].name === "NaCl" && rightSideCards[0].name === "Na"))
		{
			newCard = "Cl";
		}
		else if((leftSideCards[0].name === "Mg" && rightSideCards[0].name === "MgCl2")
					|| (leftSideCards[0].name === "MgCl2" && rightSideCards[0].name === "Mg"))
		{
			newCard = "Cl"
		}
		else if(leftSideCards[0].name === "Cl")
		{
			if(rightSideCards[0].name === "NaCl")
			{
				newCard = "Na";
			}
			else if(rightSideCards[0].name === "MgCl2")
			{
				newCard = "Mg";
			}
		}
		else if(rightSideCards[0].name === "Cl")
		{
			if(leftSideCards[0].name === "NaCl")
			{
				newCard = "Na";
			}
			else if(leftSideCards[0].name === "MgCl2")
			{
				newCard = "Mg";
			}
		}

		if(newCard !== "")
		{
			console.log("Add this card: " + newCard);

			let cardData = "";
			
			//Deleting cards
			
			await deleteCardsFromPlayer(playerId, leftSideCards, rightSideCards);
			console.log("Deleted cards");
			
			//Check the newCard if it is compound or element
			
			console.log("Card to add: " + newCard);
			
			cardData = await addNewCardToPlayer(playerId, newCard);
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
			return;
		}
	}

	let isItCorrect = false;

	if(leftSideCards.length === 2 && rightSideCards.length === 1)
	{
		if(rightSideCards[0].name === "NaCl")
		{
			if(leftSideCards[0].name === "Na" && leftSideCards[1].name === "Cl" 
				|| (leftSideCards[0].name === "Cl" && leftSideCards[1].name === "Na"))
			{
				isItCorrect = true;
			}
		}
		else if(rightSideCards[0].name === "MgCl2")
		{
			if(leftSideCards[0].name === "Mg" && leftSideCards[1].name === "Cl"
				|| (leftSideCards[0].name === "Cl" && leftSideCards[1].name === "Mg"))
			{
				isItCorrect = true;
			}
		}
	}
	else if(leftSideCards.length === 1 && rightSideCards.length === 2)
	{
		if(leftSideCards[0].name === "NaCl")
		{
			if(rightSideCards[0].name === "Na" && rightSideCards[1].name === "Cl" 
				|| (rightSideCards[0].name === "Cl" && rightSideCards[1].name === "Na"))
			{
				isItCorrect = true;
			}
		}
		else if(leftSideCards[0].name === "MgCl2")
		{
			if(rightSideCards[0].name === "Mg" && rightSideCards[1].name === "Cl" 
				|| (rightSideCards[0].name === "Cl" && rightSideCards[1].name === "Mg"))
			{
				isItCorrect = true;
			}
		}
	}

	if(isItCorrect)
	{
		let correctMsgWithoutData = {
			"notification": {
				"title": "Complete Reaction Successed",
				"body": "Correct reaction"
			}
		};
		
		await admin.messaging().sendToDevice(playerToken, correctMsgWithoutData);
	
		//Deleting cards
	
		await deleteCardsFromPlayer(playerId, leftSideCards, rightSideCards);
	
		await admin.firestore().collection("players").doc(playerId).update({"points": admin.firestore.FieldValue.increment(20)});
		
		const playerData = await admin.firestore().collection("players").doc(playerId).get();
	
		var pointsUpdated = {
			"notification": {
				"title": "Points Updated",
				"body": "Your points have been updated"
			},
			"data": {
				"pointsToAdd": "20" //TODO: change it depending on the reaction
			}
		};
	
		await admin.messaging().sendToDevice(playerToken, pointsUpdated);
	
		if((playerData).get("elementCards").length <= 0)
		{
			const roomId = await (playerData).get("roomId");
			
			const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
			const roomData = await roomDataRef.get();
			const roomTurnDataRef = await admin.firestore().collection("roomsTurnData").doc(roomId);
			const playerOnTurnIndex = await (await roomTurnDataRef.get()).get("nextTurn");
	
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

		return;
	}

	let fillMoreCardsMsg = {
		"notification": {
			"title": "Complete Reaction Failed",
			"body": "You need to fill more cards in the reaction!"
		},
	};
	
	await admin.messaging().sendToDevice(playerToken, fillMoreCardsMsg);
	return;

	// leftSideString += leftSideCards[0].name;

	// for(let i = 1; i < leftSideCards.length; i++)
	// {
	// 	leftSideString += " + " + leftSideCards[i].name;
	// }

	// console.log("String : " + leftSideString);

	// let rightSideString = "";

	// rightSideString += rightSideCards[0].name;

	// for(let i = 1; i < rightSideCards.length; i++)
	// {
	// 	rightSideString += " + " + rightSideCards[i].name;
	// }

	// console.log("String : " + rightSideString);

	// await waApi.getFull({
	// 	input: leftSideString + " -> " + rightSideString,
	// 	includepodid: 'ReactionList:ChemicalReactionData',
	// 	podstate: 'ReactionList:ChemicalReactionData__Show formulas',
	// 	format: 'plaintext',
	// }).then(async (queryresult: any) => {
	// 	//If numpods is equel to 0, there is such a reaction
	// 	if(queryresult.numpods !== 0)
	// 	{
	// 		var receivedString = queryresult.pods[0].subpods[0].plaintext;
			
	// 		console.log(receivedString);
			
			

	// 		if(receivedString === '(data not available)')
	// 		{
	// 			console.log("No such a reaction");
	// 			//return no such a reaction

	// 			let incorrectReactionMsg = {
	// 				"notification": {
	// 					"title": "Complete Reaction Failed",
	// 					"body": "Incorrect reaction!"
	// 				},
	// 			};
		
	// 			await admin.messaging().sendToDevice(playerToken, incorrectReactionMsg);
	// 			return;
	// 		}
	// 		else
	// 		{
	// 			var splitted = receivedString.split("\n")[0].split(" ");
	// 			console.log(splitted);

	// 			//The first one should be the in the cards
	// 			let nextReactant = false;
	// 			let newCardsCount = 0;
	// 			let newCard = true;
	// 			let newCards = [];

	// 			for(let i = 1; i < splitted.length; i++)
	// 			{
	// 				if(nextReactant)
	// 				{
	// 					const currReactant = splitted[i].split("_")[0];

	// 					console.log(i+1 + ": " + currReactant);
	// 					nextReactant = false;
	// 					newCard = true;

	// 					for(let j = 1; j < leftSideCards.length; j++)
	// 					{
	// 						if(leftSideCards[j].name === currReactant)
	// 						{
	// 							console.log("There is it in the left side");
	// 							newCard = false;
	// 						}
	// 					}
						
	// 					for(let j = 1; j < rightSideCards.length; j++)
	// 					{
	// 						if(rightSideCards[j].name === currReactant)
	// 						{
	// 							console.log("There is it in the right side");
	// 							newCard = false;
	// 						}
	// 					}

	// 					if(newCard)
	// 					{
	// 						newCards.push(currReactant);
	// 						newCardsCount++;
	// 					}

	// 					continue;
	// 				}

	// 				if(splitted[i] === '+')
	// 				{
	// 					nextReactant = true;
	// 					continue;
	// 				}
	// 				else
	// 				{
	// 					nextReactant = false;
	// 					continue;
	// 				}
	// 			}

	// 			console.log("newCardsCount : " + newCardsCount);

	// 			if(newCardsCount === 1)
	// 			{
	// 				console.log("Add this card: " + newCards);

	// 				let cardData = "";

	// 				//Deleting cards

	// 				await deleteCardsFromPlayer(playerId, leftSideCards, rightSideCards);
	// 				console.log("Deleted cards");

	// 				//Check the newCard if it is compound or element

	// 				cardData = await addNewCardToPlayer(playerId, newCards[0]);
	// 				console.log("Added new card");

	// 				var correctMsgWithData = {
	// 					"notification": {
	// 						"title": "Complete Reaction Successed",
	// 						"body": "Correct reaction with one missing reactant"
	// 					},
	// 					"data": {
	// 						"cardToAdd": cardData.toString(),
	// 					}
	// 				};

	// 				await admin.messaging().sendToDevice(playerToken, correctMsgWithData);
	// 				//TODO: maybe add bonus points
	// 				return;
	// 			}
	// 			else
	// 			{
	// 				var fillMoreCardsMsg = {
	// 					"notification": {
	// 						"title": "Complete Reaction Failed",
	// 						"body": "You need to fill more cards in the reaction!"
	// 					},
	// 				};
			
	// 				await admin.messaging().sendToDevice(playerToken, fillMoreCardsMsg);
	// 				return;
	// 			}
	// 		}
	// 	}
	// 	else
	// 	{
	// 		var correctMsgWithoutData = {
	// 			"notification": {
	// 				"title": "Complete Reaction Successed",
	// 				"body": "Correct reaction"
	// 			}
	// 		};
	
	// 		await admin.messaging().sendToDevice(playerToken, correctMsgWithoutData);

	// 		//Deleting cards

	// 		await deleteCardsFromPlayer(playerId, leftSideCards, rightSideCards);

	// 		await admin.firestore().collection("players").doc(playerId).update({"points": admin.firestore.FieldValue.increment(20)});
			
	// 		const playerData = await admin.firestore().collection("players").doc(playerId).get();

	// 		var pointsUpdated = {
	// 			"notification": {
	// 				"title": "Points Updated",
	// 				"body": "Your points have been updated"
	// 			},
	// 			"data": {
	// 				"pointsToAdd": "20" //TODO: change it depending on the reaction
	// 			}
	// 		};

	// 		await admin.messaging().sendToDevice(playerToken, pointsUpdated);

	// 		if((playerData).get("elementCards").length <= 0)
	// 		{
	// 			const roomId = await (playerData).get("roomId");
				
	// 			const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	// 			const roomData = await roomDataRef.get();
	// 			const roomTurnDataRef = await admin.firestore().collection("roomsTurnData").doc(roomId);
	// 			const playerOnTurnIndex = await (await roomTurnDataRef.get()).get("nextTurn");

	// 			if(roomData.get("gameType") === "TeamGame")
	// 			{
	// 				if(playerOnTurnIndex % 2 === 0)
	// 				{
	// 					await roomDataRef.update({"firstTeamWon": true});
	// 				}
	// 				else
	// 				{
	// 					await roomDataRef.update({"firstTeamWon": false});
	// 				}

	// 				await roomTurnDataRef.update({"finishedPlayers": admin.firestore.FieldValue.increment(1)});
	// 			}
	// 			else
	// 			{
	// 				await roomTurnDataRef.update({"finishedPlayers": admin.firestore.FieldValue.increment(1)});
	// 				await roomDataRef.update({"finishedPlayerIds": admin.firestore.FieldValue.arrayUnion(playerId)});
	// 				await roomDataRef.update({"players": admin.firestore.FieldValue.arrayRemove(playerId)});

	// 				await sendFinishedPlayerMsg(playerToken);
	// 			}
	// 		}
	// 	}
	// }).catch(console.error)
})

async function playerHasTheseCards(playerId: string, leftSideCards: any, rightSideCards: any)
{
	const playerRef = await admin.firestore().collection("players").doc(playerId);
	const playerData = (await playerRef.get());
	const elementCards = (playerData).get("elementCards");
	const elementCardsCount = (playerData).get("elementCards").length;
	const compoundCards = (playerData).get("compoundCards");
	const compoundCardsCount = (playerData).get("compoundCards").length;

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

async function addNewCardToPlayer(playerId: string, newCard: any)
{
	let upperCases = 0;
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
		cardData = await getCardData(newCard);
	}

	console.log("Card Data: " + cardData);

	let newCardUuid;

	if(upperCases >= 2)
	{
		const data = await addNewCompoundCard(newCard, playerId);
		newCardUuid = data.uuid;
	}
	else
	{
		console.log("Element card");
		const data = await addNewElementCard(newCard, playerId);
		newCardUuid = data.uuid;
	}

	console.log("Before return");

	cardData = newCardUuid + "," + cardData;

	return cardData;
}

async function deleteCardsFromPlayer(playerId: string, leftSideCards: any, rightSideCards: any)
{
	for(let i = 0; i < leftSideCards.length; i++)
	{
		await admin.firestore().collection("players").doc(playerId)
			.update({"elementCards": admin.firestore.FieldValue.arrayRemove(leftSideCards[i])})
		await admin.firestore().collection("players").doc(playerId)
			.update({"compoundCards": admin.firestore.FieldValue.arrayRemove(leftSideCards[i])})
	}

	for(let i = 0; i < rightSideCards.length; i++)
	{
		await admin.firestore().collection("players").doc(playerId)
			.update({"elementCards": admin.firestore.FieldValue.arrayRemove(rightSideCards[i])})
		await admin.firestore().collection("players").doc(playerId)
			.update({"compoundCards": admin.firestore.FieldValue.arrayRemove(rightSideCards[i])})
	}
}
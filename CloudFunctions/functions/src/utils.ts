// import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
const uuidv4 = require('uuid/v4');

export async function sendFinishedPlayerMsg(playerToken: string)
{
	var msg = {
		"notification": {
			"title": "You Finished",
			"body": "You have finished your cards!",
		}
	}

	await admin.messaging().sendToDevice(playerToken, msg);
};

export async function getCardData(name: string)
{
	const cardRef = admin.firestore().collection("elementCards").doc(name);
	let cardData = name;

	await cardRef.get().then((doc: any) => {
		if(doc.exists)
		{
			cardData += "," + doc.data().group + "," + doc.data().period;
		}
	})

	return cardData;
}

export async function addNewElementCard(name: string, playerId: string)
{
	const uuid = await uuidv4();

	await admin.firestore().collection("players").doc(playerId).update({"elementCards": admin.firestore.FieldValue.arrayUnion({name: name, uuid: uuid})});

	return {name: name, uuid: uuid};
}

export async function addNewCompoundCard(name: string, playerId: string)
{
	const uuid = await uuidv4();

	await admin.firestore().collection("players").doc(playerId).update({"compoundCards": admin.firestore.FieldValue.arrayUnion({name: name, uuid: uuid})});

	return {name: name, uuid: uuid};
}

export async function generateNewDeck()
{
	var deck = new Array<string>();

	await admin.firestore().collection("elementCards").get()
		.then(function(querySnapshot)  {
			querySnapshot.forEach(function (doc) {
				console.log(doc.data().symbol);
				deck.push(doc.data().symbol);
			});
		})

	deck = shuffleArray(deck);
	
	return deck;
}

function shuffleArray(array: any[]) {
    for (var i = array.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var temp = array[i];
        array[i] = array[j];
        array[j] = temp;
	}
	
	return array;
}
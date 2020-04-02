import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const leaveRoom1 = functions.region("europe-west1").https.onCall(async (data, context) => { //NOT TESTED
	const roomId = data.roomId.toString();
	const roomRef = await admin.firestore().collection("rooms").doc(roomId);
	const roomDataRef = await admin.firestore().collection("roomsData").doc(roomId);
	const gameType = data.gameType.toString();

	switch (gameType) {
		case "SingleGame":
			const playerId = data.playerId.toString();

			if((await roomRef.get()).get("freeSeats") === 0)
			{
				console.log("Cannnot leave the room");
				return false;
			}

			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayRemove(playerId)});

			await roomRef.update({freeSeats : admin.firestore.FieldValue.increment(1)});

			return true;
		case "TeamGame":
			if((await roomRef.get()).get("freeSeats") === 0)
			{
				console.log("Cannnot leave the room");
				return false;
			}
			
			const firstPlayerId = data.firstPlayerId.toString();
			const secondPlayerId = data.secondPlayerId.toString();
		
			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayRemove(firstPlayerId)});
			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayRemove(secondPlayerId)});

			await roomRef.update({"freeSeats": admin.firestore.FieldValue.increment(2)});
			return true;
		default:
			return false;
			break;
	}
})
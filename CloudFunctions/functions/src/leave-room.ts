import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const leaveRoom1 = functions.https.onCall(async (data, context) => { //NOT TESTED
	const roomId = data.roomId.toString();
	const roomRef = await admin.firestore().collection("rooms").doc(roomId);
	const roomDataRef = await admin.firestore().collection("roomsData").doc(roomId);
	const gameType = data.gameType.toString();

	switch (gameType) {
		case "SingleGame":
			const playerId = data.playerId.toString();

			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayRemove(playerId)});

			await roomRef.update({freeSeats : admin.firestore.FieldValue.increment(1)});

			break;
		case "TeamGame":
			//const firstPlayerId = data.firstPlayerId.toString();
			//const secondPlayerId = data.secondPlayerId.toString();

			//await roomRef.delete({"teams.secondTeam" : {"points": 0}}}); //, [secondPlayerId] : {"points": 0}

			//TODO: delete 2 players

			await roomRef.update({"freeSeats": admin.firestore.FieldValue.increment(2)});
			break;
		default:
			break;
	}
})
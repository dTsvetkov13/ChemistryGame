import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

//https://us-central1-chemistrygame-cd3a6.cloudfunctions.net/fillTheRoomWithFictitiousPlayers
export const fillTheRoomWithFictitiousPlayers1 = functions.https.onRequest(async (req, resp) => {
	const roomId = req.query.roomId;
	const gameType = await (await admin.firestore().collection("rooms").doc(roomId).get()).get("gameType");

	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);
	const roomData = roomDataRef.get();

	const fictitiousPlayers = ["13", "47", "11"];

	switch(gameType)
	{
		case("SingleGame"):
		{
			const currPlayers = (await roomData).get("players");
			let index = 0;

			for(let i = currPlayers.length; i < 4; i++)
			{
				await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion(fictitiousPlayers[index])});
				index++;
			}
		
			await admin.firestore().collection("rooms").doc(roomId).update({"freeSeats": 0});

			break;
		}
		case("TeamGame"):
		{
			const firstTeamPlayerTemp = (await roomData).get("firstTeamPlayerTemp");

			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion(fictitiousPlayers[0])});
			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion(firstTeamPlayerTemp)});
			await roomDataRef.update({"players": admin.firestore.FieldValue.arrayUnion(fictitiousPlayers[1])});
			
			await admin.firestore().collection("rooms").doc(roomId).update({"freeSeats": 0});

			await roomDataRef.update({
				"firstTeamPlayerTemp": admin.firestore.FieldValue.delete()
			});

			break;
		}
	}
})
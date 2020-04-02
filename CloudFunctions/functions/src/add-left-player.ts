import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const addLeftPlayer1 = functions.region("europe-west1").https.onCall(async (data, context) => {
	const playerId = data.playerId;
	const roomId = data.roomId;

	const roomDataRef = admin.firestore().collection("roomsData").doc(roomId);

	const playerToken = (await admin.firestore().collection("tokens").doc(playerId).get()).get("token");

 	await admin.messaging().unsubscribeFromTopic(playerToken, roomId);
	await roomDataRef.update({"subscribedTokens": admin.firestore.FieldValue.arrayRemove(playerToken)});

	const roomData = await roomDataRef.get();

	if(roomData.get("gameType") === "TeamGame")
	{
		const players = roomData.get("players");

		for(let i = 0; i < players.length; i++)
		{
			if(players[i] === playerId)
			{
				if(i % 2 == 0)
				{
					await roomDataRef.update({"firstTeamWon": false});
				}
				else
				{
					await roomDataRef.update({"firstTeamWon": true});
				}

				await admin.firestore().collection("roomsTurnData").doc(roomId)
					.update({"finishedPlayers": admin.firestore.FieldValue.increment(1)});
			}
		}

		return;
	}
	else
	{
		await roomDataRef.update({"leftPlayers": admin.firestore.FieldValue.arrayUnion(playerId)});
		await roomDataRef.update({"players": admin.firestore.FieldValue.arrayRemove(playerId)});
	}

	if(roomData.get("leftPlayers")?.length >= 2)
	{
		await admin.firestore().collection("roomsTurnData").doc(roomId).update({"finishedPlayers": 2});
	}
})
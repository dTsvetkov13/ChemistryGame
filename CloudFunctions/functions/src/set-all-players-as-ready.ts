import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

//https://us-central1-chemistrygame-cd3a6.cloudfunctions.net/setAllPlayersAsReady/addMessage?roomId=
export const setAllPlayersAsReady1 = functions.https.onRequest(async (req, resp) => {
    const playerId = "JKOZhZFV7nedIhwXSprBLmoPVr93";
    
    const playerRef = admin.firestore().collection("players").doc(playerId);

    const roomId = (await playerRef.get()).get("roomId");
    const roomTurnDataRef = admin.firestore().collection("roomsTurnData").doc(roomId);

    await roomTurnDataRef.update({"readyPlayers": 4});
})
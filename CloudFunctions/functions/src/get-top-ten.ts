import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const getTopTen1 = functions.https.onCall(async (data, context) => {
	const sortedBy = data.sortedBy;

	let resultData = new Array<{name: string, wins: number}>();

	await admin.firestore().collection("users").orderBy(sortedBy.toString(), "desc").limit(10).get()
		.then(function (querySnapshot)  {
			querySnapshot.docs.forEach(function(doc) {
				if(doc.exists)
				{
					switch(sortedBy)
					{
						case("singleGameWins"):
							resultData.push({name: doc.data().username, wins: doc.data().singleGameWins});
							break;
						case("teamGameWins"):
							resultData.push({name: doc.data().username, wins: doc.data().teamGameWins});
							break;
					}
				}
			})
		})
		.catch(function(error) {
			console.log("Error getting documents: ", error);
		});
	
	return resultData;
});
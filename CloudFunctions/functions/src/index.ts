import * as admin from 'firebase-admin';
import { updateUser1 } from './update-user';
import { findRoom1 } from './find-room';
import { getPlayerCards1 } from './get-player-cards';
import { readyPlayer1 } from './ready-player';
import { acceptInvitation1 } from './accept-invitation';
import { acceptTeamInvitation1 } from './accept-team-invitation';
import { addFriend1 } from './add-friend';
import { addLeftPlayer1 } from './add-left-player';
import { declineInvitation1 } from './decline-invitation';
import { fillTheRoomWithFictitiousPlayers1 } from './fill-the-room-with-fictitious-players';
import { getAllFriends1 } from './get-all-friends';
import { getAllInvitations1 } from './get-all-invitations';
import { getOnlineFriends1 } from './get-online-friends';
import { getDeckCard1 } from './get-deck-card';
import { getProfileData1 } from './get-profile-data';
import { getTopTen1 } from './get-top-ten';
import { placeCard1 } from './place-card';
import { sendChatMsgToEveryone1 } from './send-chat-msg-to-everyone';
import { sendTeamGameInvitation1 } from './send-team-game-invitation';
import { updateCurrToken1 } from './update-curr-token';
import { listenersToRoomFreeSeats1 } from "./listeners-to-room-free-seats";
import { listenersToRoomTurnData1 } from "./listeners-to-room-turn-data";
import { completeReaction1 } from './complete-reaction';
import { leaveRoom1 } from './leave-room';

const serviceAccount = require("../chemistrygame-cd3a6-firebase-adminsdk-cd58r-855bee1b82");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://chemistrygame-cd3a6.firebaseio.com"
});

export const acceptInvitation = acceptInvitation1;
export const acceptTeamInvitation = acceptTeamInvitation1;
export const addFriend = addFriend1;
export const addLeftPlayer = addLeftPlayer1;
export const declineInvitation = declineInvitation1;
export const fillTheRoomWithFictitiousPlayers = fillTheRoomWithFictitiousPlayers1;
export const findRoom = findRoom1;
export const getAllFriends = getAllFriends1;
export const getAllInvitations = getAllInvitations1;
export const getOnlineFriends = getOnlineFriends1;
export const getDeckCard = getDeckCard1;
export const getPlayerCards = getPlayerCards1;
export const getProfileData = getProfileData1;
export const getTopTen = getTopTen1;
export const placeCard = placeCard1;
export const readyPlayer = readyPlayer1;
export const sendChatMsgToEveryone = sendChatMsgToEveryone1;
export const sendTeamGameInvitation = sendTeamGameInvitation1;
export const updateCurrToken = updateCurrToken1;
export const updateUser = updateUser1;
export const completeReaction = completeReaction1;
export const leaveRoom = leaveRoom1;

exports.listenersToRoomFreeSeats = listenersToRoomFreeSeats1;
exports.listenersToRoomTurnData = listenersToRoomTurnData1;
import WebSocket from "ws";
import { generateId } from "./utils/crypto";
import { Peer, PeerStatus } from "./types/Peer";
import { ClientMessageType, Message, ServerMessageType } from "./types/Message";
import { Match } from "./types/Match";
const PORT = 8080;
const MAX_NUMBER_OF_PEERS_ON_MATCH = 2;

const wss = new WebSocket.Server({ port: PORT });
console.log("Server started at por: " + PORT);

const Peers = new Map<number, Peer>();
const Matches = new Map<number, Match>();

wss.on("connection", (ws) => {
  const id = generateId();
  const peer: Peer = { id, ws, status: PeerStatus.IDLE };
  Peers.set(id, peer);

  console.log("New peer connected with id: " + id);

  sendMessage(peer, {
    type: ServerMessageType.CONNECTED,
    payload: { id },
    sourceId: 0,
  });

  handleFindMatch(peer);

  ws.on("message", (message) => {
    parseMessage(peer, message.toString());
  });

  ws.on("close", () => {
    console.log("Peer " + peer.id + " disconnected");
    handleDisconnection(peer);
  });

  ws.send("Hello! Message From Server!!");
});

const parseMessage = (peer: Peer, stringMessage: string) => {
  let parsedMessage: Message;
  try {
    parsedMessage = JSON.parse(stringMessage);
  } catch (e) {
    throw new Error("Invalid JSON");
  }

  console.log(
    "MESSAGE: \n From: " +
      peer.id +
      "\n Destination: " +
      parsedMessage.destinationPeer +
      "\n Type: " +
      parsedMessage.type
  );
  switch (parsedMessage.type as ClientMessageType) {
    case ClientMessageType.FIND_MATCH:
      handleFindMatch(peer);
      break;
    case ClientMessageType.OFFER:
      handleMessage(peer, parsedMessage);
      break;
    case ClientMessageType.ANSWER:
      handleMessage(peer, parsedMessage);
      break;
    case ClientMessageType.CANDIDATE:
      handleMessage(peer, parsedMessage);
      break;
    default:
      throw new Error("Invalid message type");
  }
};

export const handleMessage = (peer: Peer, data: any) => {
  if (data.destinationPeer) {
    const destinationPeer = Peers.get(data.destinationPeer);
    if (!destinationPeer) {
      throw new Error("Destination peer not found");
    }
    sendMessage(destinationPeer, {
      type: data.type,
      payload: data.payload,
      sourceId: peer.id,
    });
  }
};

export const sendMessage = (peer: Peer, message: Message) => {
  peer.ws.send(JSON.stringify(message));
};

export const handleFindMatch = (peer: Peer) => {
  if (Matches.size === 0) {
    createMatch(peer);
  }
  const match = findMatch();
  if (match) {
    joinMatch(peer, match);
  }
  if (match?.players.length === MAX_NUMBER_OF_PEERS_ON_MATCH) {
    startMatch(match);
  }
};

export const startMatch = (match: Match) => {
  match.players.forEach((playerId) => {
    const player = Peers.get(playerId);
    if (player) {
      sendMessage(player, {
        type: ServerMessageType.START_MATCH,
        payload: { matchId: match.id, players: match.players },
        sourceId: 0,
      });
    }
  });
};

export const createMatch = (peer: Peer) => {
  const matchId = generateId();
  const match: Match = { id: matchId, players: [] };
  Matches.set(matchId, match);
  peer.status = PeerStatus.FINDING_MATCH;
  console.log("Match created with id: " + matchId);
};

export const findMatch = () => {
  return Array.from(Matches.values()).find(
    (match) => match.players.length < MAX_NUMBER_OF_PEERS_ON_MATCH
  );
};

export const joinMatch = (peer: Peer, match: Match) => {
  match.players.push(peer.id);
  console.log("Peer " + peer.id + " joined match " + match.id);
};

export const leaveMatch = (peer: Peer): Match | null => {
  const match = Array.from(Matches.values()).find((match) =>
    match.players.includes(peer.id)
  );
  if (match) {
    match.players = match.players.filter((id) => id !== peer.id);
    console.log("Peer " + peer.id + " left match " + match.id);
    if (match.players.length === 0) {
      Matches.delete(match.id);
      return null;
    }
    return match;
  }
  return null;
};

export const handleDisconnection = (peer: Peer) => {
  const match = leaveMatch(peer);
  if (!match) return;

  match.players.forEach((playerId) => {
    const player = Peers.get(playerId);
    if (player) {
      sendMessage(player, {
        type: ServerMessageType.PEER_DISCONNECTED,
        payload: { id: peer.id },
        sourceId: 0,
      });
    }
  });
};

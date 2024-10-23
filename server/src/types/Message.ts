export enum ClientMessageType {
  FIND_MATCH = "FIND_MATCH",
  OFFER = "OFFER",
  ANSWER = "ANSWER",
  CANDIDATE = "CANDIDATE",
  START_MATCH = "START_MATCH",
}

export interface Message {
  type: ClientMessageType | ServerMessageType;
  destinationPeer?: number;
  sourceId?: number;
  payload: any;
}

export enum ServerMessageType {
  CONNECTED = "CONNECTED",
  START_MATCH = "START_MATCH",
  PEER_DISCONNECTED = "PEER_DISCONNECTED",
}

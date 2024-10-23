import WebSocket from "ws";

export interface Peer {
  id: number;
  status: PeerStatus;
  ws: WebSocket;
}

export enum PeerStatus {
  FINDING_MATCH = "FINDING_MATCH",
  PLAYING = "PLAYING",
  IDLE = "IDLE",
}

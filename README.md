
# Godot Ts WebRTC

This project implements WebRTC technology, using Godot for the game and client-side and TypeScript with WebSocket for the signaling server.

Once connected, players can move, jump, and interact with each other in real time.

## Prerequisites

-   Node (v18.15)
-   Yarn (v3.5.1) or npm (Yarn recommended)
-   Godot 4.3

## How to Start

1.  Clone the repository.
2.  Import the project into Godot.
3.  Open the `./server` folder.
4.  Run `npm i` or `yarn`.
5.  Run `npm run dev` or `yarn dev`.
6.  In Godot, go to `Debug -> Customize run instances`. (Steps might vary based on the Godot version.)
7.  Enable multiple instances and set the number to 2.
8.  Press OK.
9.  Run the project in Godot.
10.  Click the **Find match** button in both instances.
extends Node

var rtc_mp: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()

var ws: WebSocketPeer = WebSocketPeer.new()
var code = 1000
var reason = "Unknown"
const ADDRESS = "127.0.0.1:8080" 
var start_match_clicked = false
var start_match_signal_sent = false

const MessageTypes = {
	CONNECTED = "CONNECTED", 
	START_MATCH = "START_MATCH", 
	CANDIDATE="CANDIDATE", 
	OFFER="OFFER", 
	ANSWER="ANSWER", 
	DISCONNECTED= "DISCONNECTED", 
	PEER_DISCONNECTED = "PEER_DISCONNECTED"
}

signal start_match()

func start(address):
	stop()
	connect_to_url(address)

func stop():
	multiplayer.multiplayer_peer = null
	rtc_mp.close()
	close()

func _create_peer(id):
	var peer: WebRTCPeerConnection = WebRTCPeerConnection.new()
	#replace with your own stun/turn server
	peer.initialize({
		"iceServers":[
	  {
		"urls": "stun:stun.relay.metered.ca:80",
	  }
  	]
	})
	peer.session_description_created.connect(self._offer_created.bind(id))
	peer.ice_candidate_created.connect(self._new_ice_candidate.bind(id))
	rtc_mp.add_peer(peer, id)

	if id > rtc_mp.get_unique_id():
		peer.create_offer()
	return peer


func connect_to_url(url):
	close()
	code = 1000
	reason = "Unknown"
	ws.connect_to_url(url)

func close():
	ws.close()

func _process(delta):
	var old_state: int = ws.get_ready_state()
	if old_state == WebSocketPeer.STATE_CLOSED:
		return
	ws.poll()
	var state = ws.get_ready_state()
	if state != old_state and state == WebSocketPeer.STATE_OPEN:
		pass
	while state == WebSocketPeer.STATE_OPEN and ws.get_available_packet_count():
		_parse_msgs()
	if state == WebSocketPeer.STATE_CLOSED:
		code = ws.get_close_code()
		reason = ws.get_close_reason()
	
	if(start_match_clicked and not start_match_signal_sent):
		var peer_status = _check_connection_status()
		if peer_status:
			emit_signal("start_match")
			start_match_signal_sent = true
	
	
	


func _parse_msgs():
	var parsed = JSON.parse_string(ws.get_packet().get_string_from_utf8())
	
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("type"): 
		return false
	
	var msg := parsed as Dictionary
	var type := str(msg.type)
	var src_id := str(msg.sourceId).to_int()
		
	if type == MessageTypes.CONNECTED:
		_connected(msg.payload.id)
	elif type == MessageTypes.START_MATCH:
		_start_match(msg.payload.players)
	elif type == MessageTypes.CANDIDATE:
		var candidate: PackedStringArray = msg.payload.split("\n", false)
		if candidate.size() != 3:
			return false
		if not candidate[1].is_valid_int():
			return false
		_candidate_received(src_id, candidate[0], candidate[1].to_int(), candidate[2])
		
	elif type == MessageTypes.OFFER:
		_offer_received(src_id, msg.payload)
	elif type == MessageTypes.ANSWER:
		_answer_received(src_id, msg.payload)
	elif type == MessageTypes.PEER_DISCONNECTED:
		_peer_disconnected(msg.payload.id)
	
func _start_match(players):
	for player in players:
		var playerId = str(player).to_int()
		if playerId != rtc_mp.get_unique_id():
			_create_peer(playerId)
	start_match_clicked = true
	
	

func send_candidate(id, mid, index, sdp) -> int:
	return send_msg(MessageTypes.CANDIDATE, id, "\n%s\n%d\n%s" % [mid, index, sdp])


func send_offer(id, offer) -> int:
	return send_msg(MessageTypes.OFFER, id, offer)


func send_answer(id, answer) -> int:
	return send_msg(MessageTypes.ANSWER, id, answer)

func send_msg(type: String, id: int, data:="") -> int:
	return ws.send_text(JSON.stringify({
		"type": type,
		"destinationPeer": id,
		"payload": data
	}))
	
func _new_ice_candidate(mid_name, index_name, sdp_name, id):
	send_candidate(id, mid_name, index_name, sdp_name)


func _offer_created(type, data, id):
	if not rtc_mp.has_peer(id):
		return
	rtc_mp.get_peer(id).connection.set_local_description(type, data)
	if type == "offer": send_offer(id, data)
	else: send_answer(id, data)


func _connected(id):
	rtc_mp.create_mesh(id)
	multiplayer.multiplayer_peer = rtc_mp
	print("Connected %d" % [id])


func _peer_disconnected(id):
	if rtc_mp.has_peer(id): rtc_mp.remove_peer(id)


func _offer_received(id, offer):
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.set_remote_description("offer", offer)


func _answer_received(id, answer):
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.set_remote_description("answer", answer)


func _candidate_received(id, mid, index, sdp):
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.add_ice_candidate(mid, index, sdp)


func _check_webrtc_connection_state():
	var peers = rtc_mp.get_peers()
	print("PEERS: ", peers)
	
func _handle_disconnect():
	stop()

func _check_connection_status():
	var peers = rtc_mp.get_peers()
	var status = true
	for peer in peers:
		var _peer = rtc_mp.get_peer(peer)
		status = _peer.connected and status
	return status

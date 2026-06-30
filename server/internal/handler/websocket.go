package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/kingmes/server/internal/db"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

var connections = struct {
	sync.RWMutex
	m map[string]*websocket.Conn
}{m: make(map[string]*websocket.Conn)}

type IncomingMessage struct {
	Action    string          `json:"action"`
	Data      json.RawMessage `json:"data"`
	RequestID string          `json:"request_id,omitempty"`
}

func WebSocketHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}
	defer conn.Close()

	var currentKey string

	for {
		_, msgBytes, err := conn.ReadMessage()
		if err != nil {
			log.Println("Read error:", err)
			break
		}

		var msg IncomingMessage
		if err := json.Unmarshal(msgBytes, &msg); err != nil {
			log.Println("Invalid JSON:", err)
			continue
		}

		switch msg.Action {
		case "register":
            var data struct {
                PublicKey string `json:"public_key"`
                Nickname  string `json:"nickname"`
            }
            if err := json.Unmarshal(msg.Data, &data); err != nil {
                sendError(conn, "invalid data")
                continue
            }
            _, err := db.DB.Exec("INSERT INTO users (public_key, nickname) VALUES (?, ?)", data.PublicKey, data.Nickname)
            if err != nil {
                sendError(conn, "registration failed: "+err.Error())
                continue
            }
            sendOK(conn, "registered")

		case "auth":
			var data struct {
				PublicKey string `json:"public_key"`
			}
			if err := json.Unmarshal(msg.Data, &data); err != nil {
				sendError(conn, "invalid data")
				continue
			}
			var exists int
			err := db.DB.QueryRow("SELECT count(*) FROM users WHERE public_key = ?", data.PublicKey).Scan(&exists)
			if err != nil || exists == 0 {
				sendError(conn, "user not found")
				continue
			}
			connections.Lock()
			connections.m[data.PublicKey] = conn
			connections.Unlock()
			currentKey = data.PublicKey
			sendOK(conn, "authenticated")

		case "search_user":
            var data struct {
                Nickname string `json:"nickname"`
            }
            if err := json.Unmarshal(msg.Data, &data); err != nil {
                sendError(conn, "invalid data")
                continue
            }
            row := db.DB.QueryRow("SELECT public_key FROM users WHERE nickname = ?", data.Nickname)
            var foundKey string
            if err := row.Scan(&foundKey); err != nil {
                sendError(conn, "user not found")
                continue
            }
            sendJSON(conn, map[string]interface{}{
                "action": "search_result",
                "data": map[string]string{
                    "public_key": foundKey,
                    "nickname":   data.Nickname,
                },
            })

		case "send_message":
			var data struct {
				Receiver string `json:"receiver"`
				Content  string `json:"content"`
			}
			if err := json.Unmarshal(msg.Data, &data); err != nil {
				sendError(conn, "invalid data")
				continue
			}
			if currentKey == "" {
				sendError(conn, "not authenticated")
				continue
			}
			// Сохраняем в БД
			_, err := db.DB.Exec(
				"INSERT INTO messages (sender_key, receiver_key, content) VALUES (?, ?, ?)",
				currentKey, data.Receiver, data.Content,
			)
			if err != nil {
				sendError(conn, "failed to save message")
				continue
			}
			// Если получатель онлайн, доставляем немедленно
			connections.RLock()
			if receiverConn, ok := connections.m[data.Receiver]; ok {
				sendJSON(receiverConn, map[string]interface{}{
					"action": "new_message",
					"data": map[string]interface{}{
						"sender":    currentKey,
						"content":   data.Content,
						"timestamp": time.Now().Unix(),
					},
				})
			}
			connections.RUnlock()
			sendOK(conn, "message sent")

		case "get_messages":
			var data struct {
				PeerKey string `json:"peer_key"`
			}
			if err := json.Unmarshal(msg.Data, &data); err != nil {
				sendError(conn, "invalid data")
				continue
			}
			if currentKey == "" {
				sendError(conn, "not authenticated")
				continue
			}
			// Диалог между мной и собеседником
			rows, err := db.DB.Query(
				`SELECT id, sender_key, content, timestamp FROM messages
				 WHERE (sender_key = ? AND receiver_key = ?) OR (sender_key = ? AND receiver_key = ?)
				 ORDER BY id ASC LIMIT 100`,
				currentKey, data.PeerKey, data.PeerKey, currentKey,
			)
			if err != nil {
				sendError(conn, "db error")
				continue
			}
			var msgs []map[string]interface{}
			for rows.Next() {
				var id int
				var sender, content, timestamp string
				rows.Scan(&id, &sender, &content, &timestamp)
				msgs = append(msgs, map[string]interface{}{
					"id": id, "sender": sender, "content": content, "timestamp": timestamp,
				})
			}
			response := map[string]interface{}{
				"action": "messages",
				"data":   msgs,
			}
			if msg.RequestID != "" {
				response["request_id"] = msg.RequestID
			}
			sendJSON(conn, response)

		default:
			sendError(conn, "unknown action")
		}
	}

	// удаляем соединение при выходе
	if currentKey != "" {
		connections.Lock()
		delete(connections.m, currentKey)
		connections.Unlock()
	}
}

func sendJSON(conn *websocket.Conn, v interface{}) {
	conn.WriteJSON(v)
}

func sendOK(conn *websocket.Conn, message string) {
	sendJSON(conn, map[string]interface{}{"status": "ok", "message": message})
}

func sendError(conn *websocket.Conn, message string) {
	sendJSON(conn, map[string]interface{}{"status": "error", "message": message})
}
package handler

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // на время разработки разрешаем все origin
	},
}

func WebSocketHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Ошибка обновления до WebSocket:", err)
		return
	}
	defer conn.Close()

	log.Println("Клиент подключился")

	for {
		messageType, msg, err := conn.ReadMessage()
		if err != nil {
			log.Println("Ошибка чтения:", err)
			break
		}
		log.Printf("Получено: %s", msg)

		// Эхо-ответ
		if err := conn.WriteMessage(messageType, msg); err != nil {
			log.Println("Ошибка записи:", err)
			break
		}
	}
}
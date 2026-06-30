package main

import (
	"log"
	"net/http"

	"github.com/kingmes/server/internal/db"
	"github.com/kingmes/server/internal/handler"
)

func main() {
	db.Init("./data.db")
	http.HandleFunc("/ws", handler.WebSocketHandler)
	log.Println("Сервер запущен на :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
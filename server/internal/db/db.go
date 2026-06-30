package db

import (
	"database/sql"
	"log"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func Init(dbPath string) {
	var err error
	DB, err = sql.Open("sqlite", dbPath)
	if err != nil {
		log.Fatal(err)
	}
	createTables()
}

func createTables() {
    _, err := DB.Exec(`
        CREATE TABLE IF NOT EXISTS users (
            public_key TEXT PRIMARY KEY,
            nickname TEXT UNIQUE
        );
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_key TEXT NOT NULL,
            receiver_key TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    `)
    if err != nil {
        log.Fatal(err)
    }
}
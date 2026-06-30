package model

type User struct {
	PublicKey string `json:"public_key"`
	Nickname  string `json:"nickname"`
}
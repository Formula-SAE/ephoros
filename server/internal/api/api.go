package api

import (
	"crypto/rand"
	"encoding/base64"
	"errors"

	"github.com/ApexCorse/ephoros/server/internal/db"
	"golang.org/x/crypto/bcrypt"
)

type API struct {
	db *db.DB
}

func NewAPI(db *db.DB) *API {
	return &API{
		db: db,
	}
}

func (a *API) validateUser(username, password string) error {
	user, err := a.db.GetUserByUsername(username)
	if err != nil {
		return errors.New("invalid credentials")
	}

	err = a.validatePassword(password, user.Salt, user.HashPassword)
	if err != nil {
		return errors.New("invalid credentials")
	}

	return nil
}

func (a *API) validatePassword(password, salt, hashedPassword string) error {
	return bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password+salt))
}

func (a *API) hashPassword(password string) (string, string, error) {
	saltBytes := make([]byte, 16)
	_, err := rand.Read(saltBytes)
	if err != nil {
		return "", "", err
	}
	salt := base64.StdEncoding.EncodeToString(saltBytes)

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password+salt), bcrypt.DefaultCost)
	if err != nil {
		return "", "", err
	}

	return string(hashedPassword), salt, nil
}

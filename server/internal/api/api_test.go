package api

import (
	"crypto/rand"
	"encoding/base64"
	"testing"

	"github.com/ApexCorse/ephoros/server/internal/db"
	"github.com/stretchr/testify/assert"
	"golang.org/x/crypto/bcrypt"
)

func TestValidateUser_Success(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	api := NewAPI(db.NewDB(gormDb))

	saltBytes := make([]byte, 16)
	rand.Read(saltBytes)
	salt := base64.StdEncoding.EncodeToString(saltBytes)

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte("Corse"+salt), bcrypt.DefaultCost)
	assert.Nil(t, err)

	user := &db.User{
		Username:     "Apex",
		HashPassword: string(hashedPassword),
		Salt:         salt,
	}
	gormDb.Create(user)

	err = api.validateUser("Apex", "Corse")
	assert.Nil(t, err)
}

func TestValidateUser_Failure(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	api := NewAPI(db.NewDB(gormDb))

	saltBytes := make([]byte, 16)
	rand.Read(saltBytes)
	salt := base64.StdEncoding.EncodeToString(saltBytes)

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte("Corse"+salt), bcrypt.DefaultCost)
	assert.Nil(t, err)

	user := &db.User{
		Username:     "Apex",
		HashPassword: string(hashedPassword),
		Salt:         salt,
	}
	gormDb.Create(user)

	err = api.validateUser("Apex", "Cors")
	assert.Error(t, err)
}

func TestHashPassword(t *testing.T) {
	password := "ApexCorse"
	api := &API{}

	hashedPassword, salt, err := api.hashPassword(password)

	assert.Nil(t, err)
	assert.NotEqual(t, password, hashedPassword)
	assert.NotEqual(t, salt, "")
}

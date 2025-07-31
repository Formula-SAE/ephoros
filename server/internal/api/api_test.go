package api

import (
	"testing"

	"github.com/ApexCorse/ephoros/server/internal/db"
	"github.com/gorilla/mux"
	"github.com/stretchr/testify/assert"
)

func TestValidateUser_Success(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	api := NewAPI("", db.NewDB(gormDb), mux.NewRouter())

	user := &db.User{
		Username: "Apex",
		Token:    "Corse",
	}
	gormDb.Create(user)

	err = api.validateUser("Corse")
	assert.Nil(t, err)
}

func TestValidateUser_Failure(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	api := NewAPI("", db.NewDB(gormDb), mux.NewRouter())

	user := &db.User{
		Username: "Apex",
		Token:    "Corse",
	}
	gormDb.Create(user)

	err = api.validateUser("Cors")
	assert.Error(t, err)
}

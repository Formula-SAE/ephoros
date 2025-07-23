package api

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"net/http"

	"github.com/ApexCorse/ephoros/server/internal/db"
	"github.com/gorilla/mux"
	"golang.org/x/crypto/bcrypt"
)

type API struct {
	db      *db.DB
	r       *mux.Router
	address string
}

func NewAPI(address string, db *db.DB, r *mux.Router) *API {
	return &API{
		db:      db,
		r:       r,
		address: address,
	}
}

func (a *API) Start() {
	a.r.HandleFunc("/auth", a.handleAuth).Methods("POST")
	a.r.HandleFunc("/data", a.handleSendData).Methods("POST")

	http.ListenAndServe(a.address, a.r)
}

func (a *API) handleAuth(w http.ResponseWriter, r *http.Request) {
	username := r.Header.Get("Username")
	password := r.Header.Get("Password")

	if err := a.validateUser(username, password); err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	json.NewEncoder(w).Encode(
		map[string]string{
			"message": "Authorized",
		},
	)
}

func (a *API) handleSendData(w http.ResponseWriter, r *http.Request) {
	username := r.Header.Get("Username")
	password := r.Header.Get("Password")

	if err := a.validateUser(username, password); err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	body := &DataRequestBody{}
	if err := json.NewDecoder(r.Body).Decode(body); err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}

	if !body.Validate() {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}

	sensor, err := a.db.GetSensorByNameAndModuleAndSection(
		body.Sensor,
		body.Module,
		body.Section,
		body.From,
		body.To,
	)
	if err != nil {
		http.Error(w, "sensor not found", http.StatusNotFound)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	json.NewEncoder(w).Encode(
		map[string]any{
			"module":  body.Module,
			"name":    sensor.Name,
			"records": sensor.Records,
			"section": body.Section,
		},
	)
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

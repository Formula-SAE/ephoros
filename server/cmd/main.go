package main

import (
	"log"
	"os"

	"github.com/ApexCorse/ephoros/server/internal/api"
	"github.com/ApexCorse/ephoros/server/internal/config"
	"github.com/ApexCorse/ephoros/server/internal/db"
	mqttPkg "github.com/ApexCorse/ephoros/server/internal/mqtt"

	"github.com/gorilla/mux"
	mqtt "github.com/mochi-mqtt/server/v2"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	dbUrl := os.Getenv("DB_URL")
	if dbUrl == "" {
		log.Fatalf("DB_URL is not set")
		return
	}

	gormDb, err := gorm.Open(postgres.Open(dbUrl))
	if err != nil {
		log.Fatalf("could not open DB: %s", err.Error())
		return
	}
	db := db.NewDB(gormDb)

	configFile, err := os.Open("config.json")
	if err != nil {
		log.Fatalf("could not open config file: %s", err.Error())
		return
	}
	configuration, err := config.NewConfigFromReader(configFile)
	if err != nil {
		log.Fatalf("could not parse config file: %s", err.Error())
		return
	}

	configManager := config.NewConfigManager(configuration, db)
	if err = configManager.UpdateDB(); err != nil {
		log.Fatalf("could not update DB: %s", err.Error())
		return
	}

	mqttServer := mqtt.New(nil)
	router := mux.NewRouter()

	api := api.NewAPI(&api.APIConfig{
		Address: ":8080",
		DB:      db,
		Router:  router,
		Config:  configuration,
	})

	dataHook := mqttPkg.NewDataHook(db)

	//TODO(lentscode): Add [Listeners] and [Certificates]
	mqttService := mqttPkg.NewMQTT(&mqttPkg.MQTTConfig{
		Config: configuration,
		DB:     db,
		Server: mqttServer,
		Hooks: []mqttPkg.HookConfig{
			{
				Hook:    dataHook,
				Options: &mqtt.Options{},
			},
		},
	})

	go mqttService.Start()
	api.Start()
}

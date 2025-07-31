package config

import (
	"testing"

	"github.com/ApexCorse/ephoros/server/internal/db"
	"github.com/stretchr/testify/assert"
)

func TestUpdateDB(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	config := &Config{
		SensorConfigs: []SensorConfig{
			{
				Name:    "NTC-1",
				Module:  "Module 1",
				Section: "Battery",
				ID:      1,
			},
			{
				Name:    "NTC-2",
				Module:  "Module 2",
				Section: "Battery",
				ID:      2,
			},
			{
				Name:    "NTC-3",
				Module:  "Module 1",
				Section: "Vehicle",
				ID:      3,
			},
		},
	}

	configManager := NewConfigManager(config, db.NewDB(gormDb))
	err = configManager.UpdateDB()

	assert.Nil(t, err)

	sections := make([]db.Section, 0)
	gormDb.Find(&sections).Order("name DESC")

	assert.Len(t, sections, 2)
	assert.Equal(t, "Battery", sections[0].Name)
	assert.Equal(t, "Vehicle", sections[1].Name)

	modules := make([]db.Module, 0)
	gormDb.Find(&modules).Order("name DESC").Order("section_id DESC")

	assert.Len(t, modules, 3)
	assert.Equal(t, "Module 1", modules[0].Name)
	assert.Equal(t, sections[0].ID, modules[0].SectionID)
	assert.Equal(t, "Module 2", modules[1].Name)
	assert.Equal(t, sections[0].ID, modules[1].SectionID)
	assert.Equal(t, "Module 1", modules[2].Name)
	assert.Equal(t, sections[1].ID, modules[2].SectionID)

	sensors := make([]db.Sensor, 0)
	gormDb.Find(&sensors).Order("name DESC").Order("section_id DESC")

	assert.Len(t, sensors, 3)
	assert.Equal(t, "NTC-1", sensors[0].Name)
	assert.Equal(t, modules[0].ID, sensors[0].ModuleID)
	assert.Equal(t, "NTC-2", sensors[1].Name)
	assert.Equal(t, modules[1].ID, sensors[1].ModuleID)
	assert.Equal(t, "NTC-3", sensors[2].Name)
	assert.Equal(t, modules[2].ID, sensors[2].ModuleID)
}

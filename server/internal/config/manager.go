package config

import (
	"time"

	"github.com/ApexCorse/ephoros/server/internal/db"
)

type ConfigManager struct {
	config *Config
	db     *db.DB
}

func NewConfigManager(config *Config, db *db.DB) *ConfigManager {
	return &ConfigManager{
		config: config,
		db:     db,
	}
}

func (m *ConfigManager) UpdateDB() error {
	for _, sConfig := range m.config.SensorConfigs {
		err := m.createSensorIfNotExists(sConfig.Section, sConfig.Module, sConfig.Name)
		if err != nil {
			return err
		}
	}

	return nil
}

func (m *ConfigManager) createSectionIfNotExists(sectionName string) (*db.Section, error) {
	section, err := m.db.GetSectionByName(sectionName)

	if err != nil {
		section = &db.Section{
			Name: sectionName,
		}

		err = m.db.InsertSection(section)
		if err != nil {
			return nil, err
		}
	}

	return section, nil
}

func (m *ConfigManager) createModuleIfNotExists(sectionName, moduleName string) (*db.Module, error) {
	section, err := m.createSectionIfNotExists(sectionName)
	if err != nil {
		return nil, err
	}

	module, err := m.db.GetModuleByNameAndSection(sectionName, moduleName)

	if err != nil {
		module = &db.Module{
			Name:      moduleName,
			SectionID: section.ID,
		}

		err = m.db.InsertModule(module)
		if err != nil {
			return nil, err
		}
	}

	return module, nil
}

func (m *ConfigManager) createSensorIfNotExists(sectionName, moduleName, sensorName string) error {
	module, err := m.createModuleIfNotExists(sectionName, moduleName)
	if err != nil {
		return err
	}

	_, err = m.db.GetSensorByNameAndModuleAndSection(sectionName, moduleName, sensorName, time.Now(), time.Now())

	if err != nil {
		sensor := &db.Sensor{
			Name:     sensorName,
			ModuleID: module.ID,
		}

		err = m.db.InsertSensor(sensor)
		if err != nil {
			return err
		}
	}

	return nil
}

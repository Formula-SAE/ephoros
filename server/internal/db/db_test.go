package db

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestInsertSection(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	err = db.InsertSection(section)
	assert.Nil(t, err)

	dbSection := &Section{}
	tx := gormDb.First(dbSection, section.ID)

	assert.Nil(t, tx.Error)
	assert.Equal(t, section.Name, dbSection.Name)
	assert.Len(t, dbSection.Modules, 0)
}

func TestInsertModule(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	module := &Module{
		Name:      "Trial",
		SectionID: section.ID,
	}
	err = db.InsertModule(module)
	assert.Nil(t, err)

	dbModule := &Module{}
	tx := gormDb.First(dbModule, module.ID)

	assert.Nil(t, tx.Error)
	assert.Equal(t, module.Name, dbModule.Name)
	assert.Len(t, dbModule.Sensors, 0)
}

func TestInsertSensor(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	module := &Module{
		Name:      "Trial",
		SectionID: section.ID,
	}
	gormDb.Create(module)

	sensor := &Sensor{
		Name:     "Trial",
		ModuleID: module.ID,
	}
	err = db.InsertSensor(sensor)
	assert.Nil(t, err)

	dbSensor := &Sensor{}
	tx := gormDb.First(dbSensor, sensor.ID)

	assert.Nil(t, tx.Error)
	assert.Equal(t, sensor.Name, dbSensor.Name)
	assert.Len(t, dbSensor.Records, 0)
}

func TestInsertRecord(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	module := &Module{
		Name:      "Trial",
		SectionID: section.ID,
	}
	gormDb.Create(module)

	sensor := &Sensor{
		Name:     "Trial",
		ModuleID: module.ID,
	}
	gormDb.Create(sensor)

	record := &Record{
		Value:    42,
		SensorID: sensor.ID,
	}
	err = db.InsertRecord(record)
	assert.Nil(t, err)

	dbRecord := &Record{}
	tx := gormDb.First(dbRecord, record.ID)

	assert.Nil(t, tx.Error)
	assert.Equal(t, record.Value, dbRecord.Value)
}

func TestInsertUser(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	user := &User{
		Username: "Apex",
		Token:    "Corse",
	}
	err = db.InsertUser(user)
	assert.Nil(t, err)

	dbUser := &User{}
	gormDb.Where("token = ?", user.Token).First(dbUser)

	assert.Equal(t, user.Username, dbUser.Username)
	assert.Equal(t, user.Token, dbUser.Token)
}

func TestGetModuleById(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	module := &Module{
		Name:      "Trial",
		SectionID: section.ID,
	}
	gormDb.Create(module)

	sensors := []*Sensor{
		{
			Name:     "Trial1",
			ModuleID: module.ID,
		},
		{
			Name:     "Trial2",
			ModuleID: module.ID,
		},
	}
	gormDb.Create(sensors)

	dbModule, err := db.GetModuleById(module.ID)

	assert.Nil(t, err)
	assert.Equal(t, module.Name, dbModule.Name)
	assert.Len(t, dbModule.Sensors, 2)
}

func TestGetSectionById(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	modules := []*Module{
		{
			Name:      "Trial1",
			SectionID: section.ID,
		},
		{
			Name:      "Trial2",
			SectionID: section.ID,
		},
		{
			Name:      "Trial3",
			SectionID: section.ID,
		},
	}
	gormDb.Create(modules)

	dbSection, err := db.GetSectionById(section.ID)
	assert.Nil(t, err)
	assert.Equal(t, section.ID, dbSection.ID)
	assert.Len(t, dbSection.Modules, 3)
}

func TestGetSectionByName_Success(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	modules := []*Module{
		{
			Name:      "Trial1",
			SectionID: section.ID,
		},
		{
			Name:      "Trial2",
			SectionID: section.ID,
		},
		{
			Name:      "Trial3",
			SectionID: section.ID,
		},
	}
	gormDb.Create(modules)

	dbSection, err := db.GetSectionByName(section.Name)
	assert.Nil(t, err)
	assert.Equal(t, section.ID, dbSection.ID)
	assert.Len(t, dbSection.Modules, 3)
}

func TestGetSectionByName_NotFound(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	modules := []*Module{
		{
			Name:      "Trial1",
			SectionID: section.ID,
		},
		{
			Name:      "Trial2",
			SectionID: section.ID,
		},
		{
			Name:      "Trial3",
			SectionID: section.ID,
		},
	}
	gormDb.Create(modules)

	dbSection, err := db.GetSectionByName("42")
	assert.Error(t, err)
	assert.Nil(t, dbSection)
}

func TestGetModuleByNameAndSection_Success(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	module := &Module{
		Name:      "Trial",
		SectionID: section.ID,
	}
	gormDb.Create(module)

	dbModule, err := db.GetModuleByNameAndSection(module.Name, section.Name)

	assert.Nil(t, err)
	assert.Equal(t, module.Name, dbModule.Name)
}

func TestGetModuleByNameAndSection_Failure(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	module := &Module{
		Name:      "Trial",
		SectionID: section.ID,
	}
	gormDb.Create(module)

	dbModule, err := db.GetModuleByNameAndSection(module.Name, "42")

	assert.Error(t, err)
	assert.Nil(t, dbModule)
}

func TestGetSensorById(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	module := &Module{
		Name:      "Trial",
		SectionID: section.ID,
	}
	gormDb.Create(module)

	sensor := &Sensor{
		Name:     "Trial",
		ModuleID: module.ID,
	}
	gormDb.Create(sensor)

	records := []*Record{
		{
			Value:    42,
			SensorID: sensor.ID,
		},
		{
			Value:    43,
			SensorID: sensor.ID,
		},
		{
			Value:    44,
			SensorID: sensor.ID,
		},
	}
	gormDb.Create(records)

	dbSensor, err := db.GetSensorById(sensor.ID, time.Time{}, time.Time{})

	assert.Nil(t, err)
	assert.Equal(t, sensor.Name, dbSensor.Name)
	assert.Len(t, dbSensor.Records, 3)
}

func TestGetSensorByNameAndModuleAndSection_Success(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	module := &Module{
		Name:      "Trial",
		SectionID: section.ID,
	}
	gormDb.Create(module)

	sensor := &Sensor{
		Name:     "Trial",
		ModuleID: module.ID,
	}
	gormDb.Create(sensor)

	records := []*Record{
		{
			Value:    42,
			SensorID: sensor.ID,
		},
		{
			Value:    43,
			SensorID: sensor.ID,
		},
		{
			Value:    44,
			SensorID: sensor.ID,
		},
	}
	gormDb.Create(records)

	dbSensor, err := db.GetSensorByNameAndModuleAndSection(sensor.Name, module.Name, section.Name, time.Time{}, time.Time{})

	assert.Nil(t, err)
	assert.Equal(t, sensor.Name, dbSensor.Name)
	assert.Len(t, dbSensor.Records, 3)
	assert.Equal(t, float32(42), dbSensor.Records[0].Value)
	assert.Equal(t, float32(43), dbSensor.Records[1].Value)
	assert.Equal(t, float32(44), dbSensor.Records[2].Value)
}

func TestGetSensorByNameAndModuleAndSection_Failure(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	section := &Section{
		Name: "Trial",
	}
	gormDb.Create(section)

	module := &Module{
		Name:      "Trial",
		SectionID: section.ID,
	}
	gormDb.Create(module)

	sensor := &Sensor{
		Name:     "Trial",
		ModuleID: module.ID,
	}
	gormDb.Create(sensor)

	records := []*Record{
		{
			Value:    42,
			SensorID: sensor.ID,
		},
		{
			Value:    43,
			SensorID: sensor.ID,
		},
		{
			Value:    44,
			SensorID: sensor.ID,
		},
	}
	gormDb.Create(records)

	dbSensor, err := db.GetSensorByNameAndModuleAndSection(sensor.Name, module.Name, "42", time.Time{}, time.Time{})

	assert.Error(t, err)
	assert.Nil(t, dbSensor)
}

func TestGetUserByToken_Success(t *testing.T) {
	gormDb, cleanUp, err := TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	db := NewDB(gormDb)

	user := &User{
		Username: "Apex",
		Token:    "Corse",
	}
	gormDb.Create(user)

	dbUser, err := db.GetUserByToken(user.Token)

	assert.Nil(t, err)
	assert.Equal(t, user.Username, dbUser.Username)
	assert.Equal(t, user.Token, dbUser.Token)
}

CREATE DATABASE proyhospital;

CREATE TABLE Especialidad (
    ID_Especialidad SERIAL PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL
);

CREATE TABLE MetodoPago (
    ID_MetodoPago SERIAL PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL
);

CREATE TABLE TipoExamen (
    ID_TipoExamen SERIAL PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL
);

CREATE TABLE TipoContacto (
    ID_TipoContacto SERIAL PRIMARY KEY,
    Nombre VARCHAR(255) NOT NULL
);

CREATE TABLE Contacto (
    ID_Contacto SERIAL PRIMARY KEY,
    Numero VARCHAR(255) NOT NULL,
    ID_TipoContacto INT NOT NULL,
    FOREIGN KEY (ID_TipoContacto) REFERENCES TipoContacto(ID_TipoContacto)
);

CREATE TABLE Persona (
    ID_Persona SERIAL PRIMARY KEY,
    Ci VARCHAR(50) UNIQUE,
    Nombre VARCHAR(100) NOT NULL,
    ApellidoPaterno VARCHAR(100) NOT NULL,
    ApellidoMaterno VARCHAR(100),
    Genero VARCHAR(100) CHECK (Genero IN ('Masculino', 'Femenino', 'Otro'))
);

CREATE TABLE PersonaContacto (
    ID_PersonaContacto SERIAL PRIMARY KEY,
    ID_Persona INT,
    ID_Contacto INT,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NULL CHECK (FechaFin >= FechaInicio),
    FOREIGN KEY (ID_Persona) REFERENCES Persona(ID_Persona),
    FOREIGN KEY (ID_Contacto) REFERENCES CONTACTO(ID_Contacto)
);

CREATE TABLE Turno (
    ID_Turno SERIAL PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL,
    HoraInicio TIME NOT NULL,
    HoraFin TIME NOT NULL
);

CREATE TABLE PersonalMedico (
    ID_PersonalMedico SERIAL PRIMARY KEY,
    ID_Persona INT NOT NULL,
    ID_Especialidad INT NOT NULL,
    ID_Turno INT NOT NULL,
    FOREIGN KEY (ID_Persona) REFERENCES Persona(ID_Persona),
    FOREIGN KEY (ID_Especialidad) REFERENCES Especialidad(ID_Especialidad),
    FOREIGN KEY (ID_Turno) REFERENCES Turno(ID_Turno)
);

CREATE TABLE Contratacion (
    ID_Contratacion SERIAL PRIMARY KEY,
    ID_PersonalMedico INT NOT NULL,
    FechaInicio DATE NOT NULL,
    Salario NUMERIC(10,2) NOT NULL,
    FechaFin DATE NULL CHECK(FechaFin >= FechaInicio),
    FOREIGN KEY (ID_PersonalMedico) REFERENCES PersonalMedico(ID_PersonalMedico)
);

CREATE TABLE Unidad (
    ID_Unidad SERIAL PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Cita (
    ID_Cita SERIAL PRIMARY KEY,
    ID_Persona INT NOT NULL,
    ID_Medico INT NOT NULL,
    Estado TEXT NOT NULL,
    FechaHora TIMESTAMP NOT NULL,
    FOREIGN KEY (ID_Persona) REFERENCES Persona(ID_Persona),
    FOREIGN KEY (ID_Medico) REFERENCES PersonalMedico(ID_PersonalMedico)
);

CREATE TABLE DetalleCita (
    ID_DetalleCita SERIAL PRIMARY KEY,
    ID_Cita INT NOT NULL,
    Motivo TEXT NOT NULL,
    ID_MetodoPago INT NOT NULL,
    Pago NUMERIC(10,2) NOT NULL,
    FOREIGN KEY (ID_Cita) REFERENCES Cita(ID_Cita),
    FOREIGN KEY (ID_MetodoPago) REFERENCES MetodoPago(ID_MetodoPago)
);

CREATE TABLE HistorialPersona (
    ID_HistorialPersona SERIAL PRIMARY KEY,
    ID_Persona INT NOT NULL, 
    ID_DetalleCita INT NOT NULL,
    FOREIGN KEY (ID_Persona) REFERENCES Persona(ID_Persona),
    FOREIGN KEY (ID_DetalleCita) REFERENCES DetalleCita(ID_DetalleCita)
);

CREATE TABLE Medicamento (
    ID_Medicamento SERIAL PRIMARY KEY,
    ATC VARCHAR(150) UNIQUE NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Descripcion TEXT NOT NULL,
    PrecioUnitario NUMERIC(10,2) NOT NULL
);

CREATE TABLE Almacen (
    ID_Almacen SERIAL PRIMARY KEY,
    ID_Medicamento INT NOT NULL,
    ID_Unidad INT NOT NULL,
    Stock INT NOT NULL,
    FOREIGN KEY (ID_Medicamento) REFERENCES Medicamento(ID_Medicamento),
    FOREIGN KEY (ID_Unidad) REFERENCES Unidad(ID_Unidad)
);

CREATE TABLE Receta (
    ID_Receta SERIAL PRIMARY KEY,
    ID_DetalleCita INT NOT NULL,
    ID_Medicamento INT NOT NULL,
    Cantidad INT NOT NULL,
    Dosis VARCHAR(255) NOT NULL,
    FOREIGN KEY (ID_DetalleCita) REFERENCES DetalleCita(ID_DetalleCita),
    FOREIGN KEY (ID_Medicamento) REFERENCES Medicamento(ID_Medicamento)
);

CREATE TABLE Equipamiento (
    ID_Equipamiento SERIAL PRIMARY KEY,
    ID_Unidad INT NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    FOREIGN KEY (ID_Unidad) REFERENCES Unidad(ID_Unidad)
);

CREATE TABLE InventarioEquipamiento (
    ID_InventarioEquipamiento SERIAL PRIMARY KEY,
    ID_Equipamiento INT NOT NULL,
    Cantidad INT NOT NULL,
    FOREIGN KEY (ID_Equipamiento) REFERENCES Equipamiento(ID_Equipamiento)
);

CREATE TABLE Habitacion (
    ID_Habitacion SERIAL PRIMARY KEY,
    Numero VARCHAR(10) NOT NULL,
    Disponible BOOLEAN NOT NULL
);

CREATE TABLE Hospitalizacion (
    ID_Hospitalizacion SERIAL PRIMARY KEY,
    ID_Paciente INT NOT NULL,
    ID_Habitacion INT NOT NULL,
    ID_Medico INT NOT NULL,
    FechaIngreso DATE NOT NULL,
    FechaAlta DATE NULL CHECK (FechaAlta IS NULL OR FechaAlta >= FechaIngreso),
    FOREIGN KEY (ID_Paciente) REFERENCES Persona(ID_Persona),
    FOREIGN KEY (ID_Habitacion) REFERENCES Habitacion(ID_Habitacion),
    FOREIGN KEY (ID_Medico) REFERENCES PersonalMedico(ID_PersonalMedico)
);


CREATE TABLE ResultadoExamen (
    ID_ResultadoExamen SERIAL PRIMARY KEY,
    ID_Persona INT NOT NULL,
    ID_TipoExamen INT NOT NULL,
    Resultado TEXT NOT NULL,
    FOREIGN KEY (ID_Persona) REFERENCES Persona(ID_Persona),
    FOREIGN KEY (ID_TipoExamen) REFERENCES TipoExamen(ID_TipoExamen)
);

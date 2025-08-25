
-- CTE: Pacientes y su última cita
-- Enunciado:
-- Mostrar la lista de pacientes que hayan tenido al menos una cita médica,
-- incluyendo la fecha de su última cita, el nombre del médico que los atendió
-- y el estado de la cita.
-- ============================================================================

WITH UltimasCitas AS (
    SELECT
        c.ID_Persona,
        MAX(c.FechaHora) AS UltimaFecha
    FROM Cita c
    GROUP BY c.ID_Persona
)
SELECT 
    p.Nombre AS Paciente,
    p.ApellidoPaterno,
    c.FechaHora AS FechaCita,
    m.Nombre AS Medico,
    c.Estado
FROM UltimasCitas uc
JOIN Cita c ON c.ID_Persona = uc.ID_Persona AND c.FechaHora = uc.UltimaFecha
JOIN Persona p ON p.ID_Persona = c.ID_Persona
JOIN PersonalMedico pm ON pm.ID_PersonalMedico = c.ID_Medico
JOIN Persona m ON m.ID_Persona = pm.ID_Persona
ORDER BY FechaCita DESC;


-- 1 CTE COMPLEJA CON WITH

WITH UltimaCitaPaciente AS (
    SELECT
        c.ID_Persona,
        MAX(c.FechaHora) AS FechaUltimaCita
    FROM Cita c
    GROUP BY c.ID_Persona
),
PacienteDatos AS (
    SELECT
        p.ID_Persona,
        p.Nombre,
        p.ApellidoPaterno,
        uc.FechaUltimaCita,
        c.ID_Medico,
        COUNT(c.ID_Cita) AS TotalCitas
    FROM Persona p
    JOIN UltimaCitaPaciente uc ON p.ID_Persona = uc.ID_Persona
    JOIN Cita c ON c.ID_Persona = p.ID_Persona AND c.FechaHora = uc.FechaUltimaCita
    GROUP BY p.ID_Persona, p.Nombre, p.ApellidoPaterno, uc.FechaUltimaCita, c.ID_Medico
)
SELECT
    pd.Nombre || ' ' || pd.ApellidoPaterno AS Paciente,
    pd.FechaUltimaCita,
    per.Nombre || ' ' || per.ApellidoPaterno AS Medico,
    pd.TotalCitas
FROM PacienteDatos pd
JOIN PersonalMedico pm ON pd.ID_Medico = pm.ID_PersonalMedico
JOIN Persona per ON pm.ID_Persona = per.ID_Persona
ORDER BY pd.FechaUltimaCita DESC
LIMIT 10;


-- ====================
-- 2. TRIGGER
-- ====================
-- Enunciado: Cada vez que se inserte una hospitalización, se marca la habitación como no disponible.

CREATE OR REPLACE FUNCTION actualizar_disponibilidad_habitacion()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Habitacion SET Disponible = FALSE
    WHERE ID_Habitacion = NEW.ID_Habitacion;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_disponibilidad
AFTER INSERT ON Hospitalizacion
FOR EACH ROW
EXECUTE FUNCTION actualizar_disponibilidad_habitacion();

-- ====================
-- 3. PROCEDIMIENTOS
-- ====================

-- 3.1 Enunciado: Registrar una nueva especialidad.
CREATE OR REPLACE PROCEDURE RegistrarEspecialidad(nom VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Especialidad(Nombre) VALUES (nom);
END;
$$;

call RegistrarEspecialidad('Cardiologo')

-- 3.2 Enunciado: Registrar contacto para una persona con fechas.
CREATE OR REPLACE PROCEDURE AsignarContactoPersona(pid INT, cid INT, fini DATE, ffin DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO PersonaContacto(ID_Persona, ID_Contacto, FechaInicio, FechaFin)
    VALUES (pid, cid, fini, ffin);
END;
$$;

CALL AsignarContactoPersona(1, 2, '2024-01-01', '2025-01-01');


-- 3.3 Enunciado: Hospitalizar un paciente (simplificado).
CREATE OR REPLACE PROCEDURE HospitalizarPaciente(pid INT, hid INT, mid INT, fecha DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Hospitalizacion(ID_Paciente, ID_Habitacion, ID_Medico, FechaIngreso)
    VALUES (pid, hid, mid, fecha);
END;
$$;
CALL HospitalizarPaciente(1, 3, 2, '2025-07-29');


-- Procedimiento 1: Insertar nueva especialidad
CREATE OR REPLACE PROCEDURE InsertarEspecialidad(nombre VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Especialidad (Nombre) VALUES (nombre);
END;
$$;

CALL InsertarEspecialidad('Neurología');

SELECT * FROM Especialidad WHERE Nombre = 'Neurología';


-- Procedimiento 2: Hospitalizar paciente validando disponibilidad de habitación
CREATE OR REPLACE PROCEDURE RegistrarHospitalizacion(
    pid INT,
    hid INT,
    mid INT,
    fecha_ingreso DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar si la habitación está disponible
    IF EXISTS (
        SELECT 1 FROM Habitacion
        WHERE ID_Habitacion = hid AND Disponible = TRUE
    ) THEN
        -- Insertar hospitalización
        INSERT INTO Hospitalizacion(ID_Paciente, ID_Habitacion, ID_Medico, FechaIngreso)
        VALUES (pid, hid, mid, fecha_ingreso);

        -- Marcar habitación como no disponible
        UPDATE Habitacion SET Disponible = FALSE WHERE ID_Habitacion = hid;
    ELSE
        RAISE EXCEPTION 'La habitación % no está disponible', hid;
    END IF;
END;
$$;


CALL RegistrarHospitalizacion(1, 10, 3, CURRENT_DATE);


-- Procedimiento 3: Reporte cantidad pacientes hospitalizados por habitación
CREATE OR REPLACE PROCEDURE ReportePacientesPorHabitacion()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE 'Habitacion | Cantidad Pacientes';
    FOR rec IN
        SELECT h.ID_Habitacion, COUNT(hos.ID_Hospitalizacion) AS CantidadPacientes
        FROM Habitacion h
        LEFT JOIN Hospitalizacion hos ON hos.ID_Habitacion = h.ID_Habitacion
        GROUP BY h.ID_Habitacion
        ORDER BY CantidadPacientes DESC
    LOOP
        RAISE NOTICE '% | %', rec.ID_Habitacion, rec.CantidadPacientes;
    END LOOP;
END;
$$;

CALL ReportePacientesPorHabitacion();



-- ====================
-- 4. FUNCIONES
-- ====================

-- 4.1 Enunciado: Calcular total pagado por una persona en citas.
CREATE OR REPLACE FUNCTION TotalPagadoPersona(pid INT)
RETURNS NUMERIC 
LANGUAGE plpgsql
AS $$
DECLARE total NUMERIC;
BEGIN
    SELECT SUM(dc.Pago) INTO total
    FROM Cita c
    JOIN DetalleCita dc ON c.ID_Cita = dc.ID_Cita
    WHERE c.ID_Persona = pid;
    RETURN COALESCE(total, 0);
END;
$$

SELECT * from TotalPagadoPersona(4)

-- 4.2 Enunciado: Verificar si un médico está actualmente contratado.
CREATE OR REPLACE FUNCTION EstaContratado(idmed INT)
RETURNS BOOLEAN 
LANGUAGE plpgsql
AS $$
DECLARE activo BOOLEAN;
BEGIN
    SELECT TRUE INTO activo
    FROM Contratacion
    WHERE ID_PersonalMedico = idmed AND (FechaFin IS NULL OR FechaFin >= CURRENT_DATE)
    LIMIT 1;
    RETURN COALESCE(activo, FALSE);
END;
$$;

select * from EstaContratado(3)
-- 4.3 Enunciado: Obtener cantidad de medicamentos en una unidad específica.
CREATE OR REPLACE FUNCTION CantidadMedicamentosUnidad(unid INT)
RETURNS INT 
LANGUAGE plpgsql
AS $$
DECLARE total INT;
BEGIN
    SELECT SUM(Stock) INTO total
    FROM Almacen
    WHERE ID_Unidad = unid;
    RETURN COALESCE(total, 0);
END;
$$;
SELECT * from CantidadMedicamentosUnidad(1)

-- Función 1: Total pagado por paciente
CREATE OR REPLACE FUNCTION TotalPagadoPaciente(pid INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(dc.Pago), 0) INTO total
    FROM Cita c
    JOIN DetalleCita dc ON c.ID_Cita = dc.ID_Cita
    WHERE c.ID_Persona = pid;
    RETURN total;
END;
$$;

SELECT 'Total pagado por paciente 1:' AS descripcion, TotalPagadoPaciente(1) AS total_pagado;


-- Función 2: Número de citas completadas por médico
CREATE OR REPLACE FUNCTION CitasCompletadasMedico(mid INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    total INT;
BEGIN
    SELECT COUNT(*)
    INTO total
    FROM Cita
    WHERE ID_Medico = mid AND Estado = 'Completada';
    RETURN total;
END;
$$;

SELECT 'Citas completadas por médico 1:' AS descripcion, CitasCompletadasMedico(1) AS total_citas;


-- Función 3: Listar citas de un paciente (conjunto de resultados)
CREATE OR REPLACE FUNCTION PromedioPagoPaciente(pid INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    promedio NUMERIC;
BEGIN
    SELECT AVG(dc.Pago) INTO promedio
    FROM Cita c
    JOIN DetalleCita dc ON c.ID_Cita = dc.ID_Cita
    WHERE c.ID_Persona = pid;
    
    RETURN COALESCE(promedio, 0);
END;
$$;

SELECT PromedioPagoPaciente(1);



-- ====================
-- 5. VISTA
-- ====================
-- Enunciado: Vista de resumen de citas con nombre paciente, médico, fecha y estado

CREATE OR REPLACE VIEW VistaResumenCitas AS
SELECT c.ID_Cita, p.Nombre AS Paciente, pm.ID_PersonalMedico, per.Nombre AS Medico,
       c.FechaHora, c.Estado
FROM Cita c
JOIN Persona p ON p.ID_Persona = c.ID_Persona
JOIN PersonalMedico pm ON c.ID_Medico = pm.ID_PersonalMedico
JOIN Persona per ON per.ID_Persona = pm.ID_Persona;

select * from VistaResumenCitas

-- ====================
-- 6. CONSULTAS
-- ====================

-- 6.1 Mostrar pacientes con 1 o mas  hospitalizaciones
SELECT p.Nombre, p.ApellidoPaterno, COUNT(h.ID_Hospitalizacion) AS VecesHospitalizado
FROM Persona p
JOIN Hospitalizacion h ON p.ID_Persona = h.ID_Paciente
GROUP BY p.ID_Persona
HAVING COUNT(h.ID_Hospitalizacion) >= 1;

-- 6.2 Listar médicos contratados actualmente y su especialidad
SELECT per.Nombre, per.ApellidoPaterno, e.Nombre AS Especialidad, c.Salario
FROM Contratacion c
JOIN PersonalMedico pm ON pm.ID_PersonalMedico = c.ID_PersonalMedico
JOIN Persona per ON per.ID_Persona = pm.ID_Persona
JOIN Especialidad e ON e.ID_Especialidad = pm.ID_Especialidad
WHERE c.FechaFin IS NULL OR c.FechaFin >= CURRENT_DATE;

-- 6.3 Total recaudado por método de pago
SELECT mp.Nombre AS MetodoPago, SUM(dc.Pago) AS TotalRecaudado
FROM MetodoPago mp
JOIN DetalleCita dc ON mp.ID_MetodoPago = dc.ID_MetodoPago
GROUP BY mp.Nombre;

-- 6.4 Inventario total de medicamentos por unidad
SELECT u.Nombre AS Unidad, SUM(a.Stock) AS TotalStock
FROM Unidad u
JOIN Almacen a ON u.ID_Unidad = a.ID_Unidad
GROUP BY u.Nombre;

-- ============================================================
-- 6.5 Top 10 medicamentos más recetados
-- Enunciado:
-- Mostrar los 10 medicamentos que han sido recetados con más frecuencia,
-- junto con el número de veces que fueron recetados y su dosis más común.
-- Ideal para análisis de demanda farmacéutica en el hospital.
-- ============================================================

SELECT 
    m.Nombre AS Medicamento,
    COUNT(r.ID_Receta) AS VecesRecetado,
    MODE() WITHIN GROUP (ORDER BY r.Dosis) AS DosisMasComun
FROM Receta r
JOIN Medicamento m ON m.ID_Medicamento = r.ID_Medicamento
GROUP BY m.Nombre
ORDER BY VecesRecetado DESC
LIMIT 10;


-- 6.6 Citas con motivo, médico, paciente y pago
SELECT p.Nombre AS Paciente, med.Nombre AS Medico, dc.Motivo, dc.Pago
FROM DetalleCita dc
JOIN Cita c ON c.ID_Cita = dc.ID_Cita
JOIN Persona p ON p.ID_Persona = c.ID_Persona
JOIN PersonalMedico pm ON c.ID_Medico = pm.ID_PersonalMedico
JOIN Persona med ON pm.ID_Persona = med.ID_Persona;

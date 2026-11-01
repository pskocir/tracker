-- Migración: cambiar day column de DD-MM-YYYY a YYYY-MM-DD (ISO)
-- Ejecutar en Supabase → SQL Editor → New Query
-- IMPORTANTE: ejecutar ANTES de hacer el deploy.

-- 1) Habilitar Row Level Security (si no está ya) — necesario para que las políticas funcionen
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- 2) Forzar RLS en todas las operaciones y aplicar nuevas política/trigger (drop+create seguro)
DROP POLICY IF EXISTS "Allow all operations for anon" ON tasks;

CREATE POLICY "Allow all operations for anon"
  ON tasks
  FOR ALL
  TO public        -- roles: anon + authenticated cubiertos con clave anon válida
  USING (true)     -- leer: siempre permitido para users con clave anon valida
  WITH CHECK (true); -- escribir/insertar: siempre permitido

-- 3) Actualizar filas existentes de DD-MM-YYYY → YYYY-MM-DD
UPDATE tasks 
SET day = CONCAT(substring(day, 7, 4), '-', substring(day, 4, 2), '-', substring(day, 1, 2))
WHERE LENGTH(day) = 10 
  AND day ~ '^[0-9]{2}-[0-9]{2}-[0-9]{4}$';

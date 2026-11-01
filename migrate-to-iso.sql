-- Migración: cambiar day column de DD-MM-YYYY a YYYY-MM-DD (ISO)
-- Ejecutar en Supabase SQL Editor antes del nuevo deploy.

-- 1) Actualizar filas existentes de DD-MM-YYYY → YYYY-MM-DD
UPDATE tasks 
SET day = CONCAT(substring(day, 7, 4), '-', substring(day, 4, 2), '-', substring(day, 1, 2))
WHERE LENGTH(day) = 10 
  AND day ~ '^[0-9]{2}-[0-9]{2}-[0-9]{4}$';

-- 2) Asegurar política de seguridad RLS (si no existe ya)
DO $$
BEGIN
  -- Habilitar Row Level Security si no está
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all operations for anon') THEN
    CREATE POLICY "Allow all operations for anon"
      ON tasks
      FOR ALL
      TO public
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

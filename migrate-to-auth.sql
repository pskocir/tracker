-- ============================================================
-- Migración: agregar auth multi-usuario a la tabla `tasks`
-- Ejecutar en Supabase Dashboard → SQL Editor
--
-- PASOS PREVIOS:
-- 1. Copiar tu user_id desde Supabase → Authentication → Users (clic en tu email)
--    y reemplazar 'REEMPLAZAR-CON-MI-UUID' abajo en el UPDATE:
--      UPDATE tasks SET user_id = '2273472c-c535-46a2-9265-ba8884b5a640' WHERE user_id IS NULL;
-- 2. Ejecutar este script EN UNA SOLA VEZ.
-- ============================================================

-- ============================================================
-- 1) Agregar columna user_id (nullable al inicio para asignar data)
-- ============================================================
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS user_id uuid;

-- ============================================================
-- 2) Asignar filas existentes al propietario actual
--    ¡¡REEMPLAZAR 'REEMPLAZAR-CON-MI-UUID'!! CON TU UUID REAL
-- ============================================================
UPDATE tasks SET user_id = '2273472c-c535-46a2-9265-ba8884b5a640' WHERE user_id IS NULL;

-- ============================================================
-- 3) Hacer la columna NOT NULL (ya no quedan filas sin user_id)
-- ============================================================
ALTER TABLE tasks ALTER COLUMN user_id SET NOT NULL;

-- ============================================================
-- 4) Asignar DEFAULT para nuevas filas → auth.uid() del usuario logueado
-- ============================================================
ALTER TABLE tasks ALTER COLUMN user_id SET DEFAULT auth.uid();

-- ============================================================
-- 5) Eliminar UNIQUE existente sobre day (si la hay, por la migración ISO)
--    Y crear composite unique: un día pertenece a UN usuario.
-- ============================================================
DROP INDEX IF EXISTS tasks_day_key;

-- Primero eliminar o ajustar constraint PK existente:
-- La PK actual es solo (day). Necesitamos cambiarla a (user_id, day).
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_pkey;
ALTER TABLE tasks ADD PRIMARY KEY (user_id, day);

-- ============================================================
-- 6) work_day: sin DEFAULT y nullable.
--    NULL → usar default de app (Lu=Vi=true).
-- ============================================================
ALTER TABLE tasks ALTER COLUMN work_day DROP DEFAULT;

-- ============================================================
-- 7) Eliminar política RLS anterior "Allow all operations for anon"
-- ============================================================
DROP POLICY IF EXISTS "Allow all operations for anon" ON tasks;
DROP POLICY IF EXISTS "Users can access own data" ON tasks;

-- ============================================================
-- 8) Crear nuevas políticas: cada usuario solo ve/solo su data
-- ============================================================

DROP POLICY IF EXISTS "Users can select own tasks" ON tasks;
DROP POLICY IF EXISTS "Users can insert own tasks" ON tasks;
DROP POLICY IF EXISTS "Users can update own tasks" ON tasks;
DROP POLICY IF EXISTS "Users can delete own tasks" ON tasks;

CREATE POLICY "Users can select own tasks"
  ON tasks
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tasks"
  ON tasks
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tasks"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own tasks"
  ON tasks
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================
-- Verificación: mostrar filas actuales
-- ============================================================
SELECT day, user_id, work_day, corr, preco, prev, ei, tv FROM tasks ORDER BY day;

-- ============================================================
-- 4) Reparo: secuencia pg_id de tasks puede estar desincronizada
--    Si se produjeron "duplicate key value violates unique constraint 'tasks_pkey'"
--    después de INSERTs manuales o migraciones, corregir:
-- ============================================================

-- Verificar el valor actual de la secuencia:
SELECT last_value, is_called FROM tasks_id_seq;

-- Si last_value < MAX(id), ejecutar:
-- SELECT setval('tasks_id_seq', (SELECT COALESCE(MAX(id), 1) FROM tasks));

-- O simplemente reiniciar desde el máximo:
-- SELECT setval('tasks_id_seq', (SELECT MAX(id) + 1 FROM tasks));

SET search_path TO public;

-- Poner DEFAULT 0 a los campos que no lo tienen
ALTER TABLE tasks ALTER COLUMN work_day   SET DEFAULT false;
ALTER TABLE tasks ALTER COLUMN corr       SET DEFAULT 0;
ALTER TABLE tasks ALTER COLUMN preco      SET DEFAULT 0;
ALTER TABLE tasks ALTER COLUMN prev       SET DEFAULT 0;
ALTER TABLE tasks ALTER COLUMN ei         SET DEFAULT 0;
ALTER TABLE tasks ALTER COLUMN tv         SET DEFAULT 0;

-- Arreglar la fila de hoy (2026-11-01 es lunes → laboral)
UPDATE tasks SET work_day = true WHERE day = '2026-11-01';

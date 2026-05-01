-- Crear tabla categoria
CREATE TABLE IF NOT EXISTS categoria (
    cod_categoria INT(10) PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(30) NOT NULL,
    descripcion VARCHAR(50),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insertar categorías iniciales
INSERT INTO categoria (cod_categoria, nombre, descripcion) VALUES
(1, 'Laptop', 'Computadoras portátiles y notebooks'),
(2, 'PC Escritorio', 'Computadoras de escritorio y torres');

-- Modificar tabla ordenes_reclamos para agregar el campo tipo
ALTER TABLE ordenes_reclamos 
ADD COLUMN tipo VARCHAR(12) DEFAULT 'reclamo' AFTER prioridad;

-- Agregar clave foránea para relacionar con categoria
-- Nota: Esto asume que ya existe una columna cod_categoria en ordenes_reclamos
-- Si no existe, primero agregar la columna
ALTER TABLE ordenes_reclamos 
ADD COLUMN cod_categoria INT(10) AFTER tipo;

-- Agregar la relación de clave foránea
ALTER TABLE ordenes_reclamos 
ADD CONSTRAINT fk_ordenes_categoria 
FOREIGN KEY (cod_categoria) 
REFERENCES categoria(cod_categoria) 
ON DELETE SET NULL 
ON UPDATE CASCADE;

-- Actualizar órdenes existentes para asignar categorías por defecto
UPDATE ordenes_reclamos SET cod_categoria = 6 WHERE cod_categoria IS NULL; -- Asignar 'Soporte' por defecto

-- Actualizar tipos existentes basados en el contenido de la descripción
UPDATE ordenes_reclamos SET tipo = 'mantenimiento' 
WHERE descripcion LIKE '%mantenimiento%' OR descripcion LIKE '%preventivo%';

UPDATE ordenes_reclamos SET tipo = 'instalacion' 
WHERE descripcion LIKE '%instalaci%' OR descripcion LIKE '%configuraci%';

UPDATE ordenes_reclamos SET tipo = 'reparacion' 
WHERE descripcion LIKE '%reparaci%' OR descripcion LIKE '%daño%' OR descripcion LIKE '%falla%';

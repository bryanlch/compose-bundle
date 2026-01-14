-- =====================================
-- 1. PERMISSIONS (Adaptados al Mundial)
-- =====================================
INSERT INTO permissions (slug, description) VALUES
  -- Gestión de Usuarios CMS
  ('cms_users:view', 'Ver lista de administradores'),
  ('cms_users:create', 'Crear nuevos administradores'),
  ('cms_users:edit', 'Editar administradores'),
  ('cms_users:delete', 'Eliminar administradores'),
  
  -- Gestión de Roles
  ('roles:manage', 'Crear y asignar roles'),

  -- Gestión de Fans (App Users)
  ('app_users:view', 'Ver usuarios de la app'),
  ('app_users:ban', 'Bloquear usuarios de la app'),

  -- Noticias (News)
  ('news:create', 'Crear noticias'),
  ('news:edit', 'Editar noticias'),
  ('news:delete', 'Eliminar noticias'),
  ('news:publish', 'Publicar o destacar noticias'), -- Permiso delicado

  -- Partidos (Matches) - Crítico
  ('matches:view', 'Ver calendario interno'),
  ('matches:edit_info', 'Cambiar horarios o estadios'),
  ('matches:live_update', 'Actualizar marcador y eventos en vivo'), -- Solo para operadores en vivo

  -- Trivias y Juegos
  ('games:create', 'Crear nuevas trivias'),
  ('games:edit', 'Editar preguntas o respuestas'),
  ('games:view_results', 'Ver estadísticas de participación')
ON CONFLICT (slug) DO NOTHING;

-- =====================================
-- 2. ROLES
-- =====================================
INSERT INTO roles (name, description, is_system) VALUES 
  ('superadmin', 'Acceso total al sistema', TRUE),
  ('editor', 'Editor de contenido (Noticias)', FALSE),
  ('live_operator', 'Encargado de actualizar marcadores', FALSE)
ON CONFLICT (name) DO NOTHING;

-- =====================================
-- 3. ASIGNAR PERMISOS A ROLES
-- =====================================

-- A. Superadmin: Obtiene TODOS los permisos
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p -- CROSS JOIN une todo con todo
WHERE r.name = 'superadmin'
ON CONFLICT DO NOTHING;

-- B. Editor: Solo noticias y ver partidos (Ejemplo de rol limitado)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.slug LIKE 'news:%' OR p.slug = 'matches:view'
WHERE r.name = 'editor'
ON CONFLICT DO NOTHING;

-- =====================================
-- 4. CREAR USUARIO ADMIN INICIAL
-- =====================================
INSERT INTO cms_users (email, password_hash, first_name, last_name, role_id, status)
SELECT
  'admin@worldcup.com',
  '$2b$10$J8Ecc4K0TW/pkoaryNArfuCxRfv2iH7h2XeqtFFFZxb.ujtv.M9d6', -- Admin123!
  'Super',
  'Admin',
  r.id,
  'active'
FROM roles r
WHERE r.name = 'superadmin'
ON CONFLICT (email) DO NOTHING;
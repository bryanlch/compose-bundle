-- ==========================================
-- 1. CONFIGURACIÓN INICIAL Y UTILIDADES
-- ==========================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE "user_status" AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE "system_role" AS ENUM ('superadmin', 'editor', 'viewer');
CREATE TYPE "session_owner_type" AS ENUM ('cms', 'app');

-- Función única para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ==========================================
-- SECCIÓN A: CMS / ADMINISTRACIÓN (RBAC)
-- ==========================================

CREATE TABLE "roles" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(50) UNIQUE NOT NULL,
  "description" TEXT,
  "is_system" BOOLEAN DEFAULT FALSE,
  "created_at" TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE "permissions" (
  "id" SERIAL PRIMARY KEY,
  "slug" VARCHAR(100) UNIQUE NOT NULL,
  "description" TEXT
);

CREATE TABLE "role_permissions" (
  "role_id" INT REFERENCES "roles" ("id") ON DELETE CASCADE,
  "permission_id" INT REFERENCES "permissions" ("id") ON DELETE CASCADE,
  PRIMARY KEY ("role_id", "permission_id")
);

CREATE TABLE "cms_users" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "email" VARCHAR(255) UNIQUE NOT NULL,
  "password_hash" TEXT NOT NULL,
  "first_name" VARCHAR(100),
  "last_name" VARCHAR(100),
  "role_id" INT REFERENCES "roles" ("id") ON DELETE SET NULL,
  "status" user_status DEFAULT 'active',
  "last_login_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_cms_users_modtime BEFORE UPDATE ON "cms_users" 
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- ==========================================
-- SECCIÓN B: APP / FANS (Mundial)
-- ==========================================

CREATE TABLE "app_users" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "msisdn" VARCHAR(20) UNIQUE NOT NULL,
  "nickname" VARCHAR(50),
  "avatar_url" TEXT,
  "points" INT DEFAULT 0, -- Agregado para soportar el índice de ranking
  "created_at" TIMESTAMPTZ DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_app_users_modtime BEFORE UPDATE ON "app_users" 
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE INDEX "idx_app_users_msisdn" ON "app_users" ("msisdn");
CREATE INDEX "idx_app_users_ranking" ON "app_users" ("points" DESC);

-- ==========================================
-- SECCIÓN C: SESIONES (Tokens de Refresco)
-- ==========================================

CREATE TABLE "refresh_tokens" (
  "id" SERIAL PRIMARY KEY,
  "token" TEXT UNIQUE NOT NULL,
  "user_id" UUID NOT NULL, -- Compatible con cms_users y app_users
  "user_type" session_owner_type NOT NULL,
  "ip_address" INET,
  "user_agent" TEXT,
  "device_info" TEXT,
  "is_revoked" BOOLEAN DEFAULT FALSE,
  "expires_at" TIMESTAMPTZ NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX "idx_refresh_tokens_lookup" ON "refresh_tokens" ("token");
CREATE INDEX "idx_refresh_tokens_user" ON "refresh_tokens" ("user_id", "user_type");

-- ==========================================
-- SECCIÓN D: NOTICIAS (CONTENT)
-- ==========================================

CREATE TABLE news (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255),
    description TEXT NOT NULL,
    gallery_urls JSONB DEFAULT '[]', 
    is_featured BOOLEAN DEFAULT FALSE,
    slug VARCHAR(300) UNIQUE,
    
    -- CORREGIDO: Referencia a cms_users y tipo UUID
    created_by UUID REFERENCES cms_users(id),
    last_updated_by UUID REFERENCES cms_users(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_news_modtime BEFORE UPDATE ON news 
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE INDEX idx_news_featured ON news(is_featured);
CREATE INDEX idx_news_created ON news(created_at DESC);

-- ==========================================
-- SECCIÓN E: JUEGOS Y DINÁMICAS
-- ==========================================

CREATE TABLE games (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL, -- 'trivia', 'prediction', 'poll', 'bracket'
    is_active BOOLEAN DEFAULT TRUE,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE game_items (
    id SERIAL PRIMARY KEY,
    game_id INT REFERENCES games(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    media_url VARCHAR(500),
    media_type VARCHAR(20),
    response_type VARCHAR(50) DEFAULT 'single_choice',
    points INT DEFAULT 10,
    order_index INT DEFAULT 0,
    settings JSONB DEFAULT '{}' 
);

CREATE TABLE game_item_options (
    id SERIAL PRIMARY KEY,
    game_item_id INT REFERENCES game_items(id) ON DELETE CASCADE,
    option_text VARCHAR(255) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    order_index INT DEFAULT 0
);

CREATE TABLE user_game_responses (
    id SERIAL PRIMARY KEY,
    
    -- CORREGIDO: Referencia a app_users y tipo UUID
    user_id UUID REFERENCES app_users(id) ON DELETE CASCADE,
    game_item_id INT REFERENCES game_items(id) ON DELETE CASCADE,
    selected_option_id INT REFERENCES game_item_options(id),
    
    text_response TEXT,
    is_correct BOOLEAN,
    points_awarded INT DEFAULT 0,
    responded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, game_item_id)
);

-- ==========================================
-- SECCIÓN F: DEPORTES (PARTIDOS Y EQUIPOS)
-- ==========================================

CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    short_name VARCHAR(10),
    flag_url VARCHAR(500),
    group_name VARCHAR(5),
    iso_code VARCHAR(3)
);

CREATE TABLE matches (
    id SERIAL PRIMARY KEY,
    home_team_id INT REFERENCES teams(id),
    away_team_id INT REFERENCES teams(id),
    match_date TIMESTAMP WITH TIME ZONE NOT NULL,
    stadium VARCHAR(150),
    stage VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'scheduled',
    home_score INT DEFAULT 0,
    away_score INT DEFAULT 0,
    stats JSONB DEFAULT '{}',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- CORREGIDO: El trigger llamaba a la función incorrecta
CREATE TRIGGER update_matches_modtime BEFORE UPDATE ON matches 
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TABLE match_events (
    id SERIAL PRIMARY KEY,
    match_id INT REFERENCES matches(id) ON DELETE CASCADE,
    team_id INT REFERENCES teams(id),
    event_type VARCHAR(50) NOT NULL,
    minute INT,
    extra_minute INT,
    player_name VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
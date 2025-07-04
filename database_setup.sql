-- Configuración de la base de datos para LensysApp
-- Ejecutar en el SQL Editor de Supabase

-- Tabla de empresas
CREATE TABLE IF NOT EXISTS empresas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    tamano TEXT NOT NULL,
    empleados_total INTEGER NOT NULL,
    empleados_asociados JSONB DEFAULT '[]'::jsonb,
    unidades TEXT NOT NULL,
    areas INTEGER NOT NULL,
    sector TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de usuarios (perfil extendido)
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    nombre TEXT,
    telefono TEXT,
    foto_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security)
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para empresas
CREATE POLICY "Los usuarios pueden ver sus propias empresas" ON empresas
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden insertar sus propias empresas" ON empresas
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden actualizar sus propias empresas" ON empresas
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden eliminar sus propias empresas" ON empresas
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas de seguridad para usuarios
CREATE POLICY "Los usuarios pueden ver su propio perfil" ON usuarios
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Los usuarios pueden insertar su propio perfil" ON usuarios
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Los usuarios pueden actualizar su propio perfil" ON usuarios
    FOR UPDATE USING (auth.uid() = id);

-- Función para crear perfil automáticamente
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.usuarios (id, nombre, telefono)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'nombre', ''), COALESCE(NEW.raw_user_meta_data->>'telefono', ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear perfil automáticamente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Función para actualizar timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualizar timestamp automáticamente
CREATE TRIGGER update_empresas_updated_at
    BEFORE UPDATE ON empresas
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER update_usuarios_updated_at
    BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

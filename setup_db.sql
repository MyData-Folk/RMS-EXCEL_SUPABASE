-- Supabase Auto-Importer (RMS Sync) v2.0
-- Script d'initialisation de la base de données Supabase
-- Exécuter ce script dans l'éditeur SQL de Supabase Dashboard

-- ============================================================================
-- TABLE: import_templates
-- Stocke les configurations d'import réutilisables
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.import_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    source_type TEXT CHECK (source_type IN ('csv', 'excel')),
    target_table TEXT NOT NULL,
    sheet_name TEXT,
    column_mapping JSONB NOT NULL DEFAULT '{}',
    column_types JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ============================================================================
-- FONCTION: get_public_tables()
-- Liste toutes les tables du schéma public
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_public_tables()
RETURNS TABLE (
    table_name TEXT,
    table_type TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.table_name::TEXT,
        t.table_type::TEXT
    FROM information_schema.tables t
    WHERE t.table_schema = 'public'
    AND t.table_name NOT LIKE 'pg_%'
    AND t.table_name NOT LIKE 'sql_%'
    ORDER BY t.table_name;
END;
$$;

-- ============================================================================
-- FONCTION: get_table_columns(t_name TEXT)
-- Retourne les colonnes et leurs types pour une table donnée
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_table_columns(t_name TEXT)
RETURNS TABLE (
    column_name TEXT,
    data_type TEXT,
    is_nullable TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.column_name::TEXT,
        c.data_type::TEXT,
        c.is_nullable::TEXT
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
    AND c.table_name = t_name
    ORDER BY c.ordinal_position;
END;
$$;

-- ============================================================================
-- FONCTION: get_all_columns_with_types()
-- Retourne toutes les colonnes de toutes les tables publiques avec leurs types
-- Utile pour l'introspection globale
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_all_columns_with_types()
RETURNS TABLE (
    table_name TEXT,
    column_name TEXT,
    data_type TEXT,
    is_nullable TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.table_name::TEXT,
        c.column_name::TEXT,
        c.data_type::TEXT,
        c.is_nullable::TEXT
    FROM information_schema.tables t
    JOIN information_schema.columns c ON t.table_name = c.table_name AND t.table_schema = c.table_schema
    WHERE t.table_schema = 'public'
    AND t.table_name NOT LIKE 'pg_%'
    AND t.table_name NOT LIKE 'sql_%'
    ORDER BY t.table_name, c.ordinal_position;
END;
$$;

-- ============================================================================
-- POLICIES RLS (Row Level Security)
-- Sécurité pour la table des templates
-- ============================================================================
ALTER TABLE public.import_templates ENABLE ROW LEVEL SECURITY;

-- Politique允许 l'authentification complète (admin)
CREATE POLICY "Admin can do everything" ON public.import_templates
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- INDEX pour optimiser les performances
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_import_templates_name
    ON public.import_templates(name);

CREATE INDEX IF NOT EXISTS idx_import_templates_target_table
    ON public.import_templates(target_table);

-- ============================================================================
-- COMMENTAIRES pour documentation
-- ============================================================================
COMMENT ON TABLE public.import_templates IS 'Stocke les configurations d import réutilisables pour RMS Sync';
COMMENT ON COLUMN public.import_templates.column_mapping IS 'Mapping JSON { "col_source": "col_target" }';
COMMENT ON COLUMN public.import_templates.column_types IS 'Types JSON { "col_source": "date|numeric|text" }';
COMMENT ON FUNCTION public.get_public_tables() IS 'Liste les tables du schéma public pour RMS Sync';
COMMENT ON FUNCTION public.get_table_columns(t_name TEXT) IS 'Retourne les colonnes d une table spécifique';

-- ============================================================================
-- VUE: v_template_summary
-- Vue pratique pour lister les templates avec résumé
-- ============================================================================
CREATE OR REPLACE VIEW public.v_template_summary AS
SELECT
    id,
    name,
    description,
    source_type,
    target_table,
    sheet_name,
    (column_mapping::jsonb)->>'count' as mapped_columns,
    created_at,
    updated_at
FROM (
    SELECT
        id,
        name,
        description,
        source_type,
        target_table,
        sheet_name,
        jsonb_build_object('count', jsonb_array_length(column_mapping::jsonb)) as column_mapping,
        created_at,
        updated_at
    FROM public.import_templates
) t;

-- Fin du script d'initialisation
-- ============================================================================

-- Migration: Adicionar policies RLS na tabela perfis
-- Corrige erro 42501 (Unauthorized) no fluxo de cadastro de usuário
-- Ref: PRD RLS + Race Condition Fix

-- Garantir que RLS está ativo
ALTER TABLE perfis ENABLE ROW LEVEL SECURITY;

-- Policy de INSERT: usuário só pode inserir o próprio perfil
CREATE POLICY "Users can insert own profile"
ON perfis
FOR INSERT
WITH CHECK (auth.uid() = id);

-- Policy de SELECT: usuário só lê o próprio perfil
CREATE POLICY "Users can view own profile"
ON perfis
FOR SELECT
USING (auth.uid() = id);

-- Policy de UPDATE: usuário só edita o próprio perfil
CREATE POLICY "Users can update own profile"
ON perfis
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

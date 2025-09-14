-- ============================================================================
-- Script de Criação do Banco de Dados ClickBus
-- Projeto: Enterprise Challenge - ClickBus
-- Descrição: Estrutura completa para armazenar dados de viagens, clientes,
--           rotas, municípios e análises de machine learning
-- ============================================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis" CASCADE;

-- ============================================================================
-- TABELAS DE LOCALIZAÇÃO E GEOGRAFIA
-- ============================================================================

-- Tabela de Estados
CREATE TABLE estados (
    id_estado SERIAL PRIMARY KEY,
    codigo_uf VARCHAR(2) NOT NULL UNIQUE,
    nome_estado VARCHAR(100) NOT NULL,
    regiao VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Municípios
CREATE TABLE municipios (
    id_municipio SERIAL PRIMARY KEY,
    codigo_ibge INTEGER UNIQUE,
    nome_municipio VARCHAR(100) NOT NULL,
    id_estado INTEGER NOT NULL REFERENCES estados(id_estado),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    populacao INTEGER,
    area_km2 DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TABELAS DE CLIENTES E USUÁRIOS
-- ============================================================================

-- Tabela de Clientes
CREATE TABLE clientes (
    id_cliente UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hash_cliente VARCHAR(128) UNIQUE NOT NULL, -- Hash original do dataset
    nome_cliente VARCHAR(200),
    email VARCHAR(150),
    telefone VARCHAR(20),
    data_nascimento DATE,
    cpf VARCHAR(14),
    cnpj VARCHAR(18),
    tipo_cliente VARCHAR(2) CHECK (tipo_cliente IN ('PF', 'PJ')),
    status_cliente VARCHAR(1) DEFAULT 'A' CHECK (status_cliente IN ('A', 'I')),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultima_compra TIMESTAMP,
    valor_total_gasto DECIMAL(12, 2) DEFAULT 0.00,
    quantidade_viagens INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TABELAS DE EMPRESAS DE TRANSPORTE
-- ============================================================================

-- Tabela de Viações/Empresas de Ônibus
CREATE TABLE viacoes (
    id_viacao SERIAL PRIMARY KEY,
    hash_viacao VARCHAR(128) UNIQUE NOT NULL, -- Hash original do dataset
    nome_viacao VARCHAR(200),
    cnpj VARCHAR(18),
    telefone VARCHAR(20),
    email VARCHAR(150),
    site VARCHAR(200),
    status_viacao VARCHAR(1) DEFAULT 'A' CHECK (status_viacao IN ('A', 'I')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TABELAS DE ROTAS E VIAGENS
-- ============================================================================

-- Tabela de Rotas
CREATE TABLE rotas (
    id_rota SERIAL PRIMARY KEY,
    nome_rota VARCHAR(300) NOT NULL,
    id_municipio_origem INTEGER NOT NULL REFERENCES municipios(id_municipio),
    id_municipio_destino INTEGER NOT NULL REFERENCES municipios(id_municipio),
    distancia_km DECIMAL(8, 2),
    tempo_estimado_horas DECIMAL(5, 2),
    preco_medio DECIMAL(8, 2),
    status_rota VARCHAR(1) DEFAULT 'A' CHECK (status_rota IN ('A', 'I')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_municipio_origem, id_municipio_destino)
);

-- ============================================================================
-- TABELAS DE PEDIDOS E TRANSAÇÕES
-- ============================================================================

-- Tabela de Pedidos/Compras
CREATE TABLE pedidos (
    id_pedido UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hash_pedido VARCHAR(128) UNIQUE NOT NULL, -- Hash original do dataset
    id_cliente UUID NOT NULL REFERENCES clientes(id_cliente),
    id_viacao INTEGER NOT NULL REFERENCES viacoes(id_viacao),
    id_rota INTEGER NOT NULL REFERENCES rotas(id_rota),
    data_compra DATE NOT NULL,
    hora_compra TIME NOT NULL,
    valor_total DECIMAL(10, 2) NOT NULL,
    quantidade_passagens INTEGER NOT NULL DEFAULT 1,
    valor_por_passagem DECIMAL(10, 2),
    tipo_viagem VARCHAR(10) CHECK (tipo_viagem IN ('IDA', 'VOLTA', 'IDA_VOLTA')),
    status_pedido VARCHAR(20) DEFAULT 'CONFIRMADO',
    metodo_pagamento VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Rotas de Retorno (para viagens de ida e volta)
CREATE TABLE pedidos_retorno (
    id_pedido_retorno SERIAL PRIMARY KEY,
    id_pedido UUID NOT NULL REFERENCES pedidos(id_pedido),
    id_rota_retorno INTEGER NOT NULL REFERENCES rotas(id_rota),
    data_retorno DATE,
    hora_retorno TIME,
    valor_retorno DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TABELAS DE ANÁLISE E MACHINE LEARNING
-- ============================================================================

-- Tabela de Clusters de Clientes
CREATE TABLE clusters_clientes (
    id_cluster SERIAL PRIMARY KEY,
    nome_cluster VARCHAR(100) NOT NULL,
    descricao_cluster TEXT,
    caracteristicas JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Classificação de Clientes por Cluster
CREATE TABLE cliente_clusters (
    id_cliente_cluster SERIAL PRIMARY KEY,
    id_cliente UUID NOT NULL REFERENCES clientes(id_cliente),
    id_cluster INTEGER NOT NULL REFERENCES clusters_clientes(id_cluster),
    pontos_fidelidade DECIMAL(10, 2) DEFAULT 0.00,
    valor_reais DECIMAL(10, 2) DEFAULT 0.00,
    data_classificacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_cliente, id_cluster)
);

-- ============================================================================
-- TABELAS DE AUDITORIA E LOG
-- ============================================================================

-- Tabela de Log de Operações
CREATE TABLE logs_operacoes (
    id_log SERIAL PRIMARY KEY,
    tabela_afetada VARCHAR(100),
    operacao VARCHAR(10) CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos JSONB,
    dados_novos JSONB,
    usuario VARCHAR(100),
    timestamp_operacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

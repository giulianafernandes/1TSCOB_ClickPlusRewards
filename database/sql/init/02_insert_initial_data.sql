-- ============================================================================
-- Script de Inserção de Dados Iniciais
-- Projeto: Enterprise Challenge - ClickBus
-- ============================================================================

-- ============================================================================
-- INSERÇÃO DE ESTADOS BRASILEIROS
-- ============================================================================

INSERT INTO estados (codigo_uf, nome_estado, regiao) VALUES
('AC', 'Acre', 'Norte'),
('AL', 'Alagoas', 'Nordeste'),
('AP', 'Amapá', 'Norte'),
('AM', 'Amazonas', 'Norte'),
('BA', 'Bahia', 'Nordeste'),
('CE', 'Ceará', 'Nordeste'),
('DF', 'Distrito Federal', 'Centro-Oeste'),
('ES', 'Espírito Santo', 'Sudeste'),
('GO', 'Goiás', 'Centro-Oeste'),
('MA', 'Maranhão', 'Nordeste'),
('MT', 'Mato Grosso', 'Centro-Oeste'),
('MS', 'Mato Grosso do Sul', 'Centro-Oeste'),
('MG', 'Minas Gerais', 'Sudeste'),
('PA', 'Pará', 'Norte'),
('PB', 'Paraíba', 'Nordeste'),
('PR', 'Paraná', 'Sul'),
('PE', 'Pernambuco', 'Nordeste'),
('PI', 'Piauí', 'Nordeste'),
('RJ', 'Rio de Janeiro', 'Sudeste'),
('RN', 'Rio Grande do Norte', 'Nordeste'),
('RS', 'Rio Grande do Sul', 'Sul'),
('RO', 'Rondônia', 'Norte'),
('RR', 'Roraima', 'Norte'),
('SC', 'Santa Catarina', 'Sul'),
('SP', 'São Paulo', 'Sudeste'),
('SE', 'Sergipe', 'Nordeste'),
('TO', 'Tocantins', 'Norte');

-- ============================================================================
-- INSERÇÃO DE CLUSTERS DE CLIENTES (baseado no projeto original)
-- ============================================================================

INSERT INTO clusters_clientes (nome_cluster, descricao_cluster, caracteristicas) VALUES
('viajantes_frequentes', 'Clientes que viajam com alta frequência', 
 '{"frequencia": "alta", "valor_medio": "medio_alto", "fidelidade": "alta"}'),
('viajantes_ocasionais', 'Clientes que viajam esporadicamente', 
 '{"frequencia": "baixa", "valor_medio": "medio", "fidelidade": "media"}'),
('viajantes_grupo', 'Clientes que viajam em grupos ou família', 
 '{"frequencia": "media", "valor_medio": "alto", "fidelidade": "media_alta"}');

-- ============================================================================
-- INSERÇÃO DE MUNICÍPIOS PRINCIPAIS (baseado no dataset do projeto)
-- ============================================================================

-- Alguns municípios principais que aparecem no dataset
INSERT INTO municipios (codigo_ibge, nome_municipio, id_estado, latitude, longitude) VALUES
-- Amazonas
(1300300, 'Caapiranga', (SELECT id_estado FROM estados WHERE codigo_uf = 'AM'), -3.1167, -61.4833),

-- São Paulo
(3526209, 'Lavínia', (SELECT id_estado FROM estados WHERE codigo_uf = 'SP'), -21.1667, -51.0333),
(3529401, 'Luiziânia', (SELECT id_estado FROM estados WHERE codigo_uf = 'SP'), -21.6833, -50.3167),
(3530607, 'Maracaí', (SELECT id_estado FROM estados WHERE codigo_uf = 'SP'), -22.6167, -50.6667),

-- Rio Grande do Sul
(4312401, 'Miraguaí', (SELECT id_estado FROM estados WHERE codigo_uf = 'RS'), -27.4667, -53.7667),
(4315602, 'Paraíso do Sul', (SELECT id_estado FROM estados WHERE codigo_uf = 'RS'), -29.6667, -53.1333),

-- Piauí
(2209708, 'São Braz do Piauí', (SELECT id_estado FROM estados WHERE codigo_uf = 'PI'), -3.9167, -42.2833),

-- Rio Grande do Norte
(2411403, 'São Rafael', (SELECT id_estado FROM estados WHERE codigo_uf = 'RN'), -6.4833, -36.8833),
(2401305, 'Alto do Rodrigues', (SELECT id_estado FROM estados WHERE codigo_uf = 'RN'), -5.1833, -36.8167),

-- Santa Catarina
(4203006, 'Campo Erê', (SELECT id_estado FROM estados WHERE codigo_uf = 'SC'), -26.3833, -53.0833),
(4217709, 'São Bernardino', (SELECT id_estado FROM estados WHERE codigo_uf = 'SC'), -26.4833, -48.7167),

-- Tocantins
(1721208, 'Taipas do Tocantins', (SELECT id_estado FROM estados WHERE codigo_uf = 'TO'), -12.2167, -46.8667),

-- Minas Gerais
(3154606, 'Santa Rita de Caldas', (SELECT id_estado FROM estados WHERE codigo_uf = 'MG'), -22.0167, -46.3833),
(3106200, 'Baldim', (SELECT id_estado FROM estados WHERE codigo_uf = 'MG'), -19.2667, -43.9333),
(3107109, 'Belo Vale', (SELECT id_estado FROM estados WHERE codigo_uf = 'MG'), -20.4167, -44.0167),

-- Goiás
(5209937, 'Heitoraí', (SELECT id_estado FROM estados WHERE codigo_uf = 'GO'), -15.7167, -49.9167),

-- Mato Grosso
(5104104, 'Indiavaí', (SELECT id_estado FROM estados WHERE codigo_uf = 'MT'), -15.2167, -58.6833),

-- Paraná
(4127700, 'Tijucas do Sul', (SELECT id_estado FROM estados WHERE codigo_uf = 'PR'), -25.9333, -49.1833),

-- Pará
(1505502, 'Paragominas', (SELECT id_estado FROM estados WHERE codigo_uf = 'PA'), -2.9833, -47.3500),

-- Bahia
(2930204, 'Santa Cruz Cabrália', (SELECT id_estado FROM estados WHERE codigo_uf = 'BA'), -16.2833, -39.0333),
(2928901, 'Santa Brígida', (SELECT id_estado FROM estados WHERE codigo_uf = 'BA'), -9.1833, -38.1167),

-- Ceará
(2313005, 'Tamboril', (SELECT id_estado FROM estados WHERE codigo_uf = 'CE'), -4.8333, -40.3167),

-- Paraíba
(2506301, 'Gurinhém', (SELECT id_estado FROM estados WHERE codigo_uf = 'PB'), -7.1333, -35.4167);

-- ============================================================================
-- CRIAÇÃO DE ÍNDICES PARA PERFORMANCE
-- ============================================================================

-- Índices para tabelas principais
CREATE INDEX idx_municipios_estado ON municipios(id_estado);
CREATE INDEX idx_municipios_nome ON municipios(nome_municipio);
CREATE INDEX idx_clientes_hash ON clientes(hash_cliente);
CREATE INDEX idx_clientes_email ON clientes(email);
CREATE INDEX idx_viacoes_hash ON viacoes(hash_viacao);
CREATE INDEX idx_pedidos_hash ON pedidos(hash_pedido);
CREATE INDEX idx_pedidos_cliente ON pedidos(id_cliente);
CREATE INDEX idx_pedidos_data ON pedidos(data_compra);
CREATE INDEX idx_rotas_origem_destino ON rotas(id_municipio_origem, id_municipio_destino);
CREATE INDEX idx_cliente_clusters_cliente ON cliente_clusters(id_cliente);

-- ============================================================================
-- TRIGGERS PARA AUDITORIA
-- ============================================================================

-- Função para atualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
CREATE TRIGGER update_estados_updated_at BEFORE UPDATE ON estados
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_municipios_updated_at BEFORE UPDATE ON municipios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clientes_updated_at BEFORE UPDATE ON clientes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_viacoes_updated_at BEFORE UPDATE ON viacoes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rotas_updated_at BEFORE UPDATE ON rotas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pedidos_updated_at BEFORE UPDATE ON pedidos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

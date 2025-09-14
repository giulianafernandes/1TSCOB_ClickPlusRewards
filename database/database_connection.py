#!/usr/bin/env python3
"""
Módulo de Conexão com Banco de Dados PostgreSQL
Projeto: Enterprise Challenge - ClickBus

Este módulo fornece funcionalidades para conectar e interagir com o banco
de dados PostgreSQL do projeto ClickBus.
"""

import os
import pandas as pd
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
import logging
from typing import Optional, Dict, List, Any
from datetime import datetime

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ClickBusDatabase:
    """Classe para gerenciar conexões e operações com o banco ClickBus"""
    
    def __init__(self):
        """Inicializa a conexão com o banco de dados"""
        load_dotenv()
        self.connection = None
        self.cursor = None
        self._connect()
    
    def _connect(self):
        """Estabelece conexão com o banco PostgreSQL"""
        try:
            self.connection = psycopg2.connect(
                host=os.getenv('POSTGRES_HOST'),
                port=os.getenv('POSTGRES_PORT'),
                database=os.getenv('POSTGRES_DB'),
                user=os.getenv('POSTGRES_USER'),
                password=os.getenv('POSTGRES_PASSWORD')
            )
            self.cursor = self.connection.cursor(cursor_factory=RealDictCursor)
            logger.info("Conexão com banco de dados estabelecida com sucesso")
        except Exception as e:
            logger.error(f"Erro ao conectar com banco de dados: {e}")
            raise
    
    def close_connection(self):
        """Fecha a conexão com o banco"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("Conexão com banco de dados fechada")
    
    def execute_query(self, query: str, params: Optional[tuple] = None) -> List[Dict]:
        """
        Executa uma query SELECT e retorna os resultados
        
        Args:
            query: Query SQL a ser executada
            params: Parâmetros para a query (opcional)
            
        Returns:
            Lista de dicionários com os resultados
        """
        try:
            self.cursor.execute(query, params)
            results = self.cursor.fetchall()
            return [dict(row) for row in results]
        except Exception as e:
            logger.error(f"Erro ao executar query: {e}")
            raise
    
    def execute_insert(self, query: str, params: Optional[tuple] = None) -> bool:
        """
        Executa uma query INSERT/UPDATE/DELETE
        
        Args:
            query: Query SQL a ser executada
            params: Parâmetros para a query (opcional)
            
        Returns:
            True se executada com sucesso
        """
        try:
            self.cursor.execute(query, params)
            self.connection.commit()
            logger.info("Query executada com sucesso")
            return True
        except Exception as e:
            self.connection.rollback()
            logger.error(f"Erro ao executar insert/update: {e}")
            raise
    
    def insert_municipio(self, codigo_ibge: int, nome: str, uf: str, 
                        latitude: float = None, longitude: float = None) -> bool:
        """
        Insere um novo município no banco
        
        Args:
            codigo_ibge: Código IBGE do município
            nome: Nome do município
            uf: Sigla do estado
            latitude: Latitude (opcional)
            longitude: Longitude (opcional)
            
        Returns:
            True se inserido com sucesso
        """
        query = """
        INSERT INTO municipios (codigo_ibge, nome_municipio, id_estado, latitude, longitude)
        VALUES (%s, %s, (SELECT id_estado FROM estados WHERE codigo_uf = %s), %s, %s)
        ON CONFLICT (codigo_ibge) DO NOTHING
        """
        return self.execute_insert(query, (codigo_ibge, nome, uf, latitude, longitude))
    
    def insert_cliente(self, hash_cliente: str, nome: str = None, email: str = None,
                      tipo_cliente: str = 'PF') -> bool:
        """
        Insere um novo cliente no banco
        
        Args:
            hash_cliente: Hash único do cliente
            nome: Nome do cliente (opcional)
            email: Email do cliente (opcional)
            tipo_cliente: Tipo do cliente (PF ou PJ)
            
        Returns:
            True se inserido com sucesso
        """
        query = """
        INSERT INTO clientes (hash_cliente, nome_cliente, email, tipo_cliente)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (hash_cliente) DO NOTHING
        """
        return self.execute_insert(query, (hash_cliente, nome, email, tipo_cliente))
    
    def insert_viacao(self, hash_viacao: str, nome: str = None) -> bool:
        """
        Insere uma nova viação no banco
        
        Args:
            hash_viacao: Hash único da viação
            nome: Nome da viação (opcional)
            
        Returns:
            True se inserido com sucesso
        """
        query = """
        INSERT INTO viacoes (hash_viacao, nome_viacao)
        VALUES (%s, %s)
        ON CONFLICT (hash_viacao) DO NOTHING
        """
        return self.execute_insert(query, (hash_viacao, nome))
    
    def get_municipios_by_uf(self, uf: str) -> List[Dict]:
        """
        Busca municípios por UF
        
        Args:
            uf: Sigla do estado
            
        Returns:
            Lista de municípios
        """
        query = """
        SELECT m.*, e.codigo_uf, e.nome_estado
        FROM municipios m
        JOIN estados e ON m.id_estado = e.id_estado
        WHERE e.codigo_uf = %s
        ORDER BY m.nome_municipio
        """
        return self.execute_query(query, (uf,))
    
    def get_rotas_populares(self, limit: int = 10) -> List[Dict]:
        """
        Busca as rotas mais populares
        
        Args:
            limit: Número máximo de rotas a retornar
            
        Returns:
            Lista de rotas populares
        """
        query = """
        SELECT 
            r.nome_rota,
            mo.nome_municipio as origem,
            md.nome_municipio as destino,
            eo.codigo_uf as uf_origem,
            ed.codigo_uf as uf_destino,
            COUNT(p.id_pedido) as total_viagens,
            AVG(p.valor_total) as valor_medio,
            r.distancia_km
        FROM rotas r
        JOIN municipios mo ON r.id_municipio_origem = mo.id_municipio
        JOIN municipios md ON r.id_municipio_destino = md.id_municipio
        JOIN estados eo ON mo.id_estado = eo.id_estado
        JOIN estados ed ON md.id_estado = ed.id_estado
        LEFT JOIN pedidos p ON r.id_rota = p.id_rota
        GROUP BY r.id_rota, r.nome_rota, mo.nome_municipio, md.nome_municipio, 
                 eo.codigo_uf, ed.codigo_uf, r.distancia_km
        ORDER BY total_viagens DESC
        LIMIT %s
        """
        return self.execute_query(query, (limit,))
    
    def import_csv_data(self, csv_file_path: str) -> bool:
        """
        Importa dados do CSV do projeto original
        
        Args:
            csv_file_path: Caminho para o arquivo CSV
            
        Returns:
            True se importado com sucesso
        """
        try:
            df = pd.read_csv(csv_file_path)
            logger.info(f"Carregando {len(df)} registros do CSV")
            
            # Processar cada linha do CSV
            for _, row in df.iterrows():
                # Inserir cliente se não existir
                self.insert_cliente(row['id_cliente'])
                
                # Inserir viação se não existir
                self.insert_viacao(row['viacao'])
                
                # Aqui você pode adicionar mais lógica para inserir pedidos, rotas, etc.
                
            logger.info("Importação do CSV concluída com sucesso")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao importar CSV: {e}")
            return False

def main():
    """Função principal para testar a conexão"""
    db = ClickBusDatabase()
    
    try:
        # Testar conexão
        estados = db.execute_query("SELECT * FROM estados LIMIT 5")
        print("Estados encontrados:")
        for estado in estados:
            print(f"- {estado['nome_estado']} ({estado['codigo_uf']})")
        
        # Testar inserção de município
        db.insert_municipio(3550308, "São Paulo", "SP", -23.5505, -46.6333)
        
        # Buscar municípios de SP
        municipios_sp = db.get_municipios_by_uf("SP")
        print(f"\nMunicípios de SP encontrados: {len(municipios_sp)}")
        
    except Exception as e:
        logger.error(f"Erro no teste: {e}")
    finally:
        db.close_connection()

if __name__ == "__main__":
    main()

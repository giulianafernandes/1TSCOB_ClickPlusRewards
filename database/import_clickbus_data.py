#!/usr/bin/env python3
"""
Script de Importação de Dados do ClickBus
Projeto: Enterprise Challenge - ClickBus

Este script importa os dados do projeto original para o banco PostgreSQL.
"""

import pandas as pd
import numpy as np
from database_connection import ClickBusDatabase
import logging
from datetime import datetime
import hashlib

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ClickBusDataImporter:
    """Classe para importar dados do projeto ClickBus"""
    
    def __init__(self):
        """Inicializa o importador"""
        self.db = ClickBusDatabase()
    
    def import_municipios_from_csv(self, csv_path: str = "../data/municipios_final.csv"):
        """
        Importa municípios do arquivo CSV
        
        Args:
            csv_path: Caminho para o arquivo de municípios
        """
        try:
            logger.info("Iniciando importação de municípios...")
            df_municipios = pd.read_csv(csv_path)
            
            success_count = 0
            for _, row in df_municipios.iterrows():
                try:
                    success = self.db.insert_municipio(
                        codigo_ibge=int(row['COD']),
                        nome=row['NOME'],
                        uf=row['UF']
                    )
                    if success:
                        success_count += 1
                except Exception as e:
                    logger.warning(f"Erro ao inserir município {row['NOME']}: {e}")
                    continue
            
            logger.info(f"Importação de municípios concluída: {success_count} registros inseridos")
            
        except Exception as e:
            logger.error(f"Erro ao importar municípios: {e}")
    
    def import_clickbus_data_from_csv(self, csv_path: str = "../data/modelo_banco.csv"):
        """
        Importa dados principais do ClickBus do arquivo CSV
        
        Args:
            csv_path: Caminho para o arquivo de dados do ClickBus
        """
        try:
            logger.info("Iniciando importação de dados do ClickBus...")
            df = pd.read_csv(csv_path)
            
            # Limpar dados NaN
            df = df.fillna('')
            
            # Contadores
            clientes_inseridos = 0
            viacoes_inseridas = 0
            rotas_inseridas = 0
            pedidos_inseridos = 0
            
            # Processar cada linha
            for _, row in df.iterrows():
                try:
                    # 1. Inserir cliente
                    if self.db.insert_cliente(
                        hash_cliente=str(row['id_cliente']),
                        tipo_cliente='PF'  # Assumindo pessoa física por padrão
                    ):
                        clientes_inseridos += 1
                    
                    # 2. Inserir viação
                    if self.db.insert_viacao(
                        hash_viacao=str(row['viacao'])
                    ):
                        viacoes_inseridas += 1
                    
                    # 3. Inserir/buscar rota
                    rota_id = self._insert_or_get_rota(
                        origem=str(row['origem']),
                        destino=str(row['destino']),
                        uf_origem=str(row['uf_origem']),
                        uf_destino=str(row['uf_destino']),
                        distancia_km=float(row['distancia_km']) if row['distancia_km'] else None
                    )
                    
                    if rota_id:
                        rotas_inseridas += 1
                    
                    # 4. Inserir pedido
                    if self._insert_pedido(row, rota_id):
                        pedidos_inseridos += 1
                    
                    # 5. Inserir classificação de cluster se existir
                    if row['cluster'] and row['nome_cluster']:
                        self._insert_cliente_cluster(
                            hash_cliente=str(row['id_cliente']),
                            cluster_nome=str(row['nome_cluster']),
                            pontos=float(row['pontos']) if row['pontos'] else 0.0,
                            reais=float(row['reais']) if row['reais'] else 0.0
                        )
                
                except Exception as e:
                    logger.warning(f"Erro ao processar linha {row.name}: {e}")
                    continue
            
            logger.info(f"""
            Importação concluída:
            - Clientes: {clientes_inseridos}
            - Viações: {viacoes_inseridas}
            - Rotas: {rotas_inseridas}
            - Pedidos: {pedidos_inseridos}
            """)
            
        except Exception as e:
            logger.error(f"Erro ao importar dados do ClickBus: {e}")
    
    def _insert_or_get_rota(self, origem: str, destino: str, uf_origem: str, 
                           uf_destino: str, distancia_km: float = None) -> int:
        """
        Insere ou busca uma rota existente
        
        Returns:
            ID da rota
        """
        try:
            # Buscar IDs dos municípios
            origem_id = self._get_municipio_id(origem, uf_origem)
            destino_id = self._get_municipio_id(destino, uf_destino)
            
            if not origem_id or not destino_id:
                return None
            
            # Verificar se rota já existe
            query_check = """
            SELECT id_rota FROM rotas 
            WHERE id_municipio_origem = %s AND id_municipio_destino = %s
            """
            existing = self.db.execute_query(query_check, (origem_id, destino_id))
            
            if existing:
                return existing[0]['id_rota']
            
            # Inserir nova rota
            nome_rota = f"{origem} - {destino}"
            query_insert = """
            INSERT INTO rotas (nome_rota, id_municipio_origem, id_municipio_destino, distancia_km)
            VALUES (%s, %s, %s, %s)
            RETURNING id_rota
            """
            
            self.db.cursor.execute(query_insert, (nome_rota, origem_id, destino_id, distancia_km))
            result = self.db.cursor.fetchone()
            self.db.connection.commit()
            
            return result['id_rota'] if result else None
            
        except Exception as e:
            logger.warning(f"Erro ao inserir rota {origem}-{destino}: {e}")
            return None
    
    def _get_municipio_id(self, nome_municipio: str, uf: str) -> int:
        """
        Busca o ID de um município pelo nome e UF
        
        Returns:
            ID do município ou None se não encontrado
        """
        query = """
        SELECT m.id_municipio 
        FROM municipios m
        JOIN estados e ON m.id_estado = e.id_estado
        WHERE m.nome_municipio = %s AND e.codigo_uf = %s
        """
        result = self.db.execute_query(query, (nome_municipio, uf))
        return result[0]['id_municipio'] if result else None
    
    def _insert_pedido(self, row, rota_id: int) -> bool:
        """
        Insere um pedido no banco
        
        Returns:
            True se inserido com sucesso
        """
        try:
            if not rota_id:
                return False
            
            # Buscar IDs de cliente e viação
            cliente_id = self._get_cliente_id(str(row['id_cliente']))
            viacao_id = self._get_viacao_id(str(row['viacao']))
            
            if not cliente_id or not viacao_id:
                return False
            
            query = """
            INSERT INTO pedidos (
                hash_pedido, id_cliente, id_viacao, id_rota,
                data_compra, hora_compra, valor_total, quantidade_passagens,
                valor_por_passagem
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (hash_pedido) DO NOTHING
            """
            
            return self.db.execute_insert(query, (
                str(row['id_pedido']),
                cliente_id,
                viacao_id,
                rota_id,
                row['date_purchase'],
                row['time_purchase'],
                float(row['valor_total_compra']),
                int(row['qtd_passagens']),
                float(row['valor_passagem']) if row['valor_passagem'] else float(row['valor_total_compra'])
            ))
            
        except Exception as e:
            logger.warning(f"Erro ao inserir pedido: {e}")
            return False
    
    def _get_cliente_id(self, hash_cliente: str) -> str:
        """Busca ID do cliente pelo hash"""
        query = "SELECT id_cliente FROM clientes WHERE hash_cliente = %s"
        result = self.db.execute_query(query, (hash_cliente,))
        return result[0]['id_cliente'] if result else None
    
    def _get_viacao_id(self, hash_viacao: str) -> int:
        """Busca ID da viação pelo hash"""
        query = "SELECT id_viacao FROM viacoes WHERE hash_viacao = %s"
        result = self.db.execute_query(query, (hash_viacao,))
        return result[0]['id_viacao'] if result else None
    
    def _insert_cliente_cluster(self, hash_cliente: str, cluster_nome: str, 
                               pontos: float, reais: float):
        """Insere classificação de cluster do cliente"""
        try:
            cliente_id = self._get_cliente_id(hash_cliente)
            if not cliente_id:
                return
            
            # Buscar ID do cluster
            query_cluster = "SELECT id_cluster FROM clusters_clientes WHERE nome_cluster = %s"
            cluster_result = self.db.execute_query(query_cluster, (cluster_nome,))
            
            if not cluster_result:
                return
            
            cluster_id = cluster_result[0]['id_cluster']
            
            # Inserir classificação
            query = """
            INSERT INTO cliente_clusters (id_cliente, id_cluster, pontos_fidelidade, valor_reais)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (id_cliente, id_cluster) DO UPDATE SET
                pontos_fidelidade = EXCLUDED.pontos_fidelidade,
                valor_reais = EXCLUDED.valor_reais
            """
            
            self.db.execute_insert(query, (cliente_id, cluster_id, pontos, reais))
            
        except Exception as e:
            logger.warning(f"Erro ao inserir cluster do cliente: {e}")
    
    def close(self):
        """Fecha conexão com banco"""
        self.db.close_connection()

def main():
    """Função principal"""
    importer = ClickBusDataImporter()
    
    try:
        # Importar municípios primeiro
        importer.import_municipios_from_csv()
        
        # Importar dados principais do ClickBus
        importer.import_clickbus_data_from_csv()
        
        logger.info("Importação completa!")
        
    except Exception as e:
        logger.error(f"Erro na importação: {e}")
    finally:
        importer.close()

if __name__ == "__main__":
    main()

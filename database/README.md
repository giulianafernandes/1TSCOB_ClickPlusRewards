# 🐳 Banco de Dados ClickBus

Banco de dados PostgreSQL para armazenar os dados do projeto Enterprise Challenge - ClickBus.

## 🚀 Instalação

### 1. Deploy na VPS
```bash
./deploy.sh
```

### 2. Verificar instalação
```bash
ssh root@72.60.50.72 "cd /opt/clickbus-db && docker-compose ps"
```

## 🔗 Acesso

### PostgreSQL
- **Host:** 72.60.50.72:5432
- **Database:** clickbus_db
- **Usuário:** clickbus_admin
- **Senha:** ClickBus2024!@#

### pgAdmin (Interface Web)
- **URL:** http://72.60.50.72:8080
- **Email:** admin@clickbus.com
- **Senha:** admin123

## 📊 Importar Dados

```bash
# Instalar dependências
pip install psycopg2-binary pandas python-dotenv

# Importar dados do CSV
python import_clickbus_data.py
```

## 🔧 Comandos Úteis

```bash
# Status dos containers
ssh root@72.60.50.72 "cd /opt/clickbus-db && docker-compose ps"

# Ver logs
ssh root@72.60.50.72 "cd /opt/clickbus-db && docker-compose logs"

# Reiniciar
ssh root@72.60.50.72 "cd /opt/clickbus-db && docker-compose restart"

# Backup
ssh root@72.60.50.72 "docker exec clickbus_postgres pg_dump -U clickbus_admin clickbus_db > backup.sql"
```

## 📋 Estrutura

- **docker-compose.yml** - Configuração Docker
- **sql/init/** - Scripts de criação do banco
- **database_connection.py** - Módulo de conexão Python
- **import_clickbus_data.py** - Script de importação de dados
- **.env** - Credenciais para conexão remota

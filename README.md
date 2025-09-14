# 🚌 ClickPlusRewards: Análise de Clientes e Sistema de Recompensas

Apesar da grande procura por passagens de ônibus no Brasil, muitas empresas de vendas de passagens ainda enfrentam dificuldades para fidelizar seus usuários, que muitas vezes buscam apenas o menor preço sem criar vínculo com o aplicativo ou viação.
O nosso objetivo é criar uma **conexão significativa** com o cliente de acordo com o seu perfil viajante, garantindo assim a sua satisfação através de experiências e vantagens personalizadas.
Além disso, buscamos otimizar nossos recursos com a previsibilidade de demanda e trecho mais provável a ser escolhido, otimizando assim nossas operações e campanhas de marketing.

-----

## 👥 Equipe

| Nome                                            | RM       |
| ----------------------------------------------- | -------- |
| Giuliana Fernandes                              | RM563086 |
| Henrique Soares Meira                           | RM565646 |
| Francisco Emmanuel Mendes de Almeida Rezende Silvério | RM563573 |

-----

### 1\. Análise Exploratória e Engenharia de Atributos

  - **Limpeza e Tratamento de Dados:** Dados de compras de passagens foram carregados, renomeados para maior clareza e tratados, incluindo a conversão de colunas de data e hora para formatos adequados.
  - **Análise de Rotas Populares:** Identificamos as rotas de ônibus mais populares, como **"Caapiranga - Lavínia"** e **"Lavínia - Caapiranga"**, utilizando a contagem de frequência das viagens.
  - **Geolocalização:** Um recurso interessante é a integração com a **API do Google Maps** para calcular a distância em quilômetros entre a origem e o destino de cada viagem, um passo fundamental para o cálculo de pontos no programa de recompensas.

### 2\. Segmentação de Clientes (Clustering)

  - Utilizando o algoritmo de agrupamento **K-Means**, os clientes foram segmentados em quatro clusters distintos, com base em seu comportamento de compra.
  - O método **Elbow** foi aplicado para determinar que 4 clusters seria o número ideal para a segmentação.

### 3\. Sistema de Recompensas

  - Com base nos clusters, uma lógica de pontuação foi criada para o programa de recompensas **ClickPlusRewards**.
  - A pontuação é calculada multiplicando a distância percorrida pelo cliente por um fator de peso específico para cada cluster, oferecendo mais pontos para os clientes de maior valor.
  - Os pontos acumulados podem ser convertidos em reais, onde cada ponto equivale a **R$ 0,40**.

### 4\. Previsão de Comportamento do Cliente

Dois modelos de machine learning foram desenvolvidos para prever o comportamento futuro dos clientes:

  - **Previsão de Retorno de Compra:** Um modelo de **Random Forest Classifier** foi treinado para prever se um cliente fará uma nova compra em até 90 dias, com base em features como recência da última compra e valor total gasto. O modelo alcançou uma acurácia de **73%**.
  - **Previsão de Próximo Trecho:** Outro modelo de **Random Forest Classifier** foi utilizado para prever a próxima rota que um cliente irá comprar, com base em seu histórico de viagens. Com foco nas 20 rotas mais populares, o modelo demonstrou uma alta acurácia de **85%**.

-----

## 📽️ Apresentação do Projeto

Você pode assistir à apresentação completa do projeto neste link: [Pitch ClickPlus Rewards](https://www.youtube.com/watch?v=3mRAdfMfL_w)

-----


## 🛠️ Tecnologias e Bibliotecas

  - **Python**
  - **Pandas**: Manipulação e análise de dados.
  - **Numpy**: Suporte a operações matemáticas.
  - **Matplotlib**: Visualização de dados.
  - **Scikit-learn**: Implementação dos modelos de machine learning (K-Means e Random Forest).
  - **Google Maps API**: Cálculo de distâncias entre municípios.
  - **Banco de dados PostgreSQL**: Armazenamento de dados da ClickPlus Rewards.

-----

## 📈 Como Utilizar e Contribuir

Para rodar este projeto, você precisará de uma chave de API do Google Maps. Crie um arquivo `calcKMs.py` e adicione sua chave.

```python
API_KEY = "SUA_CHAVE_AQUI"

def calcular_distancia(origem, destino, api_key):
    # lógica da função
    pass
```

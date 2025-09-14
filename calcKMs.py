import requests

API_KEY = ""  # adicione aqui a sua chave

# Função para calcular a distância entre dois locais usando a API do Google Maps
def calcular_distancia(origem, destino, api_key):
    url = "https://maps.googleapis.com/maps/api/distancematrix/json"
    params = {
        'origins': origem,
        'destinations': destino,
        'units': 'metric',
        'key': api_key
    }

    response = requests.get(url, params=params)

    if response.status_code == 200:
        data = response.json()
        if data['status'] == 'OK':
            elemento = data['rows'][0]['elements'][0]
            if elemento['status'] == 'OK':
                distancia_metros = elemento['distance']['value']
                print(f"Distância de {origem} para {destino}: {distancia_metros / 1000:.2f} km")
                return distancia_metros / 1000  # converte para km
            else:
                print("Erro no elemento:", elemento['status'])
                return None
        else:
            print("Erro na API:", data['status'])
            return None
    else:
        print("Falha na requisição:", response.status_code)
        return None

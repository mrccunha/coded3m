# DriveTracker — CarPlay Driver Tracking App

Aplicativo iOS/CarPlay para controle de motoristas, percursos e monitoramento de velocidade.

## Funcionalidades

### Cadastro de Motoristas
- Nome completo, número e categoria da CNH
- Foto do motorista (câmera ou galeria)
- Histórico de km percorridos por motorista
- Edição e exclusão

### Controle de Viagem
- Seleção do motorista antes de iniciar
- Rastreamento GPS em tempo real (CoreLocation)
- Acumulação de km percorridos
- Registro de pontos a cada 5 s ou 10 m
- Persistência de viagem em andamento (retomada após reinício do app)

### Monitoramento de Velocidade
- Velocidade atual em tempo real
- Velocidade máxima + coordenadas exatas do ponto
- Velocidade mínima (enquanto em movimento) + coordenadas exatas
- Histórico de pontos com hora, velocidade e coordenadas

### Interface CarPlay
- Seleção de motorista diretamente na tela do carro
- Painel ao vivo: velocidade atual, máxima, mínima, distância e duração
- Botão para encerrar a viagem
- Atualização a cada segundo

### App iPhone
- **Painel (aba 1)**: Gauge de velocidade animado, stats em cards, iniciar/encerrar viagem
- **Motoristas (aba 2)**: Lista, cadastro, edição, detalhe com histórico de viagens
- **Viagens (aba 3)**: Lista com filtro por motorista, resumo de km, detalhe completo

### Detalhe de Viagem
- Mapa com rota desenhada (polyline)
- Pins no mapa: início, fim, ponto de vel. máxima (vermelho), ponto de vel. mínima (verde)
- Coordenadas copiáveis de cada evento de velocidade
- Tabela de todos os pontos GPS registrados

## Tecnologias

| Camada | Tecnologia |
|---|---|
| UI iOS | SwiftUI |
| UI CarPlay | CarPlay framework (CPInformationTemplate, CPListTemplate) |
| Persistência | Core Data |
| Localização | CoreLocation |
| Mapas | MapKit |
| Arquitetura | MVVM + Combine |

## Requisitos

- iOS 17.0+
- Xcode 15+
- Dispositivo real para testar CarPlay (ou CarPlay Simulator no Xcode)
- Permissão de localização "Sempre" para rastreamento em background

## Como rodar

1. Abra `DriveTracker/DriveTracker.xcodeproj` no Xcode
2. Configure o Team e Bundle ID em `Signing & Capabilities`
3. Ative a capability **CarPlay** no target
4. Rode no device (ou simulador + CarPlay Simulator via `I/O > External Displays > CarPlay`)

## Estrutura do Projeto

```
DriveTracker/
├── App/
│   ├── DriveTrackerApp.swift       # @main, env setup
│   └── AppDelegate.swift           # Scene configs (iOS + CarPlay)
├── CarPlay/
│   ├── CarPlaySceneDelegate.swift  # Conecta ao CPInterfaceController
│   └── CarPlayTemplateManager.swift# Templates e atualização do painel
├── Models/
│   ├── Driver.swift                # NSManagedObject
│   ├── Trip.swift                  # NSManagedObject com helpers
│   └── RoutePoint.swift            # NSManagedObject + SpeedAnnotation
├── Services/
│   ├── LocationService.swift       # CLLocationManager wrapper
│   ├── TripManager.swift           # Lógica de viagem + cálculo km/velocidade
│   └── PersistenceController.swift # Core Data stack
├── ViewModels/
│   ├── DriversViewModel.swift      # CRUD motoristas
│   └── TripsViewModel.swift        # Lista e filtro de viagens
├── Views/
│   ├── ContentView.swift           # TabView raiz
│   ├── Dashboard/
│   │   └── DashboardView.swift     # Gauge + cards ao vivo
│   ├── Drivers/
│   │   ├── DriversListView.swift   # Lista + detalhe
│   │   └── AddDriverView.swift     # Cadastro e edição
│   └── Trips/
│       ├── TripsListView.swift     # Lista com filtro
│       ├── TripDetailView.swift    # Stats + tabela de pontos
│       └── TripMapView.swift       # MKMapView com rota e pins
└── DriveTracker.xcdatamodeld/      # Schema Core Data
```

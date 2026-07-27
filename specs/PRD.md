# PRD — RubyAPI

**Versão:** 2.0 (reestruturado em formato SDD)
**Status:** Em elaboração
**Autor:** Bruno Queiroz
**Metodologia:** Spec Driven Development (SDD)

---

## Changelog do Documento

| Versão | Data       | Alteração                                                            |
|--------|------------|-----------------------------------------------------------------------|
| 1.0    | -          | PRD original em prosa livre                                          |
| 2.0    | 2026-07-26 | Reestruturação em RF-XX/T-XX, ADR-lite, Given/When/Then, fases v0.1–v1.0 |

---

## 1. Visão Geral

RubyAPI é um framework web para Ruby inspirado no FastAPI, com objetivo de oferecer produtividade equivalente combinando a expressividade do Ruby com tipagem opcional, validação declarativa e documentação OpenAPI automática. O framework prioriza baixo footprint de memória, inicialização rápida e uma API minimalista sobre Rack, com suporte prioritário ao servidor Falcon.

## 2. Objetivos

### 2.1 Objetivos principais
- Permitir a criação de uma API REST funcional em menos de 5 minutos.
- Reduzir boilerplate frente a Rails API/Sinatra.
- Oferecer validação e conversão automática de tipos em path/query/body.
- Gerar documentação OpenAPI 100% automática, sem configuração adicional.
- Manter sintaxe limpa e idiomática em Ruby.
- Prover arquitetura extensível via sistema de plugins.

### 2.2 Objetivos secundários (pós-v1.0)
WebSockets, Server-Sent Events, Background Jobs, ecossistema de plugins, CLI completa, deploy simplificado.

## 3. Público-alvo
Desenvolvedores Ruby vindos de Sinatra, Rails API ou Hanami; desenvolvedores FastAPI migrando para Ruby; times construindo microsserviços e backends para SPA/mobile.

## 4. Fora de Escopo (v0.1–v1.0)
- Suporte a linguagens além de Ruby 3.3+.
- ORM próprio (integração via plugins ActiveRecord/Sequel, não substituição).
- GraphQL (não previsto no roadmap atual).
- Admin UI / painel administrativo.

---

## 5. Decisões de Arquitetura (ADR-lite)

### ADR-001: Servidor de aplicação prioritário
- **Contexto:** Framework precisa rodar sobre um app server Rack-compatível.
- **Decisão:** Falcon é o servidor de referência (suporte nativo a HTTP/2 e fibers para I/O não-bloqueante); Puma é suportado como fallback compatível.
- **Consequência:** Recursos que dependem de concorrência via fibers (streaming, SSE futuro) assumem Falcon como alvo primário de testes de performance.
- **Alternativas rejeitadas:** Puma como padrão único (não oferece fibers nativas), servidor HTTP próprio (esforço desproporcional ao MVP).

### ADR-002: Tipagem opcional via DSL própria (não Sorbet/RBS)
- **Contexto:** FastAPI usa type hints nativos do Python; Ruby não tem tipagem estática nativa madura o suficiente para essa DX no MVP.
- **Decisão:** Tipagem declarada via DSL própria do RubyAPI (`params: { id: Integer }`), com conversão e validação em runtime.
- **Consequência:** Sem checagem estática; validação ocorre apenas em request-time. Abre porta para adaptador Sorbet/RBS como plugin futuro (pós-v1.0).
- **Alternativas rejeitadas:** Exigir Sorbet (aumenta curva de aprendizado, contraria objetivo de simplicidade).

### ADR-003: Roteamento O(1)/trie-based
- **Contexto:** Meta de performance exige roteamento eficiente mesmo com centenas de rotas.
- **Decisão:** Implementar router baseado em trie/radix tree com suporte a path params, em vez de iteração linear com regex.
- **Consequência:** Maior complexidade de implementação inicial, mas necessário para meta de <50ms de boot e throughput competitivo.

### ADR-004: Serialização JSON sem reflection pesada
- **Contexto:** Reflection excessiva em runtime é citada como anti-meta de performance.
- **Decisão:** Schemas (`RubyAPI::Schema`) pré-compilam a lista de campos e tipos na definição da classe (load-time), não a cada request.
- **Consequência:** `field` gera métodos otimizados via `define_method` em tempo de carregamento da classe, não via `method_missing` em runtime.

### ADR-005: Sistema de plugins com registro explícito
- **Contexto:** Plugins precisam estender rotas, middlewares, hooks, comandos CLI e OpenAPI sem acoplamento forte ao core.
- **Decisão:** Plugins implementam uma interface `RubyAPI::Plugin` com hooks de ciclo de vida (`on_load`, `register_routes`, `register_cli`), registrados explicitamente via `plugin NomeDoPlugin`.
- **Consequência:** Sem auto-discovery mágico no MVP; plugins precisam ser requeridos e registrados manualmente. Auto-discovery pode ser avaliado pós-v1.0.

---

## 6. Convenções do Projeto

- **Commits:** `ADD` para novas features, `TEST` para testes, `FIX` para correção de bugs (não usar Conventional Commits).
- **Rastreamento de progresso:** ver `CONTEXT.md`, com checklist atômico por tarefa (T-XX).
- **README.md:** deve ser mantido atualizado a cada fase com instruções de configuração, execução local e deploy (Falcon/Puma), refletindo o estado real do projeto a cada release.
- **Testes:** RSpec, cobertura mínima de 90% desde o MVP.

---

## 7. Requisitos Funcionais por Fase

### FASE MVP — v0.1

#### RF-01: Roteamento básico
O framework deve suportar registro de rotas para os métodos GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD, incluindo agrupamento via `group`.

**Critérios de aceite:**
- **Given** uma aplicação com `get "/users" do ... end` definida
  **When** uma requisição GET é feita para `/users`
  **Then** o bloco correspondente é executado e sua resposta é retornada.
- **Given** rotas agrupadas em `group "/api" do group "/v1" do get "/users" end end`
  **When** uma requisição GET é feita para `/api/v1/users`
  **Then** a rota é resolvida corretamente.
- **Given** uma rota não registrada
  **When** uma requisição é feita para ela
  **Then** o framework retorna 404.

#### RF-02: Extração de parâmetros (path, query, body)
O framework deve extrair automaticamente path params, query params e JSON body, disponibilizando-os no contexto da rota.

**Critérios de aceite:**
- **Given** uma rota `get "/users/:id"`
  **When** requisitada como `/users/10`
  **Then** `id` é acessível no bloco com valor `"10"` (string, antes de conversão de tipo).
- **Given** uma requisição `GET /users?page=2`
  **When** o bloco acessa `params[:page]`
  **Then** o valor `"2"` é retornado.
- **Given** um POST com corpo `{"name":"John"}` e `Content-Type: application/json`
  **When** o bloco acessa `body[:name]` ou `body.name`
  **Then** o valor `"John"` é retornado.

#### RF-03: Conversão e validação automática de tipos
Parâmetros declarados com tipo (`id: Integer`) devem ser convertidos automaticamente; falhas de conversão retornam 422.

**Critérios de aceite:**
- **Given** uma rota `get "/users/:id", params: { id: Integer }`
  **When** requisitada como `/users/10`
  **Then** `id` é entregue ao bloco como `Integer` com valor `10`.
- **Given** a mesma rota
  **When** requisitada como `/users/abc`
  **Then** a resposta é `422` com corpo `{"error": "id must be Integer"}`.
- **Given** tipos suportados (String, Integer, Float, Boolean, Date, Time, DateTime, Array, Hash, UUID, Decimal, Symbol)
  **When** cada tipo é usado em uma declaração de parâmetro
  **Then** a conversão funciona conforme a tabela de tipos documentada.

#### RF-04: Serialização automática de resposta
Qualquer valor Ruby retornado por uma rota (Hash, Array, objeto com serializer) deve ser serializado automaticamente para JSON.

**Critérios de aceite:**
- **Given** um bloco de rota que retorna `{ message: "Hello World" }`
  **When** a rota é chamada
  **Then** a resposta HTTP tem `Content-Type: application/json` e corpo `{"message":"Hello World"}`.
- **Given** um objeto de domínio (`User.new(...)`) com um Serializer associado
  **When** retornado por uma rota
  **Then** o Serializer é usado para gerar o JSON de saída.

#### RF-05: Middlewares compatíveis com Rack
O framework deve permitir registrar middlewares Rack-compatíveis via `use`.

**Critérios de aceite:**
- **Given** um middleware Rack válido registrado via `use LoggerMiddleware`
  **When** uma requisição passa pela aplicação
  **Then** o middleware é executado na ordem de registro, antes do handler da rota.

#### RF-06: Hooks globais e por rota
O framework deve suportar hooks `before`/`after` globais e escopados a uma rota específica.

**Critérios de aceite:**
- **Given** um hook `before` global
  **When** qualquer rota é chamada
  **Then** o hook é executado antes do handler.
- **Given** um hook `before` definido dentro de uma rota específica
  **When** apenas essa rota é chamada
  **Then** o hook é executado somente para essa rota, não para as demais.

#### RF-07: OpenAPI básico + Swagger UI
O framework deve gerar `/openapi.json` automaticamente a partir das rotas registradas, e servir Swagger UI em `/docs`.

**Critérios de aceite:**
- **Given** uma aplicação com rotas registradas
  **When** `/openapi.json` é requisitado
  **Then** a resposta contém um documento OpenAPI válido listando as rotas, parâmetros e métodos.
- **Given** a mesma aplicação
  **When** `/docs` é acessado via navegador
  **Then** a Swagger UI é renderizada consumindo `/openapi.json`.

#### RF-08: CLI mínima
A CLI deve suportar `rubyapi new`, `rubyapi server`.

**Critérios de aceite:**
- **Given** o comando `rubyapi new blog`
  **When** executado em um diretório vazio
  **Then** a estrutura de projeto padrão é criada (app/, config/, config.ru, Gemfile, rubyapi.rb, test/, public/).
- **Given** um projeto válido
  **When** `rubyapi server` é executado
  **Then** o servidor sobe em modo produção usando Falcon (ou Puma como fallback).

#### RF-09: Suíte RSpec configurada
Todo projeto gerado por `rubyapi new` deve vir com RSpec configurado e pelo menos um teste de exemplo passando.

**Critérios de aceite:**
- **Given** um projeto recém-criado via `rubyapi new`
  **When** `bundle exec rspec` é executado
  **Then** a suíte roda sem erros de configuração e o teste de exemplo passa.

#### RF-NF-01: Performance mínima (MVP)
- Inicialização da aplicação mínima: **< 50ms**.
- Roteamento: complexidade O(1) ou próxima disso para lookup de rota exata.
- Memória: **< 2MB** para aplicação mínima em idle.

**Critérios de aceite:**
- **Given** uma aplicação mínima (`get "/hello"`)
  **When** medido o tempo entre `require "rubyapi"` e o servidor pronto para aceitar requisições
  **Then** o tempo é inferior a 50ms em benchmark de CI.

---

### FASE v0.2

#### RF-10: Schemas (`RubyAPI::Schema`)
Suporte a definição de schemas com `field :nome, Tipo`, usados para validação de body em rotas POST/PUT/PATCH.

**Critérios de aceite:**
- **Given** um `UserSchema` com `field :name, String` e `field :age, Integer`
  **When** uma rota declara `body UserSchema` e recebe um payload válido
  **Then** os campos ficam disponíveis validados e tipados no contexto da rota.
- **Given** a mesma rota
  **When** o payload recebido não satisfaz o schema (campo faltando ou tipo incorreto)
  **Then** a resposta é 422 com detalhamento dos erros de validação por campo.

#### RF-11: Upload de arquivos
Suporte a multipart/form-data com extração de arquivos enviados.

**Critérios de aceite:**
- **Given** uma rota que espera um upload
  **When** uma requisição multipart com um arquivo é enviada
  **Then** o arquivo é acessível no contexto da rota com nome, tipo MIME e conteúdo.

#### RF-12: Cookies e Sessions
Suporte à leitura/escrita de cookies e sessão baseada em cookie assinado.

**Critérios de aceite:**
- **Given** uma rota que define `session[:user_id] = 1`
  **When** uma requisição subsequente do mesmo cliente é feita
  **Then** `session[:user_id]` retorna `1`.

#### RF-13: Tratamento de erros customizável
Suporte a `rescue_from` mapeando exceções para respostas HTTP.

**Critérios de aceite:**
- **Given** `rescue_from ActiveRecord::RecordNotFound` mapeado para 404
  **When** um handler de rota levanta essa exceção
  **Then** a resposta HTTP é 404 com corpo de erro padronizado.

#### RF-14: Configuração por ambiente
Suporte a configuração distinta por `development`, `test`, `production` via `config/environments/`.

**Critérios de aceite:**
- **Given** variável `RUBYAPI_ENV=production`
  **When** a aplicação inicia
  **Then** as configurações de `config/environments/production.rb` são carregadas, sobrepondo defaults.

---

### FASE v0.3

#### RF-15: Dependency Injection
Suporte a `inject` e `depends` para resolução de dependências (ex: usuário autenticado atual).

**Critérios de aceite:**
- **Given** uma classe `CurrentUser` registrada como dependência
  **When** uma rota declara `inject CurrentUser`
  **Then** a instância resolvida é injetada no contexto antes da execução do handler.
- **Given** `depends Authentication` em uma rota
  **When** a autenticação falha
  **Then** a rota não é executada e uma resposta 401 é retornada automaticamente.

#### RF-16: Sistema de Plugins (base)
Interface `RubyAPI::Plugin` conforme ADR-005, com registro via `plugin NomeDoPlugin`.

**Critérios de aceite:**
- **Given** um plugin válido implementando `register_routes` e `register_cli`
  **When** registrado via `plugin MeuPlugin`
  **Then** suas rotas e comandos CLI ficam disponíveis na aplicação.

#### RF-17: Cache, CORS, JWT, Autenticação (como plugins oficiais)
Plugins de primeira parte usando a interface do RF-16.

**Critérios de aceite:**
- **Given** `plugin CORS` configurado com origens permitidas
  **When** uma requisição OPTIONS (preflight) é feita de uma origem permitida
  **Then** os headers CORS corretos são retornados.
- **Given** `plugin JWT` configurado
  **When** uma rota protegida recebe um token JWT válido no header `Authorization`
  **Then** o payload decodificado fica disponível no contexto da rota.

#### RF-18: Logging estruturado e métricas
Logs em formato estruturado (JSON) e exposição de métricas básicas (contagem de requests, latência).

**Critérios de aceite:**
- **Given** o middleware de logging estruturado ativo
  **When** uma requisição é processada
  **Then** uma linha de log JSON é emitida contendo método, path, status e duração em ms.

---

### FASE v0.4

#### RF-19: WebSockets
Suporte a rotas WebSocket via Falcon.

**Critérios de aceite:**
- **Given** uma rota `websocket "/ws"` definida
  **When** um cliente estabelece conexão WebSocket
  **Then** o handler recebe e pode enviar mensagens na conexão.

#### RF-20: Server-Sent Events (SSE)
Suporte a streaming de eventos via SSE.

**Critérios de aceite:**
- **Given** uma rota que usa `stream do |out| ... end` com eventos SSE
  **When** um cliente se conecta
  **Then** eventos são recebidos incrementalmente sem fechar a conexão.

#### RF-21: Streaming de respostas
Suporte a respostas HTTP em streaming (chunked).

#### RF-22: Background Jobs
Suporte a enfileiramento e execução assíncrona de jobs.

**Critérios de aceite:**
- **Given** um job definido e enfileirado via `SomeJob.enqueue(args)`
  **When** um worker está ativo
  **Then** o job é executado de forma assíncrona e seu resultado/erro é registrado.

---

### FASE v1.0

#### RF-23: Estabilização de API pública
Nenhuma breaking change sem major version bump; API pública documentada e congelada.

#### RF-24: Benchmark oficial
Suíte de benchmark comparando RubyAPI a Sinatra e Hanami API em throughput, latência e uso de memória, publicada no README.

#### RF-25: Publicação no RubyGems
Gem publicada e versionada seguindo SemVer, compatível com Ruby 3.3+.

---

## 8. Critérios de Sucesso Globais

| Indicador                              | Meta                                  |
|-----------------------------------------|----------------------------------------|
| Tempo para criar uma API funcional      | < 5 minutos                            |
| Cobertura de testes                     | ≥ 90%                                  |
| Inicialização da aplicação              | < 50 ms                                |
| Documentação OpenAPI                    | 100% automática                        |
| Conversão automática de tipos           | Todos os tipos básicos suportados      |
| Hot Reload                              | Disponível em modo desenvolvimento     |
| Compatibilidade                         | Rack, Puma e Falcon                    |
| Extensibilidade                         | Sistema de plugins estável             |

## 9. Diferenciais Competitivos
- Sintaxe inspirada no FastAPI, adaptada às convenções idiomáticas do Ruby.
- Tipagem opcional e explícita, sem obrigatoriedade (ADR-002).
- Geração automática de OpenAPI e Swagger UI sem configuração adicional.
- Conversão e validação automática de parâmetros de rota, query e corpo da requisição.
- Arquitetura modular orientada a plugins (ADR-005).
- Foco em desempenho e baixo consumo de memória.
- Experiência de desenvolvimento moderna: CLI, hot reload e testes configurados desde a criação do projeto.

## 10. Próximos Passos
1. Validar RF-01 a RF-09 (MVP) com protótipo funcional mínimo.
2. Rodar benchmark preliminar de boot time e roteamento antes de comprometer com ADR-003 (radix tree) em produção.
3. Detalhar RFC de arquitetura interna (Router, Context, Request, Validator, Schema, OpenAPI Generator, DI, ciclo de vida da requisição) como documento complementar a este PRD.

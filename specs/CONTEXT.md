# CONTEXT.md — FastRb

## Contexto Geral do Projeto

FastRb é um framework web Ruby inspirado no FastAPI. Ver `PRD.md` para requisitos completos, critérios de aceite (Given/When/Then) e ADRs. Este documento serve para rastreamento de progresso via tarefas atômicas (T-XX), ligadas aos requisitos funcionais (RF-XX) do PRD.

**Convenção de commits:** `ADD` (nova feature), `TEST` (testes), `FIX` (correção de bug). Não usar Conventional Commits.

**Stack de referência:**
- Ruby 3.3+
- Rack (compatibilidade), Falcon (servidor primário), Puma (fallback)
- RSpec (testes, meta ≥90% cobertura)
- Sem dependências pesadas de metaprogramação em runtime (ver ADR-004)

**README.md:** deve ser atualizado a cada tarefa que altere configuração, comandos CLI ou passos de deploy.

---

## Estado Atual
- [x] Fase MVP (v0.1) — concluída
- [x] Fase v0.2 — concluída
- [x] Fase v0.3 — concluída
- [x] Fase v0.4 — concluída
- [ ] Fase v1.0 — não iniciada

---

## MVP — v0.1

### RF-01: Roteamento básico
- [x] T-01: Implementar classe `RubyAPI::Router` com estrutura de dados trie/radix (ver ADR-003)
- [x] T-02: Suportar registro de rotas para GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD
- [x] T-03: Implementar `group` para prefixos de rota aninhados
- [x] T-04: Implementar resolução de rota não encontrada → 404
- [x] T-05 (TEST): Testes RSpec cobrindo os 3 critérios de aceite de RF-01

### RF-02: Extração de parâmetros
- [x] T-06: Implementar extração de path params a partir do pattern da rota (`:id`)
- [x] T-07: Implementar parsing de query string para `params`
- [x] T-08: Implementar parsing de JSON body para `body`, com acesso via `body[:x]` e `body.x`
- [x] T-09 (TEST): Testes RSpec cobrindo os 3 critérios de aceite de RF-02

### RF-03: Conversão e validação automática de tipos
- [x] T-10: Implementar conversores para String, Integer, Float, Boolean, Date, Time, DateTime, Array, Hash, UUID, Decimal, Symbol
- [x] T-11: Implementar DSL `params: { id: Integer }` na declaração de rota
- [x] T-12: Implementar resposta 422 padronizada em caso de falha de conversão
- [x] T-13 (TEST): Testes RSpec para cada tipo suportado, incluindo caso de erro (`/users/abc`)

### RF-04: Serialização automática
- [x] T-14: Implementar serialização automática de Hash/Array para JSON no Response
- [x] T-15: Implementar interface `Serializer` para objetos de domínio
- [x] T-16 (TEST): Testes RSpec cobrindo serialização de Hash e de objeto com Serializer

### RF-05: Middlewares Rack
- [x] T-17: Implementar `use` para registro de middlewares compatíveis com Rack
- [x] T-18: Garantir ordem de execução respeitando ordem de registro
- [x] T-19 (TEST): Teste RSpec com middleware de exemplo (ex: logger) validando execução antes do handler

### RF-06: Hooks
- [x] T-20: Implementar `before`/`after` globais
- [x] T-21: Implementar `before`/`after` escopados por rota
- [x] T-22 (TEST): Testes RSpec validando escopo global vs. por rota

### RF-07: OpenAPI + Swagger UI
- [x] T-23: Implementar gerador de documento OpenAPI a partir do registro de rotas
- [x] T-24: Expor `/openapi.json`
- [x] T-25: Servir Swagger UI estática em `/docs` consumindo `/openapi.json`
- [x] T-26 (TEST): Teste RSpec validando estrutura mínima do OpenAPI gerado

### RF-08: CLI mínima
- [x] T-27: Implementar `fastrb new <nome>` gerando estrutura de projeto padrão
- [x] T-28: Implementar `fastrb server` com boot via Falcon (fallback Puma)
- [x] T-29 (TEST): Teste de integração validando estrutura de diretórios gerada por `fastrb new`

### RF-09: RSpec configurado
- [x] T-30: Template de projeto gerado inclui `.rspec`, `spec_helper.rb` e um spec de exemplo
- [x] T-31 (TEST): Validar que `bundle exec rspec` roda sem erro em projeto recém-gerado

### RF-NF-01: Performance MVP
- [x] T-32: Benchmark de boot time (`require "fastrb"` até servidor pronto) em CI, meta < 50ms
- [x] T-33: Benchmark de memória em idle para app mínima, meta < 2MB
- [x] T-34 (TEST): Adicionar benchmarks ao CI com limite de regressão

### Documentação
- [x] T-35: Atualizar README.md com instruções de instalação, `fastrb new`, `fastrb server`, e requisitos (Ruby 3.3+, Falcon/Puma)

---

## v0.2

### RF-10: Schemas
- [x] T-36: Implementar `RubyAPI::Schema` com DSL `field :nome, Tipo`
- [x] T-37: Implementar pré-compilação de campos em load-time (ver ADR-004)
- [x] T-38: Implementar `body UserSchema` em declaração de rota, com validação automática
- [x] T-39: Implementar resposta 422 com erros de validação por campo
- [x] T-40 (TEST): Testes RSpec cobrindo schema válido e inválido

### RF-11: Upload de arquivos
- [x] T-41: Implementar parsing de multipart/form-data
- [x] T-42: Expor arquivos recebidos no contexto da rota (nome, MIME, conteúdo)
- [x] T-43 (TEST): Teste RSpec de upload simples

### RF-12: Cookies e Sessions
- [x] T-44: Implementar leitura/escrita de cookies
- [x] T-45: Implementar sessão baseada em cookie assinado
- [x] T-46 (TEST): Teste RSpec de persistência de sessão entre requisições

### RF-13: Tratamento de erros
- [x] T-47: Implementar `rescue_from` mapeando exceção → status HTTP
- [x] T-48 (TEST): Teste RSpec validando mapeamento de exceção customizada

### RF-14: Configuração por ambiente
- [x] T-49: Implementar carregamento de `config/environments/{env}.rb`
- [x] T-50: Implementar leitura de `FASTRB_ENV`
- [x] T-51 (TEST): Teste validando override de config por ambiente
- [x] T-52: Atualizar README.md com instruções de configuração por ambiente

---

## v0.3

### RF-15: Dependency Injection
- [x] T-53: Implementar `inject` para resolução de dependências no contexto da rota
- [x] T-54: Implementar `depends` com curto-circuito de execução (ex: 401 em falha de auth)
- [x] T-55 (TEST): Testes RSpec cobrindo injeção e curto-circuito

### RF-16: Sistema de Plugins (base)
- [x] T-56: Definir interface `RubyAPI::Plugin` (ver ADR-005)
- [x] T-57: Implementar `plugin NomeDoPlugin` com hooks `on_load`, `register_routes`, `register_cli`
- [x] T-58 (TEST): Teste com plugin de exemplo registrando rota e comando CLI

### RF-17: Plugins oficiais (Cache, CORS, JWT, Auth)
- [x] T-59: Implementar plugin CORS
- [x] T-60: Implementar plugin JWT
- [x] T-61: Implementar plugin de Autenticação básica
- [x] T-62: Implementar plugin de Cache
- [x] T-63 (TEST): Testes RSpec para cada plugin oficial

### RF-18: Logging estruturado e métricas
- [x] T-64: Implementar middleware de logging estruturado (JSON)
- [x] T-65: Implementar coleta básica de métricas (contagem, latência)
- [x] T-66 (TEST): Teste validando formato do log estruturado

---

## v0.4

### RF-19: WebSockets
- [x] T-67: Implementar suporte a rotas `websocket` via Falcon
- [x] T-68 (TEST): Teste de conexão e troca de mensagens WebSocket

### RF-20: SSE
- [x] T-69: Implementar `stream` com suporte a eventos SSE
- [x] T-70 (TEST): Teste de recepção incremental de eventos

### RF-21: Streaming de respostas
- [x] T-71: Implementar suporte a respostas chunked
- [x] T-72 (TEST): Teste de streaming de resposta HTTP

### RF-22: Background Jobs
- [x] T-73: Implementar API de enfileiramento (`Job.enqueue`)
- [x] T-74: Implementar worker de execução assíncrona
- [x] T-75 (TEST): Teste de execução e registro de erro de job

---

## v1.0

### RF-23: Estabilização de API pública
- [ ] T-76: Auditoria de API pública e congelamento de assinatura
- [ ] T-77: Definir política de SemVer e breaking changes

### RF-24: Benchmark oficial
- [ ] T-78: Implementar suíte de benchmark comparando FastRb, Sinatra e Hanami API
- [ ] T-79: Publicar resultados no README.md

### RF-25: Publicação no RubyGems
- [ ] T-80: Preparar gemspec, versionamento SemVer
- [ ] T-81: Publicar gem no RubyGems
- [ ] T-82: Atualizar README.md com instruções de instalação via `gem install fastrb`

---

## Notas para Agentes de Execução (Claude Code / Codex / OpenCode)
- Sempre consultar `PRD.md` para o critério de aceite completo (Given/When/Then) antes de marcar uma tarefa como concluída.
- Cada tarefa T-XX deve resultar em ao menos um commit `ADD` ou `FIX`, seguido de um commit `TEST` correspondente quando aplicável.
- Ao concluir uma tarefa que altere comandos, configuração ou deploy, atualizar o README.md como parte da mesma tarefa, não como tarefa separada.
- Não iniciar tarefas de uma fase seguinte antes de todas as tarefas RF da fase atual estarem concluídas, salvo dependência técnica explícita.

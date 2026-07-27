# CONTEXT.md — RubyAPI

## Contexto Geral do Projeto

RubyAPI é um framework web Ruby inspirado no FastAPI. Ver `PRD.md` para requisitos completos, critérios de aceite (Given/When/Then) e ADRs. Este documento serve para rastreamento de progresso via tarefas atômicas (T-XX), ligadas aos requisitos funcionais (RF-XX) do PRD.

**Convenção de commits:** `ADD` (nova feature), `TEST` (testes), `FIX` (correção de bug). Não usar Conventional Commits.

**Stack de referência:**
- Ruby 3.3+
- Rack (compatibilidade), Falcon (servidor primário), Puma (fallback)
- RSpec (testes, meta ≥90% cobertura)
- Sem dependências pesadas de metaprogramação em runtime (ver ADR-004)

**README.md:** deve ser atualizado a cada tarefa que altere configuração, comandos CLI ou passos de deploy.

---

## Estado Atual
- [ ] Fase MVP (v0.1) — não iniciada
- [ ] Fase v0.2 — não iniciada
- [ ] Fase v0.3 — não iniciada
- [ ] Fase v0.4 — não iniciada
- [ ] Fase v1.0 — não iniciada

---

## MVP — v0.1

### RF-01: Roteamento básico
- [ ] T-01: Implementar classe `RubyAPI::Router` com estrutura de dados trie/radix (ver ADR-003)
- [ ] T-02: Suportar registro de rotas para GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD
- [ ] T-03: Implementar `group` para prefixos de rota aninhados
- [ ] T-04: Implementar resolução de rota não encontrada → 404
- [ ] T-05 (TEST): Testes RSpec cobrindo os 3 critérios de aceite de RF-01

### RF-02: Extração de parâmetros
- [ ] T-06: Implementar extração de path params a partir do pattern da rota (`:id`)
- [ ] T-07: Implementar parsing de query string para `params`
- [ ] T-08: Implementar parsing de JSON body para `body`, com acesso via `body[:x]` e `body.x`
- [ ] T-09 (TEST): Testes RSpec cobrindo os 3 critérios de aceite de RF-02

### RF-03: Conversão e validação automática de tipos
- [ ] T-10: Implementar conversores para String, Integer, Float, Boolean, Date, Time, DateTime, Array, Hash, UUID, Decimal, Symbol
- [ ] T-11: Implementar DSL `params: { id: Integer }` na declaração de rota
- [ ] T-12: Implementar resposta 422 padronizada em caso de falha de conversão
- [ ] T-13 (TEST): Testes RSpec para cada tipo suportado, incluindo caso de erro (`/users/abc`)

### RF-04: Serialização automática
- [ ] T-14: Implementar serialização automática de Hash/Array para JSON no Response
- [ ] T-15: Implementar interface `Serializer` para objetos de domínio
- [ ] T-16 (TEST): Testes RSpec cobrindo serialização de Hash e de objeto com Serializer

### RF-05: Middlewares Rack
- [ ] T-17: Implementar `use` para registro de middlewares compatíveis com Rack
- [ ] T-18: Garantir ordem de execução respeitando ordem de registro
- [ ] T-19 (TEST): Teste RSpec com middleware de exemplo (ex: logger) validando execução antes do handler

### RF-06: Hooks
- [ ] T-20: Implementar `before`/`after` globais
- [ ] T-21: Implementar `before`/`after` escopados por rota
- [ ] T-22 (TEST): Testes RSpec validando escopo global vs. por rota

### RF-07: OpenAPI + Swagger UI
- [ ] T-23: Implementar gerador de documento OpenAPI a partir do registro de rotas
- [ ] T-24: Expor `/openapi.json`
- [ ] T-25: Servir Swagger UI estática em `/docs` consumindo `/openapi.json`
- [ ] T-26 (TEST): Teste RSpec validando estrutura mínima do OpenAPI gerado

### RF-08: CLI mínima
- [ ] T-27: Implementar `rubyapi new <nome>` gerando estrutura de projeto padrão
- [ ] T-28: Implementar `rubyapi server` com boot via Falcon (fallback Puma)
- [ ] T-29 (TEST): Teste de integração validando estrutura de diretórios gerada por `rubyapi new`

### RF-09: RSpec configurado
- [ ] T-30: Template de projeto gerado inclui `.rspec`, `spec_helper.rb` e um spec de exemplo
- [ ] T-31 (TEST): Validar que `bundle exec rspec` roda sem erro em projeto recém-gerado

### RF-NF-01: Performance MVP
- [ ] T-32: Benchmark de boot time (`require "rubyapi"` até servidor pronto) em CI, meta < 50ms
- [ ] T-33: Benchmark de memória em idle para app mínima, meta < 2MB
- [ ] T-34 (TEST): Adicionar benchmarks ao CI com limite de regressão

### Documentação
- [ ] T-35: Atualizar README.md com instruções de instalação, `rubyapi new`, `rubyapi server`, e requisitos (Ruby 3.3+, Falcon/Puma)

---

## v0.2

### RF-10: Schemas
- [ ] T-36: Implementar `RubyAPI::Schema` com DSL `field :nome, Tipo`
- [ ] T-37: Implementar pré-compilação de campos em load-time (ver ADR-004)
- [ ] T-38: Implementar `body UserSchema` em declaração de rota, com validação automática
- [ ] T-39: Implementar resposta 422 com erros de validação por campo
- [ ] T-40 (TEST): Testes RSpec cobrindo schema válido e inválido

### RF-11: Upload de arquivos
- [ ] T-41: Implementar parsing de multipart/form-data
- [ ] T-42: Expor arquivos recebidos no contexto da rota (nome, MIME, conteúdo)
- [ ] T-43 (TEST): Teste RSpec de upload simples

### RF-12: Cookies e Sessions
- [ ] T-44: Implementar leitura/escrita de cookies
- [ ] T-45: Implementar sessão baseada em cookie assinado
- [ ] T-46 (TEST): Teste RSpec de persistência de sessão entre requisições

### RF-13: Tratamento de erros
- [ ] T-47: Implementar `rescue_from` mapeando exceção → status HTTP
- [ ] T-48 (TEST): Teste RSpec validando mapeamento de exceção customizada

### RF-14: Configuração por ambiente
- [ ] T-49: Implementar carregamento de `config/environments/{env}.rb`
- [ ] T-50: Implementar leitura de `RUBYAPI_ENV`
- [ ] T-51 (TEST): Teste validando override de config por ambiente
- [ ] T-52: Atualizar README.md com instruções de configuração por ambiente

---

## v0.3

### RF-15: Dependency Injection
- [ ] T-53: Implementar `inject` para resolução de dependências no contexto da rota
- [ ] T-54: Implementar `depends` com curto-circuito de execução (ex: 401 em falha de auth)
- [ ] T-55 (TEST): Testes RSpec cobrindo injeção e curto-circuito

### RF-16: Sistema de Plugins (base)
- [ ] T-56: Definir interface `RubyAPI::Plugin` (ver ADR-005)
- [ ] T-57: Implementar `plugin NomeDoPlugin` com hooks `on_load`, `register_routes`, `register_cli`
- [ ] T-58 (TEST): Teste com plugin de exemplo registrando rota e comando CLI

### RF-17: Plugins oficiais (Cache, CORS, JWT, Auth)
- [ ] T-59: Implementar plugin CORS
- [ ] T-60: Implementar plugin JWT
- [ ] T-61: Implementar plugin de Autenticação básica
- [ ] T-62: Implementar plugin de Cache
- [ ] T-63 (TEST): Testes RSpec para cada plugin oficial

### RF-18: Logging estruturado e métricas
- [ ] T-64: Implementar middleware de logging estruturado (JSON)
- [ ] T-65: Implementar coleta básica de métricas (contagem, latência)
- [ ] T-66 (TEST): Teste validando formato do log estruturado

---

## v0.4

### RF-19: WebSockets
- [ ] T-67: Implementar suporte a rotas `websocket` via Falcon
- [ ] T-68 (TEST): Teste de conexão e troca de mensagens WebSocket

### RF-20: SSE
- [ ] T-69: Implementar `stream` com suporte a eventos SSE
- [ ] T-70 (TEST): Teste de recepção incremental de eventos

### RF-21: Streaming de respostas
- [ ] T-71: Implementar suporte a respostas chunked
- [ ] T-72 (TEST): Teste de streaming de resposta HTTP

### RF-22: Background Jobs
- [ ] T-73: Implementar API de enfileiramento (`Job.enqueue`)
- [ ] T-74: Implementar worker de execução assíncrona
- [ ] T-75 (TEST): Teste de execução e registro de erro de job

---

## v1.0

### RF-23: Estabilização de API pública
- [ ] T-76: Auditoria de API pública e congelamento de assinatura
- [ ] T-77: Definir política de SemVer e breaking changes

### RF-24: Benchmark oficial
- [ ] T-78: Implementar suíte de benchmark comparando RubyAPI, Sinatra e Hanami API
- [ ] T-79: Publicar resultados no README.md

### RF-25: Publicação no RubyGems
- [ ] T-80: Preparar gemspec, versionamento SemVer
- [ ] T-81: Publicar gem no RubyGems
- [ ] T-82: Atualizar README.md com instruções de instalação via `gem install rubyapi`

---

## Notas para Agentes de Execução (Claude Code / Codex / OpenCode)
- Sempre consultar `PRD.md` para o critério de aceite completo (Given/When/Then) antes de marcar uma tarefa como concluída.
- Cada tarefa T-XX deve resultar em ao menos um commit `ADD` ou `FIX`, seguido de um commit `TEST` correspondente quando aplicável.
- Ao concluir uma tarefa que altere comandos, configuração ou deploy, atualizar o README.md como parte da mesma tarefa, não como tarefa separada.
- Não iniciar tarefas de uma fase seguinte antes de todas as tarefas RF da fase atual estarem concluídas, salvo dependência técnica explícita.

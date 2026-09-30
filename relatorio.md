# Relatório de Processo — Prova do Primeiro Bimestre (DevOps)

**Aluno:** Nicolas de Jesus Silva
**RA:** 6325171
**Disciplina:** DevOps — Análise e Desenvolvimento de Sistemas 2026.2
**Professor:** Alexandre da Costa Tavares Jr
**Ferramenta de IA Utilizada:** Kiro (IDE com agente Spec-Driven integrado)

---

## Questão 1 — A Jornada Completa (Aulas 01 a 07)

A construção da API de Reservas da TechNova foi feita seguindo exatamente a progressão das aulas, porque cada etapa serve de base para a próxima. Começar pelo Git antes de escrever qualquer linha de código foi uma decisão consciente: o versionamento precisa existir desde o início, não como um detalhe final.

**Aula 01 — Git e Versionamento:**
O ponto de partida foi criar o repositório `prova-primeiro-bimestre-devops` no GitHub e configurar o `.gitignore` corretamente, excluindo `node_modules/`, `.env`, `.terraform/`, arquivos `*.tfstate` e `*.pem` desde o primeiro commit. Trabalhar com feature branches desde o início foi importante para simular o fluxo real de desenvolvimento em equipe — a branch `feature/ajustes-entrega-prova` foi criada para isolar as mudanças finais antes do merge na `main`. Os commits seguiram o padrão Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`), o que torna o histórico legível e rastreável por qualquer pessoa que clone o repositório.

**Aula 01/02 — API Node.js e Docker:**
A API foi escrita em Node.js com Express e o driver `pg` para comunicação com o PostgreSQL. A estrutura é simples e direta: um único arquivo `src/index.js` que cria o pool de conexão via variáveis de ambiente, inicializa a tabela `reservas` automaticamente no boot se ela não existir, e registra as seis rotas obrigatórias — `GET /health`, `POST /reservas`, `GET /reservas`, `GET /reservas/:id`, `PUT /reservas/:id` e `DELETE /reservas/:id`. Todas as rotas de CRUD fazem leitura e escrita diretamente no banco PostgreSQL, sem nenhum dado em memória.

O Dockerfile foi construído com multi-stage build: o primeiro estágio (`builder`) usa `node:20-alpine` para instalar somente as dependências de produção com `npm install --omit=dev`, e o segundo estágio copia apenas o necessário e configura um usuário não-root (`expressuser`) para rodar o processo, seguindo a boa prática de segurança de containers.

**Aula 02 — Docker Compose:**
O `docker-compose.yml` orquestra dois serviços: `postgres` (imagem `postgres:15-alpine`) e `api` (build local do Dockerfile). O banco tem um volume nomeado `pgdata` para garantir que os dados sobrevivam a um `docker compose down`. A rede customizada `reservas_net` com driver `bridge` isola os serviços. O healthcheck no serviço `postgres` usa `pg_isready` e o `depends_on` da API usa `condition: service_healthy`, garantindo que o Node.js só tente conectar quando o banco já estiver aceitando conexões. O `.env.example` foi versionado com valores de exemplo (sem senhas reais), e o `.env` real fica no `.gitignore`.

Para validar o ambiente local, os containers foram iniciados com `docker compose up -d --build`, testados com `docker compose ps` (evidência salva em `evidencias/compose-ps.txt`) e validados com chamadas `curl` contra todos os endpoints do CRUD (evidência em `evidencias/curl-crud-tests.txt`). O teste de persistência foi feito reiniciando os containers com `docker compose down && docker compose up -d` e confirmando que os dados ainda existiam no banco.

**Aulas 03 a 05 — Terraform e Módulos AWS:**
Com a aplicação funcionando localmente, o passo seguinte foi modelar a infraestrutura na AWS usando Terraform com estrutura modularizada. Foram criados quatro módulos independentes:

- **`modules/vpc`**: provisiona a VPC com CIDR `10.0.0.0/16`, dois pares de subnets (públicas e privadas) em `us-east-1a` e `us-east-1b`, um Internet Gateway e uma Route Table pública associada às subnets públicas.
- **`modules/security-group`**: cria o SG da EC2 (portas 22 e 3000 abertas para `0.0.0.0/0`) e o SG do RDS (porta 5432 liberada **somente** para o ID do SG da EC2).
- **`modules/ec2`**: instância `t2.micro` na subnet pública com `iam_instance_profile = "LabInstanceProfile"`, user data instalando Docker e clonando a aplicação.
- **`modules/rds`**: banco PostgreSQL `db.t3.micro` nas subnets privadas com `publicly_accessible = false`, `storage_encrypted = true` e `db_subnet_group_name` apontando para as subnets privadas.

A composição dos módulos no `main.tf` raiz passa os outputs de um como inputs de outro — o `vpc_id` e as listas de subnet IDs saem do módulo `vpc` e alimentam os módulos `security-group`, `ec2` e `rds`. O `db_host` sai do módulo `rds` e alimenta o módulo `ec2` via variáveis de ambiente no user data.

**Aula 06 — Remote State (S3 + DynamoDB):**
Antes de configurar o backend no projeto principal, foi necessário criar o bucket S3 e a tabela DynamoDB separadamente, dentro do diretório `infra/backend/`. O AWS Academy impõe uma SCP (Service Control Policy) que bloqueia operações `s3:GetBucketObjectLockConfiguration`, fazendo o provider AWS `~> 5.0` falhar ao tentar gerenciar buckets S3 diretamente via `aws_s3_bucket`. A solução foi usar `terraform_data` com provisioners `local-exec` chamando a AWS CLI para criar o bucket e habilitar o versionamento, contornando a restrição. O `main.tf` raiz aponta para o bucket `tech-nova-tfstate-6325171` com `encrypt = true` e `use_lockfile = true`.

**Aula 07 — IA como Copiloto:**
O Kiro foi usado durante todo o processo como ferramenta de geração de código, mas com validação humana em cada etapa. Os detalhes do processo estão na Questão 2.

---

## Questão 2 — O Processo com IA como Copiloto

A ferramenta utilizada foi o **Kiro**, uma IDE com agente de IA integrado que opera no modo **Spec-Driven** — um fluxo estruturado onde primeiro se define o contrato (o que deve ser construído), depois o design (como será construído) e só então as tarefas de implementação são executadas. Isso é diferente de simplesmente pedir código numa caixa de chat: a IA trabalha dentro de um contexto documentado de requisitos.

### Fluxo de Trabalho Adotado

O processo seguiu três camadas:

1. **Prompts de geração inicial** — pedidos estruturados descrevendo exatamente o que precisava ser criado, com as restrições do ambiente (AWS Academy, `LabInstanceProfile`, sem IAM próprio).
2. **Revisão humana** — leitura de todo código gerado antes de executar qualquer comando.
3. **Prompts de correção** — quando erros apareciam, o contexto do erro era passado integralmente para a IA junto com o comando que falhou.

### Prompts Principais Utilizados

**Prompt 1 — Geração da API Node.js:**
> *"Crie uma API em Node.js com Express e o pacote 'pg' para PostgreSQL. A API gerencia reservas de clientes. Campos da tabela 'reservas': id (SERIAL/PRIMARY KEY), cliente (VARCHAR), data (DATE/TIMESTAMP), status (VARCHAR). Conexão via variáveis de ambiente: DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME. Crie a tabela automaticamente na inicialização se ela não existir. Rotas obrigatórias: GET /health, POST /reservas, GET /reservas, GET /reservas/:id, PUT /reservas/:id, DELETE /reservas/:id. Entregue os arquivos app/package.json e app/src/index.js."*

A IA gerou a estrutura completa e funcional da API com pool de conexão, inicialização automática da tabela e todas as rotas CRUD com tratamento de erro e retorno 404 para recursos não encontrados. O código funcionou na primeira execução local.

**Prompt 2 — Geração da Infraestrutura Terraform:**
> *"Gere a infraestrutura em Terraform modularizada para o AWS Academy Learner Lab (us-east-1). Restrições estritas: Não crie IAM Roles/Policies. Use o IAM Instance Profile 'LabInstanceProfile' na EC2. Módulo VPC: VPC 10.0.0.0/16, 2 Subnets Públicas e 2 Subnets Privadas em us-east-1a e us-east-1b, Internet Gateway, Route Table Pública. Módulo Security Group: SG EC2 (entradas 22, 3000) e SG RDS (entrada 5432 liberada apenas a partir do SG da EC2). Módulo EC2: t2.micro, subnet pública, com User Data instalando Docker/Docker Compose e clonando a aplicação. Módulo RDS: PostgreSQL db.t3.micro, subnets privadas, publicly_accessible = false, storage_encrypted = true. Configuração de Remote State no S3 e DynamoDB para lock."*

A IA gerou toda a estrutura modularizada corretamente. O único ajuste necessário foi na configuração do backend S3, pois ela usou `dynamodb_table` (deprecated no provider 5.x) em vez de `use_lockfile = true`.

**Prompt 3 — Correção do erro de Object Lock no S3:**
> *"Estou enfrentando o seguinte erro ao executar `terraform apply` no diretório `infra/backend`: `api error AccessDenied: s3:GetBucketObjectLockConfiguration — explicit deny in a service control policy`. O AWS Academy bloqueia essa operação via SCP. Como posso criar o bucket S3 e habilitar o versionamento sem usar o recurso `aws_s3_bucket` do provider diretamente?"*

A IA identificou corretamente que o provider AWS 5.x faz uma chamada automática a `GetBucketObjectLockConfiguration` ao gerenciar buckets, e propôs substituir o recurso `aws_s3_bucket` por `terraform_data` com provisioners `local-exec` chamando a AWS CLI diretamente. Essa solução contornou o bloqueio do SCP.

**Prompt 4 — Correção do erro de bucket inexistente no state:**
> *"Estou enfrentando o seguinte erro ao executar `terraform apply` no diretório `infra/backend`: o `enable_versioning` falha com `NoSuchBucket` porque o `create_s3_bucket` não foi executado nessa rodada — o Terraform o considerou como já existente no state, mas o bucket real havia sido deletado. Como resolver?"*

A IA indicou o comando `terraform state rm` para remover os recursos do state local, forçando a recriação na próxima execução. Isso resolveu o problema imediatamente.

**Prompt 5 — Correção do placeholder no backend S3:**
> *"Ao executar `terraform init` na pasta `infra/`, recebo o erro: `S3 bucket 'SUBSTITUA_PELO_NOME_DO_BUCKET' does not exist`. O nome real do bucket criado é `tech-nova-tfstate-6325171`. Além disso, o parâmetro `dynamodb_table` está sendo apontado como deprecated. Como corrigir o `main.tf`?"*

A IA atualizou o `main.tf` substituindo o placeholder pelo nome real do bucket e trocando `dynamodb_table` por `use_lockfile = true`.

### O que a IA Fez Bem

- Gerou o esqueleto completo da API, do Dockerfile multi-stage e de todos os módulos Terraform em segundos, o que economizou horas de digitação.
- Identificou corretamente a causa raiz dos erros quando o contexto completo foi fornecido (mensagem de erro + comando executado).
- Manteve coerência entre os módulos, passando outputs corretamente como inputs.
- Respeitou as restrições do AWS Academy quando elas foram explicitadas no prompt.

### O que Precisou de Correção Humana

- A IA não sabia de antemão as restrições específicas do AWS Academy Learner Lab (SCP de Object Lock, IAM bloqueado). Foi necessário informar essas restrições explicitamente em cada prompt relevante.
- O placeholder `SUBSTITUA_PELO_NOME_DO_BUCKET` foi deixado no `main.tf` e precisou ser corrigido manualmente após a criação do bucket.
- O parâmetro `dynamodb_table` foi gerado como deprecated — a IA usou documentação levemente desatualizada.
- O destroy provisioner do `terraform_data` usou `self.output` (que é `null` para esse tipo de recurso), causando erro no `terraform destroy`. Foi necessário corrigir para usar o nome do bucket diretamente.

### Comparação com Fazer Manualmente

Sem a IA, estimar o tempo para gerar toda a estrutura Terraform modularizada (4 módulos, ~15 arquivos HCL) seria de 3 a 4 horas só de digitação e consulta à documentação. Com a IA, o scaffolding foi gerado em minutos, permitindo que o tempo fosse focado na validação, nos testes e nas correções de ambiente. A IA acelerou drasticamente as partes mecânicas, mas as decisões de arquitetura (por que o RDS fica na subnet privada, por que usar `use_lockfile`, por que separar o backend em diretório próprio) precisaram de entendimento humano para serem validadas.

---

## Questão 3 — Infraestrutura, Segurança e o Learner Lab

### Arquitetura Provisionada

A infraestrutura provisionada na AWS Academy segue o padrão de arquitetura em camadas com separação entre recursos públicos e privados:

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
Route Table Pública ──▶ Subnet Pública (us-east-1a)
                              │
                              ▼
                         EC2 t2.micro
                         SG: porta 22 (SSH) e 3000 (API)
                         IAM: LabInstanceProfile
                              │
                              │ porta 5432 (apenas do SG EC2)
                              ▼
                    Subnet Privada (us-east-1a / us-east-1b)
                              │
                              ▼
                    RDS PostgreSQL db.t3.micro
                    publicly_accessible = false
                    storage_encrypted = true
```

O Remote State fica fora dessa arquitetura, em um bucket S3 (`tech-nova-tfstate-6325171`) com versionamento habilitado e um arquivo de lock nativo (`use_lockfile = true`).

### Por que o RDS fica na Subnet Privada?

O banco de dados não precisa ser acessado diretamente pela internet em nenhum momento. Toda comunicação com o banco passa pela API na EC2. Colocar o RDS em uma subnet privada (sem rota para o Internet Gateway) significa que mesmo que alguém obtenha as credenciais do banco, não conseguirá conectar a partir de fora da VPC — o banco simplesmente não é roteável pela internet. Isso é o princípio de **defesa em profundidade**: o atacante precisaria primeiro comprometer a EC2 para só então tentar acessar o banco. O parâmetro `publicly_accessible = false` reforça isso no nível da configuração do RDS, impedindo que a AWS atribua um endpoint público ao banco.

Além disso, `storage_encrypted = true` garante que os dados em repouso no disco do RDS estejam criptografados com a chave gerenciada pela AWS (KMS), protegendo contra acesso físico ou por snapshot não autorizado.

### Security Group com Menor Privilégio

O Security Group do RDS tem uma única regra de entrada: porta `5432/tcp` com `source_security_groups = [aws_security_group.ec2.id]`. Isso significa que **apenas instâncias que possuem o SG da EC2 associado** conseguem fazer conexões TCP na porta 5432. Nenhum CIDR externo está liberado. Essa é a forma correta de implementar o princípio do menor privilégio em Security Groups da AWS — ao invés de liberar um range de IPs (que pode mudar), associa-se o SG como fonte, criando uma referência dinâmica e precisa.

### LabInstanceProfile e as Restrições do Learner Lab

O AWS Academy Learner Lab não permite criar IAM Users, Groups, Roles ou Policies. Toda tentativa de criar esses recursos via Terraform resulta em um erro `AccessDenied` com bloqueio via SCP organizacional. A solução é usar os recursos IAM pré-existentes no laboratório:

- **`LabRole`**: a role IAM com as permissões necessárias (EC2, RDS, S3, DynamoDB, etc.) já configurada pela instituição.
- **`LabInstanceProfile`**: o Instance Profile que encapsula a `LabRole` e pode ser associado diretamente a instâncias EC2 via `iam_instance_profile = "LabInstanceProfile"`.

Isso foi informado explicitamente no prompt para a IA, evitando que ela gerasse recursos `aws_iam_role` que seriam bloqueados no apply.

Outras adaptações necessárias para o Learner Lab:

- **Credenciais temporárias com Session Token**: o AWS Academy gera credenciais temporárias (Access Key, Secret Key e Session Token) que expiram periodicamente. É necessário atualizar o arquivo `~/.aws/credentials` com os novos valores sempre que a sessão expira ou o Lab é reiniciado. Sem o `aws_session_token` configurado, todos os comandos Terraform e AWS CLI retornam `ExpiredTokenException`.
- **Região `us-east-1` obrigatória**: o Lab restringe operações a essa região. Qualquer recurso criado em outra região falha. Por isso o provider AWS foi configurado com `region = "us-east-1"` tanto no `providers.tf` quanto no `backend.tf`.
- **Restrição de Object Lock no S3**: a SCP organizacional bloqueia `s3:GetBucketObjectLockConfiguration`, que o provider AWS 5.x chama automaticamente. Foi necessário criar o bucket via AWS CLI dentro de um `terraform_data` para contornar essa restrição.

### Outputs Úteis

Ao final do `terraform apply`, os outputs configurados em `infra/outputs.tf` exibem:
- `ec2_public_ip`: IP público da EC2 para acesso SSH e à API
- `ec2_public_dns`: DNS público da EC2
- `rds_endpoint`: endpoint completo do RDS (host:porta)
- `api_url`: URL base formatada da API (`http://IP:3000`)

---

## Questão 4 — Validação e Responsabilidade

### Checklist Pré-Apply

Antes de executar qualquer `terraform apply`, o seguinte checklist foi aplicado:

1. **Revisão estática do código HCL**: leitura de cada arquivo `.tf` gerado pela IA para verificar se os recursos criados eram os esperados, se os nomes de variáveis eram coerentes e se não havia recursos indesejados (como `aws_iam_role`).

2. **`terraform validate`**: valida a sintaxe e a estrutura do código sem fazer nenhuma chamada à API da AWS. Erros de tipo, referências quebradas e argumentos inválidos são pegos nessa etapa.

3. **`terraform plan -out=tfplan`**: gera o plano de execução e salva em arquivo. A leitura minuciosa do plan permitiu verificar:
   - Quais recursos seriam criados (`+`), modificados (`~`) ou destruídos (`-`)
   - Se o `iam_instance_profile` estava como `"LabInstanceProfile"` e não como uma referência a um recurso IAM criado pela própria configuração
   - Se `publicly_accessible = false` e `storage_encrypted = true` estavam presentes no bloco do RDS
   - Se as regras de ingress do SG do RDS apontavam para o SG da EC2 e não para um CIDR aberto
   - Se o backend S3 apontava para o bucket correto e não para o placeholder

4. **Testes locais antes do deploy na nuvem**: todos os endpoints do CRUD foram testados localmente com Docker Compose antes de subir para a AWS. Isso garantiu que a lógica da aplicação estava correta independentemente da infraestrutura.

5. **Validação das evidências**: `docker compose ps`, `docker build` e `terraform plan` foram capturados em arquivos de texto na pasta `evidencias/` como prova rastreável de que cada etapa foi executada.

### O que Acontece se o Código da IA for Aceito Sem Revisão

Durante esse projeto, isso aconteceu em momentos pontuais e as consequências foram imediatas:

- **Recurso `aws_s3_bucket` com ObjectLock**: o apply falhou com `AccessDenied` no meio da execução, deixando alguns recursos criados e outros não, resultando em um state parcialmente aplicado que precisou de `terraform state rm` para ser corrigido.
- **Placeholder `SUBSTITUA_PELO_NOME_DO_BUCKET`**: o `terraform init` falhou porque o bucket não existia com aquele nome. Se tivesse sido executado sem leitura, o erro apareceria apenas depois de todo o trabalho de configuração.
- **`self.output` nulo no destroy provisioner**: o `terraform destroy` falhou com erro de interpolação nula. Sem entender o código, seria impossível saber onde estava o problema.

Em cenários de produção real, os riscos são ainda maiores: credenciais hardcoded no código podem ser commitadas no repositório e expostas publicamente, instâncias EC2 do tipo `m5.24xlarge` ou RDS `db.r5.4xlarge` podem ser criadas por erro gerando custos de centenas de dólares por hora, e regras de Security Group abertas (`0.0.0.0/0` em todas as portas) podem expor serviços críticos à internet.

### Como a Progressão das Aulas Prepara para Usar IA com Responsabilidade

A sequência Git → Docker → Terraform → Modules não é arbitrária. Cada camada ensina um conceito que se torna pré-requisito para entender o código gerado pela IA na camada seguinte:

- **Git** ensina que todo artefato tem histórico e rastreabilidade. Sem isso, não há como saber o que mudou quando algo quebra.
- **Docker** ensina isolamento e reprodutibilidade. Entender por que o Dockerfile precisa de um usuário não-root é pré-requisito para revisar o que a IA gera.
- **Terraform** ensina que infraestrutura tem estado, e que o estado pode ficar inconsistente se o apply falhar no meio. Sem esse entendimento, o `terraform state rm` seria mágica incompreensível.
- **Modules** ensina composição e separação de responsabilidades. Sem isso, não seria possível avaliar se os outputs de um módulo estão sendo corretamente passados como inputs de outro.

A IA acelera a execução, mas o entendimento vem das aulas. Quem pulou as aulas e foi direto para a IA não conseguiu interpretar os erros, não sabia o que estava no `terraform plan` e não tinha base para corrigir os problemas específicos do Learner Lab. A responsabilidade sobre o que está rodando na nuvem é sempre do desenvolvedor — a IA é uma ferramenta, não um substituto para o conhecimento técnico.

---

*Relatório elaborado com base na experiência real de construção do projeto, utilizando Kiro como ferramenta de IA assistente durante toda a jornada de desenvolvimento.*

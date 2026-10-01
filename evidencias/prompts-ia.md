# Evidência de Uso de IA — Prompts Utilizados no Kiro

**Ferramenta:** Kiro (IDE com agente de IA integrado)
**Modalidade:** Vibe Session (conversacional com execução autônoma de ferramentas)

---

## Prompt 1 — Geração da API Node.js

> "Crie uma API em Node.js com Express e o pacote 'pg' para PostgreSQL. A API gerencia reservas de clientes.
> Requisitos:
> Campos da tabela 'reservas': id (SERIAL/PRIMARY KEY), cliente (VARCHAR), data (DATE/TIMESTAMP), status (VARCHAR).
> Conexão via variáveis de ambiente: DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME.
> Crie a tabela automaticamente na inicialização se ela não existir.
> Rotas obrigatórias: GET /health, POST /reservas, GET /reservas, GET /reservas/:id, PUT /reservas/:id, DELETE /reservas/:id.
> Entregue os arquivos app/package.json e app/src/index.js sem explicações teóricas."

**O que a IA gerou:** `app/package.json` e `app/src/index.js` com pool de conexão, criação automática da tabela e todas as rotas CRUD com tratamento de erro e retorno 404.

**Resultado:** Funcionou na primeira execução local sem ajustes.

---

## Prompt 2 — Geração da Infraestrutura Terraform

> "Gere a infraestrutura em Terraform modularizada para o AWS Academy Learner Lab (us-east-1).
> Restrições estritas:
> Não crie IAM Roles/Policies. Use o IAM Instance Profile 'LabInstanceProfile' na EC2.
> Módulo VPC: VPC 10.0.0.0/16, 2 Subnets Públicas e 2 Subnets Privadas em us-east-1a e us-east-1b, Internet Gateway, Route Table Pública.
> Módulo Security Group: SG EC2 (entradas 22, 3000) e SG RDS (entrada 5432 liberada apenas a partir do SG da EC2).
> Módulo EC2: t2.micro, subnet pública, com User Data instalando Docker/Docker Compose e clonando a aplicação.
> Módulo RDS: PostgreSQL db.t3.micro, subnets privadas, publicly_accessible = false, storage_encrypted = true.
> Configuração de Remote State no S3 e DynamoDB para lock.
> Entregue apenas os blocos HCL dos módulos e do main.tf."

**O que a IA gerou:** Estrutura completa com 4 módulos (vpc, security-group, ec2, rds), main.tf, variables.tf, outputs.tf e backend/.

**Ajuste necessário:** O parâmetro `dynamodb_table` gerado estava deprecated no provider 5.x — corrigido para `use_lockfile = true`.

---

## Prompt 3 — Correção do erro de Object Lock no S3

> "Estou enfrentando o seguinte erro ao executar `terraform apply` no diretório `infra/backend`:
> `api error AccessDenied: s3:GetBucketObjectLockConfiguration — explicit deny in a service control policy`
> O AWS Academy bloqueia essa operação via SCP. Como posso criar o bucket S3 e habilitar o versionamento sem usar o recurso `aws_s3_bucket` do provider diretamente?"

**Contexto:** O provider AWS 5.x chama `GetBucketObjectLockConfiguration` automaticamente ao gerenciar buckets, o que é bloqueado pela SCP do Learner Lab.

**Solução da IA:** Substituir `aws_s3_bucket` por `terraform_data` com provisioners `local-exec` chamando a AWS CLI diretamente para criar o bucket e habilitar versionamento.

**Resultado:** Contornou o bloqueio do SCP com sucesso.

---

## Prompt 4 — Correção do bucket inexistente no state

> "Estou enfrentando o seguinte erro ao executar `terraform apply` no diretório `infra/backend`:
> O recurso `enable_versioning` falha com `NoSuchBucket` porque o `create_s3_bucket` não foi executado nessa rodada — o Terraform o considerou como já existente no state, mas o bucket real havia sido deletado manualmente. Como resolver?"

**Solução da IA:** Usar `terraform state rm terraform_data.create_s3_bucket` e `terraform state rm terraform_data.enable_versioning` para remover os recursos do state local, forçando a recriação na próxima execução.

**Resultado:** Resolveu imediatamente.

---

## Prompt 5 — Correção do placeholder no backend S3

> "Ao executar `terraform init` na pasta `infra/`, recebo o erro:
> `S3 bucket 'SUBSTITUA_PELO_NOME_DO_BUCKET' does not exist`
> O nome real do bucket criado é `tech-nova-tfstate-6325171`. Além disso, o parâmetro `dynamodb_table` está sendo apontado como deprecated no provider AWS 5.x. Como corrigir o `main.tf`?"

**Solução da IA:** Substituiu o placeholder pelo nome real do bucket e trocou `dynamodb_table = "..."` por `use_lockfile = true`.

**Resultado:** `terraform init` executou sem erros.

---

## Prompt 6 — Correção do state desatualizado após destroy manual do bucket

> "Ao executar `terraform apply` no backend, o plan mostra `2 to add` mas o `enable_versioning` falha com `NoSuchBucket`. O `create_s3_bucket` já estava no state de execução anterior mas o bucket foi deletado. O `depends_on` existe no código mas não está sendo respeitado. O que está acontecendo?"

**Diagnóstico da IA:** O `create_s3_bucket` não foi executado porque o Terraform o considerou inalterado (já no state), mesmo com o bucket real deletado. O `depends_on` só funciona entre recursos que estão sendo criados na mesma execução.

**Solução:** `terraform state rm` em ambos os recursos para forçar recriação sequencial.

---

## Resumo do Processo

| Etapa | Gerado pela IA | Ajuste Manual |
|---|---|---|
| API Node.js (index.js + package.json) | ✅ Completo | Nenhum |
| Dockerfile multi-stage | ✅ Completo | Nenhum |
| docker-compose.yml | ✅ Completo | Nenhum |
| Módulos Terraform (vpc, sg, ec2, rds) | ✅ Completo | `dynamodb_table` → `use_lockfile` |
| Backend S3 (terraform_data + CLI) | ✅ Após correção de SCP | Informar restrição do Learner Lab |
| Correções de state e bucket | ✅ Diagnóstico correto | Executar comandos manualmente |

**Conclusão:** A IA acelerou a geração de código em ~80% do tempo. As correções necessárias exigiram entendimento real das restrições do AWS Academy Learner Lab — sem esse conhecimento, não seria possível interpretar os erros e aplicar as soluções corretamente.

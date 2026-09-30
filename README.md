# Prova do Primeiro Bimestre — DevOps (API de Reservas TechNova)

**Aluno:** Nicolas de Jesus Silva  
**RA:** 6325171  
**Disciplina:** DevOps  
**Curso:** Análise e Desenvolvimento de Sistemas — 2026.2  
**Professor:** Alexandre da Costa Tavares Jr  

---

## 📌 Descrição do Projeto

Este repositório contém a solução prática para a Prova do Primeiro Bimestre da disciplina de DevOps. O projeto consiste no provisionamento completo e automatizado da **API de Reservas** da empresa TechNova, abrangendo desde o desenvolvimento da aplicação em Node.js com banco de dados PostgreSQL até a conteinerização com Docker/Docker Compose e a automação de infraestrutura na AWS via Terraform modularizado.

---

## 🏗️ Estrutura do Repositório

```text
prova-primeiro-bimestre-devops/
├── README.md                     # Identificação do aluno e documentação do projeto
├── .gitignore                    # Regras de ignorabilidade (node_modules, .env, tfstate)
├── app/                          # Código fonte da API de Reservas
│   ├── src/                      # Código Express/Node.js e conexão PostgreSQL
│   ├── package.json              # Dependências do projeto
│   ├── Dockerfile                # Multi-stage build com usuário não-root
│   └── .dockerignore             # Arquivos ignorados no build Docker
├── docker-compose.yml            # Orquestração local (API + PostgreSQL + Healthcheck)
├── .env.example                  # Modelo de variáveis de ambiente
├── infra/                        # Infraestrutura como Código (Terraform)
│   ├── modules/                  # Módulos reutilizáveis (vpc, security-group, ec2, rds)
│   ├── main.tf                   # Composição principal dos módulos
│   ├── providers.tf              # Configuração do provider AWS e Remote State S3
│   ├── variables.tf              # Variáveis globais de entrada
│   ├── outputs.tf                # Outputs dos recursos gerados
│   └── backend/                  # Script para criação do S3 e DynamoDB de Lock
├── evidencias/                   # Logs de validação (docker-build, compose-ps, terraform-plan)
└── relatorio.md                  # Relatório dissertativo do processo com IA
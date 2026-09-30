Questão 1 — A Jornada Completa: Detalhe como você começou configurando o Git e escrevendo a API em Node.js com persistência PostgreSQL. Explique o isolamento e validação local via Docker Compose (Aulas 01-02), o empacotamento modular da nuvem AWS com VPC, Security Groups, EC2 e RDS via HCL Terraform (Aulas 03-05) e a segurança de estado com Remote State no S3 e DynamoDB (Aula 06).

Questão 2 — O Processo com IA como Copiloto: Explique a metodologia Spec-Driven no Kiro. Descreva como definiu o contrato da API e os blocos HCL da infraestrutura. Cite as correções necessárias (ex.: a IA tentou gerar um recurso aws_iam_role que o Learner Lab bloqueia e você precisou ajustar para LabInstanceProfile).

Questão 3 — Infraestrutura, Segurança e o Learner Lab: Justifique por que o RDS reside nas subnets privadas e a EC2 na subnet pública (defesa em profundidade). Descreva a regra do Security Group liberando a porta 5432 do PostgreSQL unicamente para o Security Group da EC2. Detalhe as adaptações de credenciais temporárias do Learner Lab (aws_session_token) e a obrigatoriedade da região us-east-1.

Questão 4 — Validação e Responsabilidade: Descreva o checklist pré-aplicação: revisão estática dos scripts, terraform fmt, terraform validate, inspeção minuciosa dos recursos no terraform plan antes da aprovação do apply e testes operacionais dos endpoints HTTP da API. Explique o risco de aceitar códigos de IA sem auditoria (vazamento de chaves, bloqueios SCP e criação de recursos caros).


# Relatório de Processo — Prova do Primeiro Bimestre

**Aluno:** Nicolas de Jesus Silva  
**RA:** 6325171  
**Ferramenta de IA Utilizada:** Kiro (Spec-Driven AI)

---

### Questão 1 — A Jornada Completa (Aulas 01 a 07)

Para entregar a API de Reservas da TechNova, eu decidi seguir exatamente a ordem em que a matéria foi ensinada nas aulas, porque fazia mais sentido validar cada etapa isoladamente antes de subir tudo para a nuvem. Comecei na Aula 01 criando a estrutura do repositório no Git e escrevendo a aplicação em Node.js com Express para fazer as rotas de CRUD persistindo no PostgreSQL. Depois, montei o Dockerfile multi-stage com usuário não-root e criei o "docker-compose.yml" na Aula 02 para validar a comunicação entre o banco e a API com a rede bridge e o volume nomeado. Quando vi que o ambiente local estava respondendo aos comandos de cURL e que os dados não sumiam após reiniciar os containers, passei para a infraestrutura como código com Terraform. Entre as Aulas 03 e 06, separei os módulos de VPC, Security Group, EC2 e RDS para manter o código organizado, conectando a saída de um módulo na entrada do outro. No final, configurei o Remote State com S3 e DynamoDB para guardar o estado com segurança, conectando tudo do commit inicial até o deploy na AWS.

### Questão 2 — O Processo com IA como Copiloto

Eu utilizei o Kiro adotando o fluxo Spec-Driven, onde primeiro eu passava os requisitos do que precisava antes de pedir o código. A IA foi muito rápida para gerar a estrutura inicial da API, do Dockerfile e o esqueleto dos arquivos HCL do Terraform, o que me economizou um tempo enorme de digitação. No entanto, ela também me atrapalhou em momentos em que tentou criar recursos que o AWS Academy Learner Lab não permite, como quando tentou instanciar um "aws_iam_role" e acabou tomando bloqueio de SCP na criação do bucket S3 por conta de políticas de "ObjectLockConfiguration". Eu precisei intervir manualmente, ajustando o código para usar a "LabInstanceProfile" pré-existente e criando o bucket S3 via comando de CLI do AWS dentro do Terraform. A IA ajudou muito na produtividade, mas se eu só tivesse copiado e colado sem entender o erro, a aplicação não teria subido na AWS.

### Questão 3 — Infraestrutura, Segurança e o Learner Lab

A arquitetura que montei na AWS foi pensada para manter o banco de dados protegido. A instância EC2 foi colocada na subnet pública com IP público associado para que a gente conseguisse acessar a API na porta 3000 e via SSH na porta 22. Já o banco RDS PostgreSQL ficou isolado nas subnets privadas com o parâmetro "publicly_accessible = false" e criptografia ativada no storage. A segurança foi garantida liberando a porta 5432 do Security Group do RDS apenas e exclusivamente para o id do Security Group da EC2, impedindo qualquer acesso externo direto ao banco. Por estarmos rodando no Learner Lab da AWS Academy, precisei ajustar as credenciais temporárias do terminal adicionando o "AWS_SESSION_TOKEN", fixando a região em "us-east-1" e usando os perfis IAM de laboratório da própria instituição em vez de tentar criar novos usuários.

### Questão 4 — Validação e Responsabilidade

Antes de rodar qualquer "terraform apply", eu criei o hábito de inspecionar o código e rodar o "terraform validate" junto do "terraform plan" salvando a saída no arquivo de evidências para verificar detalhadamente quais recursos seriam criados. Eu também testei todo o CRUD e a persistência do banco localmente usando "docker compose down" e subindo novamente antes de ir para a nuvem. Se eu tivesse aceito o código da IA sem revisar, o deploy teria falhado no meio do caminho por conta das travas de IAM do ambiente e eu corria o risco de deixar recursos caros ligados sem necessidade. A evolução que tivemos durante as aulas me ensinou que a IA serve como um assistente de desenvolvimento, mas a validação técnica e a responsabilidade sobre o que está rodando na nuvem é 100% do desenvolvedor.
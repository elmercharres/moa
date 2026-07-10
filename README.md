# Portal Creditos — Infraestructura como Código

> **Entregable corporativo para MOA (Molinos Agro)**
> Alineado con **MOA-INFRA-Terraform-Best-Practices v1.3**

---

## Tabla de contenido

1. [Arquitectura](#1-arquitectura)
2. [Estructura del repositorio](#2-estructura-del-repositorio)
3. [Backend stack](#3-backend-stack)
4. [Frontend stack](#4-frontend-stack)
5. [Pipeline Azure DevOps](#5-pipeline-azure-devops)
6. [Variables y configuración](#6-variables-y-configuración)
7. [Módulos Terraform](#7-módulos-terraform)
8. [Dependencias externas](#8-dependencias-externas)
9. [Nomenclatura MOA](#9-nomenclatura-moa)
10. [Despliegue paso a paso](#10-despliegue-paso-a-paso)
11. [Documentación](#documentación)

---

## 1. Arquitectura

Portal Creditos es una aplicación web compuesta por dos servicios independientes desplegados en **AWS ECS Fargate**:

| Servicio | Tecnología | Stack Terraform | ALB |
|---|---|---|---|
| **Backend API** | ASP.NET Core + Flyway (migraciones PostgreSQL) | `infra/terraform/backend/` | Interno (configurable) |
| **Frontend Web** | Angular + Nginx | `infra/terraform/frontend/` | Interno |

```
VPN / Red Corporativa
         │
         ├──► ALB Backend (portal-creditos-QA)  ──► ECS Fargate ──► API .NET
         │                                                           │
         │                                                           └──► Amazon RDS for PostgreSQL (Single-AZ)
         │                                                               (pre-existente)
         │
         └──► ALB Frontend (portal-creditos-web-QA) ──► ECS Fargate ──► Nginx + Angular
```

**Recursos creados por Terraform:** ECR, ECS, ALB, CloudWatch Logs, IAM Roles.
**Recursos NO creados:** VPC, Subnets, RDS, Route53, ACM, Secrets Manager, S3 estado, DynamoDB.

> **Nota:** La solución no aprovisiona la base de datos. El proyecto está diseñado para consumir
> una instancia existente de **Amazon RDS for PostgreSQL (Single-AZ)** y un Secret administrado
> por MOA mediante **AWS Secrets Manager**. Amazon ECS inyecta las credenciales como variable
> de entorno; la aplicación .NET las lee a través de `ConnectionStrings__PostgresConnection`.

---

## 2. Estructura del repositorio

```
infraestructura/
├── azure-pipelines-iac.yml         ← Pipeline IaC (único propietario de Terraform)
├── README.md                       ← Este archivo
│
├── infra/terraform/
│   ├── backend/                    ← Stack Backend (API + Flyway)
│   │   ├── versions.tf             ← Versión Terraform >= 1.10, < 2.0
│   │   ├── providers.tf            ← Provider AWS con default_tags
│   │   ├── variables.tf            ← 60+ variables con type, description y validation
│   │   ├── locals.tf               ← Nomenclatura MOA + common_tags
│   │   ├── main.tf                 ← Orquestación de módulos locales
│   │   ├── outputs.tf              ← Outputs del stack
│   │   ├── terraform.tfvars.example← Plantilla de valores por despliegue
│   │   ├── backend.qa.s3.hcl.example
│   │   ├── backend.prd.s3.hcl.example
│   │   ├── env/qa.tfvars.example
│   │   └── modules/
│   │       ├── ecr/                ← ECR repositories + lifecycle policies
│   │       ├── iam/                ← IAM roles y políticas
│   │       ├── networking/         ← ALB, Target Group, Security Groups
│   │       ├── monitoring/         ← CloudWatch Log Groups
│   │       └── ecs/                ← ECS Cluster, Task Definitions, Service, Autoscaling
│   │
│   └── frontend/                   ← Stack Frontend (Angular/Nginx)
│       ├── versions.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── locals.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfvars.example
│       ├── backend.qa.hcl.example
│       ├── backend.prd.hcl.example
│       └── modules/
│           ├── ecr/
│           ├── iam/
│           ├── networking/
│           ├── monitoring/
│           └── ecs/
│
└── docs/
    ├── 01-Architecture.md          ← Arquitectura completa con diagramas Mermaid
    ├── 02-Deployment-Inputs.md     ← Todos los valores que MOA debe proveer
    ├── 03-Operational-Pending.md   ← Pendientes operacionales por categoría
    ├── 04-Architecture-Decisions.md← ADRs — decisiones y su justificación
    ├── 05-Exceptions.md            ← Excepciones al estándar MOA (EXC-01..05)
    ├── 06-Handover.md              ← Guía completa de entrega para MOA
    ├── DELIVERY-CHECKLIST.md       ← Checklist de entrega corporativa
    └── audits/
        ├── final-audit.md          ← Auditoría Final Integral
        ├── backend-audit.md        ← Auditoría Backend
        ├── frontend-audit.md       ← Auditoría Frontend
        ├── pipeline-audit.md       ← Auditoría Pipeline Azure DevOps
        └── moa-gap-analysis.md     ← Análisis de brecha inicial MOA
```

---

## 3. Backend stack

**Directorio:** `infra/terraform/backend/`

Provisiona la infraestructura para la API REST (ASP.NET Core) y las migraciones de base de datos (Flyway).

### Recursos AWS creados

| Módulo | Recursos |
|---|---|
| `modules/ecr` | 2 repositorios ECR (api + db-migrations) + lifecycle policies |
| `modules/monitoring` | 2 CloudWatch Log Groups |
| `modules/iam` | 2 IAM Roles (execution + task) + políticas inline |
| `modules/networking` | 2 Security Groups + ALB + Target Group + Listeners |
| `modules/ecs` | ECS Cluster + 2 Task Definitions + ECS Service + Autoscaling |

### Características de seguridad

- Secretos inyectados vía AWS Secrets Manager (solo ARNs en Terraform)
- ALB interno por defecto (`load_balancer_internal = true`)
- IAM mínimo privilegio (execution role con solo los secretos referenciados)
- `prevent_destroy = true` en ECR y CloudWatch Log Groups
- `deployment_circuit_breaker` con rollback automático

### Uso rápido

```powershell
cd infra/terraform/backend

# Copiar y completar archivos de configuración
Copy-Item backend.qa.s3.hcl.example backend.qa.s3.hcl    # completar valores reales
Copy-Item env/qa.tfvars.example env/qa.tfvars             # completar valores reales

# Inicializar y planificar
terraform init -backend-config=backend.qa.s3.hcl
terraform plan -var-file=env/qa.tfvars

# Aplicar
terraform apply -var-file=env/qa.tfvars
```

---

## 4. Frontend stack

**Directorio:** `infra/terraform/frontend/`

Provisiona la infraestructura para el frontend Angular servido por Nginx.

### Recursos AWS creados

| Módulo | Recursos |
|---|---|
| `modules/ecr` | 1 repositorio ECR (web) + lifecycle policy |
| `modules/monitoring` | 1 CloudWatch Log Group |
| `modules/iam` | 2 IAM Roles (execution + task) |
| `modules/networking` | 2 Security Groups + ALB interno + Target Group + Listeners |
| `modules/ecs` | ECS Cluster + Task Definition + ECS Service + Autoscaling |

### Diferencias respecto al backend

- Sin Secrets Manager (Nginx no requiere secretos)
- ALB **siempre interno** (`load_balancer_internal = true` como default firme)
- Una sola task definition (sin task de Flyway)
- Variable adicional `service_name` para distinguir el servicio

### Uso rápido

```powershell
cd infra/terraform/frontend

# Copiar y completar archivos de configuración
Copy-Item backend.qa.hcl.example backend.qa.hcl          # completar valores reales
Copy-Item terraform.tfvars.example terraform.tfvars       # completar valores reales

# Inicializar y planificar
terraform init -backend-config=backend.qa.hcl
terraform plan -var-file=terraform.tfvars

# Aplicar
terraform apply -var-file=terraform.tfvars
```

---

## 5. Pipeline Azure DevOps

**Archivo:** `azure-pipelines-iac.yml`

Pipeline centralizado que gestiona el ciclo de vida de Terraform para ambos stacks.

### Parámetros

| Parámetro | Opciones | Descripción |
|---|---|---|
| `targetEnvironment` | `qa` / `prod` | Ambiente de destino |
| `stack` | `all` / `backend` / `frontend` | Stack a ejecutar |
| `terraformAction` | `plan` / `apply` | Acción Terraform |

### Variable Groups requeridos

Crear en Azure DevOps (Pipelines → Library):

| Variable Group | Variables requeridas |
|---|---|
| `portal-creditos-iac-qa` | Variables/ARNs del ambiente; la autenticación AWS se realiza con Service Connection OIDC |
| `portal-creditos-iac-prod` | Variables/ARNs del ambiente; la autenticación AWS se realiza con Service Connection OIDC |

### Flujo de ejecución

```
1. Run pipeline (targetEnvironment=qa, stack=backend, action=plan)
2. Revisar output del plan
3. Run pipeline (targetEnvironment=qa, stack=backend, action=apply)
4. (Opcional) Run pipeline (stack=frontend, action=plan → apply)
```

> El pipeline ejecuta `terraform fmt -check`, `terraform validate`, `terraform plan` y opcionalmente `terraform apply`.

---

## 6. Variables y configuración

### Variables obligatorias (sin default) — deben estar en el tfvars

| Variable | Stack | Descripción |
|---|---|---|
| `vpc_id` | Backend + Frontend | ID de la VPC existente |
| `public_subnet_ids` | Backend | Subnets para el ALB |
| `private_subnet_ids` | Backend + Frontend | Subnets para ECS tasks |
| `load_balancer_subnet_ids` | Frontend | Subnets para el ALB interno del frontend |
| `tag_costcenter` | Backend + Frontend | Centro de costos — **provisto por MOA Finanzas** |
| `postgres_connection_string_secret_arn` | Backend | ARN del secret de conexión PostgreSQL |
| `jwt_signing_key_secret_arn` | Backend | ARN del secret de clave JWT |
| `flyway_url_secret_arn` | Backend | ARN del secret FLYWAY_URL |
| `flyway_user_secret_arn` | Backend | ARN del secret FLYWAY_USER |
| `flyway_password_secret_arn` | Backend | ARN del secret FLYWAY_PASSWORD |

### Tags corporativos MOA

Todos los recursos AWS reciben estos tags, configurados en `variables.tf` y centralizados en `local.common_tags`:

```hcl
Application  = var.tag_application   # "Portal-Creditos"
Area         = var.tag_area          # "Demanda"
Autopoweron  = var.tag_autopoweron   # "false"
Autopoweroff = var.tag_autopoweroff  # "false"
BackupPolicy = var.tag_backup_policy # "NoBackup"
Costcenter   = var.tag_costcenter    # PROVISTO POR MOA
Environment  = "QA" / "PRD"
Project      = var.tag_project       # "Portal-Creditos"
Requester    = var.tag_requester     # Confirmar con MOA
Risk         = var.tag_risk          # "medium"
```

---

## 7. Módulos Terraform

Los módulos son **locales** (en `./modules/`), sin dependencias externas. El estándar MOA prohíbe el uso de módulos remotos.

| Módulo | Recursos encapsulados | Usado en |
|---|---|---|
| `modules/ecr` | ECR repository + lifecycle policies | Backend (x2) + Frontend (x1) |
| `modules/monitoring` | CloudWatch Log Groups | Backend (x2) + Frontend (x1) |
| `modules/iam` | IAM Roles (execution + task) + políticas | Backend + Frontend |
| `modules/networking` | Security Groups + ALB + TG + Listeners | Backend + Frontend |
| `modules/ecs` | ECS Cluster + Task Definitions + Service + Autoscaling | Backend + Frontend |

Cada módulo tiene su propio `variables.tf` y `outputs.tf`. Los nombres de recursos siempre vienen como parámetros desde `locals.tf` del root module — **nunca se hardcodean en los módulos**.

---

## 8. Dependencias externas

Los siguientes recursos deben **existir antes** del primer `terraform apply`:

| Recurso | Tipo | Responsable |
|---|---|---|
| VPC + Subnets | Pre-existente | MOA Networking |
| Amazon RDS for PostgreSQL (Single-AZ) | Pre-existente | MOA / Equipo DB |
| AWS Secrets Manager (5 secretos backend) | Pre-existente | MOA Seguridad |
| S3 Bucket + DynamoDB (estado Terraform) | Pre-existente | MOA Infraestructura |
| ACM Certificate (si HTTPS) | Pre-existente, opcional | MOA Seguridad |
| KMS Key (logs, opcional) | Pre-existente, opcional | MOA Seguridad |

Ver lista completa en `docs/02-Deployment-Inputs.md`.

---

## 9. Nomenclatura MOA

Todos los nombres de recursos se calculan en `locals.tf` siguiendo la **Sección 5** del estándar MOA.

### Ejemplos — ambiente QA

| Tipo de recurso | Nombre generado |
|---|---|
| ECS Cluster (backend) | `ECS-CLT-Portal-Creditos-API-QA` |
| ECS Service (backend) | `ECS-SVC-Portal-Creditos-API-QA` |
| ECS Task Def (API) | `ECS-TASK-DEF-Portal-Creditos-API-QA` |
| ECR (API) | `ecs-repo-portal-creditos-api-qa` |
| ALB (backend) | `ALB-portal-creditos-QA` *(excepción 32 chars — ver `docs/05-Exceptions.md`)* |
| IAM Role (execution) | `ROLE-ECS-Portal-Creditos-API-QA-EXECUTION` |
| IAM Policy (secrets) | `POL-ECS-Portal-Creditos-API-QA-SECRETS` |
| Auto Scaling Policy | `AAS-Portal-Creditos-API-QA-CPU` |
| CloudWatch Log Group | `/ecs/Portal-Creditos-QA/api` |
| ECS Cluster (frontend) | `ECS-CLT-Portal-Creditos-WEB-QA` |
| ECR (frontend) | `ecs-repo-portal-creditos-web-qa` |

---

## 10. Despliegue paso a paso

Ver guía completa en `docs/06-Handover.md`.

### Resumen del flujo

```
PREREQUISITOS (MOA)
├── S3 + DynamoDB estado Terraform
├── VPC + Subnets
├── Secrets Manager (5 secretos backend)
├── Variable Groups Azure DevOps
└── tag_costcenter confirmado

PRIMER DESPLIEGUE
├── Backend: terraform apply → ECR → Push imágenes → Apply completo
├── Ejecutar Flyway (migraciones DB)
├── Verificar /health/ready
├── Frontend: terraform apply → ECR → Push imagen → Apply completo
└── Verificar /health

RELEASES CONTINUOS (sin Terraform)
├── Pipeline backend-release: build + push + register task def + update service
└── Pipeline frontend-release: build + push + register task def + update service
```

---

## Documentación

Toda la documentación técnica del proyecto se encuentra en la carpeta `docs/`.

| Documento | Descripción |
|---|---|
| [`docs/01-Architecture.md`](docs/01-Architecture.md) | Arquitectura detallada con diagramas Mermaid |
| [`docs/02-Deployment-Inputs.md`](docs/02-Deployment-Inputs.md) | **Tabla completa de valores a proveer por MOA** |
| [`docs/03-Operational-Pending.md`](docs/03-Operational-Pending.md) | Pendientes operacionales por categoría |
| [`docs/04-Architecture-Decisions.md`](docs/04-Architecture-Decisions.md) | ADRs — decisiones y su justificación |
| [`docs/05-Exceptions.md`](docs/05-Exceptions.md) | Excepciones al estándar MOA documentadas |
| [`docs/06-Handover.md`](docs/06-Handover.md) | Guía completa paso a paso para MOA |
| [`docs/DELIVERY-CHECKLIST.md`](docs/DELIVERY-CHECKLIST.md) | Checklist de entrega corporativa |

### Auditorías

| Documento | Descripción |
|---|---|
| [`docs/audits/final-audit.md`](docs/audits/final-audit.md) | Auditoría Final Integral |
| [`docs/audits/backend-audit.md`](docs/audits/backend-audit.md) | Auditoría Backend |
| [`docs/audits/frontend-audit.md`](docs/audits/frontend-audit.md) | Auditoría Frontend |
| [`docs/audits/pipeline-audit.md`](docs/audits/pipeline-audit.md) | Auditoría del Pipeline Azure DevOps |
| [`docs/audits/moa-gap-analysis.md`](docs/audits/moa-gap-analysis.md) | Análisis de brecha inicial MOA |

---

## Validación local del IaC

```powershell
cd infra/terraform/backend
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

```powershell
cd infra/terraform/frontend
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```
| [`docs/04-Architecture-Decisions.md`](docs/04-Architecture-Decisions.md) | ADRs — decisiones y su justificación |
| [`docs/05-Exceptions.md`](docs/05-Exceptions.md) | Excepciones al estándar MOA documentadas |
| [`docs/06-Handover.md`](docs/06-Handover.md) | Guía completa paso a paso para MOA |
| [`docs/DELIVERY-CHECKLIST.md`](docs/DELIVERY-CHECKLIST.md) | Checklist de entrega corporativa |

### Auditorías

| Documento | Descripción |
|---|---|
| [`docs/audits/final-audit.md`](docs/audits/final-audit.md) | Auditoría Final Integral |
| [`docs/audits/backend-audit.md`](docs/audits/backend-audit.md) | Auditoría Backend |
| [`docs/audits/frontend-audit.md`](docs/audits/frontend-audit.md) | Auditoría Frontend |
| [`docs/audits/pipeline-audit.md`](docs/audits/pipeline-audit.md) | Auditoría del Pipeline Azure DevOps |
| [`docs/audits/moa-gap-analysis.md`](docs/audits/moa-gap-analysis.md) | Análisis de brecha inicial MOA |

---

## Validación local del IaC

```powershell
cd infra/terraform/backend
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

```powershell
cd infra/terraform/frontend
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

```text
infra/terraform/
  backend/                          ← Backend stack (root module)
    providers.tf  versions.tf
    variables.tf  locals.tf
    main.tf       outputs.tf
    terraform.tfvars.example
    backend.s3.hcl.example
    env/qa.tfvars.example
    modules/
      ecr/  iam/  networking/  monitoring/  ecs/

  frontend/                         ← Frontend stack (root module)
    providers.tf  versions.tf
    variables.tf  locals.tf
    main.tf       outputs.tf
    terraform.tfvars.example
    backend.hcl.example
    modules/
      ecr/  iam/  networking/  monitoring/  ecs/

docs/                               ← Documentación operativa
```

## Flujo

1. Ejecutar `azure-pipelines-iac.yml` cuando se crea o cambia infraestructura.
2. Ejecutar el release backend cuando cambia la API o sus migraciones.
3. Ejecutar el release frontend cuando cambia Angular/Nginx.

El pipeline IaC ejecuta Terraform para crear o modificar ECR, ECS, ALB, IAM, CloudWatch
y las referencias a Secrets Manager. Los pipelines de aplicación no ejecutan Terraform:
publican imágenes en ECR, registran nuevas revisiones de task definition y actualizan los
servicios ECS existentes.

## Nomenclatura MOA (ejemplos QA)

| Recurso | Nombre |
|---|---|
| ECS Cluster (backend) | `ECS-CLT-Portal-Creditos-API-QA` |
| ECS Service (backend) | `ECS-SVC-Portal-Creditos-API-QA` |
| ECR API | `ecs-repo-portal-creditos-api-qa` |
| ALB (backend) | `ALB-portal-creditos-QA` |
| IAM Role (execution) | `ROLE-ECS-Portal-Creditos-API-QA-EXECUTION` |
| Auto Scaling | `AAS-Portal-Creditos-API-QA-CPU` |

Todos los nombres se calculan en `locals.tf` nunca se hardcodean en módulos (Sección 5).

## Tags obligatorios MOA (Sección 6)

`Application`, `Area`, `Autopoweron`, `Autopoweroff`, `BackupPolicy`, `Costcenter`,
`Environment`, `Project`, `Requester`, `Risk`

Definidos en `variables.tf` como `tag_*`, centralizados en `local.common_tags`,
aplicados globalmente mediante `default_tags` del provider.

## Validacion local del IaC

Desde `infra/terraform`:

```powershell
terraform fmt -check
terraform init -backend=false
terraform validate
```

Para validar el stack del frontend, ejecutar los mismos comandos desde `infra/terraform/frontend`.

Si Terraform no esta instalado localmente, se puede usar la imagen oficial:

```powershell
podman run --rm -v "${PWD}:/workspace" -w /workspace hashicorp/terraform:1.10.0 fmt -check
podman run --rm -v "${PWD}:/workspace" -w /workspace hashicorp/terraform:1.10.0 init -backend=false
podman run --rm -v "${PWD}:/workspace" -w /workspace hashicorp/terraform:1.10.0 validate
```

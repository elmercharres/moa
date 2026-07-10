# 06 — Guía de Handover
## Manual de Entrega para el Equipo de Infraestructura MOA

> Este documento es suficiente para que un Ingeniero de Infraestructura de MOA
> pueda preparar, validar y ejecutar el despliegue completo de Portal Creditos
> sin asistencia del equipo de desarrollo.

---

## Dependencias que deberá entregar MOA antes del primer despliegue

> Los siguientes recursos **NO son creados por Terraform** y deben existir antes de ejecutar `terraform apply`.
> Es responsabilidad del equipo de Infraestructura de MOA proveer todos estos elementos al equipo de despliegue.

| Recurso | Descripción | Responsable | Obligatorio |
|---|---|---|---|
| **AWS Account** | Account ID de la cuenta AWS de destino para QA y PRD | MOA Infraestructura | **Sí** |
| **VPC** | ID de la VPC donde se desplegará la solución (backend y frontend) | MOA Networking | **Sí** |
| **Subnets Públicas / Internas** | IDs de las subnets para los Application Load Balancers | MOA Networking | **Sí** |
| **Subnets Privadas** | IDs de las subnets para los tasks ECS Fargate (backend y frontend) | MOA Networking | **Sí** |
| **Security Groups** | Reglas de red que permitan la conectividad ECS → Amazon RDS for PostgreSQL | MOA Networking | **Sí** |
| **ACM Certificate** | ARN del certificado TLS para habilitar HTTPS en el ALB | MOA Seguridad | **Sí** |
| **Amazon RDS for PostgreSQL (Single-AZ)** | Instancia de base de datos PostgreSQL con endpoint, usuario, contraseña y base de datos provisionada | MOA / Equipo DB | **Sí** |
| **AWS Secrets Manager Secret** | Secret que contiene la cadena de conexión completa de PostgreSQL. Amazon ECS lo inyecta como `ConnectionStrings__PostgresConnection` en la aplicación .NET | MOA Seguridad / Equipo DB | **Sí** |
| **AWS Service Connection OIDC** | Nombre de la Service Connection federada para el pipeline Azure DevOps | MOA DevOps | **Sí** |
| **Cost Center** | Valor definitivo del tag corporativo `Costcenter` asignado por MOA Finanzas | MOA Finanzas | **Sí** |
| **Tags corporativos** | Valores definitivos de: `Area`, `Requester`, `Risk`, `BackupPolicy`, `Autopoweron`, `Autopoweroff` | MOA Gobernanza | **Sí** |

> Ver detalle completo de cada valor en `docs/02-Deployment-Inputs.md`.

---

## 1. Prerequisitos del ambiente

### 1.1 Herramientas requeridas

| Herramienta | Versión | Verificación |
|---|---|---|
| Terraform | `>= 1.10, < 2.0` | `terraform -version` |
| AWS CLI | `>= 2.x` | `aws --version` |
| Git | Cualquier versión reciente | `git --version` |
| PowerShell | >= 5.1 o Core 7 | (para scripts locales) |

### 1.2 Accesos requeridos

- Acceso de lectura/escritura al repositorio Azure DevOps `infraestructura`
- Credenciales AWS con permisos de despliegue para la(s) cuenta(s) de destino
- Acceso a Azure DevOps para crear Variable Groups y configurar Environments
- Acceso a AWS Secrets Manager para obtener/crear los ARNs de secretos

---

## 2. Qué completar antes del primer despliegue

### Paso 1 — Completar los archivos de backend remoto

Copiar y completar los archivos de configuración del estado Terraform para cada ambiente.

**Backend (API):**
```powershell
# QA
Copy-Item infra/terraform/backend/backend.qa.s3.hcl.example infra/terraform/backend/backend.qa.s3.hcl
# Editar: confirmar bucket, key, region y use_lockfile con valores reales MOA

# PRD
Copy-Item infra/terraform/backend/backend.prd.s3.hcl.example infra/terraform/backend/backend.prd.s3.hcl
```

**Frontend (Web):**
```powershell
# QA
Copy-Item infra/terraform/frontend/backend.qa.hcl.example infra/terraform/frontend/backend.qa.hcl
# Editar: confirmar bucket, key, region y use_lockfile con valores reales MOA

# PRD
Copy-Item infra/terraform/frontend/backend.prd.hcl.example infra/terraform/frontend/backend.prd.hcl
```

> Los archivos `*.hcl` reales están en `.gitignore` y **no deben** ser commiteados.

### Paso 2 — Completar los archivos de variables

**Backend:**
```powershell
Copy-Item infra/terraform/backend/terraform.tfvars.example infra/terraform/backend/env/qa.tfvars
# Editar: rellenar VPC, subnets, secret ARNs, tag_costcenter, etc.
```

**Frontend:**
```powershell
Copy-Item infra/terraform/frontend/terraform.tfvars.example infra/terraform/frontend/terraform.tfvars
# Editar: rellenar VPC, subnets, tag_costcenter, etc.
```

**Valores obligatorios a completar en `env/qa.tfvars` (backend):**

```hcl
tag_costcenter   = "<COSTCENTER_PROVISTO_POR_MOA>"
vpc_id           = "<VPC_ID_PROVISTO_POR_MOA>"
public_subnet_ids  = ["<SUBNET_ID_1>", "<SUBNET_ID_2>"]
private_subnet_ids = ["<SUBNET_ID_3>", "<SUBNET_ID_4>"]
alb_ingress_cidr_blocks = ["<CIDR_VPN_CORPORATIVA>"]

postgres_connection_string_secret_arn = "<ARN_PROVISTO_POR_MOA>"
jwt_signing_key_secret_arn            = "<ARN_PROVISTO_POR_MOA>"
flyway_url_secret_arn                 = "<ARN_PROVISTO_POR_MOA>"
flyway_user_secret_arn                = "<ARN_PROVISTO_POR_MOA>"
flyway_password_secret_arn            = "<ARN_PROVISTO_POR_MOA>"
```

### Paso 3 — Crear Variable Groups en Azure DevOps

Crear los siguientes Variable Groups en Azure DevOps (Pipelines → Library):

**`portal-creditos-iac-qa`:**

| Variable | Tipo | Descripción |
|---|---|---|
| `awsServiceConnection` | Parámetro de pipeline | Nombre de la AWS Service Connection OIDC provista por MOA |

**`portal-creditos-iac-prod`:**

| Variable | Tipo | Descripción |
|---|---|---|
| `awsServiceConnection` | Parámetro de pipeline | Nombre de la AWS Service Connection OIDC provista por MOA |

> Si se usan archivos `.tfvars` con todos los valores, las demás variables del pipeline son opcionales.

### Paso 4 — Verificar que los prerrequisitos AWS existen

Antes de ejecutar Terraform, verificar:

```bash
# 1. Bucket S3 de estado existe
aws s3 ls s3://<BUCKET_ESTADO> --region <REGION>

# 2. Tabla DynamoDB de locks existe
aws dynamodb describe-table --table-name <TABLA_DYNAMODB> --region <REGION>

# 3. VPC y subnets existen
aws ec2 describe-vpcs --vpc-ids <VPC_ID>
aws ec2 describe-subnets --subnet-ids <SUBNET_IDS>

# 4. Secrets Manager ARNs existen
aws secretsmanager describe-secret --secret-id <ARN_POSTGRES>
aws secretsmanager describe-secret --secret-id <ARN_JWT>

# 5. RDS es accesible desde las subnets privadas
# (verificar con MOA Networking)
```

---

## 3. Validación previa al despliegue

### 3.1 Validar formato del código Terraform

```powershell
# Backend
Set-Location infra/terraform/backend
terraform fmt -check -recursive
terraform init -backend=false
terraform validate

# Frontend
Set-Location ../frontend
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

### 3.2 Verificar variables antes del plan

Revisar los archivos `*.tfvars` y `*.hcl` completados en el Paso 2 y verificar:
- No hay valores con texto `REPLACE_ME`, `PENDIENTE`, `TODO` ni `000000`
- Los ARNs de secretos tienen el formato correcto `arn:aws:secretsmanager:...`
- Los IDs de VPC tienen el formato `vpc-xxxxxxxxxxxxxxxxx`
- Los IDs de subnets tienen el formato `subnet-xxxxxxxxxxxxxxxxx`
- `tag_costcenter` tiene el valor real provisto por MOA Finanzas

---

## 4. Cómo ejecutar Terraform (modo local)

> Para el primer despliegue se recomienda ejecutar localmente para tener control total.
> Los deployments rutinarios deben hacerse vía el Pipeline Azure DevOps.

### 4.1 Backend — primer despliegue

```powershell
Set-Location infra/terraform/backend

# 1. Inicializar con backend remoto
terraform init -backend-config=backend.qa.s3.hcl

# 2. Crear primero los repositorios ECR (necesario para poder subir las imágenes)
terraform apply `
  -target=module.ecr `
  -var-file=env/qa.tfvars

# 3. Obtener URLs de ECR para el pipeline de aplicación
terraform output -raw ecr_repository_url
terraform output -raw db_migrations_ecr_repository_url

# 4. Una vez que las imágenes estén en ECR, aplicar la infraestructura completa
terraform apply -var-file=env/qa.tfvars
```

### 4.2 Frontend — primer despliegue

```powershell
Set-Location infra/terraform/frontend

# 1. Inicializar con backend remoto
terraform init -backend-config=backend.qa.hcl

# 2. Crear primero el repositorio ECR
terraform apply `
  -target=module.ecr `
  -var-file=terraform.tfvars

# 3. Obtener URL de ECR
terraform output -raw ecr_repository_url

# 4. Infraestructura completa (una vez que la imagen esté en ECR)
terraform apply -var-file=terraform.tfvars
```

---

## 5. Cómo ejecutar el Pipeline Azure DevOps

El pipeline `azure-pipelines-iac.yml` soporta tres parámetros:

| Parámetro | Opciones | Descripción |
|---|---|---|
| `targetEnvironment` | `qa`, `prod` | Ambiente objetivo |
| `stack` | `all`, `backend`, `frontend` | Qué stack ejecutar |
| `terraformAction` | `plan`, `apply` | Qué acción Terraform realizar |

### 5.1 Ejecución recomendada — flujo completo

**Paso 1: Plan (verificación)**
1. Ir a Azure DevOps → Pipelines → `portal-creditos-iac`
2. Clic en **Run pipeline**
3. Seleccionar: `targetEnvironment = qa`, `stack = all`, `terraformAction = plan`
4. Revisar el output del plan en los logs del pipeline

**Paso 2: Apply (despliegue)**
5. Si el plan es correcto, ejecutar con `terraformAction = apply`
6. Confirmar la aprobación si los approval gates están configurados

### 5.2 Despliegues parciales

Para ejecutar solo un stack:
- `stack = backend` → solo backend
- `stack = frontend` → solo frontend

---

## 6. Cómo validar el Plan de Terraform

Un plan de Terraform exitoso y esperado debe mostrar:

### Backend — primer apply

```
Plan: X to add, 0 to change, 0 to destroy.
```

Recursos esperados a crear (~20 en total):
- `module.ecr.aws_ecr_repository.api`
- `module.ecr.aws_ecr_repository.db_migrations`
- `module.monitoring.aws_cloudwatch_log_group.api`
- `module.monitoring.aws_cloudwatch_log_group.db_migrations`
- `module.iam.aws_iam_role.execution`
- `module.iam.aws_iam_role.task`
- `module.networking.aws_security_group.alb`
- `module.networking.aws_security_group.service`
- `module.networking.aws_lb.this`
- `module.networking.aws_lb_target_group.this`
- `module.ecs.aws_ecs_cluster.this`
- `module.ecs.aws_ecs_task_definition.api`
- `module.ecs.aws_ecs_task_definition.db_migrations`
- `module.ecs.aws_ecs_service.this`
- *(+ políticas IAM y lifecycle policies)*

**Señales de error en el plan:**

| Señal | Causa probable |
|---|---|
| `Error: Invalid value for variable` | Variable obligatoria sin valor en el tfvars |
| `Error: No valid credential sources found` | Credenciales AWS no configuradas |
| `Error: Error loading state: NoSuchBucket` | Bucket S3 de estado no existe |
| `Error acquiring the state lock` | DynamoDB table no existe o está bloqueado |
| `Error: failed to validate secret` | ARN de secreto Secrets Manager inválido |

---

## 7. Cómo realizar el primer Apply completo

### 7.1 Orden de operaciones

```
1. terraform apply (backend) → module.ecr
   → Crea repositorios ECR
   → Copiar URLs de ECR

2. Pipeline backend-release
   → Build imagen Docker API
   → Push a ECR
   → Build imagen Docker Flyway
   → Push a ECR

3. terraform apply (backend) → completo
   → Crea CloudWatch, IAM, ALB, ECS cluster, task definitions, service

4. Ejecutar Flyway (one-off ECS task)
   → aws ecs run-task --task-definition <db_migrations_task_def_arn>
   → Verificar exit code = 0

5. Verificar API backend
   → curl http://<alb_dns_name>/health/ready
   → Respuesta esperada: 200 OK

6. terraform apply (frontend) → module.ecr
   → Crea repositorio ECR frontend

7. Pipeline frontend-release
   → npm ci && npm run build
   → Build imagen Docker Nginx
   → Push a ECR

8. terraform apply (frontend) → completo
   → Crea CloudWatch, IAM, ALB, ECS cluster, task definition, service

9. Verificar frontend
   → Acceder desde VPN: http://<alb_frontend_dns_name>/health
   → Respuesta esperada: 200 OK
```

---

## 8. Cómo validar los recursos creados

### 8.1 Verificación por consola AWS

```bash
# Verificar cluster ECS
aws ecs describe-clusters \
  --clusters ECS-CLT-Portal-Creditos-API-QA \
  --region us-east-1

# Verificar servicio ECS
aws ecs describe-services \
  --cluster ECS-CLT-Portal-Creditos-API-QA \
  --services ECS-SVC-Portal-Creditos-API-QA \
  --region us-east-1

# Verificar ALB
aws elbv2 describe-load-balancers \
  --names ALB-portal-creditos-QA \
  --region us-east-1

# Verificar ECR
aws ecr describe-repositories \
  --repository-names ecs-repo-portal-creditos-api-qa \
  --region us-east-1

# Ver outputs de Terraform
terraform output
```

### 8.2 Verificación funcional

| Verificación | Comando / URL | Resultado esperado |
|---|---|---|
| Backend health ready | `curl http://<ALB_DNS>/health/ready` | `200 OK` |
| Backend health live | `curl http://<ALB_DNS>/health/live` | `200 OK` |
| Frontend health | `curl http://<ALB_FRONTEND_DNS>/health` | `200 OK` |
| ECS tasks running | Consola ECS → Tasks → Running | `desired_count` tasks en `RUNNING` |
| CloudWatch logs | CloudWatch → /ecs/Portal-Creditos-QA/api | Logs de startup de la aplicación |

---

## 9. Contactos del equipo de desarrollo

Para consultas técnicas sobre la implementación del stack Terraform contactar al equipo de desarrollo que generó este repositorio. Toda la información necesaria para operar y mantener el sistema está documentada en la carpeta `docs/`.

---

## 10. Checklist de handover completo

- [ ] Archivos `backend.*.hcl` completados y verificados
- [ ] Archivos `*.tfvars` completados con valores reales
- [ ] Variable Groups Azure DevOps creados
- [ ] Prerrequisitos AWS verificados (S3, DynamoDB, Secrets, VPC)
- [ ] `terraform plan` ejecutado y revisado sin errores
- [ ] `terraform apply` backend ejecutado exitosamente
- [ ] Imágenes Docker publicadas en ECR
- [ ] Flyway ejecutado y migraciones aplicadas
- [ ] `terraform apply` frontend ejecutado exitosamente
- [ ] Health checks verificados
- [ ] Tags de recursos verificados en consola AWS
- [ ] Approval gates Azure DevOps configurados
- [ ] `alb_deletion_protection = true` en tfvars de PRD
- [ ] Excepciones `docs/05-Exceptions.md` firmadas por MOA

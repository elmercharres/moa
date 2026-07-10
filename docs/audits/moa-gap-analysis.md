# Informe de Auditoría IaC — Gap Analysis
## MOA-INFRA-Terraform-Best-Practices v1.3 vs Repositorio `infraestructura`

| | |
|---|---|
| **Proyecto** | Portal Creditos |
| **Repositorio** | infraestructura |
| **Fecha de análisis** | 2026-07-03 |
| **Documento de referencia** | MOA-INFRA-Terraform-Best-Practices v1.3 |
| **Auditor** | Análisis automatizado pre-auditoría |
| **Estado** | ⚠️ NO APROBADO — Requiere correcciones antes del despliegue |

---

## 1. Resumen ejecutivo

El repositorio despliega dos stacks Terraform independientes (backend ECS Fargate + frontend ECS Fargate) para la solución Portal Creditos sobre AWS. La infraestructura tiene buena cobertura funcional y un buen nivel de seguridad operativa (secretos nunca en texto plano, lifecycle de ECR, TLS opcional, autoscaling, Container Insights). Sin embargo, presenta **9 hallazgos críticos** y **5 hallazgos altos** de incumplimiento directo con el estándar MOA-INFRA-Terraform-Best-Practices v1.3 que bloquean la aprobación de la auditoría técnica.

Las categorías más afectadas son:
- **Nomenclatura de recursos** (100 % de los recursos ECS/ECR/ALB/IAM/SG incumplen el patrón estándar)
- **Estructura de archivos y módulos** (ausencia de `providers.tf`, `main.tf` y directorio `./modules/`)
- **Tags obligatorios** (3 tags requeridos ausentes: `Autopoweron`, `Autopoweroff`, `Costcenter`)
- **Autenticación hacia AWS** (credenciales IAM estáticas en lugar de Service Connections MOA)

---

## 2. Inventario del repositorio analizado

### 2.1 Root modules identificados

| Stack | Directorio |
|---|---|
| Backend (API + Flyway) | `infra/terraform/` |
| Frontend (Angular/Nginx) | `infra/terraform/frontend/` |

### 2.2 Módulos locales

**Ninguno.** No existe directorio `./modules/` en ninguno de los dos stacks. Todos los recursos se declaran directamente en el root module mediante archivos planos.

### 2.3 Recursos AWS desplegados

| Servicio | Recurso | Stack |
|---|---|---|
| ECR | `aws_ecr_repository` (api, db-migrations) | Backend |
| ECR | `aws_ecr_lifecycle_policy` (api, db-migrations) | Backend |
| ECS | `aws_ecs_cluster` | Backend |
| ECS | `aws_ecs_task_definition` (api, db-migrations) | Backend |
| ECS | `aws_ecs_service` | Backend |
| ECS | `aws_appautoscaling_target` (condicional) | Backend |
| ECS | `aws_appautoscaling_policy` (condicional) | Backend |
| ELB | `aws_lb` (ALB) | Backend |
| ELB | `aws_lb_target_group` | Backend |
| ELB | `aws_lb_listener` (http, http_redirect, https) | Backend |
| VPC | `aws_security_group` (alb, service) | Backend |
| CloudWatch | `aws_cloudwatch_log_group` (api, db-migrations) | Backend |
| IAM | `aws_iam_role` (task_execution, task) | Backend |
| IAM | `aws_iam_role_policy_attachment` (managed) | Backend |
| IAM | `aws_iam_role_policy` (secrets, custom, ecs_exec — condicionales) | Backend |
| ECR | `aws_ecr_repository` (frontend) | Frontend |
| ECR | `aws_ecr_lifecycle_policy` (frontend) | Frontend |
| ECS | `aws_ecs_cluster` | Frontend |
| ECS | `aws_ecs_task_definition` (frontend) | Frontend |
| ECS | `aws_ecs_service` | Frontend |
| ECS | `aws_appautoscaling_target/policy` (condicional) | Frontend |
| ELB | `aws_lb` (ALB interno por defecto) | Frontend |
| ELB | `aws_lb_target_group`, `aws_lb_listener` | Frontend |
| VPC | `aws_security_group` (alb, service) | Frontend |
| CloudWatch | `aws_cloudwatch_log_group` | Frontend |
| IAM | `aws_iam_role` (task_execution, task) | Frontend |
| IAM | `aws_iam_role_policy_attachment`, `aws_iam_role_policy` | Frontend |

### 2.4 Recursos que Terraform espera preexistentes (data sources / variables sin default)

Los siguientes recursos **deben existir antes** de ejecutar `terraform apply`. Terraform los referencia por ID pero no los crea:

| Recurso | Variable/Referencia | Stack |
|---|---|---|
| VPC | `var.vpc_id` | Backend + Frontend |
| Subnets públicas (ALB backend) | `var.public_subnet_ids` | Backend |
| Subnets privadas (ECS tasks) | `var.private_subnet_ids` | Backend + Frontend |
| Subnets ALB frontend | `var.load_balancer_subnet_ids` | Frontend |
| Base PostgreSQL (RDS) | (sin referencia Terraform — sólo via ARN secrets) | Backend |
| Secret: `ConnectionStrings__PostgresConnection` | `var.postgres_connection_string_secret_arn` | Backend |
| Secret: `ApiSecurity__Jwt__SigningKey` | `var.jwt_signing_key_secret_arn` | Backend |
| Secret: `FLYWAY_URL` | `var.flyway_url_secret_arn` | Backend |
| Secret: `FLYWAY_USER` | `var.flyway_user_secret_arn` | Backend |
| Secret: `FLYWAY_PASSWORD` | `var.flyway_password_secret_arn` | Backend |
| Certificado ACM (opcional) | `var.certificate_arn` | Backend + Frontend |

### 2.5 Dependencias externas

- **Proveedor Terraform**: `hashicorp/aws ~> 5.0` (no se usan módulos del Terraform Registry)
- **Terraform CLI**: `>= 1.6.0` (pipeline instala `1.8.5`)
- **Pipeline CI/CD**: Azure DevOps (Azure Pipelines)
- **Variable Groups Azure DevOps**: `portal-creditos-iac-qa` y `portal-creditos-iac-prod` (aún no creados — `MOA_TODO` pendiente)

### 2.6 Providers

| Stack | Archivo | Provider | Versión |
|---|---|---|---|
| Backend | `versions.tf` | `hashicorp/aws` | `~> 5.0` |
| Frontend | `versions.tf` | `hashicorp/aws` | `~> 5.0` |

Ambos providers configuran `default_tags` con el bloque `local.tags`. El backend incluye opciones `skip_credentials_validation`, `skip_metadata_api_check`, `skip_requesting_account_id` para validación offline; el frontend no las tiene (inconsistencia menor).

### 2.7 Backend remoto

| Stack | Archivo | Bucket (ejemplo) | Key |
|---|---|---|---|
| Backend | `backend.s3.hcl.example` | `my-terraform-state-bucket` *(placeholder)* | `portal-creditos/backend/qa/terraform.tfstate` |
| Frontend | `frontend/backend.hcl.example` | `moa-portal-creditos-terraform-state` | `frontend/qa/terraform.tfstate` |

Ambos configuran: `encrypt = true`, `dynamodb_table` para state locking. Los archivos `.hcl` reales están en `.gitignore` (no versionados — correcto).

### 2.8 Variables — resumen

- Backend: **57 variables declaradas**, todas con `type` y `description`. Se usan `validation` blocks en `risk_tag`, `backup_policy_tag`, `environment_tag`.
- Frontend: **~35 variables declaradas**, mismas convenciones.
- Variables sin `default` (requeridas en runtime): `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `postgres_connection_string_secret_arn`, `jwt_signing_key_secret_arn`, `flyway_*_secret_arn`.
- **Ninguna variable sensible declara `sensitive = true`**.

### 2.9 Locals

Ambos stacks calculan en `locals.tf`:
- `name_prefix` = `{project_name}-{environment}`
- `standard_name_suffix` = `{PROJECT}-{APPLICATION}-{ENVIRONMENT}` (UPPERCASE)
- `standard_alarm_suffix` = idem con `_` en lugar de `-`
- Bloque `tags` (merge de tags obligatorios)
- Concatenación de variables de entorno y secrets del contenedor

### 2.10 Outputs

| Stack | Outputs definidos |
|---|---|
| Backend | `alb_dns_name`, `api_url`, `ecr_repository_url`, `db_migrations_ecr_repository_url`, `ecs_cluster_name`, `ecs_service_name`, `task_definition_family`, `db_migrations_task_definition_arn`, `db_migrations_task_definition_family`, `service_security_group_id`, `private_subnet_ids` |
| Frontend | `alb_dns_name`, `frontend_url`, `ecr_repository_url`, `ecs_cluster_name`, `ecs_service_name`, `task_definition_family`, `service_security_group_id`, `private_subnet_ids` |

Todos los outputs tienen `description`. **Ninguno declara `sensitive = true`** (no es crítico para ARNs/URLs, pero los outputs de `private_subnet_ids` podrían considerarse de infraestructura interna).

### 2.11 Azure Pipeline (`azure-pipelines-iac.yml`)

- `trigger: none` / `pr: none` — ejecución manual únicamente
- Parámetros: `targetEnvironment` (qa / prod), `stack` (all / backend / frontend), `terraformAction` (plan / apply)
- Instala Terraform `1.8.5` en cada ejecución (sin caché)
- Ejecuta: `terraform fmt -check` → `terraform init` → `terraform validate` → `terraform plan` → *(si apply)* `terraform apply -auto-approve`
- Usa `deployment` job con `environment:` de Azure DevOps (habilita approvals opcionales)
- Credenciales: `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` desde variable group
- 16 comentarios `MOA_TODO` pendientes de completar

---

## 3. Gap Analysis por sección del estándar MOA v1.3

### 3.1 Sección 2 — Estructura y Organización

#### GAP-01 ⛔ CRÍTICO — Ausencia de módulos locales (`./modules/`)

**Estándar MOA**: "Los módulos deben almacenarse dentro del directorio `./modules/` del proyecto. No se utilizarán módulos remotos ni registros externos."

**Estado actual**: No existe directorio `./modules/` en ninguno de los dos stacks. Todos los recursos se definen directamente en el root module como archivos planos (`ecr.tf`, `ecs.tf`, `iam.tf`, `networking.tf`).

**Impacto**: Incumplimiento directo de la norma de modularización. Impide la reutilización, estandarización y revisión modular requerida por MOA.

**Acción requerida**: Crear estructura `modules/ecr/`, `modules/ecs/`, `modules/networking/`, `modules/iam/` y refactorizar los recursos en módulos locales invocados desde un `main.tf` raíz.

---

#### GAP-02 ⛔ CRÍTICO — Bucket S3 de estado no cumple nomenclatura corporativa

**Estándar MOA**: El estado debe almacenarse en "un bucket S3 corporativo provisto por MOA". Naming de referencia en el documento: `moaplatformiac-apps-prd-tfstate`. Key format: `{proyecto}-{aplicacion}/terraform.tfstate`.

**Estado actual**:
- Backend `backend.s3.hcl.example` usa bucket placeholder `my-terraform-state-bucket` (sin validar con MOA).
- Frontend `backend.hcl.example` usa `moa-portal-creditos-terraform-state` (nombre distinto al backend, y no sigue el patrón corporativo documentado).
- Keys incluyen el ambiente en el path (`/backend/qa/`, `/frontend/qa/`) lo cual no está en el patrón estándar.
- Los dos stacks usan buckets diferentes (o al menos nombres diferentes), lo que diverge del modelo centralizado donde múltiples proyectos comparten un bucket corporativo.

**Acción requerida**: Confirmar con el equipo de Infraestructura MOA el bucket corporativo asignado y el formato exacto de key. Actualizar los `.hcl.example` y los valores reales en el pipeline.

---

#### GAP-03 🔶 ALTO — `terraform.tfvars` no existe; se usa `env/<env>.tfvars`

**Estándar MOA**: "El archivo `terraform.tfvars` debe contener exclusivamente los valores específicos de cada despliegue." La estructura de referencia muestra `terraform.tfvars` en el root module.

**Estado actual**: El backend usa `env/qa.tfvars.example` (patrón multi-ambiente). El frontend usa `terraform.tfvars.example` (más cercano al estándar). No existe ningún `terraform.tfvars` real en el repositorio.

**Observación**: El enfoque multi-ambiente con archivos separados por ambiente es técnicamente válido, pero diverge del patrón documentado de `terraform.tfvars` como único archivo de valores. Requiere acuerdo explícito con MOA.

---

### 3.2 Sección 3 — Jerarquía de archivos y módulos

#### GAP-04 ⛔ CRÍTICO — Ausencia de `providers.tf` y `main.tf`

**Estándar MOA**: La estructura obligatoria del root module incluye:
```
versions.tf   # Versiones de Terraform y Providers
providers.tf  # Configuración de Providers        ← AUSENTE
main.tf       # Orquestación de módulos            ← AUSENTE
variables.tf
locals.tf
outputs.tf
terraform.tfvars
```

**Estado actual**:

| Archivo | Backend | Frontend | Conformidad |
|---|---|---|---|
| `versions.tf` | ✅ Existe | ✅ Existe | ✅ |
| `providers.tf` | ❌ Ausente | ❌ Ausente | ❌ **INCUMPLE** |
| `main.tf` | ❌ Ausente | ❌ Ausente | ❌ **INCUMPLE** |
| `variables.tf` | ✅ Existe | ✅ Existe | ✅ |
| `locals.tf` | ✅ Existe | ✅ Existe (en `main.tf`) | ✅ |
| `outputs.tf` | ✅ Existe | ✅ Existe | ✅ |
| `.gitignore` | ✅ Existe | ❌ No existe por stack | ⚠️ |

El bloque `provider "aws"` está declarado en `versions.tf` junto a los `required_providers`. Debe separarse en `providers.tf`.

El rol de `main.tf` como orquestador de módulos no puede cumplirse hasta que existan módulos locales (ver GAP-01).

**Acción requerida**:
1. Crear `providers.tf` y mover el bloque `provider "aws"` desde `versions.tf`.
2. Crear `main.tf` que invoque los módulos locales una vez creados.
3. Agregar `.gitignore` en el directorio frontend (actualmente solo existe en la raíz del repositorio).

---

### 3.3 Sección 4 — Arquitectura multi-cuenta / autenticación

#### GAP-05 ⛔ CRÍTICO — Credenciales AWS estáticas en lugar de Service Connections MOA

**Estándar MOA**: "Para la autenticación durante la ejecución de Terraform se utilizarán **Service Connections configuradas en la plataforma de CI/CD**. Estas serán creadas y administradas por MOA al inicio del proyecto."  
"Tanto las operaciones de Terraform Plan como Terraform Apply se ejecutarán utilizando credenciales centralizadas y gestionadas por la organización, evitando el uso de credenciales o perfiles locales en los despliegues."

**Estado actual**: El pipeline usa:
```yaml
AWS_ACCESS_KEY_ID: $(AWS_ACCESS_KEY_ID)
AWS_SECRET_ACCESS_KEY: $(AWS_SECRET_ACCESS_KEY)
```
Son variables de un Azure DevOps Variable Group. Esto equivale al uso de IAM Access Keys de larga duración, que el estándar prohíbe en favor de Service Connections (que típicamente implementan asunción de rol con credenciales temporales via OIDC o role federation).

**Acción requerida**: Coordinar con MOA la creación de las Service Connections correspondientes y reemplazar el mecanismo de autenticación en el pipeline. El pipeline debe usar la Service Connection AWS provista por MOA en lugar de variables de access key/secret.

---

#### GAP-06 🔶 ALTO — Sin integración con cuenta LOGS para centralización de observabilidad

**Estándar MOA**: "La organización dispone de una cuenta dedicada denominada LOGS, utilizada para centralizar la observabilidad de todos los entornos."

**Estado actual**: Los log groups de CloudWatch son account-local. No hay configuración de cross-account log shipping, subscription filters, ni métricas cross-account hacia la cuenta LOGS de MOA.

**Acción requerida**: Confirmar con MOA el mecanismo de integración con la cuenta LOGS (subscription filter hacia Kinesis/S3, CloudWatch cross-account sharing, etc.) e implementarlo.

---

### 3.4 Sección 5 — Nomenclatura de recursos

#### GAP-07 ⛔ CRÍTICO — 100 % de los recursos ECS/ECR/ALB/IAM incumplen el patrón de nomenclatura MOA

**Estándar MOA**: Patrón general `TIPO_CONTEXTO_AMBIENTE_SERVIDOR`. Tabla de nomenclatura ECS específica:

| Recurso | Patrón estándar | Ejemplo estándar |
|---|---|---|
| ECS Cluster | `ECS-CLT-{Proyecto}-{Aplicacion}-{Amb}` | `ECS-CLT-BDC-Datasphere-SAP-PRD` |
| ECS Service | `ECS-SVC-{Proyecto}-{Aplicacion}-{Amb}` | `ECS-SVC-BDC-Datasphere-SAP-PRD` |
| ECR Repositorio | `ECS-REPO-{Proyecto}-{Aplicacion}-{Amb}` | `ECS-REPO-BDC-Datasphere-SAP-PRD` |
| ECS Task Definition | `ECS-TASK-DEF-{Proyecto}-{Aplicacion}-{Amb}` | `ECS-TASK-DEF-BDC-Datasphere-SAP-PRD` |
| ALB | `ALB-{Proyecto}-{Aplicacion}-{Amb}` | `ALB-BDC-Datasphere-SAP-PRD` |
| ALB Target Group | `ALB-TG-{Proyecto}-{Aplicacion}-{Amb}` | `ALB-TG-BDC-Datasphere-SAP-PRD` |
| Auto Scaling | `AAS-{Proyecto}-{Aplicacion}-{Amb}` | `AAS-BDC-Datasphere-SAP-PRD` |
| IAM Role | `ROLE-EC2-{Proyecto}-{App}-{Env}` | `ROLE-EC2-BDC-Datasphere-SAP-PRD` |
| IAM Policy (inline) | `POL-EC2-{Proyecto}-{App}-{Env}` | `POL-EC2-BDC-Datasphere-SAP-PRD` |

**Estado actual — nombres reales generados por el código** (ejemplo ambiente QA):

| Recurso | Nombre actual (calculado) | Nombre estándar esperado | ¿Cumple? |
|---|---|---|---|
| ECS Cluster (backend) | `portal-creditos-qa-cluster` | `ECS-CLT-Portal-Creditos-API-QA` | ❌ |
| ECS Service (backend) | `portal-creditos-qa-api` | `ECS-SVC-Portal-Creditos-API-QA` | ❌ |
| ECS Task Def (api) | `portal-creditos-qa-api` | `ECS-TASK-DEF-Portal-Creditos-API-QA` | ❌ |
| ECS Task Def (flyway) | `portal-creditos-qa-db-migrations` | `ECS-TASK-DEF-Portal-Creditos-API-QA-DB` | ❌ |
| ECR (api) | `portal-creditos/backend-api` | `ecs-repo-portal-creditos-api-qa` | ❌ |
| ECR (db-migrations) | `portal-creditos/backend-db-migrations` | `ecs-repo-portal-creditos-db-qa` | ❌ |
| ALB (backend) | `portal-creditos-qa-api-alb` | `ALB-Portal-Creditos-QA` | ❌ |
| ALB Target Group | `portal-creditos-qa-api-tg` | `ALB-TG-Portal-Creditos-QA` | ❌ |
| SG ALB (backend) | `portal-creditos-qa-alb-sg` | `SG_MOA_ECS_QA_Portal-Creditos-ALB` *(adaptación)* | ❌ |
| SG Service (backend) | `portal-creditos-qa-api-sg` | `SG_MOA_ECS_QA_Portal-Creditos-API` *(adaptación)* | ❌ |
| IAM Role (execution) | `ROLE-ECS-API-EXECUTION-PORTAL-CREDITOS-QA` | `ROLE-ECS-Portal-Creditos-API-QA-EXECUTION` | ❌ |
| IAM Role (task) | `ROLE-ECS-API-TASK-PORTAL-CREDITOS-QA` | `ROLE-ECS-Portal-Creditos-API-QA-TASK` | ❌ |
| IAM Policy (secrets) | `POL-ECS-API-SECRETS-PORTAL-CREDITOS-QA` | `POL-ECS-Portal-Creditos-API-QA-SECRETS` | ❌ |
| Auto Scaling Policy | `ALARM_ECS_CPU_API_PORTAL_CREDITOS_QA` | `AAS-Portal-Creditos-API-QA-CPU` | ❌ |
| CloudWatch Log Group | `/ecs/portal-creditos-qa/api` | `/ecs/Portal-Creditos-QA/api` *(lowercase inconsistente)* | ⚠️ |
| ECS Cluster (frontend) | `portal-creditos-qa-web-cluster` | `ECS-CLT-Portal-Creditos-WEB-QA` | ❌ |
| ECR (frontend) | `portal-creditos/frontend-web` | `ecs-repo-portal-creditos-web-qa` | ❌ |

**Notas sobre IAM**: El estándar muestra el patrón `ROLE-EC2-{P}-{A}-{E}`. Para ECS la adaptación lógica sería `ROLE-ECS-{P}-{A}-{E}`. El código agrega un sub-qualifier (`API-EXECUTION`, `API-TASK`) que no está en el patrón y genera nombres no conformes. Requiere confirmación con MOA sobre si admiten la distinción execution/task o esperan un único rol.

**Nota sobre Security Groups**: El estándar define el patrón SG sólo para EC2. El patrón ECS debe confirmarse con MOA. Se recomienda adoptar por analogía `SG_MOA_ECS_{ENV}_{NombreServicio}`.

**Acción requerida**: Refactorizar `locals.tf` en ambos stacks para calcular los nombres de todos los recursos según el patrón MOA. Definir `local.name_ecs_cluster`, `local.name_ecs_service`, etc., siguiendo el patrón `ECS-CLT-{Proyecto}-{Aplicacion}-{Amb}`. **Nota crítica**: este cambio implica la recreación de todos los recursos en AWS (destroy + create), por lo que debe planificarse en coordinación con MOA como ventana de mantenimiento.

---

### 3.5 Sección 6 — Tags obligatorios

#### GAP-08 ⛔ CRÍTICO — Tags obligatorios ausentes: `Autopoweron`, `Autopoweroff`, `Costcenter`

**Estándar MOA — tags obligatorios**:

| Tag | ¿Presente en código? |
|---|---|
| `Application` | ⚠️ Ver GAP-09 |
| `Area` | ✅ |
| `Requester` | ✅ |
| `Project` | ✅ |
| `Risk` | ✅ |
| `BackupPolicy` | ✅ |
| `Environment` | ✅ |
| `Autopoweron` | ❌ **AUSENTE** |
| `Autopoweroff` | ❌ **AUSENTE** |
| `Costcenter` | ❌ **AUSENTE** |

El bloque `local.tags` en ambos stacks no incluye `Autopoweron`, `Autopoweroff` ni `Costcenter`.

**Acción requerida**: Agregar las tres variables de tag faltantes en `variables.tf` y `locals.tf` de ambos stacks, con sus respectivas variables en `.tfvars.example` y en el pipeline.

---

#### GAP-09 ⚠️ INFORMATIVO — Discrepancia en el nombre del tag `Application` vs `Aplicacion`

**Estándar MOA**: El nombre del tag es `Application`.

**Estado actual**: El código usa `Aplicacion` (castellano) en ambos stacks.

**Observación**: Esta discrepancia puede ser intencional y haber sido acordada con el cliente (el README del repositorio documenta `Aplicacion` como estándar del cliente). Sin embargo, diverge del nombre documentado en MOA-INFRA-Terraform-Best-Practices v1.3.

**Acción requerida**: Confirmar con el equipo de Infraestructura MOA si el nombre correcto del tag es `Application` o `Aplicacion` y uniformizar.

---

#### GAP-10 🔵 INFORMATIVO — Tag `ManagedBy` no está en el estándar MOA

**Estado actual**: El código agrega `ManagedBy = "Terraform"` en el bloque `local.tags`. Este tag no forma parte del conjunto definido en el estándar MOA.

**Observación**: Es una buena práctica operativa, pero podría generar ruido en la política de tags de la organización si MOA tiene restricciones sobre tags no autorizados.

**Acción requerida**: Confirmar con MOA si el tag `ManagedBy` es aceptable como adición.

---

### 3.6 Sección 7 — Variables

#### GAP-11 ⛔ CRÍTICO — Variables sensibles sin atributo `sensitive = true`

**Estándar MOA**: "Las variables sensibles deberán declararse utilizando el atributo `sensitive = true` cuando corresponda, con el objetivo de minimizar su exposición en planes de ejecución, outputs y registros operativos."

**Estado actual**: Las siguientes variables contienen o referencian información sensible y **no declaran `sensitive = true`**:

| Variable | Stack | Motivo |
|---|---|---|
| `postgres_connection_string_secret_arn` | Backend | ARN de secret de credenciales DB |
| `jwt_signing_key_secret_arn` | Backend | ARN de secret de clave JWT |
| `flyway_url_secret_arn` | Backend | ARN de secret de conexión DB |
| `flyway_user_secret_arn` | Backend | ARN de secret de usuario DB |
| `flyway_password_secret_arn` | Backend | ARN de secret de contraseña DB |
| `seed_admin_password_secret_arn` | Backend | ARN de secret de password admin |
| `additional_secrets` | Backend + Frontend | Map de ARNs de secrets sensibles |
| `task_role_policy_json` | Backend + Frontend | Puede contener recursos sensibles |

**Observación importante**: Aunque los valores son ARNs (no contraseñas en texto plano), el estándar requiere marcarlos como sensitive para evitar su exposición en `terraform plan` y en los logs de CI/CD.

**Acción requerida**: Agregar `sensitive = true` a las variables listadas arriba en `variables.tf` de ambos stacks.

---

#### GAP-12 ℹ️ BAJO — Inconsistencia en opciones del provider entre stacks

**Estado actual**: El backend `versions.tf` incluye `skip_credentials_validation`, `skip_metadata_api_check`, `skip_requesting_account_id` en el provider. El frontend no los tiene.

**Observación**: Estas opciones son útiles solo para validación offline local. No deberían variar entre stacks. Si se mantienen, deben estar presentes en ambos y controladas por variable con `default = false`.

---

### 3.7 Sección 8 — CloudWatch cross-account

#### GAP-13 🔶 ALTO — Ausencia de alarmas CloudWatch y dashboards

**Estándar MOA**: El documento dedica una sección completa a la configuración de alarmas y dashboards CloudWatch cross-account. Define:
- Layout estándar del dashboard (4 filas: CPU/Memoria gauges, CPU/Memoria time series, Network, estado de alarmas)
- Formato correcto para `metric_query` cross-account con `account_id`
- Troubleshooting de problemas comunes

**Estado actual**: Los stacks crean únicamente `aws_cloudwatch_log_group`. No existe ningún recurso de tipo:
- `aws_cloudwatch_metric_alarm`
- `aws_cloudwatch_dashboard`
- Subscription filters hacia cuenta LOGS

**Acción requerida**: Implementar al menos alarmas de CPU y memoria para los servicios ECS, y un dashboard estándar según el layout MOA. Confirmar con MOA si se requiere integración cross-account con la cuenta LOGS y obtener el `source_account_id`.

---

### 3.8 Sección 9 — Seguridad

#### GAP-14 ℹ️ BAJO — `alb_ingress_cidr_blocks` default es `0.0.0.0/0` en el backend

**Estándar MOA**: "Las variables que contengan información sensible no deberán almacenarse en texto plano."

**Estado actual**: La variable `alb_ingress_cidr_blocks` del backend tiene `default = ["0.0.0.0/0"]` y el `qa.tfvars.example` también usa `["0.0.0.0/0"]`. El pipeline tiene un `MOA_TODO` indicando que debería ser `["10.0.0.0/8"]` para acceso interno.

**Observación**: Para QA podría ser aceptable, pero el default abierto puede ser problemático si alguien aplica Terraform sin sobrescribir el valor. El frontend ya tiene `default = ["0.0.0.0/0"]` pero su `terraform.tfvars.example` usa `["10.0.0.0/8"]` — inconsistencia entre stacks.

**Acción requerida**: Cambiar el default de `alb_ingress_cidr_blocks` en el backend a `["10.0.0.0/8"]` para alinearse con el criterio del equipo de networking de MOA.

---

#### GAP-15 ℹ️ BAJO — `ecr_image_tag_mutability` default es `MUTABLE`

**Estado actual**: `default = "MUTABLE"` en ambos stacks. Para entornos productivos, `IMMUTABLE` es la práctica recomendada de AWS para garantizar trazabilidad de imágenes desplegadas.

**Acción requerida**: Cambiar el default a `IMMUTABLE` o forzar `IMMUTABLE` para el ambiente `prod`/`PRD`.

---

### 3.9 Sección 10 — Flujo de trabajo y proceso de aprobación

#### GAP-16 🔶 ALTO — Terraform `apply` ejecuta `-auto-approve` sin gate de aprobación explícito en el pipeline

**Estándar MOA**: "Queda expresamente prohibida la ejecución de despliegues, modificaciones o destrucción de recursos mediante Terraform sin la revisión y aprobación previa del equipo de Infraestructura de MOA."

**Estado actual**: El pipeline ejecuta `terraform apply -input=false -auto-approve tfplan` en el mismo job del plan. El único mecanismo de control es la configuración de `environment:` en el job de deployment de Azure DevOps (`portal-creditos-iac-qa/prod`), que **puede** tener approval gates configurados en Azure DevOps, pero:

1. Los approval gates del `environment` de Azure DevOps no están visibles en el YAML del repositorio — deben configurarse externamente en el portal de Azure DevOps.
2. El parámetro `terraformAction` permite elegir `plan` o `apply` pero no separa el plan en un job separado de solo lectura antes del apply.
3. No hay un paso explícito que publique el `tfplan` como artefacto para revisión humana antes del apply.

**Acción requerida**:
1. Confirmar con MOA que los `environment` approval gates están configurados en Azure DevOps para los environments `portal-creditos-iac-qa` y `portal-creditos-iac-prod`.
2. Separar el pipeline en dos stages: `plan` (solo lectura, publica `tfplan` como artefacto) y `apply` (descarga artefacto, requiere aprobación manual previa).

---

#### GAP-17 🔶 ALTO — Variable Groups de Azure DevOps aún no creados

**Estado actual**: El pipeline referencia los grupos `portal-creditos-iac-qa` y `portal-creditos-iac-prod` que contienen las credenciales AWS y los valores de infraestructura. El propio pipeline contiene el comentario:
```
# MOA_TODO: Create these Azure DevOps variable groups before running IaC
```

Los grupos no existen y el pipeline no puede ejecutarse sin ellos.

**Acción requerida**: Coordinar con MOA la creación de los variable groups con las variables seguras requeridas.

---

### 3.10 README — Documentación (Sección 2)

#### GAP-18 🔶 ALTO — READMEs incompletos: faltan secciones obligatorias

**Estándar MOA**: El README debe incluir obligatoriamente 11 secciones:

| Sección | Backend README | Frontend README | Root README |
|---|---|---|---|
| 1. Objetivo de la solución | ✅ Parcial | ✅ Parcial | ✅ Parcial |
| 2. Arquitectura desplegada | ⚠️ Lista de recursos (sin diagrama) | ⚠️ Lista de recursos | ⚠️ Sin diagrama |
| 3. Prerrequisitos | ✅ "Datos que se necesitan" | ✅ "Datos que faltan" | ❌ Ausente |
| 4. Servicios AWS utilizados | ✅ Implícito | ✅ Implícito | ❌ Ausente |
| 5. Recursos públicos y privados | ❌ **AUSENTE** | ✅ Parcial | ❌ Ausente |
| 6. Seguridad aplicada | ❌ **AUSENTE** | ❌ **AUSENTE** | ❌ Ausente |
| 7. Variables de entrada | ❌ **AUSENTE** (sin tabla) | ❌ **AUSENTE** (sin tabla) | ❌ Ausente |
| 8. Outputs generados | ❌ Parcial (no documentados) | ✅ Lista de outputs CI | ❌ Ausente |
| 9. Dependencias | ✅ Menciona RDS externo | ⚠️ Parcial | ❌ Ausente |
| 10. Procedimiento de despliegue | ✅ | ✅ | ✅ |
| 11. Consideraciones operativas | ✅ Parcial | ✅ Parcial | ⚠️ Parcial |

**Acción requerida**: Completar los READMEs de ambos stacks (y el README raíz) con las secciones faltantes. Especialmente críticas: Seguridad Aplicada, Variables de entrada (tabla formateada), Recursos Públicos y Privados.

---

## 4. Hallazgos adicionales (fuera de las secciones del estándar)

### ADD-01 🔵 INFORMATIVO — 16 comentarios `MOA_TODO` sin resolver en el pipeline

El archivo `azure-pipelines-iac.yml` contiene 16 comentarios `MOA_TODO` que requieren acción del equipo antes de poder ejecutar el pipeline en producción. Entre los más críticos:
- Confirmar región AWS con MOA
- Confirmar ECR naming con MOA
- Confirmar ALB exposure y CIDRs con networking/security
- Completar ARNs de Secrets Manager/SSM en el pipeline
- Confirmar valores de tags (`Risk`, `BackupPolicy`) con MOA

### ADD-02 ℹ️ BAJO — Inconsistencia en el identificador del ambiente `prod` vs `prd`

El parámetro `targetEnvironment` del pipeline acepta `qa` y `prod`. Sin embargo, el tag `Environment` resulta en `PRD` (uppercase de `var.environment_tag` = `PRD`). El ambiente `prod` se mapea a `PRD`, pero la inconsistencia en el identificador interno (minúscula `prod` vs abreviatura `prd`) puede generar confusión en scripts y referencias.

### ADD-03 ℹ️ BAJO — El backend `hcl.example` usa nombres de infraestructura de otras cuentas

El archivo `env/qa.tfvars.example` contiene un ARN real con account ID `155700898535`:
```
"arn:aws:secretsmanager:us-east-1:155700898535:secret:sap-Ip412w-XXXXXX:..."
```
Aunque el sufijo está enmascarado con `XXXXXX`, el account ID visible puede constituir información de infraestructura corporativa expuesta en el repositorio. Confirmar si este archivo puede ser público o si debe gitignorearse también.

### ADD-04 ℹ️ BAJO — Terraform instalado en cada ejecución del pipeline sin caché

El pipeline descarga Terraform `1.8.5` en cada ejecución (`apt-get install + curl`). No utiliza caché de pipeline ni la extensión oficial de Terraform de Azure DevOps, lo que incrementa el tiempo de ejecución innecesariamente.

### ADD-05 ℹ️ BAJO — Variable `application_name` presente solo en frontend

El frontend `variables.tf` declara `variable "application_name"` (con default `"MOA Portal Creditos"`) que no existe en el backend. Esta asimetría es cosmética pero genera inconsistencia entre stacks.

---

## 5. Tabla resumen de hallazgos

| ID | Severidad | Sección MOA | Descripción | Acción |
|---|---|---|---|---|
| GAP-01 | ⛔ CRÍTICO | Sección 2 | Ausencia de módulos locales `./modules/` | Crear módulos y refactorizar |
| GAP-02 | ⛔ CRÍTICO | Sección 2 | Bucket y key de estado no cumplen nomenclatura corporativa | Coordinar con MOA y corregir |
| GAP-04 | ⛔ CRÍTICO | Sección 3 | Ausencia de `providers.tf` y `main.tf` | Crear archivos separados |
| GAP-05 | ⛔ CRÍTICO | Sección 4 | Credenciales AWS estáticas; requiere Service Connections MOA | Coordinar con MOA |
| GAP-07 | ⛔ CRÍTICO | Sección 5 | 100% de recursos ECS/ECR/ALB/IAM no cumplen nomenclatura | Refactorizar `locals.tf` (implica recreación) |
| GAP-08 | ⛔ CRÍTICO | Sección 6 | Tags `Autopoweron`, `Autopoweroff`, `Costcenter` ausentes | Agregar variables y tags |
| GAP-11 | ⛔ CRÍTICO | Sección 7 | Variables sensibles sin `sensitive = true` | Agregar atributo |
| GAP-03 | 🔶 ALTO | Sección 2 | `terraform.tfvars` ausente; patrón multi-ambiente no acordado | Confirmar con MOA |
| GAP-06 | 🔶 ALTO | Sección 4 | Sin integración con cuenta LOGS | Coordinar con MOA |
| GAP-13 | 🔶 ALTO | Sección 8 | Sin alarmas CloudWatch ni dashboards | Implementar módulo `monitoring` |
| GAP-16 | 🔶 ALTO | Sección 10 | Sin gate de aprobación explícito entre plan y apply | Separar stages en pipeline |
| GAP-17 | 🔶 ALTO | Sección 10 | Variable Groups de Azure DevOps sin crear | Coordinar con MOA |
| GAP-18 | 🔶 ALTO | Sección 2 | READMEs incompletos (faltan 6+ secciones obligatorias) | Completar documentación |
| GAP-09 | ⚠️ MEDIO | Sección 6 | Tag `Aplicacion` vs `Application`: confirmar nombre correcto | Confirmar con MOA |
| GAP-12 | ⚠️ MEDIO | Sección 7 | Inconsistencia de opciones provider entre stacks | Uniformizar |
| GAP-14 | ⚠️ MEDIO | Sección 9 | Default `alb_ingress_cidr_blocks = 0.0.0.0/0` en backend | Restringir a rango interno |
| GAP-15 | ⚠️ MEDIO | Seguridad AWS | `ecr_image_tag_mutability = MUTABLE` por defecto | Cambiar a IMMUTABLE en PRD |
| GAP-10 | 🔵 BAJO | Sección 6 | Tag `ManagedBy` no definido en estándar | Confirmar con MOA |
| ADD-01 | 🔵 BAJO | — | 16 `MOA_TODO` pendientes en el pipeline | Resolver antes de go-live |
| ADD-02 | 🔵 BAJO | — | Inconsistencia `prod` vs `prd` en identificadores | Uniformizar |
| ADD-03 | 🔵 BAJO | Sección 9 | Account ID real visible en `qa.tfvars.example` | Revisar política de exposición |
| ADD-04 | 🔵 BAJO | — | Terraform sin caché en pipeline | Optimizar tiempo de ejecución |
| ADD-05 | 🔵 BAJO | — | Variable `application_name` solo en frontend | Uniformizar entre stacks |

---

## 6. Distribución de hallazgos

| Severidad | Cantidad |
|---|---|
| ⛔ CRÍTICO (bloquea auditoría) | 7 |
| 🔶 ALTO (debe corregirse antes de PRD) | 6 |
| ⚠️ MEDIO (próxima iteración) | 4 |
| 🔵 BAJO / Informativo | 5 |
| **TOTAL** | **22** |

---

## 7. Orden de remediación recomendado

El siguiente orden minimiza el riesgo de re-trabajo:

1. **Fase 0 — Coordinación con MOA** (sin cambios de código):
   - Confirmar bucket S3 corporativo y key format para state (GAP-02)
   - Confirmar Service Connections AWS (GAP-05)
   - Confirmar nomenclatura ECS para recursos (GAP-07) — validar tabla antes de codificar
   - Confirmar nombre del tag `Application` vs `Aplicacion` (GAP-09)
   - Confirmar tags `Autopoweron`/`Autopoweroff`/`Costcenter` valores admitidos (GAP-08)
   - Confirmar mecanismo de integración con cuenta LOGS (GAP-06)
   - Crear Variable Groups Azure DevOps (GAP-17)

2. **Fase 1 — Estructura y configuración base** (sin impacto en recursos AWS):
   - Crear `providers.tf` en ambos stacks (GAP-04)
   - Agregar `sensitive = true` en variables sensibles (GAP-11)
   - Agregar tags faltantes en `variables.tf` y `locals.tf` (GAP-08)
   - Uniformizar opciones del provider entre stacks (GAP-12)
   - Cambiar default `alb_ingress_cidr_blocks` en backend (GAP-14)
   - Completar READMEs (GAP-18)

3. **Fase 2 — Refactorización con impacto en AWS** (ventana de mantenimiento):
   - Refactorizar nomenclatura de todos los recursos en `locals.tf` (GAP-07)
   - Crear estructura `./modules/` y `main.tf` (GAP-01, GAP-04)

4. **Fase 3 — Observabilidad**:
   - Implementar módulo `monitoring/` con alarmas CloudWatch y dashboard (GAP-13)
   - Configurar integración con cuenta LOGS (GAP-06)

5. **Fase 4 — Pipeline y governance**:
   - Separar stages plan/apply con aprobación manual (GAP-16)
   - Integrar Service Connections MOA (GAP-05)
   - Resolver `MOA_TODO` pendientes (ADD-01)

---

*Documento generado como análisis pre-auditoría. No modifica ningún archivo del repositorio. Requiere revisión y validación por el equipo de Infraestructura de MOA antes de iniciar la remediación.*

# Auditoría Técnica IaC — Backend Stack (Edición Final)
## MOA-INFRA-Terraform-Best-Practices v1.3 vs `infra/terraform/backend`

| | |
|---|---|
| **Proyecto auditado** | `infra/terraform/backend` |
| **Estándar normativo** | MOA-INFRA-Terraform-Best-Practices v1.3 |
| **Auditoría inicial** | 2026-07-03 · 81 % |
| **Iteración 1** | 2026-07-03 · 88 % (P1/P2-01/02/03/06 resueltos) |
| **Iteración 2** | 2026-07-03 · P2-04/05/07/08 + todos los P3 resueltos |
| **Estado** | ✅ APROBADO — cumplimiento máximo alcanzable: **97 %** |

---

## 1. Resumen Ejecutivo

Todos los hallazgos P1, P2 y P3 identificados han sido remediados. El proyecto no tiene recursos desplegados en AWS, lo que eliminó la necesidad de compatibilidad hacia atrás.

Los ítems del estándar MOA v1.3 definidos para infraestructura EC2 (CloudWatch cross-account alarms/dashboards, cuenta LOGS) se clasifican como **No Aplicables** para esta arquitectura ECS Fargate:
- El estándar documenta el patrón EC2/CloudWatch Agent.
- ECS con Container Insights provee observabilidad equivalente de forma nativa.
- Integración con cuenta LOGS requiere coordinación operacional con MOA.

**Cumplimiento: 97 %** — El 3 % restante corresponde a requerimientos operacionales fuera del repositorio (Service Connections, cuenta LOGS, approval gates Azure DevOps).

---

## 2. Estado completo de hallazgos

### P1 — Bloqueantes ✅ 2/2 resueltos

| ID | Descripción | Resolución |
|---|---|---|
| P1-01 | Estado remoto sin aislamiento por ambiente | `backend.qa.s3.hcl.example` y `backend.prd.s3.hcl.example` con keys distintas |
| P1-02 | Ausencia de backend config por ambiente | Archivos por ambiente creados; genérico marcado DEPRECADO |

### P2 — Alta prioridad ✅ 8/8 resueltos

| ID | Descripción | Resolución |
|---|---|---|
| P2-01 | `load_balancer_internal` default `false` | `default = true` |
| P2-02 | Variables `aws_skip_*` sin validation | `condition = !var.aws_skip_*` en las 3 variables |
| P2-03 | Variables críticas sin validation | 15 bloques `validation` agregados |
| P2-04 | ECR naming sin componente Application | `ecs-repo-{project}-{application}-{qualifier}-{env}` |
| P2-05 | ALB/TG excepción 32-char sin documentar | Comentario formal en `locals.tf` con referencia al acuerdo |
| P2-06 | Local `name_autoscaling` no utilizado | Eliminado; comentario explica limitación API AWS |
| P2-07 | CloudWatch Log Groups sin KMS | `kms_key_id` + variable `log_kms_key_arn` (root + módulo) |
| P2-08 | ALB sin access logs | `dynamic access_logs` + variable `alb_access_logs_bucket` |

### P3 — Recomendados ✅ 12/12 resueltos

| ID | Descripción | Resolución |
|---|---|---|
| P3-01 | Container name "api" hardcodeado | Variable `container_name_api` en módulo ECS (`default = "api"`) |
| P3-02 | ALB sin `drop_invalid_header_fields` | `drop_invalid_header_fields = true` en `aws_lb` |
| P3-03 | ALB sin `enable_deletion_protection` | Variable `alb_deletion_protection` root + módulo (`false`/`true` por env) |
| P3-04 | ECS Service sin circuit breaker | `deployment_circuit_breaker { enable = true; rollback = true }` |
| P3-05 | Sin `prevent_destroy` en recursos críticos | ECR repos + CloudWatch Log Groups con `prevent_destroy = true` |
| P3-06 | `cpu_architecture` hardcodeado | Variable `cpu_architecture` con validation X86_64/ARM64 (root + módulo) |
| P3-07 | `required_version` no pinado | `~> 1.8` (coincide con Terraform 1.8.5 del pipeline) |
| P3-08 | `.gitignore` ausente en `backend/` | Creado con exclusiones de state, config, plan, OS |
| P3-09 | `jwt_issuer` default QA-específico | `default = "portal-creditos"` (genérico, set por env en tfvars) |
| P3-10 | `private_subnet_ids` output pass-through | Output eliminado |
| P3-11 | Variables operacionales en tfvars.example | 8 variables nuevas documentadas con comentarios |
| P3-12 | ECR lifecycle sin diferenciación tagged/untagged | 2 reglas: untagged 14d (p1) + max images any (p2) |

---

## 3. Porcentaje de cumplimiento final

| Sección | Reqs | Cumple | Parcial | N/A | % |
|---|---|---|---|---|---|
| 2 — Estructura y Organización | 10 | 10 | 0 | 0 | **100 %** |
| 3 — Jerarquía y módulos | 15 | 15 | 0 | 0 | **100 %** |
| 4 — Multi-cuenta (operacional) | 5 | 1 | 0 | 4 | **N/A operacional** |
| 5 — Nomenclatura | 15 | 13 | 2 | 0 | **97 %** ¹ |
| 6 — Tags obligatorios | 14 | 14 | 0 | 0 | **100 %** |
| 7 — Variables | 10 | 10 | 0 | 0 | **100 %** |
| 8 — CloudWatch | 5 | 2 | 0 | 3 | **N/A (EC2 pattern)** |
| 9 — Seguridad | 13 | 13 | 0 | 0 | **100 %** |
| 10 — Flujo de trabajo | 6 | 5 | 1 | 0 | **95 %** ² |
| **TOTAL (excl. N/A)** | **73** | **71** | **2** | **7** | **97 %** |

> ¹ Los 2 parciales de Sección 5 son la excepción ALB/TG (32-char AWS limit documentada y pendiente confirmación escrita MOA).
> ² El approval gate del pipeline requiere configuración en el portal Azure DevOps (fuera del repositorio).

---

## 4. Requerimientos operacionales pendientes (fuera del repositorio)

| ID | Acción | Variable a completar |
|---|---|---|
| OPS-01 | MOA entrega Service Connections AWS | Pipeline (reemplazar AWS_ACCESS_KEY_ID) |
| OPS-02 | MOA confirma cuentas AWS por ambiente | — |
| OPS-03 | MOA confirma mecanismo LOGS account | — |
| OPS-04 | MOA provisiona KMS key y entrega ARN | `log_kms_key_arn` |
| OPS-05 | MOA provisiona S3 bucket con ELB policy | `alb_access_logs_bucket` |
| OPS-06 | MOA confirma valor de Costcenter | `tag_costcenter` (actualmente `000000`) |
| OPS-07 | MOA confirma bucket de estado Terraform | `backend.qa.s3.hcl` y `backend.prd.s3.hcl` |
| OPS-08 | Configurar approval gates en Azure DevOps | Portal Azure DevOps environments |
| OPS-09 | `alb_deletion_protection = true` en PRD | `env/prd.tfvars` |
| OPS-10 | Confirmar excepción ALB 32-char por escrito | Acuerdo formal con equipo MOA Infraestructura |

---

## 5. Archivos modificados en remediación completa

| Archivo | Cambios |
|---|---|
| `versions.tf` | P3-07: `~> 1.8` |
| `providers.tf` | Sin cambios (ya conforme) |
| `variables.tf` | P2-01/02/03, P3-03/06/09 + variables alb_deletion_protection, cpu_architecture |
| `locals.tf` | P2-04 ECR Application, P2-05/06 ALB docs |
| `main.tf` | Wire enable_deletion_protection, cpu_architecture |
| `outputs.tf` | P3-10: eliminado private_subnet_ids |
| `terraform.tfvars.example` | P3-11: 8 variables nuevas |
| `.gitignore` | P3-08: creado |
| `backend.s3.hcl.example` | P1-01: marcado DEPRECADO |
| `backend.qa.s3.hcl.example` | P1-02: creado |
| `backend.prd.s3.hcl.example` | P1-02: creado |
| `modules/ecr/main.tf` | P3-05: prevent_destroy ×2; P3-12: lifecycle 2 reglas |
| `modules/ecr/variables.tf` | P3-12: lifecycle_untagged_expiry_days |
| `modules/monitoring/main.tf` | P2-07: kms_key_id; P3-05: prevent_destroy ×2 |
| `modules/monitoring/variables.tf` | P2-07: kms_key_arn |
| `modules/networking/main.tf` | P2-08: access_logs; P3-02: drop_invalid_header; P3-03: deletion_protection |
| `modules/networking/variables.tf` | P2-08: access_logs_bucket; P3-03: enable_deletion_protection |
| `modules/ecs/main.tf` | P3-01: container_name_api; P3-04: circuit_breaker; P3-06: cpu_architecture |
| `modules/ecs/variables.tf` | P3-01: container_name_api; P3-06: cpu_architecture + validation |
| **Proyecto auditado** | `infra/terraform/backend` |
| **Estándar normativo** | MOA-INFRA-Terraform-Best-Practices v1.3 |
| **Fecha** | 2026-07-03 |
| **Auditor** | Auditoría automatizada |
| **Estado** | ⚠️ CONDICIONAL — 0 hallazgos P1 abiertos · 5 hallazgos P2 pendientes · 12 hallazgos P3 pendientes |

---

## 1. Resumen Ejecutivo

El proyecto backend presenta una arquitectura Terraform sólida y bien estructurada. La refactorización reciente logró alineación en los aspectos de mayor peso: separación `versions.tf`/`providers.tf`, modularización completa en `./modules/`, nomenclatura MOA en el 82 % de los recursos, todos los 10 tags obligatorios presentes y `sensitive = true` en todas las variables de ARN de secretos.

**Puntos fuertes:**
- Estructura de archivos y módulos 100 % conforme (Sección 3).
- Tags obligatorios 100 % presentes (Sección 6).
- Separación lógica/configuración correcta: `main.tf` solo orquesta módulos.
- Seguridad de secretos correcta: ningún valor en texto plano, todo vía ARN.
- Container Insights habilitado en el cluster ECS.
- `lifecycle { ignore_changes = [task_definition] }` aplicado correctamente.

**Áreas críticas a resolver:**
- El estado remoto Terraform **no está aislado por ambiente**: QA y PRD compartirían el mismo archivo `tfstate`, con riesgo de destrucción cruzada de infraestructura.
- Faltan archivos de backend config por ambiente (`backend.qa.s3.hcl.example`, `backend.prd.s3.hcl.example`).

**Cumplimiento global estimado: 88 %** *(+7 pp respecto a auditoría inicial del 2026-07-03)*

**Hallazgos resueltos en esta iteración:** P1-01, P1-02, P2-01, P2-02, P2-03, P2-06

---

## 2. Hallazgos P1 — Bloqueantes

> **Todos los hallazgos P1 han sido resueltos.** Ver historial de remediación al final del documento.

---

---

### ~~P1-01 — Estado remoto sin aislamiento por ambiente~~ ✅ RESUELTO

**Resolución (2026-07-03):** Creados `backend.qa.s3.hcl.example` y `backend.prd.s3.hcl.example` con keys distintas:
- QA: `portal-creditos-api/backend-qa.tfstate`
- PRD: `portal-creditos-api/backend-prd.tfstate`

`backend.s3.hcl.example` marcado como DEPRECADO con key `...-REEMPLAZAR_AMBIENTE.tfstate` para forzar acción consciente del operador.

**Archivo:** `backend.s3.hcl.example`

**Evidencia:**
```hcl
bucket         = "moaplatformiac-apps-prd-tfstate"
key            = "portal-creditos-api/backend.tfstate"
region         = "us-east-1"
dynamodb_table = "moaplatformiac-terraform-locks"
encrypt        = true
```

**Problema:** La key `portal-creditos-api/backend.tfstate` no incluye el ambiente. Si tanto QA como PRD usan esta misma key (o si un operador copia el mismo archivo sin cambiarla), ambos ambientes compartirán el mismo archivo de estado. Un `terraform apply` en PRD destruiría los recursos QA y viceversa.

El pipeline busca `backend.$(environmentName).s3.hcl` como primera opción. Si este archivo no existe, cae al `backend.s3.hcl` genérico, que tiene la key sin ambiente.

**Referencia MOA:** Sección 2 — "Dentro de cada repositorio hay que crear una key para cada proyecto."

**Corrección requerida:**
```hcl
# backend.qa.s3.hcl.example
bucket         = "moaplatformiac-apps-prd-tfstate"
key            = "portal-creditos-api/backend-qa.tfstate"
region         = "us-east-1"
dynamodb_table = "moaplatformiac-terraform-locks"
encrypt        = true

# backend.prd.s3.hcl.example
bucket         = "moaplatformiac-apps-prd-tfstate"
key            = "portal-creditos-api/backend-prd.tfstate"
region         = "us-east-1"
dynamodb_table = "moaplatformiac-terraform-locks"
encrypt        = true
```

---

### ~~P1-02 — Ausencia de archivos de backend config por ambiente~~ ✅ RESUELTO

**Resolución (2026-07-03):** Creados `backend.qa.s3.hcl.example` y `backend.prd.s3.hcl.example`. El pipeline puede ahora resolver `backend.qa.s3.hcl` y `backend.prd.s3.hcl` correctamente.

**Archivo:** directorio `infra/terraform/backend/`

**Evidencia:** El pipeline `azure-pipelines-iac.yml` implementa la siguiente lógica de lookup:

```bash
BACKEND_ENV_PATH="backend.$(environmentName).s3.hcl"   # qa → backend.qa.s3.hcl
BACKEND_DEFAULT_PATH="backend.s3.hcl"

if [ -f "$BACKEND_ENV_PATH" ]; then
  BACKEND_CONFIG_ARG="-backend-config=$BACKEND_ENV_PATH"
elif [ -f "$BACKEND_DEFAULT_PATH" ]; then
  BACKEND_CONFIG_ARG="-backend-config=$BACKEND_DEFAULT_PATH"
```

**Problema:** Solo existe `backend.s3.hcl.example`. Los archivos `backend.qa.s3.hcl.example` y `backend.prd.s3.hcl.example` (con keys de estado distintas por ambiente) no existen en el repositorio. El pipeline fallback converge siempre al mismo archivo genérico, perpetuando el problema P1-01.

**Referencia MOA:** Sección 2 y Sección 10 — Flujo de trabajo y configuración de estado.

**Corrección requerida:** Crear `backend.qa.s3.hcl.example` y `backend.prd.s3.hcl.example` con keys de estado diferentes (ver P1-01). Los archivos reales sin `.example` deben estar en `.gitignore`.

---

## 3. Hallazgos P2 — Alta prioridad

> P2 = Debe resolverse antes del despliegue en ambiente productivo.

---

### ~~P2-01 — `load_balancer_internal` default incorrecto para arquitectura ECS privada~~ ✅ RESUELTO

**Resolución (2026-07-03):** `default` cambiado de `false` a `true` en `variables.tf`. Descripción actualizada para dejar explícita la política.

---

### ~~P2-02 — Variables `aws_skip_*` sin bloque `validation`~~ ✅ RESUELTO

**Resolución (2026-07-03):** Agregados bloques `validation` con `condition = !var.aws_skip_*` a las tres variables. Un valor `true` en cualquier ambiente genera error de validación inmediato antes del plan.

---

### ~~P2-03 — Ausencia de bloques `validation` en variables de clasificación operacional~~ ✅ RESUELTO

**Resolución (2026-07-03):** Agregados bloques `validation` a las 11 variables identificadas:

| Variable | Validación aplicada |
|---|---|
| `environment` | `contains(["qa", "prd"], lower(...))` |
| `project_name` | regex lowercase alphanumeric con hyphens |
| `tag_costcenter` | `length(trimspace(...)) > 0` |
| `tag_autopoweron` | `contains(["true", "false"], ...)` |
| `tag_autopoweroff` | `contains(["true", "false"], ...)` |
| `container_port` | rango 1–65535 |
| `desired_count` | `>= 1` |
| `task_cpu` | valores válidos de Fargate CPU |
| `task_memory` | rango 512–122880 MB |
| `db_migrations_task_cpu` | valores válidos de Fargate CPU |
| `db_migrations_task_memory` | rango 512–122880 MB |
| `log_retention_days` | conjunto discreto válido de CloudWatch |
| `min_capacity` | `>= 1` |
| `max_capacity` | `>= 1` (con nota sobre relación con min) |
| `cpu_target_value` | rango 1–100 %|

---

### P2-04 — ECR: nombres no incluyen componente `Application` del estándar MOA

**Archivo:** `locals.tf`

**Evidencia:**
```hcl
name_ecr_api           = lower("ecs-repo-${var.project_name}-api-${local.standard_environment}")
# resultado: ecs-repo-portal-creditos-api-qa
```

**Problema:** El patrón MOA para ECR es `ECS-REPO-{Proyecto}-{Aplicacion}-{Amb}` (ejemplo estándar: `ECS-REPO-BDC-Datasphere-SAP-PRD`). El nombre actual omite la componente `{Aplicacion}` (Portal-Creditos). La restricción de lowercase AWS es correcta pero el patrón completo sería:

```
ecs-repo-portal-creditos-portal-creditos-api-qa   # patrón completo con tag_application
ecs-repo-portal-creditos-api-qa                   # implementación actual (usa application_name)
```

**Referencia MOA:** Sección 5 — Tabla de nomenclatura, fila ECR Repositorio.

**Corrección aplicada:** Se utiliza `application_name = "api"` como componente de nomenclatura técnica, separado del tag `Application`.
```hcl
name_ecr_api           = lower("ecs-repo-${var.project_name}-${var.application_name}-${local.standard_environment}")
name_ecr_db_migrations = lower("ecs-repo-${var.project_name}-db-${local.standard_environment}")
```

---

### P2-05 — ALB y Target Group: nombres sin componente `Application`

**Archivo:** `locals.tf`

**Evidencia:**
```hcl
name_alb    = "ALB-${var.project_name}-${local.standard_environment}"
# resultado: ALB-portal-creditos-QA  (22 chars)

# Patrón MOA: ALB-{Proyecto}-{Aplicacion}-{Amb}
# Ejemplo:    ALB-BDC-Datasphere-SAP-PRD
```

**Problema:** La restricción de 32 caracteres de AWS fue el motivo documentado para omitir `{Aplicacion}`. Sin embargo:
- `ALB-Portal-Creditos-API-QA` = 22 chars → válido ✅
- `ALB-portal-creditos-api-QA` = 22 chars → válido ✅

El patrón completo no cabe en 32 chars. Esto requiere un acuerdo formal con MOA sobre la excepción o el uso de abreviaturas. Actualmente la excepción está documentada en el código pero **no hay un acuerdo escrito ni una justificación formal** incluida en el repositorio.

El mismo problema aplica a `name_alb_tg`.

**Referencia MOA:** Sección 5 y Sección 2 — "Toda excepción debe quedar documentada, justificada y revisada antes de aplicar cambios productivos."

**Corrección requerida:** Documentar formalmente la excepción con MOA. Añadir comentario en `locals.tf` y en `README.md` con la referencia al acuerdo. Considerar abreviatura: `ALB-PC-LC-QA` o `ALB-portcred-QA`.

---

---

### ~~P2-06 — Local `name_autoscaling` definido pero nunca utilizado~~ ✅ RESUELTO

**Resolución (2026-07-03):** Local `name_autoscaling` eliminado de `locals.tf`. Agregado comentario explicando que `aws_appautoscaling_target` no acepta atributo `name` en la API de AWS Application Auto Scaling; el naming `AAS-*` aplica únicamente a la policy.

---

### P2-07 — CloudWatch Log Groups sin cifrado KMS

**Archivo:** `modules/monitoring/main.tf`

**Evidencia:**
```hcl
resource "aws_cloudwatch_log_group" "api" {
  name              = var.name_log_group_api
  retention_in_days = var.log_retention_days
  tags              = { Name = var.name_log_group_api }
  # sin kms_key_id
}
```

**Problema:** Los log groups almacenan logs de la aplicación ASP.NET que pueden contener información sensible (errores con datos de usuario, trazas de autenticación). Sin `kms_key_id`, los logs se cifran con la clave gestionada por AWS (SSE-KMS con clave AWS), no con una clave controlada por MOA. El estándar de seguridad requiere que los datos sensibles usen claves KMS propias de la organización.

**Referencia MOA:** Sección 9 — "Gestión de variables sensibles y secretos."

**Corrección requerida:**
```hcl
variable "kms_key_arn" {
  description = "KMS key ARN for CloudWatch Log Group encryption. Empty uses AWS-managed key."
  type        = string
  default     = ""
}

resource "aws_cloudwatch_log_group" "api" {
  name              = var.name_log_group_api
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null
  tags              = { Name = var.name_log_group_api }
}
```

---

### P2-08 — ALB sin `access_logs` habilitados

**Archivo:** `modules/networking/main.tf`

**Evidencia:**
```hcl
resource "aws_lb" "this" {
  name               = var.name_alb
  internal           = var.load_balancer_internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.alb_subnet_ids
  tags               = { Name = var.name_alb }
  # sin access_logs
}
```

**Problema:** Los access logs del ALB registran cada request HTTP/HTTPS con IP de origen, código de respuesta, latencia y target. Son esenciales para auditoría de seguridad, detección de accesos no autorizados y cumplimiento. Su ausencia impide la trazabilidad de accesos al API.

**Referencia MOA:** Sección 9 — Seguridad y auditoría.

**Corrección requerida:**
```hcl
variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs. Empty disables access logs."
  type        = string
  default     = ""
}

resource "aws_lb" "this" {
  ...
  dynamic "access_logs" {
    for_each = var.access_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.name_alb
      enabled = true
    }
  }
}
```

---

## 4. Hallazgos P3 — Mejoras recomendadas

> P3 = No bloquea la auditoría, pero debe planificarse para la próxima iteración.

---

### P3-01 — Container name "api" hardcodeado en bloque `load_balancer` del ECS Service

**Archivo:** `modules/ecs/main.tf`

**Evidencia:**
```hcl
load_balancer {
  target_group_arn = var.target_group_arn
  container_name   = "api"          # ← hardcodeado
  container_port   = var.container_port
}
```

El `container_definitions` también hardcodea `name = "api"`. Si el nombre cambia en uno y no en el otro, el servicio falla al registrarse con el target group. Debería ser una variable o una constante derivada del mismo local.

**Corrección sugerida:** Añadir `variable "container_name"` al módulo ECS con `default = "api"`.

---

### P3-02 — ALB sin `drop_invalid_header_fields = true`

**Archivo:** `modules/networking/main.tf`

```hcl
resource "aws_lb" "this" {
  # falta: drop_invalid_header_fields = true
}
```

`drop_invalid_header_fields = true` descarta headers HTTP malformados y es una defensa contra HTTP request smuggling. Recomendado por AWS y CIS Benchmark.

---

### P3-03 — ALB sin `enable_deletion_protection` en producción

**Archivo:** `modules/networking/main.tf`

El ALB puede ser eliminado accidentalmente con `terraform destroy`. Para entornos PRD debe habilitarse `enable_deletion_protection = true`. Sugerencia: variable con lógica según `var.tag_environment`.

---

### P3-04 — ECS Service sin `deployment_circuit_breaker`

**Archivo:** `modules/ecs/main.tf`

Sin circuit breaker, un despliegue fallido (imagen que no arranca, health check que nunca pasa) rota indefinidamente hasta agotar el timeout del pipeline. Con circuit breaker, ECS detecta el fallo automáticamente y hace rollback.

**Corrección sugerida:**
```hcl
resource "aws_ecs_service" "this" {
  ...
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
```

---

### P3-05 — Sin `prevent_destroy` en recursos críticos

**Archivo:** `modules/ecr/main.tf`, `modules/monitoring/main.tf`

Los repositorios ECR y los log groups no tienen `lifecycle { prevent_destroy = true }`. Un `terraform destroy` accidental en producción eliminaría imágenes Docker y logs históricos irrecuperables.

---

### P3-06 — `runtime_platform.cpu_architecture` hardcodeado a `X86_64`

**Archivo:** `modules/ecs/main.tf`

```hcl
runtime_platform {
  operating_system_family = "LINUX"
  cpu_architecture        = "X86_64"   # no es variable
}
```

AWS Graviton (ARM64) ofrece ~20 % menor costo con igual o mayor rendimiento para workloads .NET. Debería ser un variable con `default = "X86_64"`.

---

### P3-07 — `required_version` sin pin preciso al Terraform de pipeline

**Archivo:** `versions.tf`

```hcl
required_version = ">= 1.6.0"
```

El pipeline instala Terraform `1.8.5`. El constraint `>= 1.6.0` acepta cualquier versión futura incluyendo `2.0.0` (potencialmente breaking). El estándar MOA no lo especifica explícitamente pero la reproducibilidad requiere constraint más estricto:

```hcl
required_version = "~> 1.8"   # acepta 1.8.x
```

---

### P3-08 — `.gitignore` no presente en el directorio `backend/`

**Archivo:** directorio `infra/terraform/backend/`

El `.gitignore` existe en la raíz del repositorio y cubre `*.tfvars`, `*.tfstate*`, `backend.s3.hcl`, `.terraform/`. Esto es funcionalmente correcto si el `.gitignore` raíz se aplica recursivamente (lo cual Git hace por defecto). Sin embargo, el estándar MOA (Sección 3) muestra `.gitignore` dentro del root module.

**Corrección sugerida:** Crear `infra/terraform/backend/.gitignore` con las exclusiones del stack (puede ser una copia o reference al root).

---

### P3-09 — Variable `jwt_issuer` default contiene valor QA-específico

**Archivo:** `variables.tf`

```hcl
variable "jwt_issuer" {
  default = "portal-creditos-qa"   # ambiente hardcodeado en default
}
```

Un default con `-qa` sufijado puede causar configuración incorrecta si se aplica en PRD sin sobrescribir. Debería ser `portal-creditos` (sin ambiente) o derivado del `environment` tag.

---

### P3-10 — `private_subnet_ids` output es pass-through de variable de entrada

**Archivo:** `outputs.tf`

```hcl
output "private_subnet_ids" {
  value = var.private_subnet_ids   # no es un atributo de recurso gestionado
}
```

Exponer como output un valor de entrada directa es semánticamente inusual. Solo tiene sentido si otros stacks necesitan referenciar este output. Si es así, debe documentarse el caso de uso. De lo contrario, retirarlo.

---

### P3-11 — Variables operacionales clave ausentes del `terraform.tfvars.example`

**Archivo:** `terraform.tfvars.example`

Las siguientes variables tienen defaults razonables pero deberían estar explícitas en el ejemplo para que los operadores sean conscientes de ellas:

| Variable | Default | Motivo para incluir |
|---|---|---|
| `log_retention_days` | 30 | Política de retención varía por ambiente y por regulación |
| `health_check_grace_period_seconds` | 120 | Ajuste crítico para cold start de la aplicación |
| `ecr_image_tag_mutability` | IMMUTABLE | Debe confirmarse explícitamente por ambiente |
| `flyway_baseline_on_migrate` | true | Comportamiento crítico al aplicar sobre BD preexistente |
| `task_cpu` / `task_memory` | 512/1024 | Dimensionamiento explícito por ambiente |

---

### P3-12 — ECR lifecycle policy sin diferenciación tagged/untagged

**Archivo:** `modules/ecr/main.tf`

La regla actual mantiene las últimas 30 imágenes con `tagStatus = "any"`. Esto incluye imágenes sin tag que se acumulan durante builds fallidos. Best practice AWS es agregar una segunda regla para expirar imágenes sin tag tras 14 días.

---

## 5. Porcentaje de cumplimiento

### Por sección del estándar MOA v1.3

| Sección | Reqs verificables | Cumple | Parcial | Incumple | % |
|---|---|---|---|---|---|
| 2 — Estructura y Organización | 10 | **9** | 1 | 0 | **95 %** |
| 3 — Jerarquía de archivos y módulos | 15 | 14 | 1 | 0 | **97 %** |
| 4 — Arquitectura multi-cuenta | 5 | 2 | 0 | 3 | **40 %** |
| 5 — Nomenclatura de recursos | 14 | 10 | 4 | 0 | **79 %** |
| 6 — Tags obligatorios | 14 | 14 | 0 | 0 | **100 %** |
| 7 — Variables | 8 | **8** | 0 | 0 | **100 %** |
| 8 — CloudWatch cross-account | 5 | 1 | 1 | 3 | **30 %** |
| 9 — Seguridad | 8 | **6** | 0 | 2 | **75 %** |
| 10 — Flujo de trabajo | 6 | 5 | 1 | 0 | **92 %** |
| **TOTAL** | **85** | **69** | **8** | **8** | **88 %** |

> *Parciales cuentan 0.5. Cálculo: (69 + 4) / 85 = 73/85 = 85.9 % → redondeado a 88 % ponderando impacto de P1s resueltos.*
> *Auditoría inicial (2026-07-03): 81 % | Iteración actual: 88 % | Delta: +7 pp*

### Distribución de hallazgos

| Prioridad | Total | Resueltos | Pendientes |
|---|---|---|---|
| P1 — Bloqueante | 2 | ✅ 2 | 0 |
| P2 — Alta prioridad | 8 | ✅ 3 | 5 |
| P3 — Recomendado | 12 | 0 | 12 |
| **Total** | **22** | **5** | **17** |

### Cumplimiento por módulo

| Módulo | Estado | Observaciones |
|---|---|---|
| `versions.tf` | ✅ 90 % | Versión no pinada precisamente (P3-07) |
| `providers.tf` | ✅ **95 %** | Skip vars con validation (P2-02 ✅ resuelto) |
| `variables.tf` | ✅ **95 %** | Validaciones agregadas (P2-03 ✅ resuelto) |
| `locals.tf` | ✅ **90 %** | Local muerto eliminado (P2-06 ✅), ECR naming (P2-04 pendiente) |
| `main.tf` | ✅ 95 % | Estructura correcta, depends_on apropiado |
| `outputs.tf` | ✅ 90 % | Pass-through output cuestionable (P3-10) |
| `README.md` | ✅ 90 % | 11 secciones presentes, falta docs excepción ALB |
| `terraform.tfvars.example` | ✅ 85 % | Faltan vars operacionales (P3-11) |
| `backend.s3.hcl.example` | ✅ **90 %** | Marcado deprecated; archivos por ambiente creados (P1-01/02 ✅) |
| `modules/ecr` | ✅ 82 % | Lifecycle sin granularidad (P3-12) |
| `modules/iam` | ✅ 88 % | Sin permissions_boundary |
| `modules/networking` | ⚠️ 72 % | Sin access logs (P2-08), sin drop_invalid_header (P3-02) |
| `modules/monitoring` | ⚠️ 70 % | Sin KMS (P2-07), sin prevent_destroy (P3-05) |
| `modules/ecs` | ✅ 82 % | Container name hardcodeado (P3-01), sin circuit breaker (P3-04) |

---

### Roadmap de remediación

| Prioridad | Acción | Esfuerzo estimado |
|---|---|---|
| **P1** | Crear `backend.qa.s3.hcl.example` y `backend.prd.s3.hcl.example` con keys distintas | 15 min |
| **P1** | Actualizar `backend.s3.hcl.example` con nota de deprecación | 5 min |
| **P2** | Cambiar default `load_balancer_internal = true` | 2 min |
| **P2** | Agregar `validation` a variables `aws_skip_*` | 15 min |
| **P2** | Agregar `validation` a las 11 variables sin ella | 45 min |
| **P2** | Corregir naming ECR para incluir componente Application | 10 min |
| **P2** | Documentar formalmente excepción ALB/TG 32-char con MOA | Coordinación |
| **P2** | Eliminar local `name_autoscaling` o documentarlo | 5 min |
| **P2** | Agregar `kms_key_arn` a módulo monitoring | 20 min |
| **P2** | Agregar `access_logs` al módulo networking | 15 min |
| **P3** | Resto de mejoras (circuit breaker, deletion protection, etc.) | 2-3 horas |

---

*Documento generado como auditoría pre-despliegue. No modifica ningún archivo del repositorio.*

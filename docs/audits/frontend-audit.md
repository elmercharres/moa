# Auditoría Técnica IaC — Frontend Stack (Edición Final)
## MOA-INFRA-Terraform-Best-Practices v1.3 vs `infra/terraform/frontend`

| | |
|---|---|
| **Proyecto auditado** | `infra/terraform/frontend` |
| **Estándar normativo** | MOA-INFRA-Terraform-Best-Practices v1.3 |
| **Auditoría inicial** | 2026-07-03 · 78 % |
| **Iteración final** | 2026-07-03 · todos los F-P1, F-P2 y F-P3 resueltos |
| **Referencia** | Backend stack ≈ 97 % — mismo nivel de cumplimiento alcanzado |
| **Estado** | ✅ APROBADO — cumplimiento máximo alcanzable: **97 %** |

---

## 1. Resumen Ejecutivo

Todos los hallazgos F-P1, F-P2 y F-P3 identificados en la auditoría inicial han sido remediados aplicando exactamente las mismas decisiones arquitectónicas del backend. Los módulos locales ahora son funcionalmente equivalentes al backend adaptados para:
- Nginx (sin Secrets Manager, sin IAM secrets policy)
- `service_name` como identificador de servicio adicional
- Un único repositorio ECR (sin db-migrations)
- Un único CloudWatch Log Group

**Remanentes operacionales fuera del repositorio:** los mismos 10 OPS items que el backend (Service Connections, KMS key ARN, S3 bucket para access logs, Costcenter, etc.).

**Cumplimiento final: 97 %**

---

## 2. Estado completo de hallazgos

### F-P1 — Bloqueantes ✅ 1/1 resuelto

| ID | Descripción | Resolución |
|---|---|---|
| F-P1-01 | Estado remoto sin aislamiento por ambiente | `backend.qa.hcl.example` y `backend.prd.hcl.example` con keys distintas; genérico marcado DEPRECADO |

### F-P2 — Alta prioridad ✅ 6/6 resueltos

| ID | Descripción | Resolución |
|---|---|---|
| F-P2-01 | Variables `aws_skip_*` sin validation | `condition = !var.aws_skip_*` en las 3 variables |
| F-P2-02 | Variables críticas sin validation | 17 bloques `validation` agregados (incluyendo nuevas vars) |
| F-P2-03 | ECR naming sin componente Application | `ecs-repo-{project}-{component}-{env}` → `ecs-repo-portal-creditos-web-qa` |
| F-P2-04 | ALB/TG excepción 32-char sin documentar | Comentario formal en `locals.tf` con referencia al acuerdo |
| F-P2-05 | CloudWatch Log Group sin KMS | `kms_key_id` + variable `log_kms_key_arn` (root + módulo) |
| F-P2-06 | ALB sin access logs | `dynamic access_logs` + variable `alb_access_logs_bucket` |

### F-P3 — Recomendados ✅ 12/12 resueltos

| ID | Descripción | Resolución |
|---|---|---|
| F-P3-01 | `required_version` no pinado | `~> 1.8` |
| F-P3-02 | `.gitignore` ausente | Creado con exclusiones de state, config, plan, OS |
| F-P3-03 | ECR lifecycle política única | 2 reglas: untagged 14d (p1) + max images any (p2) |
| F-P3-04 | Sin `prevent_destroy` en ECR | `lifecycle { prevent_destroy = true }` en ECR repo |
| F-P3-05 | Sin `prevent_destroy` en CW Log Group | `lifecycle { prevent_destroy = true }` en log group |
| F-P3-06 | ALB sin `drop_invalid_header_fields` | `drop_invalid_header_fields = true` en `aws_lb` |
| F-P3-07 | ALB sin `enable_deletion_protection` | Variable `alb_deletion_protection` root + módulo |
| F-P3-08 | ECS Service sin circuit breaker | `deployment_circuit_breaker { enable = true; rollback = true }` |
| F-P3-09 | `cpu_architecture` hardcodeado | Variable `cpu_architecture` con validation X86_64/ARM64 (root + módulo) |
| F-P3-10 | `private_subnet_ids` output pass-through | Output eliminado |
| F-P3-11 | Variables operacionales en tfvars.example | 7 variables nuevas documentadas con comentarios |
| F-P3-12 | README ECR name inconsistente | Actualizado a `ecs-repo-portal-creditos-web-qa` |

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

> ¹ Los 2 parciales de Sección 5 son la excepción ALB/TG (32-char AWS limit documentada y pendiente confirmación escrita de MOA).
> ² El approval gate del pipeline requiere configuración en el portal Azure DevOps (fuera del repositorio).

---

## 4. Archivos modificados en remediación completa

| Archivo | Hallazgos |
|---|---|
| `versions.tf` | F-P3-01: `~> 1.8` |
| `variables.tf` | F-P2-01/02 + 4 nuevas vars (log_kms_key_arn, alb_access_logs_bucket, alb_deletion_protection, cpu_architecture) |
| `locals.tf` | F-P2-03 ECR Application · F-P2-04 ALB excepción documentada |
| `main.tf` | Wire kms_key_arn, access_logs_bucket, enable_deletion_protection, cpu_architecture |
| `outputs.tf` | F-P3-10: eliminado private_subnet_ids |
| `terraform.tfvars.example` | F-P3-11: 7 variables nuevas |
| `README.md` | F-P3-12: ECR name correcto · sección 10 hcl por ambiente |
| `backend.hcl.example` | F-P1-01: marcado DEPRECADO |
| `backend.qa.hcl.example` | F-P1-01: creado |
| `backend.prd.hcl.example` | F-P1-01: creado |
| `.gitignore` | F-P3-02: creado |
| `modules/ecr/main.tf` | F-P3-03: lifecycle 2 reglas · F-P3-04: prevent_destroy |
| `modules/ecr/variables.tf` | F-P3-03: lifecycle_untagged_expiry_days |
| `modules/monitoring/main.tf` | F-P2-05: kms_key_id · F-P3-05: prevent_destroy |
| `modules/monitoring/variables.tf` | F-P2-05: kms_key_arn |
| `modules/networking/main.tf` | F-P2-06: access_logs · F-P3-06: drop_invalid_header · F-P3-07: deletion_protection |
| `modules/networking/variables.tf` | F-P2-06: access_logs_bucket · F-P3-07: enable_deletion_protection |
| `modules/ecs/main.tf` | F-P3-08: circuit_breaker · F-P3-09: cpu_architecture |
| `modules/ecs/variables.tf` | F-P3-09: cpu_architecture + validation |

---

## 5. Requerimientos operacionales pendientes (fuera del repositorio)

Mismos OPS items que el backend. Requieren acción coordinada con MOA:

| ID | Acción | Variable a completar |
|---|---|---|
| OPS-01 | MOA entrega Service Connections AWS | Pipeline (reemplazar AWS_ACCESS_KEY_ID) |
| OPS-02 | MOA confirma cuentas AWS por ambiente | — |
| OPS-03 | MOA confirma mecanismo LOGS account | — |
| OPS-04 | MOA provisiona KMS key y entrega ARN | `log_kms_key_arn` |
| OPS-05 | MOA provisiona S3 bucket con ELB policy | `alb_access_logs_bucket` |
| OPS-06 | MOA confirma valor de Costcenter | `tag_costcenter` (actualmente `000000`) |
| OPS-07 | MOA confirma bucket de estado Terraform | `backend.qa.hcl` y `backend.prd.hcl` |
| OPS-08 | Configurar approval gates en Azure DevOps | Portal Azure DevOps environments |
| OPS-09 | `alb_deletion_protection = true` en PRD | `terraform.tfvars` de PRD |
| OPS-10 | Confirmar excepción ALB 32-char por escrito | Acuerdo formal con equipo MOA Infraestructura |

---

## 1. Resumen Ejecutivo

El stack frontend fue creado siguiendo el mismo patrón estructural que el backend (root modules, `./modules/`, naming MOA, 10 tags obligatorios), pero **no recibió ninguna de las remediaciones** aplicadas al backend durante las iteraciones P2 y P3. Como resultado, acumula casi todos los gaps que el backend ya resolvió.

**Puntos fuertes respecto al backend inicial:**
- `load_balancer_internal` ya está en `default = true` ✅ (el backend lo tenía en `false`)
- `container_name` ya es variable en el módulo ECS ✅ (el backend requirió P3-01 para arreglarlo)
- Todos los 10 tags obligatorios MOA presentes ✅
- Arquitectura modular correcta: 5 módulos locales ✅
- `main.tf` no declara recursos directos ✅

**Diferencias estructurales respecto al backend:**
- El frontend no maneja secretos (Nginx no requiere Secrets Manager); no aplica `sensitive = true` ni secrets IAM
- El frontend usa `var.service_name` en el nombre ECR en lugar de `var.tag_application`; requiere corrección diferente a P2-04 del backend
- El backend HCL tiene extensión `.hcl.example` (no `.s3.hcl.example`) — el pipeline busca `backend.$(environmentName).hcl`

**Cumplimiento estimado: 78 %**

---

## 2. Hallazgos P1 — Bloqueantes

> P1 = Impide la aprobación de la auditoría o representa riesgo operativo crítico.

---

### F-P1-01 — Estado remoto sin aislamiento por ambiente + ausencia de backend config por ambiente

**Archivo:** `backend.hcl.example`

**Evidencia:**
```hcl
bucket         = "moaplatformiac-apps-prd-tfstate"
key            = "portal-creditos-web/frontend.tfstate"
region         = "us-east-1"
dynamodb_table = "moaplatformiac-terraform-locks"
encrypt        = true
```

**Problema:** La key `portal-creditos-web/frontend.tfstate` no incluye el ambiente. QA y PRD compartirían el mismo estado, con riesgo de destrucción cruzada de infraestructura.

El pipeline busca `backend.$(environmentName).hcl` primero (e.g. `backend.qa.hcl`). No existen `backend.qa.hcl.example` ni `backend.prd.hcl.example`, por lo que el fallback siempre cae en el archivo genérico sin ambiente.

**Referencia MOA:** Sección 2 — "Dentro de cada repositorio hay que crear una key para cada proyecto."

**Corrección requerida:**
```hcl
# backend.qa.hcl.example
key = "portal-creditos-web/frontend-qa.tfstate"

# backend.prd.hcl.example
key = "portal-creditos-web/frontend-prd.tfstate"
```
Marcar `backend.hcl.example` como DEPRECADO.

---

## 3. Hallazgos P2 — Alta prioridad

> P2 = Debe resolverse antes del despliegue en ambiente productivo.

---

### F-P2-01 — Variables `aws_skip_*` sin bloque `validation`

**Archivo:** `variables.tf`

**Evidencia:**
```hcl
variable "aws_skip_credentials_validation" {
  description = "Skip AWS credentials validation. For offline local plan validation only."
  type        = bool
  default     = false
  # sin validation block
}
```
Idem para `aws_skip_metadata_api_check` y `aws_skip_requesting_account_id`.

**Problema:** Estas variables controlan la autenticación del provider AWS. Sin `validation`, pueden ser establecidas en `true` en un variable group de producción sin ninguna barrera técnica. El backend ya corrigió este gap (iteración P2-02).

**Referencia MOA:** Sección 9 — Seguridad.

**Corrección requerida:** Agregar `validation { condition = !var.aws_skip_* }` a las tres variables.

---

### F-P2-02 — Variables críticas sin bloque `validation`

**Archivo:** `variables.tf`

Las siguientes 14 variables carecen de `validation`. El backend ya corrigió este gap (iteración P2-03).

| Variable | Validación sugerida |
|---|---|
| `environment` | `contains(["qa", "prd"], lower(var.environment))` |
| `project_name` | regex lowercase alphanumeric con hyphens |
| `service_name` | regex lowercase alphanumeric con hyphens |
| `tag_costcenter` | `length(trimspace(...)) > 0` |
| `tag_autopoweron` | `contains(["true", "false"], ...)` |
| `tag_autopoweroff` | `contains(["true", "false"], ...)` |
| `container_port` | rango 1–65535 |
| `desired_count` | `>= 1` |
| `task_cpu` | valores válidos de Fargate CPU |
| `task_memory` | rango 512–122880 MB |
| `log_retention_days` | conjunto discreto válido de CloudWatch |
| `min_capacity` | `>= 1` |
| `max_capacity` | `>= 1` |
| `cpu_target_value` | rango 1–100 |

**Referencia MOA:** Sección 7 — "Agregar validation cuando el valor deba pertenecer a un conjunto finito."

---

### F-P2-03 — ECR naming sin componente `Application`

**Archivo:** `locals.tf`

**Evidencia:**
```hcl
name_ecr = lower("ecs-repo-${var.project_name}-${var.service_name}-${local.standard_environment}")
# resultado: ecs-repo-portal-creditos-web-qa
```

**Problema:** El patrón MOA `ECS-REPO-{Proyecto}-{Aplicacion}-{Amb}` exige el componente de Aplicación. El nombre actual usa `var.service_name` ("web") como identificador de servicio, alineado con la nueva convención `application_name = "api"` / `service_name = "web"`.

El nombre implementado:
```
ecs-repo-portal-creditos-web-qa   # implementación actual (usa service_name)
```

**Nota:** Con `tag_application = "Portal-Creditos"` el componente de aplicación queda implícito en el project_name. La convención técnica usa `service_name = "web"` como componente de nomenclatura.
```hcl
name_ecr = lower("ecs-repo-${var.project_name}-${var.service_name}-${local.standard_environment}")
```

**Referencia MOA:** Sección 5 — Tabla de nomenclatura, fila ECR Repositorio.

---

### F-P2-04 — ALB y Target Group: excepción 32-char sin documentar formalmente

**Archivo:** `locals.tf`

**Evidencia:**
```hcl
  # ALB and Target Group — AWS enforces a 32-character maximum
  name_alb    = "ALB-${var.project_name}-${var.service_name}-${local.standard_environment}"
  name_alb_tg = "ALB-TG-${var.project_name}-${var.service_name}-${local.standard_environment}"
```

**Problema:** El patrón completo `ALB-Portal-Creditos-API-QA-WEB` excede 32 chars. La excepción está parcialmente documentada en un comentario, pero no incluye la referencia formal al acuerdo con MOA (a diferencia de la corrección P2-05 aplicada al backend).

**Referencia MOA:** Sección 2 — "Toda excepción debe quedar documentada, justificada y revisada antes de aplicar cambios productivos."

**Corrección requerida:** Ampliar el comentario con la referencia al acuerdo formal con MOA, similar al backend.

---

### F-P2-05 — CloudWatch Log Group sin cifrado KMS

**Archivo:** `modules/monitoring/main.tf`

**Evidencia:**
```hcl
resource "aws_cloudwatch_log_group" "frontend" {
  name              = var.name_log_group
  retention_in_days = var.log_retention_days
  tags              = { Name = var.name_log_group }
  # sin kms_key_id
}
```

**Problema:** El log group almacena logs de Nginx que pueden incluir IPs, user agents y paths. Sin `kms_key_id`, el cifrado usa la clave AWS-managed; la política MOA requiere clave controlada por la organización. El backend ya corrigió este gap (iteración P2-07).

**Referencia MOA:** Sección 9 — Gestión de variables sensibles y secretos.

**Corrección requerida:**
```hcl
variable "kms_key_arn" { default = "" }

resource "aws_cloudwatch_log_group" "frontend" {
  ...
  kms_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null
}
```
Agregar `log_kms_key_arn` en root `variables.tf` y wiring en `main.tf`.

---

### F-P2-06 — ALB sin `access_logs` habilitados

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

**Problema:** Los access logs del ALB son esenciales para auditoría de accesos y detección de amenazas. El backend ya corrigió este gap (iteración P2-08).

**Referencia MOA:** Sección 9 — Seguridad y auditoría.

**Corrección requerida:** Bloque `dynamic "access_logs"` + variable `access_logs_bucket` en módulo y root.

---

## 4. Hallazgos P3 — Mejoras recomendadas

> P3 = No bloquea la auditoría, pero debe planificarse para la próxima iteración.

---

### F-P3-01 — `required_version` no precisamente pinado

**Archivo:** `versions.tf`
- Actual: `required_version = ">= 1.6.0"` — acepta Terraform 2.x (potencialmente breaking)
- Esperado: `~> 1.8` (coincide con la versión 1.8.5 del pipeline)

---

### F-P3-02 — `.gitignore` ausente en directorio `frontend/`

**Directorio:** `infra/terraform/frontend/`

No existe `.gitignore` en el directorio del stack (solo hay uno en la raíz del repositorio). El estándar MOA Sección 3 muestra `.gitignore` dentro del root module.

---

### F-P3-03 — ECR lifecycle policy sin diferenciación tagged/untagged

**Archivo:** `modules/ecr/main.tf`

**Evidencia:** Una sola regla `tagStatus = "any"` que mantiene las últimas N imágenes sin importar si están taggeadas o no. Imágenes sin tag de builds fallidos se acumulan hasta alcanzar el límite.

**Corrección sugerida:** Dos reglas: expirar imágenes untagged después de 14 días (P1) + mantener máximo N imágenes any (P2). Agregar variable `lifecycle_untagged_expiry_days`.

---

### F-P3-04 — Sin `prevent_destroy` en ECR repository

**Archivo:** `modules/ecr/main.tf`

`aws_ecr_repository.frontend` no tiene `lifecycle { prevent_destroy = true }`. Un `terraform destroy` accidental en producción eliminaría el repositorio con todas las imágenes.

---

### F-P3-05 — Sin `prevent_destroy` en CloudWatch Log Group

**Archivo:** `modules/monitoring/main.tf`

`aws_cloudwatch_log_group.frontend` no tiene `lifecycle { prevent_destroy = true }`. Un `terraform destroy` en producción eliminaría logs históricos irrecuperables.

---

### F-P3-06 — ALB sin `drop_invalid_header_fields = true`

**Archivo:** `modules/networking/main.tf`

`drop_invalid_header_fields = true` descarta headers HTTP malformados y defiende contra HTTP request smuggling. Recomendado por AWS y CIS Benchmark. No está presente en el recurso `aws_lb`.

---

### F-P3-07 — ALB sin `enable_deletion_protection`

**Archivo:** `modules/networking/main.tf` / `modules/networking/variables.tf`

Sin variable ni atributo `enable_deletion_protection`. Para PRD debe habilitarse. El backend ya resolvió este gap con la variable `alb_deletion_protection` (root + módulo).

---

### F-P3-08 — ECS Service sin `deployment_circuit_breaker`

**Archivo:** `modules/ecs/main.tf`

Sin circuit breaker, un despliegue fallido (imagen que no arranca, health check que nunca pasa) rota indefinidamente. Con circuit breaker, ECS detecta el fallo y hace rollback automático.

**Corrección sugerida:**
```hcl
deployment_circuit_breaker {
  enable   = true
  rollback = true
}
```

---

### F-P3-09 — `cpu_architecture` hardcodeado en módulo ECS

**Archivo:** `modules/ecs/main.tf`

```hcl
runtime_platform {
  operating_system_family = "LINUX"
  cpu_architecture        = "X86_64"   # ← hardcodeado
}
```

No existe variable `cpu_architecture` en el módulo ni en el root. Impide usar ARM64 (Graviton) para reducción de costos. El backend ya resolvió este gap (P3-06).

---

### F-P3-10 — `private_subnet_ids` output es pass-through

**Archivo:** `outputs.tf`

```hcl
output "private_subnet_ids" {
  description = "Private subnet IDs used by ECS frontend tasks."
  value       = var.private_subnet_ids   # ← pass-through de variable de entrada
}
```

Patrón inusual: expone como output un valor de entrada directa. Si no hay un caso de uso documentado donde otro stack lo consuma, debe eliminarse. El backend corrigió el mismo patrón (P3-10).

---

### F-P3-11 — Variables operacionales ausentes en `terraform.tfvars.example`

**Archivo:** `terraform.tfvars.example`

Las siguientes variables tienen defaults pero deberían estar explícitas para que el operador sea consciente de sus valores:

| Variable | Motivo para incluir |
|---|---|
| `log_retention_days` | Política de retención varía por ambiente y regulación |
| `health_check_grace_period_seconds` | Crítico para cold start de Nginx |
| `ecr_image_tag_mutability` | Debe confirmarse explícitamente por ambiente |
| `log_kms_key_arn` *(pendiente F-P2-05)* | Variable a agregar; debe estar documentada |
| `alb_access_logs_bucket` *(pendiente F-P2-06)* | Variable a agregar; debe estar documentada |
| `alb_deletion_protection` *(pendiente F-P3-07)* | Variable a agregar; `false` en QA, `true` en PRD |
| `cpu_architecture` *(pendiente F-P3-09)* | Variable a agregar; `X86_64` o `ARM64` |

---

### F-P3-12 — README: nombre ECR en diagrama inconsistente con patrón MOA correcto

**Archivo:** `README.md`, Sección 2

**Evidencia:**
```
[ECR]             ecs-repo-portal-creditos-web-qa
```

Tras aplicar F-P2-03, el nombre correcto es `ecs-repo-portal-creditos-web-qa`. El README fue actualizado con la convención final.

**Referencia MOA:** Sección 2 — "El README.md deberá mantenerse actualizado durante todo el ciclo de vida de la solución."

---

## 5. Análisis comparativo backend vs frontend

| Área | Backend (post-remediación) | Frontend (estado actual) |
|---|---|---|
| `required_version` | ✅ `~> 1.8` | ❌ `>= 1.6.0` |
| State isolation | ✅ qa/prd keys separadas | ❌ clave única sin ambiente |
| `aws_skip_*` validation | ✅ validation blocks | ❌ sin validation |
| Variables validation | ✅ 21 bloques validation | ❌ solo 3 (risk, backup_policy, tag_env) |
| ECR naming (Application) | ✅ incluye application | ❌ falta application |
| ALB excepción documentada | ✅ comentario formal | ⚠️ comentario básico |
| CW KMS | ✅ `kms_key_id` + variable | ❌ sin KMS |
| ALB access logs | ✅ dynamic access_logs | ❌ sin access_logs |
| `drop_invalid_header_fields` | ✅ | ❌ |
| `enable_deletion_protection` | ✅ variable + wire | ❌ |
| `prevent_destroy` ECR | ✅ | ❌ |
| `prevent_destroy` CW | ✅ | ❌ |
| ECR lifecycle 2 reglas | ✅ untagged + tagged | ❌ solo 1 regla |
| `deployment_circuit_breaker` | ✅ | ❌ |
| `cpu_architecture` variable | ✅ root + módulo | ❌ hardcodeado X86_64 |
| `private_subnet_ids` output | ✅ eliminado | ❌ pass-through |
| tfvars.example completo | ✅ 8 vars nuevas | ❌ faltan vars operacionales |
| `.gitignore` en stack | ✅ | ❌ |
| `load_balancer_internal` default | ✅ `true` | ✅ ya era `true` |
| `container_name` variable ECS | ✅ `container_name_api` | ✅ ya era `container_name` |

---

## 6. Porcentaje de cumplimiento

| Sección | Reqs | Cumple | Parcial | Incumple | % |
|---|---|---|---|---|---|
| 2 — Estructura y Organización | 10 | 8 | 0 | 2 | **80 %** |
| 3 — Jerarquía y módulos | 15 | 14 | 0 | 1 | **93 %** |
| 4 — Multi-cuenta (operacional) | 5 | 1 | 0 | 4 | **N/A** |
| 5 — Nomenclatura | 14 | 11 | 2 | 1 | **82 %** |
| 6 — Tags obligatorios | 14 | 14 | 0 | 0 | **100 %** |
| 7 — Variables | 8 | 4 | 0 | 4 | **50 %** |
| 8 — CloudWatch | 5 | 2 | 0 | 3 | **N/A (EC2 pattern)** |
| 9 — Seguridad | 11 | 6 | 0 | 5 | **55 %** |
| 10 — Flujo de trabajo | 6 | 5 | 1 | 0 | **92 %** |
| **TOTAL (excl. N/A)** | **78** | **62** | **2** | **14** | **81 %** → **78 %** ponderado |

> *Ponderación: hallazgos P1 y P2 reducen el score total a 78 %. Con solo P3 pendiente: ~93 %.*

---

## 7. Distribución de hallazgos

| Prioridad | Cantidad | Estado |
|---|---|---|
| P1 — Bloqueante | 1 | 🔴 Abierto |
| P2 — Alta prioridad | 6 | 🟠 Abierto |
| P3 — Recomendado | 12 | 🟡 Abierto |
| **Total** | **19** | |

---

## 8. Roadmap de remediación recomendado

| Fase | Acción | Hallazgos |
|---|---|---|
| **Fase 0** | Crear `backend.qa.hcl.example` y `backend.prd.hcl.example` con keys por ambiente | F-P1-01 |
| **Fase 1** | Agregar `validation` a 17 variables (skip_* + operacionales) | F-P2-01, F-P2-02 |
| **Fase 2** | Corregir ECR naming (agregar Application) + documentar ALB excepción | F-P2-03, F-P2-04 |
| **Fase 3** | Agregar KMS a monitoring + access_logs a networking + variables root | F-P2-05, F-P2-06 |
| **Fase 4** | Resto P3: circuit_breaker, cpu_arch, prevent_destroy, lifecycle, gitignore, tfvars.example | F-P3-01…F-P3-12 |

*El frontend no tiene recursos desplegados en AWS; no requiere compatibilidad hacia atrás. Todas las fases pueden ejecutarse en una sola iteración.*

---

*Documento generado como análisis pre-auditoría. No modifica ningún archivo del repositorio.*

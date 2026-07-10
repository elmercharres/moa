# DELIVERY CHECKLIST
## Checklist de Entrega Corporativa — Portal Creditos IaC

| | |
|---|---|
| **Proyecto** | Portal Creditos — Infraestructura como Código |
| **Entregado a** | Equipo de Infraestructura MOA (Molinos Agro) |
| **Estándar** | MOA-INFRA-Terraform-Best-Practices v1.3 |
| **Estado** | Validado y listo para auditoría MOA |
| **Última revisión** | 2026-07-03 (auditoría final de pipeline y variables) |

---

## Sección 1 — Repositorio

| # | Ítem | Estado |
|---|---|---|
| 1.1 | El repositorio está en el repositorio corporativo Azure DevOps de MOA | ✅ |
| 1.2 | El código no contiene secretos, contraseñas ni credenciales hardcodeadas | ✅ |
| 1.3 | El código no contiene valores corporativos sensibles (IDs de cuenta, ARNs reales, IPs) | ✅ |
| 1.4 | Los archivos `*.tfvars` reales están en `.gitignore` y no versionados | ✅ |
| 1.5 | Los archivos `*.hcl` reales están en `.gitignore` y no versionados | ✅ |
| 1.6 | El `tag_costcenter` no tiene valor por defecto — es variable obligatoria | ✅ |
| 1.7 | El pipeline no tiene valores placeholder (`000000`, `REPLACE_ME`, etc.) para datos corporativos | ✅ |
| 1.8 | `terraform fmt` pasa sin errores en ambos stacks | ✅ |
| 1.9 | `terraform validate` pasa sin errores en ambos stacks | ✅ |

---

## Sección 2 — Backend Stack (`infra/terraform/backend/`)

### Estructura
| # | Ítem | Estado |
|---|---|---|
| 2.1 | `versions.tf` con `required_version = ">= 1.10, < 2.0"` | ✅ |
| 2.2 | `providers.tf` separado de `versions.tf` | ✅ |
| 2.3 | `variables.tf` con tipos, descripciones y bloques `validation` | ✅ |
| 2.4 | `locals.tf` centraliza nomenclatura MOA y bloque `common_tags` | ✅ |
| 2.5 | `main.tf` solo orquesta módulos (sin recursos directos) | ✅ |
| 2.6 | `outputs.tf` sin outputs pass-through de variables | ✅ |
| 2.7 | `terraform.tfvars.example` con instrucciones claras y sin valores ambiguos | ✅ |
| 2.8 | `backend.qa.s3.hcl.example` con key de estado incluye ambiente (`-qa`) | ✅ |
| 2.9 | `backend.prd.s3.hcl.example` con key de estado incluye ambiente (`-prd`) | ✅ |
| 2.10 | `.gitignore` en directorio del stack | ✅ |

### Módulos
| # | Ítem | Estado |
|---|---|---|
| 2.11 | `modules/ecr`: `prevent_destroy`, lifecycle 2 reglas, `scan_on_push`, cifrado AES256 | ✅ |
| 2.12 | `modules/monitoring`: `kms_key_id` variable, `prevent_destroy`, retención configurable | ✅ |
| 2.13 | `modules/iam`: mínimo privilegio, políticas condicionales, separation execution/task | ✅ |
| 2.14 | `modules/networking`: `drop_invalid_header_fields`, `enable_deletion_protection`, `access_logs`, TLS 1.3 | ✅ |
| 2.15 | `modules/ecs`: Container Insights, circuit breaker, `cpu_architecture` variable | ✅ |

### Seguridad y Compliance
| # | Ítem | Estado |
|---|---|---|
| 2.16 | Variables de ARN de secretos con `sensitive = true` | ✅ |
| 2.17 | `aws_skip_*` variables con `validation { condition = !var.* }` | ✅ |
| 2.18 | `load_balancer_internal = true` por defecto | ✅ |
| 2.19 | `ecr_image_tag_mutability = "IMMUTABLE"` por defecto | ✅ |
| 2.20 | Los 10 tags MOA obligatorios presentes en `common_tags` | ✅ |

### Auditoría
| # | Ítem | Estado |
|---|---|---|
| 2.21 | Auditoría individual completada: `docs/audits/backend-audit.md` | ✅ |
| 2.22 | Cumplimiento MOA-INFRA-Terraform-Best-Practices v1.3: Validado | ✅ |

---

## Sección 3 — Frontend Stack (`infra/terraform/frontend/`)

### Estructura
| # | Ítem | Estado |
|---|---|---|
| 3.1 | `versions.tf` con `required_version = ">= 1.10, < 2.0"` | ✅ |
| 3.2 | `providers.tf` separado de `versions.tf` | ✅ |
| 3.3 | `variables.tf` con tipos, descripciones y bloques `validation` | ✅ |
| 3.4 | `locals.tf` centraliza nomenclatura MOA y bloque `common_tags` | ✅ |
| 3.5 | `main.tf` solo orquesta módulos (sin recursos directos) | ✅ |
| 3.6 | `outputs.tf` sin outputs pass-through de variables | ✅ |
| 3.7 | `terraform.tfvars.example` con instrucciones claras y sin valores ambiguos | ✅ |
| 3.8 | `backend.qa.hcl.example` con key de estado incluye ambiente (`-qa`) | ✅ |
| 3.9 | `backend.prd.hcl.example` con key de estado incluye ambiente (`-prd`) | ✅ |
| 3.10 | `.gitignore` en directorio del stack | ✅ |

### Módulos
| # | Ítem | Estado |
|---|---|---|
| 3.11 | `modules/ecr`: `prevent_destroy`, lifecycle 2 reglas, `scan_on_push`, cifrado AES256 | ✅ |
| 3.12 | `modules/monitoring`: `kms_key_id` variable, `prevent_destroy`, retención configurable | ✅ |
| 3.13 | `modules/iam`: mínimo privilegio (sin Secrets Manager — Nginx no lo requiere) | ✅ |
| 3.14 | `modules/networking`: `drop_invalid_header_fields`, `enable_deletion_protection`, `access_logs`, TLS 1.3 | ✅ |
| 3.15 | `modules/ecs`: Container Insights, circuit breaker, `cpu_architecture` variable | ✅ |

### Seguridad y Compliance
| # | Ítem | Estado |
|---|---|---|
| 3.16 | `aws_skip_*` variables con `validation { condition = !var.* }` | ✅ |
| 3.17 | `load_balancer_internal = true` por defecto (firme para frontend) | ✅ |
| 3.18 | `ecr_image_tag_mutability = "IMMUTABLE"` por defecto | ✅ |
| 3.19 | Los 10 tags MOA obligatorios presentes en `common_tags` | ✅ |

### Auditoría
| # | Ítem | Estado |
|---|---|---|
| 3.20 | Auditoría individual completada: `docs/audits/frontend-audit.md` | ✅ |
| 3.21 | Cumplimiento MOA-INFRA-Terraform-Best-Practices v1.3: Validado | ✅ |

---

## Sección 4 — Pipeline Azure DevOps

| # | Ítem | Estado |
|---|---|---|
| 4.1 | `trigger: none` — ejecución manual controlada | ✅ |
| 4.2 | `pr: none` — sin ejecución automática en PRs | ✅ |
| 4.3 | `terraform fmt -check` incluido en el pipeline | ✅ |
| 4.4 | `terraform validate` incluido en el pipeline | ✅ |
| 4.5 | `terraform plan -out=tfplan` antes del apply | ✅ |
| 4.6 | Variables de tags con prefijo `TF_VAR_tag_*` | ✅ |
| 4.7 | `tag_costcenter` sin valor placeholder en el YAML | ✅ |
| 4.8 | Soporte para ambientes `qa` y `prod` | ✅ |
| 4.9 | Soporte para stacks `backend`, `frontend`, `all` | ✅ |
| 4.10 | Búsqueda de `terraform.tfvars` antes que `env/<env>.tfvars` | ✅ |
| 4.11 | Uso de `deployment` job con `environment:` para posibles approval gates | ✅ |
| 4.12 | `BACKEND_ENV_PATH` definida correctamente en script bash del backend | ✅ **Corregido en auditoría final** |
| 4.13 | `frontendTfVarAlbIngressCidrBlocks` con rango interno `10.0.0.0/8` | ✅ **Corregido en auditoría final** |

### Pendientes del pipeline (acciones MOA)
| # | Ítem | Estado |
|---|---|---|
| 4.12 | Variable Groups `portal-creditos-iac-qa` y `portal-creditos-iac-prod` creados | ⚠️ PENDIENTE MOA |
| 4.13 | Approval gates configurados en Azure DevOps Environments | ⚠️ PENDIENTE MOA |
| 4.14 | Pipeline parametrizado con AWS Service Connection OIDC; nombre pendiente MOA | ⚠️ PENDIENTE MOA |

---

## Sección 5 — Variables

| # | Ítem | Estado |
|---|---|---|
| 5.1 | `tag_costcenter`: variable obligatoria sin default | ✅ |
| 5.2 | `tag_requester`: tiene default pendiente de confirmación MOA | ⚠️ Confirmar |
| 5.3 | `tag_area`: tiene default pendiente de confirmación MOA | ⚠️ Confirmar |
| 5.4 | `tag_risk`: validación `high/medium/low` | ✅ |
| 5.5 | `tag_backup_policy`: validación `NoBackup/DiarioR7` | ✅ |
| 5.6 | `tag_environment`: validación `QA/PRD` | ✅ |
| 5.7 | `tag_autopoweron`/`tag_autopoweroff`: validación `true/false` | ✅ |
| 5.8 | Secretos backend con `sensitive = true` | ✅ |
| 5.9 | Variables de AWS provider con `validation { condition = !var.* }` | ✅ |
| 5.10 | Todas las variables tienen `type` y `description` | ✅ || 5.10 | `env/qa.tfvars.example` sin valores ficticios para tags corporativos | ✅ **Corregido en auditoría final** |
---

## Sección 6 — README

| # | Ítem | Estado |
|---|---|---|
| 6.1 | README principal (`README.md`) reescrito para MOA | ✅ |
| 6.2 | Arquitectura explicada con diagrama | ✅ |
| 6.3 | Estructura del repositorio documentada | ✅ |
| 6.4 | Backend y Frontend documentados por separado | ✅ |
| 6.5 | Pipeline documentado con parámetros | ✅ |
| 6.6 | Variables obligatorias listadas | ✅ |
| 6.7 | Módulos documentados | ✅ |
| 6.8 | Dependencias externas listadas | ✅ |
| 6.9 | Nomenclatura MOA con ejemplos | ✅ |
| 6.10 | Flujo de despliegue documentado | ✅ |
| 6.11 | Referencias a documentación técnica en `docs/` | ✅ |

---

## Sección 7 — Documentación Técnica

| # | Documento | Estado |
|---|---|---|
| 7.1 | `docs/01-Architecture.md` — arquitectura con diagramas Mermaid | ✅ |
| 7.2 | `docs/02-Deployment-Inputs.md` — tabla completa de inputs MOA | ✅ |
| 7.3 | `docs/03-Operational-Pending.md` — 18 pendientes por categoría | ✅ |
| 7.4 | `docs/04-Architecture-Decisions.md` — 11 ADRs documentados | ✅ |
| 7.5 | `docs/05-Exceptions.md` — 5 excepciones al estándar MOA | ✅ |
| 7.6 | `docs/06-Handover.md` — guía completa para MOA | ✅ |
| 7.7 | `docs/audits/backend-audit.md` — auditoría backend | ✅ |
| 7.8 | `docs/audits/frontend-audit.md` — auditoría frontend | ✅ |
| 7.9 | `docs/audits/final-audit.md` — auditoría final integral | ✅ |
| 7.10 | `docs/audits/pipeline-audit.md` — auditoría del pipeline | ✅ **Generado en auditoría final** |
| 7.11 | `docs/audits/moa-gap-analysis.md` — análisis de brecha inicial MOA | ✅ Movido a `audits/` |

---

## Sección 8 — Pendientes MOA (acciones requeridas antes del despliegue)

| # | Pendiente | Categoría | Bloqueante | Responsable |
|---|---|---|---|---|
| 8.1 | Provisionar S3 bucket y DynamoDB para estado Terraform | Infraestructura | **Sí** | MOA Infraestructura |
| 8.2 | Confirmar y proveer VPC ID y Subnet IDs | Networking | **Sí** | MOA Networking |
| 8.3 | Crear Secrets en Secrets Manager y proveer ARNs | Seguridad | **Sí** | MOA Seguridad |
| 8.4 | Proveer valor real de `tag_costcenter` | Gobernanza | **Sí** | MOA Finanzas |
| 8.5 | Crear Variable Groups Azure DevOps con credenciales AWS | DevOps | **Sí** | MOA DevOps |
| 8.6 | Confirmar todos los valores de tags corporativos | Gobernanza | **Sí** | MOA Gobernanza |
| 8.7 | Confirmar región AWS definitiva | Infraestructura | **Sí** | MOA Infraestructura |
| 8.8 | Aprobar excepciones del estándar MOA (`docs/05-Exceptions.md`) | Gobernanza | Sí | MOA Infraestructura |
| 8.9 | Configurar approval gates en Azure DevOps | DevOps | No | MOA DevOps |
| 8.10 | Provisionar KMS Key para CloudWatch Logs | Seguridad | No | MOA Seguridad |
| 8.11 | Provisionar S3 bucket para ALB access logs | Infraestructura | No | MOA Infraestructura |
| 8.12 | Provisionar ACM Certificate (si HTTPS requerido) | Seguridad | No | MOA Seguridad |

---

## Sección 9 — Pendientes DevOps

| # | Pendiente | Estado |
|---|---|---|
| 9.1 | Crear pipeline backend-release en Azure DevOps | ⚠️ PENDIENTE |
| 9.2 | Crear pipeline frontend-release en Azure DevOps | ⚠️ PENDIENTE |
| 9.3 | Configurar pipeline de Flyway (one-off migrations) | ⚠️ PENDIENTE |
| 9.4 | Validar conectividad ECS → RDS desde subnets privadas | ⚠️ PENDIENTE |

---

## Sección 10 — Pendientes Infraestructura

| # | Pendiente | Estado |
|---|---|---|
| 10.1 | Crear `backend.qa.s3.hcl` con valores reales (no commitear) | ⚠️ PENDIENTE |
| 10.2 | Crear `backend.prd.s3.hcl` con valores reales (no commitear) | ⚠️ PENDIENTE |
| 10.3 | Crear `env/qa.tfvars` backend con valores reales (no commitear) | ⚠️ PENDIENTE |
| 10.4 | Crear `env/prd.tfvars` backend con valores reales (no commitear) | ⚠️ PENDIENTE |
| 10.5 | Crear `terraform.tfvars` frontend con valores reales (no commitear) | ⚠️ PENDIENTE |
| 10.6 | Configurar `alb_deletion_protection = true` en tfvars de PRD | ⚠️ PENDIENTE (pre-PRD) |

---

## Checklist Final de Auditoría

| # | Criterio | Estado |
|---|---|---|
| A.1 | Cumplimiento MOA-INFRA-Terraform-Best-Practices v1.3: Validado | ✅ |
| A.2 | Cero hallazgos P1 (bloqueantes) de código | ✅ |
| A.3 | Cero hallazgos P2 (alta prioridad) de código | ✅ |
| A.4 | Cero hallazgos P3 (mejoras) de código | ✅ |
| A.5 | Sin secretos en el repositorio | ✅ |
| A.6 | Sin valores ficticios o ambiguos en código productivo | ✅ |
| A.7 | Documentación completa para MOA | ✅ |
| A.8 | Excepciones al estándar documentadas | ✅ |
| A.9 | README autosuficiente para MOA | ✅ |
| A.10 | Pipeline funcional y documentado | ✅ |
| A.11 | Bug crítico de pipeline corregido (`BACKEND_ENV_PATH`) | ✅ Corregido |
| A.12 | CIDR de ALB frontend alineado con arquitectura interna | ✅ Corregido |
| A.13 | Ningún archivo de ejemplo con valor ficticio `000000` para costcenter | ✅ Corregido |

---

## Firma de entrega

| Rol | Nombre | Fecha | Firma |
|---|---|---|---|
| Equipo Desarrollo (entregante) | | 2026-07-03 | _______________ |
| MOA Infraestructura (receptor) | | | _______________ |
| MOA Seguridad (revisor) | | | _______________ |
| MOA Gobernanza (validador tags) | | | _______________ |

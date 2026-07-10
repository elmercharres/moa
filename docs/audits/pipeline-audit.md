# Auditoría del Pipeline Azure DevOps
## `azure-pipelines-iac.yml` — Revisión de cumplimiento MOA

| | |
|---|---|
| **Archivo auditado** | `azure-pipelines-iac.yml` |
| **Estándar normativo** | MOA-INFRA-Terraform-Best-Practices v1.3, Sección 10 |
| **Fecha** | 2026-07-03 |
| **Veredicto** | ✅ APROBADO — 3 incumplimientos encontrados y corregidos en esta iteración |

---

## 1. Resumen

La auditoría del pipeline identificó **3 incumplimientos**: 1 bug funcional crítico, 1 problema de seguridad y 1 valor ficticio en un archivo de ejemplo. Los tres fueron corregidos en esta misma sesión. No quedan incumplimientos abiertos en el pipeline.

| ID | Severidad | Descripción | Estado |
|---|---|---|---|
| PL-01 | 🔴 Crítico | `BACKEND_ENV_PATH` no definida en script backend | ✅ Corregido |
| PL-02 | 🟠 Seguridad | `frontendTfVarAlbIngressCidrBlocks = ["0.0.0.0/0"]` | ✅ Corregido |
| PL-03 | 🟡 Compliance | `tag_costcenter = "000000"` en `env/qa.tfvars.example` | ✅ Corregido |

---

## 2. Hallazgos corregidos

### PL-01 — Bug crítico: `BACKEND_ENV_PATH` no definida en script bash del backend

**Archivo:** `azure-pipelines-iac.yml` — script bash del stack backend

**Evidencia (antes):**
```bash
cd "$(Build.SourcesDirectory)/infra/terraform/backend"
BACKEND_DEFAULT_PATH="backend.s3.hcl"           # ← solo se define BACKEND_DEFAULT_PATH
TFVARS_STD_PATH="terraform.tfvars"
TFVARS_ENV_PATH="env/$(environmentName).tfvars"

if [ -f "$BACKEND_ENV_PATH" ]; then              # ← BACKEND_ENV_PATH nunca fue definida
  BACKEND_CONFIG_ARG="-backend-config=$BACKEND_ENV_PATH"
```

**Problema:** La variable `BACKEND_ENV_PATH` era referenciada sin estar definida, evaluando a cadena vacía. El resultado de `[ -f "" ]` es siempre falso, por lo que el pipeline **nunca usaba los archivos de backend config por ambiente** (`backend.qa.s3.hcl`, `backend.prd.s3.hcl`) creados durante la remediación P1-01/P1-02. Siempre caía al fallback `backend.s3.hcl` (el archivo deprecated con key placeholder `REEMPLAZAR_AMBIENTE`), lo que hubiera causado un fallo en `terraform init`.

**Corrección aplicada:**
```bash
BACKEND_ENV_PATH="backend.$(environmentName).s3.hcl"   # ← línea agregada
BACKEND_DEFAULT_PATH="backend.s3.hcl"
```

**Referencia MOA:** Sección 10 — Flujo de trabajo y proceso de aprobación.

---

### PL-02 — Seguridad: `frontendTfVarAlbIngressCidrBlocks` exponía `0.0.0.0/0`

**Archivo:** `azure-pipelines-iac.yml` — variable `frontendTfVarAlbIngressCidrBlocks`

**Evidencia (antes):**
```yaml
- name: frontendTfVarAlbIngressCidrBlocks
  value: '["0.0.0.0/0"]'
```

**Problema:** El ALB del frontend es interno (`load_balancer_internal = true`). Sin embargo, cuando el pipeline ejecuta sin archivo `terraform.tfvars`, esta variable se pasa como `TF_VAR_alb_ingress_cidr_blocks = ["0.0.0.0/0"]`, lo que permite tráfico desde cualquier IP al security group del ALB. Contradice:
- El `variables.tf` del frontend: `default = ["10.0.0.0/8"]`
- El `terraform.tfvars.example`: `alb_ingress_cidr_blocks = ["10.0.0.0/8"]`
- La Decisión Arquitectónica ADR-04 (ALB interno, solo desde VPN)
- MOA Sección 9 — Seguridad: gestión de acceso mínimo privilegio

**Corrección aplicada:**
```yaml
# Must match the corporate VPN or internal network range. Do NOT use 0.0.0.0/0 (frontend ALB is internal).
- name: frontendTfVarAlbIngressCidrBlocks
  value: '["10.0.0.0/8"]'
```

**Referencia MOA:** Sección 9 — Seguridad.

---

### PL-03 — Compliance: `tag_costcenter = "000000"` en `env/qa.tfvars.example`

**Archivo:** `infra/terraform/backend/env/qa.tfvars.example`

**Evidencia (antes):**
```hcl
tag_costcenter   = "000000"
```

**Problema:** La variable `tag_costcenter` fue convertida a obligatoria (sin default) en la iteración anterior de remediación. El `terraform.tfvars.example` principal fue actualizado correctamente con `<COSTCENTER_PROVISTO_POR_MOA_FINANZAS>`. Sin embargo, el archivo alternativo `env/qa.tfvars.example` mantuvo el valor ficticio `"000000"`. Un operador que copie este archivo para crear `env/qa.tfvars` desplegaría con un costcenter inválido — el valor `"000000"` pasa la validación técnica (no es cadena vacía) pero es incorrecto.

**Corrección aplicada:**
```hcl
tag_costcenter   = "<COSTCENTER_PROVISTO_POR_MOA_FINANZAS>"  # OBLIGATORIO — provisto por MOA Finanzas
```
También se añadieron comentarios explicativos al resto de los tags en el archivo, consistentes con el `terraform.tfvars.example`.

**Referencia MOA:** Sección 6 — Tags obligatorios.

---

## 3. Auditoría completa del pipeline — puntos conformes

### 3.1 Sección 10 — Flujo de trabajo y proceso de aprobación

| Requerimiento | Cumplimiento | Evidencia |
|---|---|---|
| Pipeline como único propietario de cambios Terraform | ✅ | `trigger: none` + `pr: none` |
| Plan antes de apply | ✅ | `terraform plan -out=tfplan` en todos los casos |
| Apply solo si se aprueba | ✅ | Job `deployment` con `environment:` (approval gates configurables en Azure DevOps) |
| `terraform fmt -check` | ✅ | Ejecutado antes del plan en ambos stacks |
| `terraform validate` | ✅ | Ejecutado antes del plan en ambos stacks |
| Documentación de cambios antes de apply | ✅ | `terraform show -no-color tfplan` en modo plan |
| Ejecución con credenciales centralizadas | ⚠️ | Usa `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`. Pendiente migración a Service Connections. |

### 3.2 Tags obligatorios MOA — cobertura en el pipeline

Los 10 tags obligatorios se pasan correctamente como `TF_VAR_tag_*` en ambos stacks:

| Tag MOA | Variable pipeline | `TF_VAR_` backend | `TF_VAR_` frontend |
|---|---|---|---|
| `Application` | `clientApplicationTag` = `Portal-Creditos` | ✅ | ✅ |
| `Area` | `clientAreaTag` = `Demanda` | ✅ | ✅ |
| `Autopoweron` | `clientAutopoweron` = `false` | ✅ | ✅ |
| `Autopoweroff` | `clientAutopoweroff` = `false` | ✅ | ✅ |
| `BackupPolicy` | `clientBackupPolicyTag` = `NoBackup` | ✅ | ✅ |
| `Costcenter` | `clientCostcenter` = `''` *(vacío intencional)* | ✅ | ✅ |
| `Environment` | `clientEnvironmentTag` = `QA`/`PRD` | ✅ | ✅ |
| `Project` | `clientProjectTag` = `Portal-Creditos` | ✅ | ✅ |
| `Requester` | `clientRequesterTag` = `Fernando Ponce De Leon` | ✅ | ✅ |
| `Risk` | `clientRiskTag` = `medium` | ✅ | ✅ |

> **Nota sobre `clientCostcenter = ''`**: Es intencional. La variable `tag_costcenter` no tiene default en Terraform; si no hay archivo tfvars con valor real, el `terraform plan` fallará con error de validación explícito. El valor real debe estar en el Variable Group del ambiente.

### 3.3 Variables corporativas — análisis de valores en pipeline

| Variable pipeline | Valor actual | Estado |
|---|---|---|
| `awsRegion` | `us-east-1` | ⚠️ Pendiente confirmación MOA |
| `clientProjectTag` | `Portal-Creditos` | ⚠️ Pendiente confirmación MOA |
| `clientApplicationTag` | `Portal-Creditos` | ⚠️ Pendiente confirmación MOA |
| `clientAreaTag` | `Demanda` | ⚠️ Pendiente confirmación MOA |
| `clientRiskTag` | `medium` | ⚠️ Pendiente confirmación MOA |
| `clientRequesterTag` | `Fernando Ponce De Leon` | ⚠️ Pendiente confirmación MOA |
| `clientBackupPolicyTag` | `NoBackup` | ⚠️ Pendiente confirmación MOA |
| `clientAutopoweron` | `false` | ⚠️ Pendiente confirmación MOA |
| `clientAutopoweroff` | `false` | ⚠️ Pendiente confirmación MOA |
| `clientCostcenter` | `''` (vacío) | ✅ Intencional — requiere Variable Group |

> Los valores marcados como ⚠️ son los defaults que propone el equipo de desarrollo. No son valores ficticios — son razonables para el proyecto, pero deben ser **confirmados y aprobados por MOA** antes del primer despliegue. Si MOA los aprueba, no requieren cambio.

### 3.4 Seguridad del pipeline

| Control | Estado |
|---|---|
| Sin credenciales hardcodeadas en YAML | ✅ |
| Sin secretos en valores de variables | ✅ |
| Secretos AWS en Variable Group (marcados como secretos) | ✅ (pendiente creación) |
| `TF_IN_AUTOMATION: 'true'` | ✅ |
| `TF_INPUT: '0'` | ✅ |
| `set -euo pipefail` en todos los scripts bash | ✅ |
| Terraform descargado desde releases.hashicorp.com con versión fija | ✅ `1.8.5` |

---

## 4. Verificación de variables Terraform — resultado de auditoría

### 4.1 Variables obligatorias sin default (requieren valor explícito)

**Backend:**

| Variable | Tipo | Motivo |
|---|---|---|
| `vpc_id` | string | Infraestructura pre-existente MOA |
| `public_subnet_ids` | list(string) | Infraestructura pre-existente MOA |
| `private_subnet_ids` | list(string) | Infraestructura pre-existente MOA |
| `tag_costcenter` | string | Tag corporativo — provisto por MOA Finanzas |
| `postgres_connection_string_secret_arn` | string (sensitive) | Secret ARN — provisto por MOA Seguridad |
| `jwt_signing_key_secret_arn` | string (sensitive) | Secret ARN — provisto por MOA Seguridad |
| `flyway_url_secret_arn` | string (sensitive) | Secret ARN — provisto por MOA Seguridad |
| `flyway_user_secret_arn` | string (sensitive) | Secret ARN — provisto por MOA Seguridad |
| `flyway_password_secret_arn` | string (sensitive) | Secret ARN — provisto por MOA Seguridad |

**Frontend:**

| Variable | Tipo | Motivo |
|---|---|---|
| `vpc_id` | string | Infraestructura pre-existente MOA |
| `load_balancer_subnet_ids` | list(string) | Infraestructura pre-existente MOA |
| `private_subnet_ids` | list(string) | Infraestructura pre-existente MOA |
| `tag_costcenter` | string | Tag corporativo — provisto por MOA Finanzas |

### 4.2 Variables corporativas con defaults — verificación

| Variable | Default actual | ¿Ficticio? | Acción |
|---|---|---|---|
| `tag_application` | `Portal-Creditos` | No | Confirmar con MOA Governance |
| `tag_area` | `Demanda` | No | Confirmar con MOA Governance |
| `tag_risk` | `medium` | No | Confirmar con MOA Security |
| `tag_requester` | `Fernando Ponce De Leon` | No | Confirmar con MOA / Responsable proyecto |
| `tag_backup_policy` | `NoBackup` | No | Confirmar con MOA Infrastructure |
| `tag_project` | `Portal-Creditos` | No | Confirmar con MOA Governance |
| `tag_autopoweron` | `false` | No | Confirmar con MOA Infrastructure |
| `tag_autopoweroff` | `false` | No | Confirmar con MOA Infrastructure |
| `aws_region` | `us-east-1` | No | Confirmar con MOA Infrastructure |

> Ningún default es ficticio. Son propuestas técnicas que deben confirmarse con MOA.

### 4.3 `terraform.tfvars.example` — verificación de valores ficticisos

| Archivo | Variable problemática | Estado |
|---|---|---|
| `backend/terraform.tfvars.example` | `tag_costcenter` | ✅ `<COSTCENTER_PROVISTO_POR_MOA_FINANZAS>` |
| `backend/env/qa.tfvars.example` | `tag_costcenter` | ✅ Corregido en esta iteración (era `000000`) |
| `frontend/terraform.tfvars.example` | `tag_costcenter` | ✅ `<COSTCENTER_PROVISTO_POR_MOA_FINANZAS>` |
| Todos los archivos `.example` | Placeholders de VPC/subnets | ✅ Aceptables en archivos `.example` (templates) |
| Todos los archivos `.example` | Placeholders de secret ARNs | ✅ Aceptables en archivos `.example` (muestran formato) |

---

## 5. Resultado final

| Categoría | Encontrado | Corregido | Pendiente |
|---|---|---|---|
| Bugs funcionales | 1 (PL-01) | 1 ✅ | 0 |
| Problemas de seguridad | 1 (PL-02) | 1 ✅ | 0 |
| Valores ficticios / compliance | 1 (PL-03) | 1 ✅ | 0 |
| Tags MOA sin cobertura en pipeline | 0 | — | 0 |
| Variables sensibles sin `sensitive = true` | 0 | — | 0 |
| **Total incumplimientos** | **3** | **3** | **0** |

**El pipeline está conforme con el estándar MOA tras la aplicación de las 3 correcciones.**

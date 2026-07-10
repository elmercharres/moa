# 05 — Excepciones al Estándar MOA
## Desviaciones documentadas respecto a MOA-INFRA-Terraform-Best-Practices v1.3

> Todas las excepciones en este documento son generadas por **restricciones técnicas de AWS**,
> no por decisiones arbitrarias del equipo de desarrollo.
> Cada excepción debe ser **revisada y firmada** por el equipo de Infraestructura de MOA.

---

## EXC-01 — Nombres de repositorios ECR en lowercase

| | |
|---|---|
| **Estándar MOA** | Sección 5 — `ECS-REPO-{Proyecto}-{Aplicacion}-{Amb}` (mayúsculas) |
| **Implementación** | `ecs-repo-portal-creditos-api-qa` (lowercase) |
| **Estado aprobación** | ⚠️ PENDIENTE DE APROBACIÓN ESCRITA POR MOA |

**Motivo técnico:** AWS ECR impone que los nombres de repositorios sean **únicamente en lowercase**. La expresión regular de ECR acepta solo: `[a-z0-9]+(?:[._\-\/][a-z0-9]+)*`.

**Referencia AWS:** [ECR Repository Names](https://docs.aws.amazon.com/AmazonECR/latest/APIReference/API_CreateRepository.html) — campo `repositoryName`.

**Justificación:** El patrón MOA con mayúsculas (`ECS-REPO-BDC-Datasphere-SAP-PRD`) es incompatible con ECR. La adaptación implementada preserva todos los componentes del patrón (Proyecto, Aplicacion, Servicio, Ambiente) en lowercase y con guiones.

**Patrón implementado:**
```
ecs-repo-{project_name}-{application_name}-{environment}   ← backend (application_name = "api")
ecs-repo-{project_name}-{service_name}-{environment}       ← frontend (service_name = "web")
```

**Nombres resultantes:**
| Stack | Componente | Nombre ECR |
|---|---|---|
| Backend | API | `ecs-repo-portal-creditos-api-qa` |
| Backend | Flyway | `ecs-repo-portal-creditos-db-qa` |
| Frontend | Web | `ecs-repo-portal-creditos-web-qa` |

**Impacto:** Visual — los nombres en consola AWS aparecen en lowercase. Funcionalmente no hay impacto. Las referencias dentro del código Terraform son consistentes.

---

## EXC-02 — Nombres de ALB y Target Group sin componente Application (límite 32 caracteres)

| | |
|---|---|
| **Estándar MOA** | Sección 5 — `ALB-{Proyecto}-{Aplicacion}-{Amb}` |
| **Implementación** | `ALB-portal-creditos-QA` (sin componente Application) |
| **Estado aprobación** | ⚠️ PENDIENTE DE APROBACIÓN ESCRITA POR MOA |

**Motivo técnico:** AWS impone un máximo de **32 caracteres** en los nombres de ALB (`aws_lb`) y Target Group (`aws_lb_target_group`). El nombre completo con todos los componentes del patrón MOA excede este límite:

| Nombre completo | Caracteres |
|---|---|
| `ALB-Portal-Creditos-API-QA` | 22 (válido — pero componente Application aún omitido por consistencia) |
| `ALB-portal-creditos-QA` | 22 (válido) ✅ |
| `ALB-portal-creditos-web-QA` | 26 (válido) ✅ |

**Referencia AWS:** [ALB Naming Constraints](https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_CreateLoadBalancer.html) — "The name must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with 'internal-'."

**Justificación:** No existe abreviación estándar acordada con MOA. El componente `{Aplicacion}` fue omitido para cumplir el límite. El componente `{Proyecto}` y `{Ambiente}` se preservan, manteniendo unicidad y trazabilidad suficiente.

**Patrón implementado:**
```
ALB-{project_name}-{tag_environment}       → Backend: ALB-portal-creditos-QA
ALB-{project_name}-{service_name}-{tag_environment} → Frontend: ALB-portal-creditos-web-QA

ALB-TG-{project_name}-{tag_environment}    → Backend: ALB-TG-portal-creditos-QA
```

**Impacto:** Menor — el nombre no incluye el componente `Application`. La trazabilidad se mantiene via el tag `Application` que sí se aplica a todos los recursos.

**Acción requerida:** MOA Infraestructura debe aprobar esta excepción por escrito y opcionalmente proponer una abreviatura estándar para `{Aplicacion}` que permita incluirla dentro de los 32 caracteres.

---

## EXC-03 — Nomenclatura de Security Groups adaptada para ECS

| | |
|---|---|
| **Estándar MOA** | Sección 5 — `SG_MOA_EC2_{ENV}_{NombreServidor}` |
| **Implementación** | `SG_MOA_ECS_{ENV}_{Proyecto}-{Servicio}` |
| **Estado aprobación** | ⚠️ PENDIENTE DE APROBACIÓN ESCRITA POR MOA |

**Motivo técnico:** El estándar MOA define el patrón de Security Groups únicamente para instancias EC2 (`SG_MOA_EC2_{ENV}_{NombreServidor}`). Los servicios ECS Fargate no tienen "NombreServidor" porque son serverless y los contenedores no tienen nombre de servidor individual.

**Justificación:** Se adaptó el patrón sustituyendo `EC2` por `ECS` y `NombreServidor` por `{Proyecto}-{Rol}` para mantener la semántica del patrón y la unicidad de nombres:

| SG | Nombre implementado |
|---|---|
| Backend ALB SG | `SG_MOA_ECS_QA_Portal-Creditos-ALB` |
| Backend Service SG | `SG_MOA_ECS_QA_Portal-Creditos-API` |
| Frontend ALB SG | `SG_MOA_ECS_QA_Portal-Creditos-WEB-ALB` |
| Frontend Service SG | `SG_MOA_ECS_QA_Portal-Creditos-WEB-SVC` |

**Impacto:** El patrón base `SG_MOA_*_{ENV}_*` se preserva para facilitar identificación y consultas con filtros en la consola AWS.

---

## EXC-04 — `aws_appautoscaling_target` sin atributo `name`

| | |
|---|---|
| **Estándar MOA** | Sección 5 — `AAS-{Proyecto}-{Aplicacion}-{Amb}` |
| **Implementación** | El recurso `aws_appautoscaling_target` no acepta atributo `name` |
| **Estado aprobación** | ✅ Excepción técnica — no requiere aprobación formal |

**Motivo técnico:** El recurso `aws_appautoscaling_target` de AWS Application Auto Scaling API no expone un campo `name` ni `tags` en la API de AWS. No puede ser nombrado ni taggeado directamente.

**Referencia AWS:** [RegisterScalableTarget API](https://docs.aws.amazon.com/autoscaling/application/APIReference/API_RegisterScalableTarget.html) — el target se identifica por `ResourceId`, `ScalableDimension` y `ServiceNamespace`, no por un nombre libre.

**Justificación:** El naming MOA `AAS-*` se aplica únicamente al recurso `aws_appautoscaling_policy` (la política de escalado), que sí acepta un nombre:
- Backend: `AAS-Portal-Creditos-API-QA-CPU`
- Frontend: `AAS-Portal-Creditos-WEB-QA-CPU`

**Impacto:** El target de autoscaling no aparece con nombre explícito en la consola AWS Application Auto Scaling. Es identificable vía `ResourceId = service/{cluster}/{service}`.

---

## EXC-05 — CloudWatch Log Groups patrón adaptado para ECS

| | |
|---|---|
| **Estándar MOA** | Sección 5 — `/ec2/{Proyecto}-{Env}/user-data` |
| **Implementación** | `/ecs/{Proyecto}-{Env}/{servicio}` |
| **Estado aprobación** | ✅ Adaptación técnica razonable — verificar con MOA |

**Motivo técnico:** El estándar MOA define el patrón de log group únicamente para workloads EC2 (`/ec2/{Proyecto}-{Env}/user-data`). ECS Fargate usa el log driver `awslogs` que requiere un log group separado para cada servicio/tarea.

**Patrón implementado:**
```
/ecs/{Proyecto}-{Env}/{servicio}
```

**Log groups creados:**
| Stack | Log Group |
|---|---|
| Backend API | `/ecs/Portal-Creditos-QA/api` |
| Backend Flyway | `/ecs/Portal-Creditos-QA/db-migrations` |
| Frontend Web | `/ecs/Portal-Creditos-QA/web` |

**Impacto:** Los log groups son claramente identificables. El prefijo `/ecs/` diferencia visualmente los logs de ECS de los de EC2.

---

## Tabla de estado de excepciones

| ID | Excepción | Requiere aprobación MOA | Estado |
|---|---|---|---|
| EXC-01 | ECR names en lowercase | Sí | ⚠️ PENDIENTE |
| EXC-02 | ALB/TG sin componente Application (32 chars) | **Sí (crítica)** | ⚠️ PENDIENTE |
| EXC-03 | SG nomenclatura adaptada para ECS | Sí | ⚠️ PENDIENTE |
| EXC-04 | Auto Scaling Target sin nombre | No (limitación API AWS) | ✅ Documentada |
| EXC-05 | CloudWatch Log Groups patrón ECS | Verificar con MOA | ⚠️ PENDIENTE confirmación |

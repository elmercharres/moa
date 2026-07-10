# 04 — Decisiones de Arquitectura
## Architecture Decision Records (ADR) — Portal Creditos IaC

---

## ADR-01 — Backend y Frontend como stacks Terraform independientes

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** El backend (API + Flyway) y el frontend (Angular/Nginx) se gestionan como stacks Terraform independientes en directorios separados (`infra/terraform/backend/` y `infra/terraform/frontend/`).

**Motivación:** Ambos servicios tienen ciclos de vida diferentes. El frontend puede cambiar sin afectar la infraestructura del backend y viceversa.

**Beneficio:**
- Menor superficie de impacto por cambio de IaC.
- Estados Terraform separados → destrucción de uno no afecta al otro.
- Pipelines de aplicación independientes (no requieren rerun del IaC completo).
- Escalado independiente de cada servicio.

**Impacto:**
- Requiere coordinar VPC/subnets entre ambos stacks (no se comparte estado).
- Dos archivos `tfvars` y dos `backend.hcl` por ambiente.

---

## ADR-02 — Uso de módulos locales (sin módulos remotos)

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** Todos los módulos se almacenan localmente en `./modules/`. No se usan módulos del Terraform Registry ni repositorios externos.

**Motivación:** El estándar MOA-INFRA-Terraform-Best-Practices v1.3 (Sección 2) requiere explícitamente que los módulos sean locales.

**Beneficio:**
- Control total sobre el código desplegado.
- Sin dependencias externas que puedan cambiar o desaparecer.
- Auditoría completa del código fuente.
- Funcionamiento sin acceso a internet desde el pipeline (solo AWS API).

**Impacto:**
- No se aprovechan módulos comunitarios de alta calidad (p.ej. `terraform-aws-modules/ecs`).
- Mayor volumen de código propio a mantener.

---

## ADR-03 — Amazon ECS Fargate como plataforma de compute

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** Los servicios se ejecutan en Amazon ECS con el launch type Fargate (serverless containers).

**Motivación:** Elimina la gestión de instancias EC2. MOA no debe administrar parches de OS, capacidad de cluster ni ASG de instancias.

**Beneficio:**
- Sin administración de servidores.
- Escalado automático por CPU/memoria.
- Billing por segundo de ejecución de task.
- Integración nativa con ALB, CloudWatch, IAM y Secrets Manager.

**Impacto:**
- Mayor costo por task vs. EC2 en workloads con alta y estable utilización.
- Limitaciones en configuración de red avanzada vs. EC2.
- Cold start puede ser perceptible con `desired_count = 0`.

---

## ADR-04 — ALB interno por defecto

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** El Application Load Balancer se configura como interno (`load_balancer_internal = true`) por defecto en ambos stacks.

**Motivación:** Portal Creditos es un sistema de uso interno corporativo. Exponer el ALB a internet sin autorización explícita de MOA Seguridad es inaceptable.

**Beneficio:**
- Los servicios solo son accesibles desde la VPN corporativa o la red interna de MOA.
- Reduce la superficie de ataque.
- Cumple el principio de mínimo privilegio de red.

**Impacto:**
- Los desarrolladores externos deben conectarse a la VPN para acceder a los servicios durante QA.
- Para casos de uso público (si aplica en el futuro), el valor debe cambiarse con aprobación de MOA Seguridad.

---

## ADR-05 — Amazon CloudWatch como observabilidad de logs

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** Se usa CloudWatch Logs como destino de todos los logs de contenedores. Container Insights está habilitado en todos los clusters ECS.

**Motivación:** CloudWatch es la solución nativa de AWS. No requiere agente adicional en Fargate. Container Insights provee métricas de cluster, service y task sin configuración adicional.

**Beneficio:**
- Sin infraestructura adicional de observabilidad.
- Retención configurable por variable (`log_retention_days`).
- Soporte de cifrado KMS (variable `log_kms_key_arn`).
- `prevent_destroy = true` protege los logs históricos.

**Impacto:**
- La integración con la cuenta LOGS centralizada de MOA requiere coordinación adicional (cross-account subscription).
- CloudWatch Insights y dashboards no están implementados en esta versión (fuera de alcance).

---

## ADR-06 — Amazon ECR para imágenes Docker

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** Las imágenes Docker se almacenan en Amazon ECR (Elastic Container Registry). Se crean repositorios separados para cada imagen (API, Flyway, Web).

**Motivación:** ECR es el registro de contenedores nativo de AWS. Integración directa con ECS para pull de imágenes sin credenciales adicionales.

**Beneficio:**
- Autenticación IAM nativa (sin contraseñas adicionales).
- Escaneo de vulnerabilidades (`scan_on_push = true`).
- Tags inmutables (`IMMUTABLE`) en producción para trazabilidad.
- Lifecycle policies automáticas (expiración de imágenes no taggeadas y límite de retención).
- `prevent_destroy = true` protege los repositorios y sus imágenes.

**Impacto:**
- Costo por almacenamiento de imágenes (lifecycle policies minimizan esto).
- Los pipelines de aplicación deben autenticarse con ECR antes del push.

---

## ADR-07 — No creación de Networking (VPC, Subnets, NAT)

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** El repositorio no crea ni modifica VPC, subnets, route tables, NAT Gateway ni ningún otro componente de networking.

**Motivación:** MOA gestiona su infraestructura de red de forma centralizada. Los projectos de aplicación no deben modificar la red corporativa.

**Beneficio:**
- Separación clara de responsabilidades entre el equipo de aplicación y el equipo de networking de MOA.
- Sin riesgo de afectar otros sistemas que comparten la VPC.
- Cumple el principio de mínimo privilegio de IaC.

**Impacto:**
- El equipo de desarrollo depende de MOA Networking para obtener los IDs de VPC y subnets.
- La conectividad entre ECS y RDS debe ser validada por MOA Networking.

---

## ADR-08 — No creación de Route53 ni DNS

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** El repositorio no crea ni gestiona registros Route53. El DNS de los ALBs queda como DNS name de AWS (`*.elb.amazonaws.com`).

**Motivación:** MOA gestiona el DNS corporativo de forma centralizada. Los proyectos de aplicación no tienen autoridad sobre los dominios corporativos.

**Beneficio:**
- Sin riesgo de colisión de nombres DNS.
- El equipo de aplicación no necesita permisos sobre Route53.

**Impacto:**
- Los endpoints de acceso son los DNS names del ALB, no nombres corporativos amigables.
- MOA Networking debe crear los registros CNAME/A si se requiere un dominio corporativo.

---

## ADR-09 — No creación de ACM Certificates

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** El repositorio no solicita ni gestiona certificados ACM. HTTPS se habilita pasando el ARN de un certificado pre-existente vía variable `certificate_arn`.

**Motivación:** La gestión de certificados TLS es responsabilidad del equipo de Seguridad de MOA. Los certificados corporativos pueden requerir validación por DNS o email con autoridades propias de MOA.

**Beneficio:**
- Sin dependencia del proceso de emisión/renovación de certificados en el pipeline.
- El mismo certificado puede reutilizarse en múltiples ambientes.

**Impacto:**
- Sin `certificate_arn`: el ALB opera en HTTP solamente (aceptable en ambientes internos con VPN).
- Con `certificate_arn`: HTTPS completo con redirect HTTP→HTTPS y TLS 1.3.

---

## ADR-10 — Separación de imágenes de aplicación y de infraestructura base

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** Terraform gestiona la infraestructura base (ECR, ECS cluster, ALB, IAM, CloudWatch). Los pipelines de aplicación publican las imágenes y registran nuevas revisiones de task definition. ECS service ignora cambios de `task_definition` (`lifecycle { ignore_changes = [task_definition] }`).

**Motivación:** Desacoplar el ciclo de vida de la infraestructura del ciclo de vida de la aplicación. Un release de código no debe requerir ejecutar Terraform.

**Beneficio:**
- Releases de aplicación rápidos sin intervención de IaC.
- Rollback de imagen sin tocar Terraform.
- El pipeline IaC solo se ejecuta cuando cambia infraestructura real.

**Impacto:**
- El `desired_count` del ECS service no puede ser cambiado por el pipeline de aplicación (requiere Terraform).
- La variable `image_uri` en Terraform solo se usa para el bootstrapping inicial del ECR.

---

## ADR-11 — Deployment Circuit Breaker en ECS Service

| | |
|---|---|
| **Estado** | Aprobado |
| **Fecha** | 2026-07-03 |

**Decisión:** Todos los ECS Services tienen `deployment_circuit_breaker { enable = true, rollback = true }`.

**Motivación:** Sin circuit breaker, un deployment fallido (imagen que no arranca, health check que falla) genera rotación indefinida de tasks hasta agotar el timeout, dejando el servicio degradado.

**Beneficio:**
- Detección automática de deployments fallidos.
- Rollback automático a la versión anterior estable.
- Sin intervención manual para recuperar el servicio ante una imagen defectuosa.

**Impacto:** Ninguno negativo. Mejora significativa de resiliencia operacional.

# 03 — Pendientes Operacionales
## Actividades que NO pueden resolverse desde Terraform

> Este documento lista exclusivamente las actividades que deben ser completadas
> **fuera del repositorio Terraform** antes de poder realizar el primer despliegue
> o como parte de la operación continua del sistema.

---

## Infraestructura

| ID | Actividad | Responsable | Bloqueante | Prioridad |
|---|---|---|---|---|
| INF-01 | Provisionar bucket S3 para estado Terraform con versionado, cifrado, acceso público bloqueado y política IAM de mínimo privilegio | MOA Infraestructura | **Sí** | 🔴 Crítico |
| INF-02 | Provisionar tabla DynamoDB para state locking | MOA Infraestructura | **Sí** | 🔴 Crítico |
| INF-03 | Confirmar y proveer VPC ID, subnets públicas/privadas para backend | MOA Networking | **Sí** | 🔴 Crítico |
| INF-04 | Confirmar y proveer VPC ID, subnets para frontend (ALB interno + ECS tasks) | MOA Networking | **Sí** | 🔴 Crítico |
| INF-05 | Verificar que las subnets privadas de ECS tengan salida a internet para ECR, CloudWatch Logs y Secrets Manager (NAT Gateway o VPC Endpoints) | MOA Networking | **Sí** | 🔴 Crítico |
| INF-06 | Provisionar **Amazon RDS for PostgreSQL (Single-AZ)** con las credenciales necesarias para Flyway y la API | MOA / Equipo DB | **Sí** | 🔴 Crítico |
| INF-07 | Provisionar KMS Key para cifrado de CloudWatch Log Groups | MOA Seguridad | No | 🟡 Medio |
| INF-08 | Provisionar bucket S3 con policy ELB para ALB access logs | MOA Infraestructura | No | 🟡 Medio |
| INF-09 | Confirmar bucket y DynamoDB de estado y actualizar `backend.qa.s3.hcl` y `backend.prd.s3.hcl` | MOA Infraestructura | **Sí** | 🔴 Crítico |
| INF-10 | En ambiente PRD: configurar `alb_deletion_protection = true` en el tfvars antes del primer apply | MOA Infraestructura | No | 🟠 Alto |

---

## DevOps

| ID | Actividad | Responsable | Bloqueante | Prioridad |
|---|---|---|---|---|
| DEV-01 | Crear Variable Group `portal-creditos-iac-qa` en Azure DevOps con todas las variables requeridas | MOA DevOps | **Sí** | 🔴 Crítico |
| DEV-02 | Crear Variable Group `portal-creditos-iac-prod` en Azure DevOps con todas las variables requeridas | MOA DevOps | **Sí** | 🔴 Crítico |
| DEV-03 | Configurar approval gates en los Azure DevOps Environments `portal-creditos-iac-qa` y `portal-creditos-iac-prod` para que el `apply` requiera aprobación explícita | MOA DevOps | No | 🟠 Alto |
| DEV-04 | Crear y confirmar la AWS Service Connection OIDC/role federation requerida por el parámetro `awsServiceConnection` del pipeline | MOA DevOps / Seguridad | **Sí** | 🔴 Crítico |
| DEV-05 | Completar los archivos `env/qa.tfvars` y `env/prd.tfvars` del backend con los valores reales de VPC, subnets y secret ARNs | MOA DevOps / Infraestructura | **Sí** | 🔴 Crítico |
| DEV-06 | Completar los archivos `terraform.tfvars` del frontend con los valores reales de VPC y subnets | MOA DevOps / Infraestructura | **Sí** | 🔴 Crítico |
| DEV-07 | Completar los archivos `backend.qa.s3.hcl` y `backend.prd.s3.hcl` con los datos reales del bucket de estado | MOA DevOps / Infraestructura | **Sí** | 🔴 Crítico |
| DEV-08 | Configurar pipelines de aplicación (backend-release y frontend-release) en Azure DevOps para push de imágenes a ECR y actualización del servicio ECS | MOA DevOps | No | 🟠 Alto |
| DEV-09 | Crear Pipeline de Flyway one-off en Azure DevOps para ejecutar migraciones de base de datos | MOA DevOps | No | 🟠 Alto |

---

## Seguridad

| ID | Actividad | Responsable | Bloqueante | Prioridad |
|---|---|---|---|---|
| SEG-01 | Crear secreto en AWS Secrets Manager: `ConnectionStrings__PostgresConnection` y proveer el ARN al equipo | MOA Seguridad / Equipo DB | **Sí** | 🔴 Crítico |
| SEG-02 | Crear secreto en AWS Secrets Manager: `ApiSecurity__Jwt__SigningKey` y proveer el ARN al equipo | MOA Seguridad | **Sí** | 🔴 Crítico |
| SEG-03 | Crear secretos Flyway (`FLYWAY_URL`, `FLYWAY_USER`, `FLYWAY_PASSWORD`) en AWS Secrets Manager y proveer los ARNs | MOA Seguridad / Equipo DB | **Sí** | 🔴 Crítico |
| SEG-04 | Crear secreto JSON de SAP (`SAP_BASE_URL`, `SAP_USERNAME`, `SAP_PASSWORD`) y proveer el ARN | MOA Seguridad / Integración SAP | No (si SAP habilitado: Sí) | 🟠 Alto |
| SEG-05 | Crear secreto JSON del Motor de Decisiones (`API_KEY`, etc.) y proveer el ARN | MOA Seguridad / Motor Decisiones | No (si motor habilitado: Sí) | 🟠 Alto |
| SEG-06 | Provisionar y configurar ACM Certificate para HTTPS si se requiere | MOA Seguridad | No (activable post-deploy) | 🟡 Medio |
| SEG-07 | Confirmar y documentar por escrito la excepción al estándar MOA para nombres ALB/TG (límite 32 chars AWS). Ver `docs/05-Exceptions.md`. | MOA Infraestructura | No | 🟡 Medio |
| SEG-08 | Revisar y aprobar formalmente las políticas IAM generadas por Terraform para los roles `EXECUTION` y `TASK` | MOA Seguridad | No | 🟡 Medio |
| SEG-09 | Verificar que las IAM credentials AWS usadas en el pipeline tengan solo los permisos necesarios para crear/modificar los recursos del stack | MOA Seguridad | No | 🟡 Medio |

---

## Networking

| ID | Actividad | Responsable | Bloqueante | Prioridad |
|---|---|---|---|---|
| NET-01 | Verificar routing y security groups para conectividad ECS Tasks → **Amazon RDS for PostgreSQL (Single-AZ)** | MOA Networking | **Sí** | 🔴 Crítico |
| NET-02 | Confirmar rangos CIDR de VPN/red corporativa para la variable `alb_ingress_cidr_blocks` | MOA Networking | **Sí** | 🔴 Crítico |
| NET-03 | Verificar que las subnets del frontend tengan conectividad desde la VPN corporativa hacia el ALB interno | MOA Networking | No | 🟠 Alto |
| NET-04 | Confirmar si se requiere configurar Route53 o DNS interno para los endpoints del ALB | MOA Networking | No | 🟡 Medio |

---

## Gobernanza

| ID | Actividad | Responsable | Bloqueante | Prioridad |
|---|---|---|---|---|
| GOB-01 | Confirmar y proveer el valor real del `tag_costcenter` para todos los recursos | MOA Finanzas | **Sí** | 🔴 Crítico |
| GOB-02 | Revisar y confirmar todos los valores de tags corporativos: `Area`, `Requester`, `Risk`, `BackupPolicy`, `Autopoweron`, `Autopoweroff` | MOA Gobernanza | **Sí** | 🔴 Crítico |
| GOB-03 | Confirmar la región AWS definitiva para el despliegue | MOA Infraestructura | **Sí** | 🔴 Crítico |

---

## Resumen por ambiente

### QA (primer despliegue)

Actividades **bloqueantes** a completar antes del primer `terraform apply` en QA:

- [ ] INF-01, INF-02, INF-05, INF-06, INF-09
- [ ] DEV-01, DEV-05, DEV-06, DEV-07
- [ ] SEG-01, SEG-02, SEG-03
- [ ] NET-01, NET-02
- [ ] GOB-01, GOB-02, GOB-03

### PRD (post-validación QA)

Actividades adicionales antes del despliegue en PRD:

- [ ] INF-10 (`alb_deletion_protection = true`)
- [ ] DEV-02, DEV-03
- [ ] SEG-07, SEG-08, SEG-09
- [ ] INF-07, INF-08 (KMS + access logs — recomendado para PRD)

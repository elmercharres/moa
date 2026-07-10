# Backend API — Terraform Stack

## 1. Objetivo de la solución

Provisiona la infraestructura AWS mínima para publicar la API REST de Portal Creditos en AWS ECS Fargate. El stack gestiona el ciclo de vida de la infraestructura base; los releases de aplicación (imagen Docker) los realizan los pipelines de CI/CD del backend.

---

## 2. Arquitectura desplegada

```
Internet / VPN
      │
      ▼
[ALB — ALB-portal-creditos-QA]
      │  HTTP → HTTPS redirect (si hay cert ACM)
      │  HTTPS → forward
      ▼
[Target Group — ALB-TG-portal-creditos-QA]
      │
      ▼
[ECS Service — ECS-SVC-Portal-Creditos-API-QA]
   │   (Tasks Fargate en subnets privadas)
   ↓
[ECS Task Definition — ECS-TASK-DEF-Portal-Creditos-API-QA]
   └── Container: api → puerto 8080
   └── Secretos desde AWS Secrets Manager (inyectados por ECS)

[ECS Task Definition — ECS-TASK-DEF-Portal-Creditos-API-QA-DB]  ← one-off
   └── Container: flyway migrate

[CloudWatch Logs] /ecs/Portal-Creditos-QA/api
                  /ecs/Portal-Creditos-QA/db-migrations
[ECR] ecs-repo-portal-creditos-api-qa
      ecs-repo-portal-creditos-db-qa
[Auto Scaling] AAS-Portal-Creditos-API-QA-CPU
```

Módulos Terraform:

| Módulo | Recursos |
|---|---|
| `modules/ecr` | 2 repositorios ECR + lifecycle policies |
| `modules/monitoring` | 2 CloudWatch Log Groups |
| `modules/iam` | 2 IAM Roles + políticas inline |
| `modules/networking` | 2 Security Groups + ALB + TG + Listeners |
| `modules/ecs` | ECS Cluster + 2 Task Definitions + Service + Autoscaling |

---

## 3. Prerrequisitos

Antes de ejecutar `terraform apply` deben existir los siguientes recursos en la cuenta AWS de MOA:

| Recurso | Variable |
|---|---|
| VPC | `vpc_id` |
| Subnets públicas (ALB) | `public_subnet_ids` |
| Subnets privadas (ECS tasks) | `private_subnet_ids` |
| Secret: ConnectionStrings__PostgresConnection | `postgres_connection_string_secret_arn` |
| Secret: ApiSecurity__Jwt__SigningKey | `jwt_signing_key_secret_arn` |
| Secret: FLYWAY_URL | `flyway_url_secret_arn` |
| Secret: FLYWAY_USER | `flyway_user_secret_arn` |
| Secret: FLYWAY_PASSWORD | `flyway_password_secret_arn` |
| Base PostgreSQL (RDS) | (no gestionada por este stack) |
| Certificado ACM (HTTPS) | `certificate_arn` (opcional) |
| Bucket S3 de estado Terraform | `backend.s3.hcl` |
| DynamoDB table para state lock | `backend.s3.hcl` |

Las subnets privadas necesitan salida a ECR, CloudWatch Logs y Secrets Manager mediante NAT Gateway o VPC endpoints.

---

## 4. Servicios AWS utilizados

- Amazon ECR (Elastic Container Registry)
- Amazon ECS Fargate (Elastic Container Service)
- Elastic Load Balancing (ALB)
- AWS IAM
- Amazon CloudWatch Logs
- AWS Application Auto Scaling
- AWS Secrets Manager / SSM Parameter Store (consumidos, no creados aquí)

---

## 5. Recursos públicos y privados

| Recurso | Exposición |
|---|---|
| ALB | Configurable: `load_balancer_internal = true` → privado (recomendado); `false` → público |
| ECS Tasks | Siempre en subnets privadas (`private_subnet_ids`). `assign_public_ip = false` por defecto |
| ECR | Privado; acceso vía IAM |
| CloudWatch Logs | Acceso privado vía IAM |

El tráfico externo llega al ALB. Los tasks ECS nunca tienen IP pública en configuración estándar.

---

## 6. Seguridad aplicada

- **Secretos**: ningún valor sensible en texto plano. Las credenciales viajan como ARN de AWS Secrets Manager o SSM Parameter Store; ECS los inyecta como variables de entorno en tiempo de ejecución.
- **Cifrado ECR**: `encryption_type = "AES256"` en todos los repositorios.
- **Scanning ECR**: `scan_on_push = true` en todos los repositorios.
- **TLS**: Listener HTTPS con `ELBSecurityPolicy-TLS13-1-2-2021-06` cuando se provee `certificate_arn`.
- **IAM mínimo privilegio**: execution role tiene únicamente `AmazonECSTaskExecutionRolePolicy` + acceso a los secrets ARN específicos. El task role no tiene permisos por defecto.
- **Security Groups**: el SG del servicio sólo acepta tráfico del SG del ALB en el puerto del contenedor.
- **Variables sensibles**: todas las variables de ARN de secretos declaran `sensitive = true`.

---

## 7. Variables de entrada

Ver [variables.tf](variables.tf) para la lista completa con tipos, descripciones y validaciones.

Variables obligatorias (sin default):

| Variable | Descripción |
|---|---|
| `vpc_id` | ID de la VPC existente |
| `public_subnet_ids` | Subnets para el ALB |
| `private_subnet_ids` | Subnets para los tasks ECS |
| `postgres_connection_string_secret_arn` | ARN del secret de conexión a PostgreSQL |
| `jwt_signing_key_secret_arn` | ARN del secret de la clave JWT |
| `flyway_url_secret_arn` | ARN del secret FLYWAY_URL |
| `flyway_user_secret_arn` | ARN del secret FLYWAY_USER |
| `flyway_password_secret_arn` | ARN del secret FLYWAY_PASSWORD |

Tags obligatorios MOA (todos tienen default; confirmar valores con MOA):
`tag_project`, `tag_application`, `tag_area`, `tag_risk`, `tag_requester`, `tag_backup_policy`, `tag_environment`, `tag_autopoweron`, `tag_autopoweroff`, `tag_costcenter`

---

## 8. Outputs generados

| Output | Descripción |
|---|---|
| `alb_dns_name` | DNS name del ALB |
| `api_url` | URL completa de la API |
| `ecr_repository_url` | URL del repositorio ECR de la API |
| `db_migrations_ecr_repository_url` | URL del repositorio ECR de migraciones |
| `ecs_cluster_name` | Nombre del cluster ECS |
| `ecs_service_name` | Nombre del servicio ECS |
| `task_definition_family` | Family de la task definition de la API |
| `db_migrations_task_definition_arn` | ARN de la task definition de Flyway |
| `db_migrations_task_definition_family` | Family de la task definition de Flyway |
| `service_security_group_id` | ID del Security Group de los tasks |
| `private_subnet_ids` | Subnets privadas de los tasks |

---

## 9. Dependencias

- **Base PostgreSQL**: creada y gestionada fuera de este stack. El endpoint se referencia vía secret ARN.
- **Secrets Manager / SSM**: los secrets deben existir antes de ejecutar `terraform apply`. Este stack sólo referencia sus ARNs.
- **VPC / Subnets**: red provista por MOA o el equipo de infraestructura.
- **Certificado ACM**: opcional; si se provee debe estar validado en la misma región.
- **Bucket S3 + DynamoDB**: el backend remoto de estado debe existir antes del primer `terraform init`.

---

## 10. Procedimiento de despliegue

### Primer despliegue

```powershell
# 1. Copiar y completar los archivos de configuración
Copy-Item terraform.tfvars.example terraform.tfvars   # o env/qa.tfvars
Copy-Item backend.s3.hcl.example backend.s3.hcl

# 2. Inicializar con backend remoto
terraform init -backend-config=backend.s3.hcl

# 3. Crear primero los repositorios ECR para poder subir imágenes
terraform apply `
  -target=module.ecr `
  -var-file=terraform.tfvars

# 4. Obtener URLs de ECR para el pipeline
terraform output -raw ecr_repository_url
terraform output -raw db_migrations_ecr_repository_url

# 5. Aplicar la infraestructura completa
terraform apply -var-file=terraform.tfvars
```

### Despliegues siguientes

El pipeline `azure-pipelines-iac.yml` ejecuta automáticamente plan y apply cuando se aprueba el cambio.

### Orden de operaciones (post-infraestructura)

1. `terraform apply` → crea ECR, ECS cluster, ALB, IAM, CloudWatch.
2. Pipeline backend → construye imagen, push a ECR.
3. Pipeline backend → registra nueva task definition revision, actualiza servicio ECS.
4. Pipeline backend → ejecuta one-off task de Flyway (`db_migrations_task_definition_arn`).
5. Pipeline backend → verifica `/health/ready`.

Terraform mantiene la infraestructura base. El servicio ECS ignora cambios externos de `task_definition` (`lifecycle { ignore_changes = [task_definition] }`).

---

## 11. Consideraciones operativas y de mantenimiento

- **Actualización de imágenes**: NO ejecutar `terraform apply` para actualizar la imagen del contenedor. El pipeline de backend lo hace directamente con `aws ecs register-task-definition` + `aws ecs update-service`.
- **Migración de nombres**: si se aplica este stack sobre recursos existentes con nombres diferentes, Terraform planificará `destroy + create`. Ejecutar `terraform plan` y revisar el impacto antes de aplicar.
- **State locking**: el DynamoDB table previene ejecuciones concurrentes.
- **Rotación de secretos**: al rotar un secret en Secrets Manager, actualizar el ARN en el tfvars si cambió, luego re-deploy.
- **Escalado manual temporal**: modificar `desired_count` en el tfvars y ejecutar `terraform apply`.
- **ECS Exec**: habilitar `enable_execute_command = true` sólo cuando se necesita diagnóstico activo; desactivar en producción.

# Frontend Web — Terraform Stack

## 1. Objetivo de la solución

Provisiona la infraestructura AWS para el frontend Angular de Portal Creditos como contenedor Nginx en ECS Fargate. El ALB es interno por defecto, accesible desde la red privada o VPN. Los releases de imagen los realizan los pipelines de CI/CD del frontend.

---

## 2. Arquitectura desplegada

```
VPN / red interna
      │
      ▼
[ALB interno — ALB-portal-creditos-web-QA]
      │
      ▼
[Target Group — ALB-TG-portal-creditos-web-QA]
      │
      ▼
[ECS Service — ECS-SVC-Portal-Creditos-WEB-QA]
   │   (Tasks Fargate en subnets privadas)
   ↓
[ECS Task Definition — ECS-TASK-DEF-Portal-Creditos-WEB-QA]
   └── Container: web → puerto 8080 (Nginx)

[CloudWatch Logs] /ecs/Portal-Creditos-QA/web
[ECR]             ecs-repo-portal-creditos-web-qa
[Auto Scaling]    AAS-Portal-Creditos-WEB-QA-CPU
```

Módulos Terraform:

| Módulo | Recursos |
|---|---|
| `modules/ecr` | 1 repositorio ECR + lifecycle policy |
| `modules/monitoring` | 1 CloudWatch Log Group |
| `modules/iam` | 2 IAM Roles + políticas inline |
| `modules/networking` | 2 Security Groups + ALB + TG + Listeners |
| `modules/ecs` | ECS Cluster + Task Definition + Service + Autoscaling |

---

## 3. Prerrequisitos

| Recurso | Variable |
|---|---|
| VPC | `vpc_id` |
| Subnets para ALB (privadas si internal) | `load_balancer_subnet_ids` |
| Subnets privadas (ECS tasks) | `private_subnet_ids` |
| Bucket S3 + DynamoDB para estado | `backend.hcl` |
| Certificado ACM (si HTTPS) | `certificate_arn` (opcional) |

---

## 4. Servicios AWS utilizados

- Amazon ECR, ECS Fargate, ALB, IAM, CloudWatch Logs, Application Auto Scaling

---

## 5. Recursos públicos y privados

| Recurso | Exposición |
|---|---|
| ALB | Interno por defecto (`load_balancer_internal = true`). Configurable a público. |
| ECS Tasks | Siempre en subnets privadas. |
| ECR | Privado, acceso vía IAM. |

---

## 6. Seguridad aplicada

- **Sin secretos en el contenedor**: Nginx no requiere Secrets Manager. No hay variables sensibles.
- **Cifrado y scanning ECR**: `encryption_type = "AES256"`, `scan_on_push = true`.
- **TLS**: Listener HTTPS con `ELBSecurityPolicy-TLS13-1-2-2021-06` si se provee `certificate_arn`.
- **IAM mínimo privilegio**: execution role sólo con `AmazonECSTaskExecutionRolePolicy`.
- **Security Groups**: el SG del servicio sólo acepta tráfico del SG del ALB.

---

## 7. Variables de entrada

Ver [variables.tf](variables.tf) para la lista completa.

Variables obligatorias (sin default): `vpc_id`, `load_balancer_subnet_ids`, `private_subnet_ids`

Tags MOA obligatorios: `tag_project`, `tag_application`, `tag_area`, `tag_risk`, `tag_requester`, `tag_backup_policy`, `tag_environment`, `tag_autopoweron`, `tag_autopoweroff`, `tag_costcenter`

---

## 8. Outputs generados

| Output | Descripción |
|---|---|
| `alb_dns_name` | DNS name del ALB |
| `frontend_url` | URL completa del frontend |
| `ecr_repository_url` | URL del repositorio ECR |
| `ecs_cluster_name` | Nombre del cluster ECS |
| `ecs_service_name` | Nombre del servicio ECS |
| `task_definition_family` | Family de la task definition |
| `service_security_group_id` | ID del Security Group de los tasks |
| `private_subnet_ids` | Subnets privadas de los tasks |

---

## 9. Dependencias

- VPC, subnets y certificado ACM: provistas por MOA.
- Bucket S3 + DynamoDB de estado Terraform.

---

## 10. Procedimiento de despliegue

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item backend.qa.hcl.example backend.qa.hcl  # o backend.prd.hcl.example para PRD

terraform init -backend-config=backend.qa.hcl

# Crear primero el repositorio ECR para poder subir la imagen
terraform apply -target=module.ecr -var-file=terraform.tfvars
terraform output -raw ecr_repository_url

# Infraestructura completa
terraform apply -var-file=terraform.tfvars
```

Los releases de imagen no ejecutan Terraform. El pipeline de frontend realiza:
`npm ci → npm run build → docker build/push → aws ecs register-task-definition → aws ecs update-service`

---

## 11. Consideraciones operativas

- El servicio ECS ignora cambios de `task_definition` para permitir releases sin Terraform.
- El ALB es interno por defecto; usar VPN o red privada para acceder desde navegadores.
- `enable_execute_command = true` solo para diagnóstico activo; desactivar en producción.

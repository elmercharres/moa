# 02 — Deployment Inputs
## Tabla Completa de Valores Requeridos antes del Primer Despliegue

> **Política**: Ningún valor en esta tabla debe ser estimado o inventado.
> Los valores desconocidos están marcados como **PENDIENTE DE SER PROVISTO POR MOA**.
> No se utilizan valores ficticios, placeholders ni ejemplos.

---

## Sección A — Infraestructura AWS

### A.1 Cuenta y Región

| Variable Terraform | Descripción | Stack | Responsable | Obligatorio | Estado | Observaciones |
|---|---|---|---|---|---|---|
| `aws_region` | Región AWS donde se despliega toda la infraestructura | Backend + Frontend | MOA Infraestructura | Sí | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Default configurado: `us-east-1`. Confirmar con MOA. |
| N/A (pipeline) | Account ID AWS — ambiente QA | Backend + Frontend | MOA Infraestructura | Sí | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Necesario para construir ARNs y validar permisos. |
| N/A (pipeline) | Account ID AWS — ambiente PRD | Backend + Frontend | MOA Infraestructura | Sí | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Necesario para construir ARNs y validar permisos. |

### A.2 Networking (VPC y Subnets)

| Variable Terraform | Descripción | Stack | Responsable | Obligatorio | Estado | Observaciones |
|---|---|---|---|---|---|---|
| `vpc_id` | ID de la VPC donde se despliega el servicio backend | Backend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | La VPC debe existir antes del despliegue. Las subnets privadas deben tener salida a internet vía NAT o VPC endpoints para ECR, CloudWatch y Secrets Manager. |
| `public_subnet_ids` | IDs de subnets para el ALB del backend (pueden ser privadas si ALB es interno) | Backend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Si `load_balancer_internal = true`, usar subnets privadas o internas. Mínimo 2 subnets en distintas AZs. |
| `private_subnet_ids` | IDs de subnets privadas para ECS Tasks backend | Backend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Deben tener ruta de salida (NAT GW o VPC endpoints) a ECR, CloudWatch Logs y Secrets Manager. |
| `vpc_id` | ID de la VPC donde se despliega el servicio frontend | Frontend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Puede ser la misma VPC del backend. |
| `load_balancer_subnet_ids` | IDs de subnets para el ALB del frontend (interno) | Frontend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | ALB frontend es interno por defecto. Usar subnets alcanzables desde VPN o red corporativa. |
| `private_subnet_ids` | IDs de subnets privadas para ECS Tasks frontend | Frontend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Mismas consideraciones que backend. |
| `alb_ingress_cidr_blocks` | Rangos CIDR permitidos al ALB | Backend + Frontend | MOA Networking | Sí | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Default: `["10.0.0.0/8"]`. Confirmar rangos de VPN y red corporativa con MOA Networking y Seguridad. |
| `load_balancer_internal` | Si el ALB es interno (`true`) o externo (`false`) | Backend | MOA Arquitectura | Sí | ✅ Default: `true` | Backend: `true` por defecto para acceso solo desde VPN. Cambiar a `false` solo con aprobación explícita de MOA Seguridad. |

### A.3 Certificados y HTTPS

| Variable Terraform | Descripción | Stack | Responsable | Obligatorio | Estado | Observaciones |
|---|---|---|---|---|---|---|
| `certificate_arn` | ARN del certificado ACM para HTTPS | Backend + Frontend | MOA Seguridad | No | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Sin valor: ALB expone solo HTTP. Con valor: expone HTTPS y redirige HTTP→HTTPS automáticamente. Certificado debe estar en la misma región. |

---

## Sección B — Estado Terraform

| Parámetro | Descripción | Stack | Responsable | Obligatorio | Estado | Observaciones |
|---|---|---|---|---|---|---|
| Bucket S3 nombre | Nombre del bucket S3 corporativo para estado Terraform | Backend + Frontend | MOA Infraestructura | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Configurado en archivos `backend.qa.s3.hcl` y `backend.prd.s3.hcl`. El bucket debe existir antes del `terraform init`. Patrón referencial: `moaplatformiac-apps-prd-tfstate`. |
| Key backend QA | Path del estado en S3 — Backend QA | Backend | MOA Infraestructura | **Sí** | ✅ Preconfigurado | `portal-creditos-api/backend-qa.tfstate` — confirmar con MOA. |
| Key backend PRD | Path del estado en S3 — Backend PRD | Backend | MOA Infraestructura | **Sí** | ✅ Preconfigurado | `portal-creditos-api/backend-prd.tfstate` — confirmar con MOA. |
| Key frontend QA | Path del estado en S3 — Frontend QA | Frontend | MOA Infraestructura | **Sí** | ✅ Preconfigurado | `portal-creditos-web/frontend-qa.tfstate` — confirmar con MOA. |
| Key frontend PRD | Path del estado en S3 — Frontend PRD | Frontend | MOA Infraestructura | **Sí** | ✅ Preconfigurado | `portal-creditos-web/frontend-prd.tfstate` — confirmar con MOA. |
| DynamoDB table | Tabla DynamoDB para state locking | Backend + Frontend | MOA Infraestructura | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Patrón referencial: `moaplatformiac-terraform-locks`. Debe existir antes del `terraform init`. |
| Región S3 | Región del bucket de estado | Backend + Frontend | MOA Infraestructura | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Confirmar; referenciado como `us-east-1` en los ejemplos. |

---

## Sección C — Credenciales y Acceso AWS

| Parámetro | Descripción | Stack | Responsable | Obligatorio | Estado | Observaciones |
|---|---|---|---|---|---|---|
| Azure DevOps Variable Group QA | Nombre del grupo de variables Azure DevOps para QA | Backend + Frontend | MOA DevOps | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Nombre esperado: `portal-creditos-iac-qa`. Debe contener las variables AWS y ARNs de secretos. |
| Azure DevOps Variable Group PRD | Nombre del grupo de variables Azure DevOps para PRD | Backend + Frontend | MOA DevOps | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Nombre esperado: `portal-creditos-iac-prod`. |
| `awsServiceConnection` | Nombre de la AWS Service Connection OIDC/role federation para el pipeline | Backend + Frontend | MOA DevOps / Seguridad | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Se informa al ejecutar `azure-pipelines-iac.yml`; reemplaza credenciales AWS de larga duración. |

---

## Sección D — Secretos Backend (Secrets Manager)

> Los secretos deben existir en AWS Secrets Manager **antes** del primer `terraform apply` del backend.
> Terraform solo referencia los ARNs — **no crea** los secretos.

---

### Contrato de acceso a base de datos

La aplicación .NET **NO** obtiene credenciales directamente desde AWS Secrets Manager. El flujo correcto es el siguiente:

```
MOA
 ↓
 Provisiona Amazon RDS for PostgreSQL (Single-AZ)
 ↓
 Crea un Secret en AWS Secrets Manager con la cadena de conexión completa
 ↓
 Terraform recibe únicamente el ARN del Secret como variable de entrada
   (variable: postgres_connection_string_secret_arn)
 ↓
 Amazon ECS inyecta el Secret como variable de entorno en el contenedor
   (variable de entorno: ConnectionStrings__PostgresConnection)
 ↓
 La aplicación .NET lee la configuración mediante:
   Configuration.GetConnectionString("PostgresConnection")
```

> **Terraform no almacena credenciales.** Terraform únicamente referencia el Secret mediante
> la variable `postgres_connection_string_secret_arn`. Las credenciales de base de datos
> nunca aparecen en el código Terraform ni en el estado remoto.

---

| Variable Terraform | Descripción | Responsable | Obligatorio | Estado | Formato del secreto |
|---|---|---|---|---|---|
| `postgres_connection_string_secret_arn` | ARN del Secret de AWS Secrets Manager que contiene la cadena de conexión completa para **Amazon RDS for PostgreSQL (Single-AZ)**. Este Secret es creado y administrado por MOA y será inyectado por Amazon ECS como la variable de entorno `ConnectionStrings__PostgresConnection`. | MOA / Equipo DB | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Formato del valor (solo ejemplo): `Host=<DB_ENDPOINT>;Port=5432;Database=<DATABASE>;Username=<USER>;Password=<PASSWORD>` |
| `jwt_signing_key_secret_arn` | ARN del secret con la clave de firma JWT (mínimo 32 bytes) | MOA Seguridad | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | String: clave aleatoria de alta entropía |
| `flyway_url_secret_arn` | ARN del secret con FLYWAY_URL para migraciones | MOA / Equipo DB | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | String: `jdbc:postgresql://<host>:5432/<database>` |
| `flyway_user_secret_arn` | ARN del secret con FLYWAY_USER (usuario DB) | MOA / Equipo DB | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | String: nombre de usuario de base de datos |
| `flyway_password_secret_arn` | ARN del secret con FLYWAY_PASSWORD (contraseña DB) | MOA / Equipo DB | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | String: contraseña de base de datos |
| `additional_secrets["Sap__BaseUrl"]` | ARN del secret JSON SAP — clave `SAP_BASE_URL` | MOA / Integración SAP | No (si SAP habilitado: Sí) | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | JSON secret compartido con otras claves SAP. Usar sufijo `:SAP_BASE_URL::` |
| `additional_secrets["Sap__Username"]` | ARN del secret JSON SAP — clave `SAP_USERNAME` | MOA / Integración SAP | No (si SAP habilitado: Sí) | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Mismo secret JSON SAP. Usar sufijo `:SAP_USERNAME::` |
| `additional_secrets["Sap__Password"]` | ARN del secret JSON SAP — clave `SAP_PASSWORD` | MOA / Integración SAP | No (si SAP habilitado: Sí) | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Mismo secret JSON SAP. Usar sufijo `:SAP_PASSWORD::` |
| `additional_secrets["MotorDecisiones__CallbackApiKey"]` | ARN del secret con API key del motor de decisiones | MOA / Motor Decisiones | No (si motor habilitado: Sí) | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | JSON secret compartido. Usar sufijo `:API_KEY::` |

---

## Sección E — Tags Corporativos MOA

> Todos los recursos AWS creados por este Terraform recibirán estos tags.
> Los valores deben ser confirmados por el equipo de MOA **antes del despliegue**.

| Variable Terraform | Tag AWS | Descripción | Default actual | Responsable | Estado | Observaciones |
|---|---|---|---|---|---|---|
| `tag_project` | `Project` | Nombre del proyecto sin espacios | `Portal-Creditos` | MOA Gobernanza | ⚠️ Confirmar con MOA | No debe contener espacios. |
| `tag_application` | `Application` | Sistema o aplicación | `Portal-Creditos` | MOA Gobernanza | ⚠️ Confirmar con MOA | |
| `tag_area` | `Area` | Área de negocio | `Demanda` | MOA Gobernanza | ⚠️ Confirmar con MOA | |
| `tag_requester` | `Requester` | Solicitante del recurso | `Fernando Ponce De Leon` | MOA / Solicitante | ⚠️ Confirmar con MOA | Debe ser el nombre del responsable real del proyecto. |
| `tag_risk` | `Risk` | Nivel de riesgo | `medium` | MOA Seguridad | ⚠️ Confirmar con MOA | Valores: `high`, `medium`, `low`. |
| `tag_backup_policy` | `BackupPolicy` | Política de backup | `NoBackup` | MOA Infraestructura | ⚠️ Confirmar con MOA | Valores: `NoBackup`, `DiarioR7`. ECS Fargate no requiere backup, pero debe confirmarse la política corporativa. |
| `tag_environment` | `Environment` | Ambiente de despliegue | `QA` / `PRD` | Automático (pipeline) | ✅ Configurado | Se establece automáticamente según el ambiente del pipeline. |
| `tag_autopoweron` | `Autopoweron` | Auto encendido programado | `false` | MOA Infraestructura | ⚠️ Confirmar con MOA | Valores: `true`, `false`. ECS Fargate no tiene estado de encendido/apagado de instancia, pero el tag es obligatorio por política MOA. |
| `tag_autopoweroff` | `Autopoweroff` | Auto apagado programado | `false` | MOA Infraestructura | ⚠️ Confirmar con MOA | Misma observación que `Autopoweron`. |
| `tag_costcenter` | `Costcenter` | Centro de costos | **SIN DEFAULT** | MOA Finanzas | ⚠️ **PENDIENTE DE SER PROVISTO POR MOA** | **Valor obligatorio sin default.** Debe ser provisto explícitamente en el `terraform.tfvars` de cada ambiente. No usar `000000`. |

---

## Sección F — Observabilidad y Seguridad (opcionales pero recomendados)

| Variable Terraform | Descripción | Stack | Responsable | Obligatorio | Estado | Observaciones |
|---|---|---|---|---|---|---|
| `log_kms_key_arn` | ARN de la clave KMS para cifrado de CloudWatch Log Groups | Backend + Frontend | MOA Seguridad | No | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Sin valor: logs cifrados con clave AWS-managed. Con valor: logs cifrados con clave controlada por MOA. La key debe permitir `logs.amazonaws.com` usar `kms:GenerateDataKey` y `kms:Decrypt`. |
| `alb_access_logs_bucket` | Nombre del bucket S3 para access logs del ALB | Backend + Frontend | MOA Infraestructura | No | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Sin valor: access logs deshabilitados. El bucket debe tener la bucket policy requerida por el servicio ELB de AWS antes de activarse. |
| `alb_deletion_protection` | Protección contra eliminación del ALB | Backend + Frontend | MOA Infraestructura | No | ✅ Default: `false` (QA) | **Establecer `true` en PRD** antes del primer apply productivo. Valor en `terraform.tfvars` de PRD. |
| `certificate_arn` | ARN del certificado ACM para HTTPS | Backend + Frontend | MOA Seguridad | No | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Ver Sección A.3. |

---

## Sección G — Pipeline Azure DevOps

| Variable Pipeline | Descripción | Responsable | Obligatorio | Estado | Observaciones |
|---|---|---|---|---|---|
| `awsRegion` | Región AWS en el pipeline | MOA DevOps | **Sí** | ⚠️ PENDIENTE CONFIRMACIÓN | Actualmente `us-east-1`. Confirmar con MOA. |
| `clientCostcenter` | Valor del tag Costcenter en el pipeline | MOA Finanzas | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Actualmente con valor placeholder. **Debe ser reemplazado** con el valor real antes de cualquier `apply`. |
| `backendTfVarVpcId` | VPC ID para backend (si no hay archivo tfvars) | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Se usa cuando no existe `env/qa.tfvars`. |
| `backendTfVarPublicSubnetIds` | Subnets ALB backend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Formato JSON array: `["subnet-xxx","subnet-yyy"]` |
| `backendTfVarPrivateSubnetIds` | Subnets ECS tasks backend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Formato JSON array. |
| `backendTfVarPostgresConnectionStringSecretArn` | ARN secret PostgreSQL | MOA Seguridad | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Solo si no existe archivo `env/qa.tfvars`. |
| `frontendTfVarVpcId` | VPC ID para frontend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | |
| `frontendTfVarLoadBalancerSubnetIds` | Subnets ALB frontend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Formato JSON array. |
| `frontendTfVarPrivateSubnetIds` | Subnets ECS tasks frontend | MOA Networking | **Sí** | ⚠️ PENDIENTE DE SER PROVISTO POR MOA | Formato JSON array. |

---

## Resumen de pendientes críticos

| # | Valor | Bloqueante para deploy | Responsable |
|---|---|---|---|
| 1 | VPC ID y Subnets (backend y frontend) | **Sí** | MOA Networking |
| 2 | Secrets Manager ARNs (5 secretos backend) | **Sí** | MOA Seguridad / Equipo DB |
| 3 | S3 Bucket + DynamoDB estado Terraform | **Sí** | MOA Infraestructura |
| 4 | Variable Groups Azure DevOps + credenciales AWS | **Sí** | MOA DevOps |
| 5 | `tag_costcenter` valor real | **Sí** | MOA Finanzas |
| 6 | Confirmación AWS Region | Sí | MOA Infraestructura |
| 7 | Confirmación tags corporativos (área, requester, risk) | Sí | MOA Gobernanza |
| 8 | ACM Certificate ARN (si HTTPS requerido) | No (HTTPS opcional) | MOA Seguridad |
| 9 | KMS Key ARN (logs cifrados con clave MOA) | No (activable post-deploy) | MOA Seguridad |
| 10 | S3 Bucket ALB Access Logs | No (activable post-deploy) | MOA Infraestructura |

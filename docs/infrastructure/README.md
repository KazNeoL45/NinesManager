# Infraestructura NinesManager

## Arquitectura de la Aplicación

La infraestructura de NinesManager está diseñada para ser altamente disponible, escalable y segura, utilizando servicios administrados de AWS.

## Componentes de Infraestructura

### 1. Red (VPC)
- **VPC**: Red privada virtual aislada (10.0.0.0/16)
- **Subredes Públicas**: 3 subredes en diferentes zonas de disponibilidad para ALB
- **Subredes Privadas**: 3 subredes en diferentes zonas de disponibilidad para aplicaciones y bases de datos
- **NAT Gateways**: 3 NAT Gateways (uno por AZ) para acceso a Internet desde subredes privadas
- **Internet Gateway**: Para acceso público al Application Load Balancer

### 2. Compute (EC2 Auto Scaling)
- **Auto Scaling Group**:
  - Mínimo: 2 instancias
  - Máximo: 10 instancias
  - Deseado: 2 instancias
- **Tipo de Instancia**: t3.medium
- **AMI**: Ubuntu 22.04 LTS
- **Escalado Automático**:
  - Scale Up: CPU > 70% durante 10 minutos
  - Scale Down: CPU < 30% durante 10 minutos

### 3. Load Balancer (ALB)
- **Application Load Balancer**: Distribuye tráfico entre instancias
- **Target Group**: Health checks en /health
- **Listeners**:
  - HTTP (80): Redirección a HTTPS
  - HTTPS (443): Tráfico de aplicación
- **SSL/TLS**: Certificado administrado por AWS Certificate Manager

### 4. Base de Datos (RDS PostgreSQL)
- **Motor**: PostgreSQL 15.4
- **Clase de Instancia**: db.t3.medium
- **Almacenamiento**: 100 GB GP3 con auto-escalado hasta 200 GB
- **Multi-AZ**: Habilitado para alta disponibilidad
- **Backups**:
  - Retención: 7 días
  - Ventana: 03:00-04:00 UTC
- **Cifrado**: Habilitado en reposo
- **Performance Insights**: Habilitado

### 5. Caché (ElastiCache Redis)
- **Motor**: Redis 7.0
- **Tipo de Nodo**: cache.t3.medium
- **Número de Nodos**: 2 (con replicación)
- **Multi-AZ**: Habilitado
- **Failover Automático**: Habilitado
- **Cifrado**: En tránsito y en reposo

### 6. Almacenamiento (S3 + CloudFront)
- **S3 Bucket**: Almacenamiento de archivos y assets
  - Versionado habilitado
  - Cifrado AES-256
  - Lifecycle policies:
    - Transición a IA después de 90 días
    - Transición a Glacier después de 180 días
- **CloudFront**: CDN para distribución de assets
  - Cache TTL: 1 hora (default)
  - Compresión habilitada
  - HTTPS obligatorio

### 7. Seguridad

#### Security Groups
- **ALB Security Group**:
  - Ingress: 80, 443 desde Internet
  - Egress: Todo el tráfico

- **Application Security Group**:
  - Ingress: 3000 desde ALB, 22 desde IPs permitidas
  - Egress: Todo el tráfico

- **Database Security Group**:
  - Ingress: 5432 desde Application SG
  - Egress: Todo el tráfico

- **Redis Security Group**:
  - Ingress: 6379 desde Application SG
  - Egress: Todo el tráfico

#### IAM Roles
- **EC2 Instance Role**:
  - S3 acceso completo al bucket de assets
  - SSM para administración
  - CloudWatch para logs y métricas

## Diagrama de Arquitectura

```
                                    Internet
                                       |
                                       |
                          +------------v-----------+
                          |   CloudFront (CDN)    |
                          +-----------+-----------+
                                      |
                          +-----------v-----------+
                          |   S3 Bucket (Assets)  |
                          +-----------------------+

                                    Internet
                                       |
                          +------------v-----------+
                          |   Internet Gateway    |
                          +-----------+-----------+
                                      |
    ┌─────────────────────────────────┼────────────────────────────────┐
    │                            VPC (10.0.0.0/16)                     │
    │                                 |                                 │
    │   ┌─────────────────────────────┼──────────────────────────┐    │
    │   │           Subnet Pública (3 AZs)                        │    │
    │   │                             |                            │    │
    │   │   ┌─────────────────────────v──────────────────────┐   │    │
    │   │   │  Application Load Balancer (ALB)              │   │    │
    │   │   │  - HTTP (80) → HTTPS redirect                 │   │    │
    │   │   │  - HTTPS (443) → Target Group                 │   │    │
    │   │   └─────────────────────┬──────────────────────────┘   │    │
    │   │                         |                               │    │
    │   │   ┌─────────────────────v──────────────────────┐       │    │
    │   │   │  NAT Gateway (3 instancias - una por AZ)   │       │    │
    │   │   └────────────────────────────────────────────┘       │    │
    │   └──────────────────────────────────────────────────────────┘   │
    │                                 |                                 │
    │   ┌─────────────────────────────┼──────────────────────────┐    │
    │   │           Subnet Privada (3 AZs)                        │    │
    │   │                             |                            │    │
    │   │   ┌─────────────────────────v──────────────────────┐   │    │
    │   │   │  Auto Scaling Group (EC2 Instances)           │   │    │
    │   │   │  - Min: 2, Max: 10, Desired: 2                │   │    │
    │   │   │  - Ruby 3.3.0 + Rails 7.1                     │   │    │
    │   │   │  - Nginx + Puma                               │   │    │
    │   │   └─────┬──────────────────┬───────────────────────┘   │    │
    │   │         |                  |                            │    │
    │   │   ┌─────v──────────┐  ┌───v──────────────────┐        │    │
    │   │   │ RDS PostgreSQL │  │ ElastiCache Redis    │        │    │
    │   │   │ - Multi-AZ     │  │ - Replication Group  │        │    │
    │   │   │ - db.t3.medium │  │ - cache.t3.medium x2 │        │    │
    │   │   └────────────────┘  └──────────────────────┘        │    │
    │   └──────────────────────────────────────────────────────────┘   │
    └──────────────────────────────────────────────────────────────────┘
```

## Flujo de Tráfico

1. Usuario accede a la aplicación vía HTTPS
2. CloudFront sirve assets estáticos desde S3
3. ALB recibe la petición y la distribuye a una instancia EC2 saludable
4. Nginx en EC2 recibe la petición y la pasa a Puma
5. Rails procesa la petición:
   - Consulta PostgreSQL para datos persistentes
   - Consulta Redis para caché y sesiones
   - Accede a S3 para archivos subidos
6. La respuesta regresa al usuario

## Dimensionamiento de Recursos

### Ambiente de Producción

| Recurso | Tipo | Cantidad | vCPUs | RAM | Almacenamiento |
|---------|------|----------|-------|-----|----------------|
| EC2 (App) | t3.medium | 2-10 | 2 | 4 GB | 30 GB |
| RDS (PostgreSQL) | db.t3.medium | 1 (Multi-AZ) | 2 | 4 GB | 100 GB |
| ElastiCache (Redis) | cache.t3.medium | 2 | 2 | 3.09 GB | - |
| ALB | - | 1 | - | - | - |
| NAT Gateway | - | 3 | - | - | - |

### Costos Estimados Mensuales (us-east-1)

- EC2 (2 x t3.medium): ~$60
- RDS (db.t3.medium Multi-AZ): ~$150
- ElastiCache (2 x cache.t3.medium): ~$100
- ALB: ~$25
- NAT Gateway (3): ~$100
- S3 + CloudFront: ~$20
- Data Transfer: ~$50
- **Total Estimado**: ~$505/mes

## Variables de Entorno Requeridas

```bash
RAILS_ENV=production
SECRET_KEY_BASE=<secret>
DATABASE_URL=postgresql://user:pass@host:5432/dbname
REDIS_URL=redis://host:6379/0
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_REGION=us-east-1
S3_BUCKET_NAME=ninesmanager-production-assets
```

## Alta Disponibilidad

- **Multi-AZ**: Todos los servicios están distribuidos en múltiples zonas de disponibilidad
- **Auto Scaling**: Reemplazo automático de instancias no saludables
- **RDS Failover**: Failover automático en 60-120 segundos
- **Redis Failover**: Failover automático con ElastiCache
- **Load Balancing**: Distribución de tráfico y health checks

## Monitoreo y Observabilidad

- **CloudWatch Metrics**: CPU, memoria, disco, red
- **CloudWatch Alarms**: Alertas de escalado y recursos
- **ALB Access Logs**: Logs de acceso en S3
- **Application Logs**: Logs de Rails y Puma
- **RDS Performance Insights**: Monitoreo de queries
- **Redis Slow Logs**: Logs de comandos lentos

## Respaldo y Recuperación

### RDS PostgreSQL
- Backups automáticos diarios
- Retención: 7 días
- Point-in-time recovery
- Snapshots manuales disponibles

### S3
- Versionado habilitado
- Lifecycle policies para optimización
- Replicación cross-region (opcional)

## Seguridad

- Cifrado en tránsito (TLS 1.2+)
- Cifrado en reposo (AES-256)
- Security Groups con principio de menor privilegio
- IAM Roles con permisos mínimos necesarios
- VPC privada con NAT para salida a Internet
- No acceso público directo a bases de datos
- Logs de auditoría habilitados

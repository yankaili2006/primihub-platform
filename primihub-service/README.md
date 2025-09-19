# Primihub Management Platform Service

Primihub Management Platform is a comprehensive Spring Cloud-based service platform for managing and orchestrating privacy-preserving machine learning workflows. It provides a centralized management interface for data resources, models, projects, and federated learning tasks.

## 🏗️ Architecture Overview

The platform is built on a microservices architecture with the following components:

- **Gateway Service**: API gateway handling routing, authentication, and request forwarding
- **Application Service**: Main business logic and REST API endpoints
- **Business Module**: Core business logic, data processing, and service implementations
- **Nacos**: Service discovery and configuration management
- **MySQL**: Primary database for application data
- **Redis**: Caching and session management
- **RabbitMQ**: Message queue for asynchronous task processing

## 📋 Prerequisites

Before running the project, ensure you have the following dependencies installed:

### Required Services
- **JDK 1.8+** (Java Development Kit)
- **Maven 3.6+** (Build tool)
- **Nacos 2.0.3+** (Service discovery & configuration)
- **MySQL 5.7+** (Database)
- **Redis 5.0+** (Cache)
- **RabbitMQ 3.8+** (Message broker)

### Optional Services
- **Docker** (For containerized deployment)
- **Docker Compose** (For multi-container management)

## ⚙️ Configuration Setup

### 1. Nacos Configuration

First, start Nacos server (default: http://localhost:8848/nacos) and create the following configuration files in your target namespace:

#### base.json
```json
{
  "tokenValidateUriBlackList": [
    "/user/login",
    "/common/getValidatePublicKey",
    "/shareData/syncProject"
  ],
  "defaultPassword": "123456",
  "defaultPasswordVector": "excalibur",
  "grpcClientAddress": "192.168.99.20",
  "grpcClientPort": 50050,
  // ... other configuration
}
```

#### database.yaml
```yaml
spring:
  datasource:
    druid:
      url: jdbc:mysql://localhost:3306/primihub?useUnicode=true&characterEncoding=utf-8&useSSL=false
      username: your_username
      password: your_password
      driver-class-name: com.mysql.cj.jdbc.Driver
```

#### redis.yaml
```yaml
spring:
  redis:
    host: localhost
    port: 6379
    password: your_redis_password
    database: 0
```

### 2. Local Configuration Files

Update the following configuration files:

#### Application Configuration
```bash
./application/src/main/resources/application.yaml
```

#### Gateway Configuration  
```bash
./gateway/src/main/resources/application.yaml
```

Key configuration items to update:
```yaml
server:
  port: 8090  # Application port
spring:
  profiles:
    active: dev  # Environment profile
  nacos:
    discovery:
      server-addr: localhost:8848  # Nacos server address
      namespace: your_namespace    # Nacos namespace
nacos:
  config:
    server-addr: localhost:8848    # Nacos config server
```

### 3. Database Setup

Execute the SQL scripts to initialize the database:

```sql
-- Run ddl.sql to create database schema
mysql -u username -p < ./script/ddl.sql

-- Run init.sql to populate initial data  
mysql -u username -p < ./script/init.sql
```

## 🛠️ Build and Package

### Linux Environment
```bash
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=linux-x86_64
```

### Windows Environment
```bash
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=windows-x86_64
```

### macOS Environment
```bash
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=osx-x86_64
```

## 🚀 Running the Application

### Option 1: Run with Java Commands

Start the application service:
```bash
java -jar -Dfile.encoding=UTF-8 ./application/target/*-SNAPSHOT.jar --server.port=8090
```

Start the gateway service:
```bash
java -jar -Dfile.encoding=UTF-8 ./gateway/target/*-SNAPSHOT.jar --server.port=8088
```

### Option 2: Docker Deployment

#### Build Docker Image
```bash
# Using standard Dockerfile
docker build -t primihub-service .

# Using local development Dockerfile
docker build -f Dockerfile.local -t primihub-service:dev .
```

#### Run with Docker Compose
Create a `docker-compose.yml` file:
```yaml
version: '3.8'
services:
  primihub-app:
    image: primihub-service
    ports:
      - "8090:8090"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - NACOS_SERVER_ADDR=nacos:8848
    depends_on:
      - nacos
      - mysql
      - redis

  # Include other services: nacos, mysql, redis, rabbitmq
```

## 📊 Available Services

After successful startup, you can access:

- **Gateway API**: http://localhost:8088
- **Application API**: http://localhost:8090  
- **Nacos Console**: http://localhost:8848/nacos
- **Login Endpoint**: http://localhost:8088/sys/user/login

## 🔧 Key Features

### Data Management
- Data resource registration and management
- Federated data resource synchronization
- Data privacy and access control

### Model Management  
- Machine learning model deployment
- Federated learning model training
- Model version control

### Project Orchestration
- Multi-party collaborative projects
- Privacy-preserving computation tasks
- Task scheduling and monitoring

### Security Features
- JWT-based authentication
- Role-based access control (RBAC)
- Data encryption and privacy protection
- Secure multi-party computation

## 🐛 Troubleshooting

### Common Issues

1. **Nacos Connection Failed**
   - Check if Nacos server is running
   - Verify namespace configuration
   - Ensure network connectivity

2. **Database Connection Issues**
   - Verify MySQL credentials in database.yaml
   - Check if MySQL server is accessible

3. **Port Conflicts**
   - Change default ports in application.yaml files
   - Check if ports 8088, 8090, 8848 are available

4. **Build Failures**
   - Ensure Maven and JDK are properly installed
   - Check internet connection for dependency downloads

### Logs and Monitoring

Application logs are located in:
- `./application/logs/` for application service
- `./gateway/logs/` for gateway service

Enable debug logging by setting `logging.level.com.primihub=DEBUG` in configuration.

## 📁 Project Structure

```
primihub-service/
├── application/          # Main application service
│   ├── src/main/java/   # Java source code
│   ├── src/main/resources/ # Configuration files
│   └── target/          # Build output
├── gateway/             # API gateway service
│   ├── src/main/java/   # Gateway logic
│   └── src/main/resources/ # Gateway config
├── biz/                 # Business logic module
│   ├── src/main/java/   # Service implementations
│   └── src/main/resources/ # MyBatis mappings
├── script/              # Configuration scripts
│   ├── base.json        # Base configuration
│   ├── database.yaml    # Database config
│   ├── redis.yaml       # Redis config
│   ├── ddl.sql          # Database schema
│   └── init.sql         # Initial data
├── yfl/                 # YFL components (Python)
└── Dockerfile*          # Docker deployment files
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Check the troubleshooting section above
- Review application logs for error details
- Ensure all prerequisite services are running
- Verify configuration files are properly set up

---

**Note**: This is a management platform service for Primihub. For the complete Primihub ecosystem, ensure you have the core Primihub nodes and other components properly configured and running.

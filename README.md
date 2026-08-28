# Job Portal Project

사람인(Saramin) 오픈 API를 연동하여 채용공고를 자동 수집·저장하고 조회하는 백엔드 포털 서비스입니다.

## 아키텍처

```
인터넷
  │
  ▼
[ALB - Application Load Balancer]
  │  (포트 80/443)
  ▼
[EC2 - Spring Boot App]
  │  Blue(8080) / Green(8081) 무중단 배포
  ▼
[RDS - MySQL 8.0]  ←  Private Subnet
```

## 기술 스택

| 구분 | 기술 |
|------|------|
| Backend | Spring Boot 3.2, Java 17 |
| Database | MySQL 8.0 (AWS RDS) |
| Infra | AWS EC2, ALB, RDS, ECR, VPC |
| IaC | Terraform |
| CI/CD | GitHub Actions |
| Container | Docker, Docker Compose |
| 배포 전략 | Blue-Green (포트 스위치) |
| 스케줄러 | Spring @Scheduled (매일 00:00) |

## API 엔드포인트

| Method | URL | 설명 |
|--------|-----|------|
| GET | `/api/jobs?page=0&size=20` | 채용공고 목록 (페이지네이션) |
| GET | `/api/jobs/{id}` | 채용공고 상세 |
| GET | `/api/jobs/search?location=서울` | 지역으로 검색 |
| GET | `/api/jobs/search?company=카카오` | 회사명으로 검색 |
| GET | `/api/jobs/search?keyword=백엔드` | 키워드로 검색 |
| GET | `/actuator/health` | 헬스체크 |

## 사전 준비

- Java 17+
- Docker & Docker Compose
- Terraform >= 1.5.0
- AWS CLI (배포 시)
- 사람인 오픈 API 키 ([발급 링크](https://oapi.saramin.co.kr/))

## 로컬 개발 실행

```bash
# 1. 환경변수 설정
cp .env.example .env
# .env 파일에 SARAMIN_API_KEY 등 입력

# 2. Docker Compose로 실행 (MySQL + App)
docker-compose up -d

# 3. API 확인
curl http://localhost:8080/actuator/health
```

## Terraform으로 AWS 인프라 생성

```bash
cd infrastructure

# 1. terraform.tfvars 작성 (terraform.tfvars.example 참고)
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars

# 2. 초기화
terraform init

# 3. 계획 확인
terraform plan

# 4. 인프라 생성
terraform apply

# 5. ALB 주소 확인
terraform output alb_dns_name
```

## 환경 변수 목록

| 변수명 | 설명 | 예시 |
|--------|------|------|
| `DB_HOST` | RDS 엔드포인트 | `job-portal-db.xxx.rds.amazonaws.com` |
| `DB_NAME` | 데이터베이스 이름 | `jobportal` |
| `DB_USERNAME` | DB 사용자 | `admin` |
| `DB_PASSWORD` | DB 비밀번호 | - |
| `SARAMIN_API_KEY` | 사람인 API 키 | - |

## CI/CD 파이프라인

```
git push → main 브랜치
    ↓
GitHub Actions 트리거
    ↓
[1] Gradle Build (JAR)
    ↓
[2] Docker Build → ECR Push
    ↓
[3] SSH → EC2 deploy.sh 실행
    ↓
Blue-Green 무중단 배포 완료
```

### GitHub Secrets 설정 필요

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `EC2_HOST` (EC2 퍼블릭 IP)
- `EC2_USERNAME` (ec2-user)
- `EC2_SSH_KEY` (PEM 키 내용)
- `ECR_REGISTRY`
- `DB_HOST`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`
- `SARAMIN_API_KEY`

## 배치 스케줄러

매일 **자정 00:00 (KST)** 에 자동 실행:
1. 만료된 채용공고 삭제
2. 사람인 API에서 최신 공고 100건 수집 및 저장

## 라이선스

MIT License

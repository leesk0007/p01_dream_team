# KT TECH UP 클라우드 인프라 1차 프로젝트

> Terraform · Ansible · GitHub Actions 기반 FastAPI 서비스 자동 배포 인프라
>
> 4조 드림팀

---

## 목차

1. [팀원 소개](#1-팀원-소개)
2. [프로젝트 개요](#2-프로젝트-개요)
3. [아키텍처](#3-아키텍처)
4. [기술 스택](#4-기술-스택)
5. [프로젝트 구조](#5-프로젝트-구조)
6. [실행 순서](#6-실행-순서)
7. [CI/CD 파이프라인](#7-cicd-파이프라인)
8. [모니터링](#8-모니터링)
9. [설계 결정 및 회고](#9-설계-결정-및-회고)

---

## 1. 팀원 소개

<table>
  <thead>
    <tr>
      <th>역할</th>
      <th>이름</th>
      <th>담당 영역</th>
      <th>주요 업무</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>팀장</td>
      <td><a href="https://github.com/jinsw1">진승우</a></td>
      <td>인프라 설계 및 총괄</td>
      <td>프로젝트 기획 및 일정 관리 · VPC / Subnet / NAT 설계 · Security Group 정책 수립 (WEB / WAS / DB) · 최종 발표 및 문서 관리</td>
    </tr>
    <tr>
      <td>팀원</td>
      <td><a href="https://github.com/leesk0007">이성규</a></td>
      <td>모니터링 &amp; Auto Scaling</td>
      <td>Prometheus / Grafana 구축 · Node Exporter 기반 메트릭 수집 · Alert Rule 설정 · Auto Scaling 정책 설계 · WAS AMI 이미지 생성</td>
    </tr>
    <tr>
      <td>팀원</td>
      <td><a href="https://github.com/sor21101">백두산</a></td>
      <td>운영 환경 &amp; 접근 제어</td>
      <td>Mgmt 서버 및 Bastion Host 구성 · Terraform / Ansible 실행 환경 구축 · Bootstrap 스크립트 작성 · Private 서버 접근(SSH) 구성</td>
    </tr>
    <tr>
      <td>팀원</td>
      <td><a href="https://github.com/pretty2753">송민기</a></td>
      <td>Terraform &amp; DB</td>
      <td>Terraform 기반 인프라 코드 작성 · AWS 리소스 자동 생성 (VPC / EC2 등) · DB(PostgreSQL) 구축 및 설정 · State 및 변수 관리</td>
    </tr>
    <tr>
      <td>팀원</td>
      <td><a href="https://github.com/shimseonghyun">심승현</a></td>
      <td>서버 구성 &amp; 배포</td>
      <td>Ansible 기반 서버 구성 자동화 · Nginx + Python(FastAPI) 환경 구축 · 애플리케이션 배포 및 실행 · Reverse Proxy 설정 및 서비스 검증</td>
    </tr>
  </tbody>
</table>


---

## 2. 프로젝트 개요

이번 프로젝트는 단순 서버 생성에 그치지 않고, **인프라 구축 → 서버 초기 설정 → 서비스 배포 → 무중단 업데이트**까지 전체 운영 과정을 자동화하는 것을 목표로 하였습니다.

| 단계 | 도구 | 내용 |
|------|------|------|
| 1단계 | Terraform | AWS 인프라 자동 생성 |
| 2단계 | Ansible | 초기 서버 환경 구성 (계정/키 설정) |
| 3단계 | Ansible | 서비스 구성 및 애플리케이션 배포 |
| 4단계 | GitHub Actions | CI/CD 자동 배포 + ASG Rolling Update |

---

## 3. 아키텍처

<img width="1536" height="1024" alt="ChatGPT Image 2026년 5월 21일 오전 11_58_26" src="https://github.com/user-attachments/assets/38a6f994-73ce-4e58-97d4-7eb4564d6d28" />

AWS 환경에서 **VPC 기반 네트워크 분리**를 적용하였습니다.

- **Public Subnet** : Bastion 서버, ALB, NAT Gateway
- **Private Subnet** : WAS 서버 (Nginx + FastAPI), DB 서버 (PostgreSQL)

| 서버 | 역할 |
|------|------|
| Bastion | 내부 서버 접근 중계 + 모니터링 (Prometheus / Grafana) |
| WAS | Nginx Reverse Proxy + FastAPI 애플리케이션 |
| DB | PostgreSQL 데이터베이스 |

---

## 4. 기술 스택

| 분류 | 기술 |
|------|------|
| 인프라 자동화 | Terraform |
| 서버 구성 관리 | Ansible |
| CI/CD | GitHub Actions |
| 웹 서버 | Nginx |
| 애플리케이션 | FastAPI (Python) |
| 데이터베이스 | PostgreSQL |
| 모니터링 | Prometheus, Grafana, Node Exporter, PostgreSQL Exporter |
| 클라우드 | AWS (VPC, EC2, ALB, ASG, Route 53, S3, DynamoDB, IAM) |

---

## 5. 프로젝트 구조

```
p01_dream_team/
├── .github/
│   └── workflows/
│       └── deploy.yml              # CI/CD 파이프라인 (GitHub Actions)
│
├── terraform/
│   ├── bootstrap/                  # 원격 상태 관리 초기 설정
│   │   ├── s3.tf                   # tfstate 저장 버킷
│   │   ├── dynamodb.tf             # 상태 잠금 테이블
│   │   ├── provider.tf
│   │   └── version.tf
│   │
│   ├── modules/                    # 재사용 가능한 Terraform 모듈
│   │   ├── vpc/
│   │   ├── subnet/
│   │   ├── internet-gateway/
│   │   ├── nat-gateway/
│   │   ├── security-group/
│   │   ├── route53/
│   │   ├── alb/                    # Application Load Balancer
│   │   ├── asg/                    # Auto Scaling Group
│   │   ├── ec2/
│   │   └── keypair/
│   │
│   └── envs/
│       ├── dev/                    # 개발 환경 인프라 정의
│       │   ├── 00_backend.tf       # 원격 상태 백엔드
│       │   ├── 01_data.tf          # 데이터 소스 (AMI 등)
│       │   ├── 02_network.tf       # VPC / 서브넷
│       │   ├── 03_routing.tf       # 라우팅 테이블
│       │   ├── 04_secutiry.tf      # 보안 그룹
│       │   ├── 05_compute.tf       # EC2 (Bastion / WAS / DB)
│       │   ├── 06_alb.tf           # ALB
│       │   ├── 07_iam.tf           # IAM 역할 / 정책
│       │   ├── 08_ansible.tf       # Ansible inventory 자동 생성
│       │   ├── 09_autoscaling.tf   # Auto Scaling Group
│       │   ├── 10_route53.tf       # DNS 레코드
│       │   └── 11_outputs.tf       # 출력값
│       └── prod/                   # 운영 환경 (예정)
│
├── ansible/
│   ├── ansible.cfg                 # Ansible 전역 설정
│   ├── inventories/
│   │   ├── bootstrap/              # 초기 사용자 설정용 인벤토리
│   │   └── dev/                    # 개발 환경 인벤토리 (Terraform 자동 생성)
│   ├── playbooks/
│   │   ├── site.yml                # 메인 플레이북 (전체 실행 진입점)
│   │   ├── bootstrap.yml           # 초기 서버 사용자/키 설정
│   │   ├── deploy_fastapi.yml      # FastAPI 배포
│   │   └── ami_capture.yml         # AMI 캡처
│   └── roles/
│       ├── common/                 # 공통 패키지 설치
│       ├── bootstrap_user/         # 서버 초기 사용자 설정
│       ├── nginx/                  # Nginx 설치 및 설정
│       ├── fastapi/                # FastAPI 앱 배포
│       ├── postgresql/             # PostgreSQL 설치 및 DB 초기화
│       ├── monitoring_prometheus/  # Prometheus 설치
│       ├── monitoring_grafana/     # Grafana 설치
│       ├── node_exporters/         # Node Exporter 설치
│       ├── postgres_exporters/     # PostgreSQL Exporter 설치
│       └── ami_capture/            # AMI 생성 자동화
│
└── web/
    └── event_service/
        ├── deploy/                 # 배포용 소스 (서버 반영본)
        │   ├── main.py
        │   ├── app.py
        │   ├── requirements.txt
        │   ├── static/
        │   └── templates/
        └── dev/                    # 로컬 개발용 소스
            ├── main.py
            ├── app.py
            ├── requirements.txt
            ├── static/
            └── templates/
```

---

## 6. 실행 순서

### 사전 요구사항

- Terraform, Ansible, AWS CLI 설치
- AWS Access Key 등록
- WSL(Ubuntu) 환경 권장 (Windows의 경우)

### Step 1. Terraform Bootstrap — 원격 상태 관리 초기화

```bash
terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap apply --auto-approve
```

### Step 2. Terraform Apply — AWS 인프라 생성

```bash
terraform -chdir=terraform/envs/dev init
terraform -chdir=terraform/envs/dev plan
terraform -chdir=terraform/envs/dev apply --auto-approve
```

> Terraform Apply 완료 시 `ansible/inventories/dev/inventory.yml` 자동 생성됨

### Step 3. Ansible Bootstrap — 초기 서버 계정/키 설정

```bash
cd ansible
ansible-playbook -i inventories/bootstrap/inventory.yml playbooks/bootstrap.yml
```

### Step 4. Ansible Site — 서비스 구성 및 배포

```bash
cd ansible
ansible-playbook -i inventories/dev/inventory.yml playbooks/site.yml
```

---

## 7. CI/CD 파이프라인

`web/` 또는 `ansible/roles/nginx`, `ansible/roles/fastapi` 경로에 변경사항이 Push되면 자동 배포가 실행됩니다.

```
GitHub Push
    │
    ▼
GitHub Actions 트리거
    │
    ├─ 1. WAS 서버에 최신 소스 배포 (Ansible)
    │
    ├─ 2. WAS 서버 기반 신규 AMI 생성 (AWS CLI)
    │
    ├─ 3. Launch Template 최신 AMI로 갱신
    │
    └─ 4. ASG Rolling Update — 구버전 인스턴스 순차 교체
```

---

## 8. 모니터링

Bastion 서버에 구성된 Prometheus + Grafana를 통해 전체 서버 상태를 모니터링합니다.

| 수집 대상 | Exporter |
|-----------|----------|
| WAS 서버 시스템 지표 | Node Exporter |
| DB 서버 시스템 지표 | Node Exporter |
| PostgreSQL 지표 | PostgreSQL Exporter |

### 모니터링 대시보드 접속 방법

ASG 설정 완료 후, 로컬 환경(cmd / terminal)에서 SSH 터널링으로 Bastion 서버의 포트를 로컬로 연결합니다.

**1. SSH 터널링 연결** (IP는 Bastion Public IP로 변경)

```bash
ssh -i "~/.ssh/project01-bastion-key.pem" \
    -L 9090:localhost:9090 \
    -L 3000:localhost:3000 \
    ec2-user@<Bastion-Public-IP>
```

**2. 접속 오류 시 — boto3 설치 후 재시도**

```bash
sudo dnf install python3-pip -y
pip3 install boto3 botocore
```

**3. SSH 정상 접속 후 웹 브라우저에서 접속**

| 서비스 | URL |
|--------|-----|
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3000 |

---

## 9. 설계 결정 및 회고

### Terraform과 Ansible을 분리한 이유

Terraform 내부에서 Ansible을 직접 실행할 경우, Ansible이 서버 내부를 변경해도 Terraform은 해당 변경을 추적할 수 없습니다. 이로 인해 인프라 상태 불일치 문제가 발생할 수 있어 두 도구의 실행 단계를 명확히 분리하였습니다.

- **Terraform**: 인프라 리소스 생성 및 inventory.yml 자동 생성까지
- **Ansible**: 서버 내부 구성 및 서비스 배포

### Terraform 모듈화를 적용한 이유

단순 1회성 구성에 그치지 않고, 재사용성과 유지보수성을 고려하여 Terraform 코드를 모듈 단위로 분리하였습니다. 동일한 구조의 인프라를 반복 생성할 수 있고, 협업 시 일관된 작업 환경을 유지할 수 있습니다.

### S3 + DynamoDB Backend를 적용한 이유

| 문제 | 해결 |
|------|------|
| 팀원마다 다른 로컬 tfstate | S3 중앙 관리로 상태 공유 |
| 동시 Apply 시 충돌 위험 | DynamoDB State Lock으로 중복 작업 차단 |

### ec2-user 대신 adreamin 계정을 생성한 이유

`ec2-user`는 AWS에서 기본 제공하는 계정으로 광범위한 권한을 보유하고 있어, 탈취 시 보안 위협에 노출될 위험이 높습니다. 따라서 `adreamin` 운영 계정을 별도 생성하고, `ec2-user`는 초기 계정 생성 단계에서만 사용하도록 제한하였습니다.

- `bastion-key`: Bastion 서버 접근용
- `ansible-key`: Ansible 자동화 작업용

### Packer 대신 AWS CLI 기반 AMI 생성을 선택한 이유

Packer는 초기 상태의 인스턴스에서 환경을 새롭게 구성한 뒤 AMI를 생성하는 방식으로, DB 연동 및 애플리케이션 배포 과정에서 다수의 오류가 발생하였습니다. 프로젝트 기간 내 안정적인 해결이 어렵다고 판단하여, **이미 서비스가 구성·운영 중인 WAS 인스턴스를 기반으로 AMI를 생성하는 방식**을 채택하였습니다.

> WAS 인스턴스는 ASG 관리 대상 및 ALB Target Group에서 제외된 **AMI 생성 전용 인스턴스**로만 활용됩니다.

### inventory.yml을 저장소에 포함한 이유

보안상 IP 정보가 포함된 inventory 파일은 저장소에 포함하지 않는 것이 원칙입니다. 그러나 GitHub Actions runner가 Bastion을 경유하여 Ansible 배포를 수행하기 위해 runner 환경에서도 inventory 파일 접근이 필요하였고, 팀원들이 각자 환경에서 반복적으로 인프라를 생성·삭제하며 테스트하는 과정에서 불가피하게 포함하게 되었습니다.

> **개선 방안**: GitHub Secrets에 inventory 정보를 저장하고 Actions 실행 시 동적으로 생성하는 방식이 적절합니다.

### 완전 자동화(Terraform + Ansible 일괄 실행)를 하지 않은 이유

일괄 자동화 시 수정 사항이 생기면 처음부터 전체를 재실행해야 하며, 오류 발생 지점 파악도 어려워집니다. 단계별 분리 실행으로 **문제 구간 특정 및 부분 재실행**이 가능하도록 구성하였습니다.

### NAT Gateway를 선택한 이유 (NAT Instance 대신)

NAT Instance는 직접 관리가 필요하고 단일 장애점이 될 수 있습니다. NAT Gateway는 AWS 관리형 서비스로 고가용성과 자동 확장을 지원하여, 기초 프로젝트 수준에서 운영 부담 없이 안정적인 아웃바운드 통신 환경을 구성할 수 있습니다.

### 별도 mgmt 서버를 두지 않은 이유

Cloudflare / Tailscale과 같은 역방향 터널링 기반 VPN 서비스를 프로젝트 초기 아키텍처 구상 시점에 충분히 검토하지 못하였습니다. 기초 프로젝트 규모를 고려하여 Bastion 서버가 내부 접근 중계 역할을 겸하도록 구성하였습니다.

# CloudLab — Aplicații Cloud Native

Proiect complet pentru lucrările de laborator Nr.1–4 (Curs: Aplicații Cloud).

## Arhitectură

```
┌─────────────────────────────────────────────┐
│  POD 1: Frontend (nginx + HTML)             │
│  • Pagină login / înregistrare              │
│  • Port: 80                                 │
└──────────────────┬──────────────────────────┘
                   │ HTTP (in-cluster DNS)
┌──────────────────▼──────────────────────────┐
│  POD 2: Backend (Node.js + SQLite)          │
│  • REST API: /api/register, /api/login      │
│  • Baza de date: SQLite (PersistentVolume)  │
│  • Port: 3001                               │
└─────────────────────────────────────────────┘
```

---

## Lucrarea Nr.1 — Mediu de dezvoltare

### Instalare Rancher Desktop
1. Descarcă de la https://rancherdesktop.io/
2. Instalează și pornește Rancher Desktop
3. În setări, selectează **containerd** sau **dockerd (moby)** ca Container Engine
4. Activează **Kubernetes** din setări

### Aplicația aleasă
Aplicație web simplă de autentificare cu 2 servicii:
- **Frontend**: pagină HTML servită de nginx
- **Backend**: API Node.js cu baza de date SQLite

---

## Lucrarea Nr.2 — Containerizare

### Build imagini local

```bash
# Backend
cd backend
docker build -t cloudlab-backend:latest .

# Frontend
cd ../frontend
docker build -t cloudlab-frontend:latest .
```

### Lansare cu Docker Compose

```bash
# Din rădăcina proiectului
docker compose up -d

# Verificare
docker compose ps
docker compose logs backend
docker compose logs frontend
```

### Accesare
- **Frontend**: http://localhost:8080
- **Backend health**: http://localhost:3001/health

### Test manual API

```bash
# Înregistrare utilizator
curl -X POST http://localhost:3001/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}'

# Login
curl -X POST http://localhost:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}'
```

---

## Lucrarea Nr.3 — Kubernetes

### Prerequisite
Rancher Desktop cu Kubernetes activat.

### 1. Aplică manifestele

```bash
# Creează namespace și aplică toate resursele
kubectl apply -f k8s/frontend.yaml   # namespace + frontend deployment + service
kubectl apply -f k8s/backend.yaml    # PVC + secret + backend deployment + service
```

### 2. Verifică pod-urile

```bash
# Vezi cele 2 pod-uri
kubectl get pods -n cloudlab

# Output așteptat:
# NAME                        READY   STATUS    RESTARTS   AGE
# backend-xxxxxxxxx-xxxxx     1/1     Running   0          30s
# frontend-xxxxxxxxx-xxxxx    1/1     Running   0          30s

# Vezi serviciile
kubectl get services -n cloudlab

# Descrie un pod
kubectl describe pod -n cloudlab -l app=backend
```

### 3. Accesare locală (port-forward)

```bash
# Expune frontend local
kubectl port-forward service/frontend-service 8080:80 -n cloudlab

# Expune backend local (terminal separat)
kubectl port-forward service/backend-service 3001:3001 -n cloudlab
```

Deschide http://localhost:8080

### 4. Verificare logs

```bash
kubectl logs -n cloudlab -l app=backend  --follow
kubectl logs -n cloudlab -l app=frontend --follow
```

### 5. Restart pod-uri (demonstrație reinițializare)

```bash
# Restart rollout (pentru prezentare)
kubectl rollout restart deployment/backend  -n cloudlab
kubectl rollout restart deployment/frontend -n cloudlab

# Urmărește rollout-ul
kubectl rollout status deployment/backend  -n cloudlab
kubectl rollout status deployment/frontend -n cloudlab
```

---

## Lucrarea Nr.4 — CI/CD pe Google Cloud

### Prerequisite
1. Cont Google Cloud cu proiect creat
2. API-uri activate: Cloud Run, GKE, Artifact Registry
3. Service Account cu roluri: Cloud Run Admin, Artifact Registry Writer, GKE Developer

### 1. Creează Artifact Registry

```bash
gcloud artifacts repositories create cloudlab \
  --repository-format=docker \
  --location=europe-west1 \
  --description="CloudLab Docker images"
```

### 2. Configurează GitHub Secrets

În repository GitHub → Settings → Secrets → Actions, adaugă:

| Secret | Valoare |
|--------|---------|
| `GCP_PROJECT_ID` | ID-ul proiectului tău GCP |
| `GCP_SA_KEY` | JSON key al Service Account |
| `JWT_SECRET` | Un string secret random |

### 3. Creează Service Account key

```bash
gcloud iam service-accounts create cloudlab-deployer \
  --display-name="CloudLab CI/CD Deployer"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:cloudlab-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:cloudlab-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud iam service-accounts keys create key.json \
  --iam-account=cloudlab-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Conținutul lui key.json → GitHub Secret GCP_SA_KEY
```

### 4. Push și declanșează CI/CD

```bash
git init
git add .
git commit -m "feat: initial cloudlab project"
git remote add origin https://github.com/USERNAME/cloud-lab.git
git push origin main
```

Pipeline-ul se va declanșa automat la orice `push` pe `main`:
1. **Build** — construiește imaginile Docker
2. **Push** — le urcă în Artifact Registry
3. **Deploy** — le deployuiește pe Cloud Run și/sau GKE
4. **Rollout restart** — reinițializează containerele (demonstrare CI/CD)

### 5. Urmărire pipeline

```
GitHub → Actions → CI/CD — CloudLab
```

---

## Structura proiectului

```
cloud-lab/
├── backend/
│   ├── server.js          # Express API + SQLite
│   ├── package.json
│   └── Dockerfile
├── frontend/
│   ├── index.html         # Pagina login/register
│   ├── nginx.conf
│   ├── entrypoint.sh      # Injectare BACKEND_URL
│   └── Dockerfile
├── k8s/
│   ├── backend.yaml       # PVC + Deployment + Service
│   └── frontend.yaml      # Namespace + Deployment + LoadBalancer
├── .github/
│   └── workflows/
│       └── ci-cd.yml      # GitHub Actions pipeline
├── docker-compose.yml     # Dev local
└── README.md
```

---

## Prezentare — flow demonstrare

1. **Lab 2**: `docker compose up` → arată containerele în Rancher Desktop
2. **Lab 3**: `kubectl get pods -n cloudlab` → arată 2 pod-uri Running
3. **Transmitere date**: deschide Network tab în browser, fă login, arată request HTTP frontend→backend
4. **CI/CD**: modifică ceva în `index.html`, `git push`, arată GitHub Actions în timp real
5. **Reinițializare**: în pipeline rulează `kubectl rollout restart` → pod-urile se recreează cu noua imagine

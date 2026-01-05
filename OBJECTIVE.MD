I want to create a project that will help me stand out when I apply to this job:......

AWS Cloud Engineer for Racing Applications (m/w/d)
Don’t just go to work; become part of a unique company within a fast-moving industry. Toyota Gazoo Racing Europe – creating excitement through team spirit and advanced technology!

We are looking for a Cloud Engineer to join our application development and works motorsport team in Cologne, Germany. In this role within the IT department, you will be responsible for developing and maintaining our AWS cloud infrastructure, supporting race team operations and data analytics. Partial remote work is possible.

Are you a team player who thrives on responsibility, with strong analytical and logical skills? Then you are the right person to take on this challenge. Be inspired by the passion and teamwork of our 500 strong workforce for motorsport and automotive projects.

 

What we offer:

exciting projects and a place for technical freedom and innovation to get things moving
attractive benefits packages e.g. competitive remuneration, social benefits, 30 days annual holiday, car leasing, free on-site gym
a challenging, fulfilling workplace in a multi-national company within a familiar atmosphere - driven by fascination and passion
 

Your tasks:

Design, implement, and manage Hybrid AWS infrastructure using Terraform across multiple accounts and regions.
Take part in crucial software architecture decisions.
Maintain secure and scalable hybrid setups between Edge, Cloud and On-Prem.
Maintain critical infrastructure in the AWS Cloud.
Support CI/CD pipelines and Infrastructure automation for internal software applications.
Collaborate with software developers and engineers to enable secure cloud-native solutions for motor-sport analytics, APIs, and AI workloads.
Possibilities to participate in the full software development life cycle.
 

The successful candidate will:

Have a Bachelor/master’s degree or equivalent in computer science, cloud engineering, or a related field.
Bring 3+ years of hands-on experience with AWS and Infrastructure as Code (IAC) in a production environment.
Be familiar with AWS services such as EKS, ECS, VPC, EC2, IAM, CloudTrail, Athena, RDS, ECR, and S3.
Understand CI/CD workflows and DevOps practices in cloud-native environments.
Have experience with containerized workloads (K8s and Docker).
Be fluent in English; German language skills are a plus.
Have experience with one or more of the following would be an advantage: Terraform, Azure DevOps Pipelines, Python, AI/ML workloads, Data Engineering, Networking
Be available to work on-site in Cologne, Germany at least 3 days per week. 



Project idea... 

🧩 Architecture (high level)

F1 Data Source (API / CSV)
        ↓
Edge Simulator (container)
        ↓
AWS Ingestion (API Gateway / ALB)
        ↓
EKS (processing & APIs)
        ↓
S3 (raw + processed data)
        ↓
Athena / Glue
        ↓
Dashboards (Grafana)

Why this project works for motorsport roles

This directly demonstrates:
	•	Hybrid thinking (edge → cloud)
	•	Race-weekend reliability
	•	Data latency awareness
	•	Cloud + Kubernetes mastery
	•	Infrastructure as Code
	•	Observability

It screams:

“I understand race operations, not just Kubernetes.”

⸻

Data source (easy + real)

Use Ergast F1 API (free, no auth):
	•	Laps
	•	Drivers
	•	Constructors
	•	Race results
	•	Pit stops
	•	Qualifying

Example:
http://ergast.com/api/f1/current/last/laps.json


Core components (what you actually implement)

1️⃣ Edge simulator (Docker)

Simulate trackside systems.
	•	Python container
	•	Periodically pulls F1 data
	•	Pushes to cloud endpoint
	•	Adds artificial latency + packet loss (optional)

Tech:
	•	Python
	•	Docker
	•	Deployed as:
	•	Local container OR
	•	EKS DaemonSet (nice touch)

⸻

2️⃣ AWS Infrastructure (Terraform)

This is where you shine.

Provision:
	•	VPC (private subnets)
	•	EKS cluster
	•	ALB Ingress Controller
	•	IAM Roles for Service Accounts (IRSA)
	•	S3 buckets:
	•	raw-telemetry
	•	processed-telemetry
	•	CloudWatch + Prometheus

This alone maps 1:1 to their JD.

⸻

3️⃣ Data ingestion service (Kubernetes)
	•	Small FastAPI service
	•	Receives telemetry
	•	Writes raw data to S3
	•	Pushes metrics

Run as:
	•	Deployment + HPA
	•	Proper resource limits
	•	PodDisruptionBudgets

⸻

4️⃣ Analytics pipeline

Keep it simple but realistic:
	•	Glue crawler for schema
	•	Athena queries for:
	•	Lap times
	•	Sector trends
	•	Pit stop deltas
	•	Optional:
	•	Spark job
	•	Python batch job in EKS

⸻

5️⃣ Dashboards (this is what recruiters LOVE)

Grafana dashboards showing:
	•	Lap time deltas
	•	Driver consistency
	•	Ingestion latency
	•	Error rates
	•	Throughput per minute

Bonus:
	•	“Race weekend mode” dashboard

⸻

What you explicitly document (very important)

Create a README.md that explains:

🚦 “Race weekend workflow”
	•	When infra is frozen
	•	How scaling is handled
	•	How failures are mitigated

🔒 Security
	•	IAM boundaries
	•	IRSA
	•	No static credentials

🔁 CI/CD
	•	GitHub Actions / Azure DevOps
	•	Terraform plan/apply
	•	Helm deploy

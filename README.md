AWS DevOps Challenge
Candidate name: 
Submission date: 

Challenge: Secure, Auditable Deployment Process
Create an Azure DevOps pipeline that:
Build a container java image for a Springboot application.
Security scanning for only critical vulnerabilities that will cause the pipeline to fail.
Store it to AWS ECR and store its signature (cosign).
Promotes through dev > staging > prod
Requires approvals at each stage.
Verifies images against signed digests (e.g., Cosign) in each step.
Deploys to EKS using `kubectl` and Helm.

Deliverables:
Azure DevOps pipeline yaml file.
If any, additional scripts (bash or python) used.
Kubernetes manifest files and Helm charts.

Comments on the solution:



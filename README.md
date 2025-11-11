# Documentation

## Workflow strategy

We have decided to use "feature branch" strategy for our workflow. Each feature was developed in a separate branch, which was then merged into the `develop` branch.
`main` branch is used for production, while `develop` is used for testing.

For each feature / fix / improvement, we have created a ticket following naming convention `DEV-<number>`, where `<number>` is the number of the ticket in the issue tracker. That way we can easily link merge requests to tickets in the issue tracker. And branch names are following the same convention.

The same strategy was used for the "Project Client on Board" and turned out to be very useful.

The branch name convention was set within gitlab. We have also made sure merge is only possible if there was a reviewer other than the author of the Merge Request.

## Definition of Done
For each created issue, we have put a bullet-point like description of what needs to be done.
Once the issue was completed, we have checked if all the points are done and if the code is working as expected.
If everything is checked and tested, reviewer approves the merge request and issue is closed.


## Environment Variables Overview
To launch project locally use provided `.env.example` in root directory. Copy it to `.env` and fill in the values.

---
## GITLAB Environment Variables

```
AWS_ACCESS_KEY_ID
```
- **Description:** AWS Access Key for authentication with AWS services.
- **Value:** ``

```
AWS_SECRET_ACCESS_KEY
```
- **Description:** AWS Secret Access Key for secure AWS operations.
- **Value:** ``

```
AWS_SESSION_TOKEN
```
- **Description:** Temporary session token for AWS.
- **Value:** ``

```
DEPLOY_PASSWORD
```
- **Description:** Token used for deployment authentication.
- **Value:** `gldt-XSx56TyNokSey2AyFAo1`

```
DEPLOY_USERNAME
```
- **Description:** Token used for deployment authentication.
- **Value:** `glpat-sk4f_6M8ctUA3kKWiA-N`

```
PAT
```
- **Description:** Personal Access Token for Git or other version control services.
- **Value:** `glpat-sk4f_6M8ctUA3kKWiA-N`

```
PROJECT_ID
```
- **Description:** identifier of project.
- **Value:** `68302463`

```
REGISTRY
```
- **Description:** URL Docker registry to push/pull images.
- **Value:** `registry.gitlab.com`

---
## GITLAB TERRAFORM Environment Variables

```
TF_VAR_ec2_password
```
- **Description:** Password from EC2.
- **Value:** `88005553535`

```
TF_VAR_app_key
```
- **Description:** Application key.
- **Value:** `base64:yqgFFzksV+C09W0+m69EFIaQOApHZ0knT6+kNZiidsE=`

```
TF_VAR_container_url
```
- **Description:** Fully qualified Docker image URL.
- **Value:** `registry.gitlab.com/saxionnl/hbo-ict/2.3-devops/2024-2025/exam-regular/15/backend`

```
TF_VAR_db_name
```
- **Description:** Name of the db.
- **Value:** `postgres`

```
TF_VAR_db_password
```
- **Description:** Database user’s password.
- **Value:** `88005553535`

```
TF_VAR_db_user
```
- **Description:** Database username.
- **Value:** `postgres`

```
TF_VAR_dt_password
```
- **Description:** Token for gitlab registry.
- **Value:** `gldt-bNQg1UY8z5Wx5_TT21g-`

```
TF_VAR_dt_username
```
- **Description:** Token for gitlab registry.
- **Value:** `gitlab+deploy-token-7711230`

```
TF_VAR_ec2_key_pair
```
- **Description:** Name of the AWS EC2 key pair for SSH access.
- **Value:** `saxion_imamedov`

```
TF_VAR_env
```
- **Description:** The environment name. Will be used in deployment.
- **Value:** `develop`


## Assignment 1 - Seeding Script

### Overview
Before we got started on this assignment, we had to make sure we can run the backend locally. For that purpose, we have installed
necessary dependencies and set up the database with migration commands.

After we got the backend running, we started working on the initial version of seeding script. This is a bash script that reads `data.md` and sends `POST` requests to the backend API.
The script was written in a way that it skipped falsy values and is configurable & adjustable. Logic was split into functions and use of environmental variables was implemented.

As we proceeded with the assignment and had the infrastructure running, we had to make adjustments
to the script. Namely:
- Once infrastructure was running, we had to change the script to wait until the backend was up and running before sending requests. This is done in a while loop that checks if response
  codes are not 500. Of course, to avoid infinite execution, this is checked for 10 minutes.
- Another caveat was that once we enabled autoscaling group, some instances were up and running, whilst others were still booting. Therefore, we adjusted the `postHighlight` function to try re-sending
  the request for 10 times with a 2 second delay in between.


## Assignment 2 - Dockerizing application

### Overview
In this assignment, we had to build a single `docker-compose.yml` file that would run the entire application including
frontend, backend and database.

We have started with building separate Dockerfiles for
frontend and backend. For the backend, we utilize multi-stage build to reduce the size of the image. There, we install dependencies and run Apache server.

For the frontend, we use nginx to serve the built application. We have also set up a reverse proxy for backend calls. (`main.js` had to be adjusted due to hardcoded URL values)

Having 2 separate Dockerfiles, we have started creating a `docker-compose.yml` file.
There, we set up a postgres database with a volume and define a health-check for it. The health-check is defined in a way that it waits for the database to be up and running before starting the backend.
Backend container also has a health-check defined. When the backend and db are up and running, we start a `migrate` container (runs once), and `seed` container (runs once).
Finally, we start the frontend container. The frontend container has a health-check defined as well, which waits for the backend to be up and running before starting the frontend.

We have utilized `.dockerignore` files extensively to avoid copying unnecessary files into the images.

Additionally, environmental variables are used to define the database connection string and the backend URL for the frontend.

In order to launch docker-compose, we are using this set of environmental variables:
```
GOALS_ENDPOINT=http://127.0.0.1:8000/api/goals
DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=thermometer_prod
DB_USERNAME=admin
DB_PASSWORD=admin
APP_KEY=base64:yqgFFzksV+C09W0+m69EFIaQOApHZ0knT6+kNZiidsE=
APP_NAME=thermometer
APP_DEBUG=true
APP_URL=http://localhost
APP_ENV=local
SEED_SCRIPT=add_data.sh
VITE_BACKEND_URL=http://localhost:8000
```

We can launch docker-compose manually, or using `dockerize.sh` script.

## Assignment 3 - CI/CD
### Overview
In this assignment, we had to set up a CI/CD pipeline for the application.

Before we had infrastructure running, we had a basic version of pipeline that was building the frontend and running backend tests in parallel.

However, once we started working on the infrastructure, our pipeline gradually evolved into a more complex one.

Currently, the pipeline is set up in a way that it can automatically deploy the application to the AWS, both the initial version (building entire infrastructure from scratch) and updated version (only updating backend instances).
A manual step for destroying application is also present and can be executed regardless of the version of the application.

We have the following stages in the pipeline:
- `build_and_test` – tests the backend.
- `publish_backend` – publishes the backend image to gitlab container registry. Since we operate in two environments (test and production), we publish the image under two different tags based by current branch.
- `initial_deploy` – deploys the initial version of the infrastructure. After the infrastructure is deployed, `.marker` file is created in the cache. In future jobs, we can check if this file is present and decide if we need to build the infrastructure from scratch or not.
- `deploy_backend` – updates the backend instances. This job is executed only if the infrastructure is already deployed. Runs a python script that updates backend.
- `seed_data` – seeds the database. This job is executed only if the infrastructure is already deployed and database wasn't seeded. Runs a bash script that seeds the database.
- `build_frontend` – builds the frontend. This job is executed only if the infrastructure is already deployed. It uses the URLs of the backend from the previous job as an artifact.
- `publish_frontend` – Runs a python script that publishes the frontend to S3 bucket. This job is executed only if the infrastructure is already deployed.
- `destroy_infrastructure` – destroys the entire infrastructure using saved `terraform.tfstate` file from cache. Then clears the markers and other artifacts from cache.

Alongside caching, we have heavily utilized artifacts. For example, the `initial_infrastructure_deploy` job produces `lb_dns.txt` files containing URLs of the backend, needed in subsequent `build_frontend` job. Another artifact is `autoscaling_group_name.txt` used in updating the backend.
Use of environmental variables is also present throughout the pipeline. Necessary AWS credentials are passed to allow the pipeline to access AWS resources.
Our terraform configuration is completely parameterized, allowing us to deploy application to different clouds based on branch name. For example, in our case `main` is the production, whilst `develop` is test environment.


## Assignment 4 - Infrastructure as Code
### Overview
![img.png](documentation/img.png)

In this assignment, we had to set up the infrastructure for the application using Terraform.
We have started with creating a basic version of the infrastructure, which included a VPC, subnets, security groups and an EC2 instance.
We define a security group that exposes only the ports we need:
- 80 for HTTP
- 5432 for PostgreSQL
  We also allow all outbound traffic.

RDS Database: The `voclabs` role does not have permissions to create Multi-AZ DB cluster using API, so we created Single-AZ DB instance.

Launch Template: To pass scripts to the EC2 instance, we have created a `install_docker.sh` script that installs latest container of the backend and runs it.

We output critical information such as the ALB DNS name and the Autoscaling Group name, which are needed for CI/CD steps.

`variables.tf` file was created to define all the necessary variables for the infrastructure. Sensitive parameters like keys to load the container are written in environment variables

## Assignment 5 - Continuous Deployment
### Overview
As stated above, our pipeline can automatically deploy and subsequently update the application to AWS.

We have come up with a strategy, that uses cached `.marker` files for deployment logic. Each job uses cache produced by `initial_infrastructure_deploy` stage. We can verify, if `.marker` file is present, and decide if infrastructure should be built from scratch or not.
Another handy marker is `seeded.marker` which is used to verify if the database should be seeded or not. By using these `marker` tricks, we can ensure the pipeline is fully automated and can be run multiple times without any issues.

Since we weren't limited in terms of tools, parts of the pipeline are using python scripts. Namely, we have created a script to update backend instances using `boto3` library. It checks the amount of running instances and creates 2x new ones. Old ones are automatically terminated by the autoscaling group due to `OldestInstance` policy. This allows blue/green deployment to be implemented. And makes the backend servers available even at the time of update

Another python script is publishing new built frontend to S3 bucket. This is done using `boto3` library as well. The script clears the bucket and uploads the new build.

## Assignment 7 - Scaling
### Overview
We distribute our servers via the Autoscaling Group across at least two subnets, each residing in a different Availability Zone (e.g., us-east-1a and us-east-1b). This way, even if one AZ encounters issues, the other zone can continue to serve traffic.

Our ALB automatically distributes incoming requests among the healthy instances in the Target Group. The health check uses an HTTP request (on port 80) to confirm that each instance is properly responding (checking for a 200 OK). If an instance fails, traffic is automatically routed away from it until it becomes healthy again or is replaced by the ASG.

We have defined a scaling policy that monitors CPU usage. If CPU usage surpasses a certain threshold it automatically adds another instance, up to the defined max_size.

For true end-to-end high availability, the database should also be multi-AZ, however The `voclabs` role does not have permissions to create Multi-AZ DB cluster using API

The user data script (install_docker.sh) ensures each new instance has Docker installed and pulls the latest backend container from our private registry (using environment variables for credentials). With the Autoscaling Group rolling out new instances, we avoid manual downtime — old instances are terminated only after the new ones pass their health checks.

In summary, by combining an Autoscaling Group, multiple Availability Zones, an Application Load Balancer, and a robust scaling policy, we achieve a backend layer resilient to single-AZ failures and responsive to spikes in traffic.

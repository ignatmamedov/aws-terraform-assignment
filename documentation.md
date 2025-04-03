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

Lastly, environmental variables are used to define the database connection string and the backend URL for the frontend.

## Assignment 3 - CI/CD
### Overview
In this assignment, we had to set up a CI/CD pipeline for the application. 

Before we had infrastructure running, we had a basic version of pipeline that was building the frontend and running backend tests in parallel.

However, once we started working on the infrastructure, our pipeline gradually evolved into a more complex one. 

Currently, the pipeline is set up in a way that it can automatically deploy the application to the AWS, both the initial version (building entire infrastructure from scratch) and updated version (only updating backend instances).
A manual step for destroying application is also present and can be executed regardless of the version of the application.

We have come up with a strategy, that uses cached `.marker` files for logic. Each job uses cache produced by `initial_infrastructure_deploy` stage. We can verify, if `.marker` file is present, and decide if infrastructure should be built from scratch or not.

Another handy marker is `seeded.marker` which is used to verify if the database should be seeded or not. By using these `marker` tricks, we can ensure the pipeline is fully automated and can be run multiple times without any issues.

Apart from caching, we have heavily utilized artifacts. For example, the `initial_infrastructure_deploy` job produces `.txt` files containing URLs of the backend, needed in subsequent `build_frontend` job. Another artifact is `autoscaling_group_name.txt` used in updating the backend. 

Since we weren't limited in terms of tools, parts of the pipeline are using python scripts. Namely, we have created a script to update backend instances using `boto3` library. It checks the amount of running instances and creates 2x new ones. Old ones are automatically terminated by the autoscaling group due to `OldestInstance` policy

Another python script is publishing new built frontend to S3 bucket. This is done using `boto3` library as well. The script clears the bucket and uploads the new build.

Use of environmental variables is also present throughout the pipeline. Necessary AWS credentials are passed to allow the pipeline to access AWS resources. Our terraform configuration is completely parameterized, allowing us to deploy application to different clouds based on branch name. For example, in our case `main` is the production, whilst `develop` is test environment.


## Assignment 4 - Infrastructure as Code
### Overview


## Assignment 5 - Continuous Deployment
### Overview


## Assignment 7 - Scaling
### Overview
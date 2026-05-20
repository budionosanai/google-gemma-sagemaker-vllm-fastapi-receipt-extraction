## Amazon SageMaker AI : SageMaker Studio, vLLM, Gemma 4 and Terraform for Receipt Extraction

1. Make sure already following instruction from [this link](https://dev.to/budionosan/amazon-sagemaker-sagemaker-studio-vllm-gemma-4-and-terraform-for-receipt-extraction-2cke) from step 1 until step 5.

2. Write and run this shell script in **vllm** folder for pull and push vLLM image to Amazon ECR private repository.
```
cd vllm
chmod +x vllm-to-ecr.sh
./vllm-to-ecr.sh
```

3. Run [this notebook](./vllm/vllm-sg-endpoint.ipynb) for create SageMaker model, endpoint configuration and endpoint, also test some sample photos. 
Then delete SageMaker model, endpoint configuration and endpoint use last cell in the notebook.

4. Install Terraform with run this shell script.
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"

brew install gcc

brew tap hashicorp/tap

brew install hashicorp/tap/terraform

terraform --version
```

5. Write and run this Terraform script in **terraform/sagemaker** folder for create SageMaker model, endpoint configuration and endpoint.
```
cd ..

cd terraform

cd sagemaker

terraform init

terraform plan

terraform apply --auto-approve
```

6. Write and run this shell script in **app** folder for build and push app folder to Amazon ECR private repository.
```
cd ..

cd app

aws ecr create-repository \
    --repository-name "receipt-extraction-gemma-4" \
    --image-scanning-configuration scanOnPush=false \
    --image-tag-mutability MUTABLE \
    --region "us-west-2" 2>/dev/null || echo "Repository already exists, skipping creation."

pip install sagemaker-studio-image-build

sm-docker build . --repository receipt-extraction-gemma-4:latest
```

## Amazon Elastic Container Services (ECS) : Express Mode and Custom Mode for Receipt Extraction

## Express Mode

1. Write and run this Terraform script in **terraform/ecs** folder for create API infrastructure using Amazon ECS Express Mode.
```
cd ..

cd terraform

cd ecs

terraform init

terraform plan

terraform apply --auto-approve
```

2. Open AWS console to Amazon ECS then copy ECS express service application URL like this screenshot.

![ECS express service application URL](./images/ecs-express-app-url.PNG)

3. Open **streamlit** folder then edit app.py. In this file, change from API_URL = "ALB DNS name (ECS custom mode) or ECS express service application URL (ECS express mode)/predict" to API_URL = "https://re-.../predict" and save this file.

4. In Streamlit cloud, click "Create app", click "Deploy a public app from GitHub". Choose your repository, branch, main file path of streamlit/app.py, app URL (optional) and click "Deploy".

5. Wait until available. Upload some photo samples from **photos** folder, click "Extract your receipt" then need seconds to get structured output.

6. Write "https://{ECS express service application URL}/health" to make sure this API is healthy or 200 OK.

7. Write "https://{ECS express service application URL}/docs", try predict API then repeat number 5 and 200 OK.

8. Write and run this Terraform script in **terraform/ecs** folder for delete Amazon ECS Express Mode resources.
```
terraform destroy --auto-approve
```

## Custom Mode

1. Write and run this Terraform script in **terraform/ecs-custom** folder for create API infrastructure using Amazon ECS Custom Mode.
```
cd ..

cd terraform

cd ecs-custom

terraform init

terraform plan

terraform apply --auto-approve
```

2. Open AWS console to Amazon ECS then copy application load balancer (ALB) DNS name like this screenshot.

![ECS application load balancer (ALB) DNS name](./images/ecs-custom-click-alb.PNG)

![ECS application load balancer (ALB) DNS name](./images/ecs-custom-alb-dns.PNG)

3. Open **streamlit** folder then edit app.py. In this file, change from API_URL = "ALB DNS name (ECS custom mode) or ECS express service application URL (ECS express mode)/predict" to API_URL = "http://fastapi-.../predict" and save this file.

4. In Streamlit cloud, click "Create app", click "Deploy a public app from GitHub". Choose your repository, branch, main file path of streamlit/app.py, app URL (optional) and click "Deploy".

5. Wait until available. Upload some photo samples from **photos** folder, click "Extract your receipt" then need seconds to get structured output.

6. Write "http://{application load balancer (ALB) DNS name}/health" to make sure this API is healthy or 200 OK.

7. Write "http://{application load balancer (ALB) DNS name}/docs", try predict API then repeat number 5 and 200 OK.

8. Write and run this Terraform script in **terraform/ecs-custom** folder for delete Amazon ECS Custom Mode resources.
```
terraform destroy --auto-approve
```

9. Write and run this Terraform script in **terraform/sagemaker** folder for delete SageMaker model, endpoint configuration and endpoint.
```
terraform destroy --auto-approve
```

10. In SageMaker Studio JupyterLab, click "Stop space" and delete your SageMaker Studio domain.
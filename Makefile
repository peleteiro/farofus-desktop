.DEFAULT_GOAL = apply
SHELL := /bin/bash

init:
	@cd terraform && terraform init --upgrade

lint:
	@cd terraform && terraform fmt

apply:
	@cd terraform && terraform apply

destroy:
	@cd terraform && terraform destroy

start:
	@aws ec2 start-instances --region `cd terraform && terraform output INSTANCE_REGION` --instance-id `cd terraform && terraform output INSTANCE_ID`

stop:
	@aws ec2 stop-instances --region `cd terraform && terraform output INSTANCE_REGION` --instance-id `cd terraform && terraform output INSTANCE_ID`

terminate:
	@cd terraform && terraform destroy -target=aws_spot_instance_request.desktop

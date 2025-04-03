import boto3
import os
import mimetypes
import uuid
import json
import sys

if len(sys.argv) != 3:
    print("Usage: python upload_to_s3.py <path-to-folder> <bucket-suffix>")
    sys.exit(1)

local_folder = sys.argv[1]
bucket_suffix_input = sys.argv[2].lower().strip()

region = boto3.session.Session().region_name or "us-east-1"
bucket_name = f"devops-exam-{bucket_suffix_input}"

s3 = boto3.client("s3", region_name=region)

create_bucket_params = {"Bucket": bucket_name}
if region != "us-east-1":
    create_bucket_params["CreateBucketConfiguration"] = {
        "LocationConstraint": region
    }


def configure_bucket(bucket_name):
    s3.put_bucket_website(
        Bucket=bucket_name,
        WebsiteConfiguration={
            "IndexDocument": {"Suffix": "index.html"},
            "ErrorDocument": {"Key": "index.html"},
        }
    )

    s3.put_public_access_block(
        Bucket=bucket_name,
        PublicAccessBlockConfiguration={
            'BlockPublicAcls': False,
            'IgnorePublicAcls': False,
            'BlockPublicPolicy': False,
            'RestrictPublicBuckets': False
        }
    )

    public_policy = {
        "Version": "2012-10-17",
        "Statement": [{
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": f"arn:aws:s3:::{bucket_name}/*"
        }]
    }

    s3.put_bucket_policy(
        Bucket=bucket_name,
        Policy=json.dumps(public_policy)
    )


def upload_to_s3(local_folder, bucket_name):
    for root, _, files in os.walk(local_folder):
        for file in files:
            full_path = os.path.join(root, file)
            key = os.path.relpath(full_path, local_folder).replace("\\", "/")
            content_type, _ = mimetypes.guess_type(full_path)

            s3.upload_file(
                Filename=full_path,
                Bucket=bucket_name,
                Key=key,
                ExtraArgs={
                    "ContentType": content_type or "application/octet-stream"
                }
            )
            print(f"Uploaded: {key}")

    website_url = f"http://{bucket_name}.s3-website-{region}.amazonaws.com"
    print(f"\nWebsite URL:\n{website_url}")


def empty_bucket(bucket_name):
    try:
        response = s3.list_objects_v2(Bucket=bucket_name)
        if 'Contents' in response:
            for obj in response['Contents']:
                print(f"Deleting: {obj['Key']}")
                s3.delete_object(Bucket=bucket_name, Key=obj['Key'])
    except Exception as e:
        print(f"Error while emptying bucket: {e}")


try:
    s3.create_bucket(**create_bucket_params)
    print(f"Bucket created: {bucket_name}")
    configure_bucket(bucket_name)
except s3.exceptions.BucketAlreadyOwnedByYou:
    print(f"Bucket already exists: {bucket_name}")
    empty_bucket(bucket_name)

upload_to_s3(local_folder, bucket_name)

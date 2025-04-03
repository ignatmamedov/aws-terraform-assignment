import boto3
import sys

if len(sys.argv) != 2:
    print("Usage: python delete_s3_bucket.py <bucket-suffix>")
    sys.exit(1)

bucket_suffix = sys.argv[1].lower().strip()
bucket_name = f"devops-exam-{bucket_suffix}"

s3 = boto3.resource('s3')
client = boto3.client('s3')

bucket = s3.Bucket(bucket_name)

bucket.objects.all().delete()
client.delete_bucket(Bucket=bucket.name)
print(f"Deleted bucket: {bucket.name}")

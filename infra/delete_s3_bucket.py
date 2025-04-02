import boto3

s3 = boto3.resource('s3')
client = boto3.client('s3')

for bucket in s3.buckets.all():
    print(f"Deleting bucket: {bucket.name}")
    bucket.objects.all().delete()
    client.delete_bucket(Bucket=bucket.name)

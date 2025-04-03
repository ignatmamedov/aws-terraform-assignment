import subprocess
import json
import boto3
import time
import sys

if len(sys.argv) != 2:
    print("Usage: python scale_asg.py <autoscaling_group_name>")
    sys.exit(1)

asg_name = sys.argv[1]
region = boto3.session.Session().region_name or "us-east-1"
asg_client = boto3.client("autoscaling", region_name=region)

response = asg_client.describe_auto_scaling_groups(
    AutoScalingGroupNames=[asg_name]
)

asg_info = response['AutoScalingGroups'][0]
original_min = asg_info['MinSize']
original_max = asg_info['MaxSize']
original_desired = asg_info['DesiredCapacity']

print(f" Current ASG settings: min={original_min}, max={original_max}, desired={original_desired}")

new_min = original_min * 2
new_max = original_max * 2
new_desired = original_desired * 2

print(f"Scaling up ASG: min={new_min}, max={new_max}, desired={new_desired}")
asg_client.update_auto_scaling_group(
    AutoScalingGroupName=asg_name,
    MinSize=new_min,
    MaxSize=new_max,
    DesiredCapacity=new_desired
)

print("Waiting for instances to be InService...")
while True:
    instances = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])['AutoScalingGroups'][0]['Instances']
    running = [i for i in instances if i['LifecycleState'] == 'InService']
    print(f"Pending instances: {len(running)} / {new_desired}")
    if len(running) >= new_desired:
        break
    time.sleep(10)

print(f"Reverting ASG to original settings: min={original_min}, max={original_max}, desired={original_desired}")
asg_client.update_auto_scaling_group(
    AutoScalingGroupName=asg_name,
    MinSize=original_min,
    MaxSize=original_max,
    DesiredCapacity=original_desired
)

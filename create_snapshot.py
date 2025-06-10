import boto3
from datetime import datetime

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    volumes = ec2.describe_volumes()

    for vol in volumes['Volumes']:
        volume_id = vol['VolumeId']
        timestamp = datetime.utcnow().strftime('%Y-%m-%d_%H-%M-%S')
        desc = f"Snapshot_{volume_id}_{timestamp}"

        response = ec2.create_snapshot(
            VolumeId=volume_id,
            Description=desc
        )
        print(f"Snapshot created: {response['SnapshotId']}")

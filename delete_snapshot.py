import boto3
from datetime import datetime, timedelta

RETENTION_DAYS = 14

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    delete_time = datetime.utcnow() - timedelta(days=RETENTION_DAYS)

   
    snapshots = ec2.describe_snapshots(OwnerIds=['self'])['Snapshots']

    for snapshot in snapshots:
        start_time = snapshot['StartTime'].replace(tzinfo=None)
        snapshot_id = snapshot['SnapshotId']

        if start_time < delete_time:
            try:
                ec2.delete_snapshot(SnapshotId=snapshot_id)
                print(f"Deleted snapshot: {snapshot_id}")
            except Exception as e:
                print(f"Failed to delete snapshot {snapshot_id}: {str(e)}")

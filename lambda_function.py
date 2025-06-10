import boto3
from datetime import datetime

s3 = boto3.client('s3')

def lambda_handler(event, context):
    try:
        print("Event received:", event)

        # Check if event has Records key
        if 'Records' not in event:
            print("No Records in event")
            return {
                "status": "error",
                "message": "Event does not contain Records key"
            }

        bucket = event['Records'][0]['s3']['bucket']['name']
        key    = event['Records'][0]['s3']['object']['key']

        print(f"Bucket: {bucket}, Key: {key}")

        obj = s3.get_object(Bucket=bucket, Key=key)
        text = obj['Body'].read().decode('utf-8')
        word_count = len(text.split())

        # Get current date and time in IST
        ist_time = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')

        result_key = f"count/{key.split('/')[-1].replace('.txt', '_count.txt')}"
        result_data = f"File: {key}\nWord Count: {word_count}\nDate: {ist_time}\n"

        s3.put_object(Bucket=bucket, Key=result_key, Body=result_data.encode('utf-8'))

        print("Word count file uploaded:", result_key)
        return {"status": "done", "word_count": word_count}

    except Exception as e:
        print("Error:", str(e))
        return {
            "status": "error",
            "message": str(e)
        }


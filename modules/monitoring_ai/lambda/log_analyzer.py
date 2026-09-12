import json
import gzip
import base64
import boto3
import os
import urllib.request
import urllib.error

sns = boto3.client('sns')

SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
OPENAI_API_KEY = os.environ['OPENAI_API_KEY']
OPENAI_MODEL = os.environ.get('OPENAI_MODEL', 'gpt-4o-mini')


def lambda_handler(event, context):
    """
    Déclenché par CloudWatch Logs Subscription Filter sur pattern "ERROR".
    Analyse les logs avec OpenAI GPT-4o-mini et envoie un diagnostic via SNS.
    """
    compressed_payload = base64.b64decode(event['awslogs']['data'])
    uncompressed_payload = gzip.decompress(compressed_payload)
    log_data = json.loads(uncompressed_payload)

    log_group = log_data.get('logGroup', 'unknown')
    log_stream = log_data.get('logStream', 'unknown')
    log_events = log_data.get('logEvents', [])

    if not log_events:
        return {'statusCode': 200, 'body': 'No log events to process'}

    error_messages = '\n'.join([e['message'] for e in log_events])

    prompt = f"""Tu es un expert DevOps/SRE spécialisé en microservices Spring Boot et infrastructure AWS.

Analyse les logs d'erreur suivants provenant de l'application WellnessHub en production et fournis un diagnostic concis en français.

=== CONTEXTE ===
Log Group : {log_group}
Log Stream : {log_stream}

=== LOGS D'ERREUR ===
{error_messages[:2500]}

=== FORMAT DE RÉPONSE ===
🔴 PROBLÈME DÉTECTÉ : [résumé en 1 phrase]
🔍 CAUSE PROBABLE : [explication technique courte]
⚡ URGENCE : [CRITIQUE / ÉLEVÉE / MOYENNE / FAIBLE]
✅ ACTION RECOMMANDÉE : [1-2 actions concrètes]
"""

    try:
        diagnostic = invoke_openai(prompt)
    except Exception as e:
        diagnostic = f"Erreur lors de l'appel OpenAI : {str(e)}\n\nLogs bruts :\n{error_messages[:1000]}"

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"🚨 WellnessHub — Erreur détectée dans {log_stream}",
        Message=f"""ALERTE AUTOMATIQUE — WellnessHub Production

Log Group : {log_group}
Log Stream : {log_stream}
Nombre d'événements : {len(log_events)}

{'='*50}
DIAGNOSTIC IA (OpenAI GPT-4o-mini)
{'='*50}

{diagnostic}

{'='*50}
Consultez CloudWatch Logs pour plus de détails :
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/{log_group.replace('/', '$252F')}
"""
    )

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Diagnostic envoyé', 'diagnostic': diagnostic})
    }


import time

def invoke_openai(prompt: str, max_retries: int = 3) -> str:
    """Appelle l'API OpenAI avec retry en cas de 429."""
    for attempt in range(max_retries):
        try:
            payload = json.dumps({
                "model": OPENAI_MODEL,
                "messages": [
                    {
                        "role": "system",
                        "content": "Tu es un expert DevOps/SRE. Analyse les logs et fournis des diagnostics en français."
                    },
                    {"role": "user", "content": prompt}
                ],
                "max_tokens": 400,
                "temperature": 0.3
            }).encode('utf-8')

            req = urllib.request.Request(
                "https://api.openai.com/v1/chat/completions",
                data=payload,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {OPENAI_API_KEY}"
                }
            )

            with urllib.request.urlopen(req, timeout=20) as response:
                result = json.loads(response.read().decode('utf-8'))
                return result['choices'][0]['message']['content']

        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < max_retries - 1:
                wait_time = (attempt + 1) * 2  # 2s, 4s, 6s
                print(f"Rate limit 429 — retry {attempt + 1}/{max_retries} dans {wait_time}s")
                time.sleep(wait_time)
                continue
            error_body = e.read().decode('utf-8')
            raise Exception(f"HTTP Error {e.code}: {error_body}")

    raise Exception("Max retries atteint")
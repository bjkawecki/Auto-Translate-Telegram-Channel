import boto3


def lambda_handler(event, context):
    ec2 = boto3.client("ec2")

    # Der Tag-Name, nach dem wir suchen (in deinem Fall "ttc-public-instance")
    instance_name_tag = "ttc-public-instance"

    # Beschreibe alle Instanzen, um die mit dem Tag "Name" = "ttc-public-instance" übereinstimmende Instanz zu finden
    try:
        response = ec2.describe_instances(
            Filters=[{"Name": "tag:Name", "Values": [instance_name_tag]}]
        )
    except Exception as e:
        print(f"Fehler bei der Abfrage von Instanzen: {e}")
        return {"statusCode": 500, "body": f"Fehler bei der Abfrage von Instanzen: {e}"}

    terminated_instances = []  # Liste, um terminierte Instanzen zu speichern

    # Iteriere durch die Ergebnisse und hole die Instanz-IDs der gefundenen Instanzen
    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            instance_id = instance["InstanceId"]
            print(f"Found instance with ID: {instance_id}")

            # Terminieren der Instanz
            try:
                ec2.terminate_instances(InstanceIds=[instance_id])
                terminated_instances.append(instance_id)
                print(f"Instanz {instance_id} wurde erfolgreich terminiert.")
            except Exception as e:
                print(f"Fehler beim Terminieren der Instanz {instance_id}: {e}")

    if terminated_instances:
        return {
            "statusCode": 200,
            "body": f"EC2-Instanzen {', '.join(terminated_instances)} wurden erfolgreich terminiert.",
        }
    else:
        return {
            "statusCode": 404,
            "body": "Keine Instanzen mit dem Tag 'ttc-public-instance' gefunden oder keine Instanzen wurden terminiert.",
        }

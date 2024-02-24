# Example HiveMQ Listener

This basic example subscribes to the HiveMQ broker and listens for messages. The messages are then stored in a MongoDB database.

## Locally

> Ensure your public ip is whitelisted in the Azure Network Security Group. Simply update the allowed_ips under the tfvars files.

```bash
cd my-listenr

poetry shell

poetry install --no-root

poetry run python main.py
```

Publishing a test payload:

```bash
docker run hivemq/mqtt-cli pub -h hivemq-broker.victoriousbeach-e8313d1b.australiaeast.azurecontainerapps.io -p 1883 -u admin-user -pw admin-password -t test -m "hello"
```

Verifying the payload was stored in the MongoDB database:

![image](https://github.com/chrisvfabio/hivemq-terraform-azure/assets/5626828/36d1395b-a234-4e18-9b33-566904d5ed1d)
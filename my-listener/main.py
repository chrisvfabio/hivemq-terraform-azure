import os
from pymongo import MongoClient
import paho.mqtt.client as paho

MONGO_USER = os.environ.get("MONGO_USER", "root")
MONGO_PASSWORD = os.environ.get("MONGO_PASSWORD", "supersecret")
MONGO_URI = os.environ.get("MONGO_URI", f"mongodb://{MONGO_USER}:{MONGO_PASSWORD}@hd4goo.australiaeast.cloudapp.azure.com:27017")
MONGO_DATABASE = os.environ.get("MONGO_DATABASE", "hivemq")
MONGO_COLLECTION = os.environ.get("MONGO_COLLECTION", "test")

HIVEMQ_BROKER_HOSTNAME = os.environ.get(
    "HIVEMQ_BROKER_HOSTNAME",
    "hivemq-broker.victoriousbeach-e8313d1b.australiaeast.azurecontainerapps.io",
)
HIVEMQ_BROKER_PORT = int(os.environ.get("HIVEMQ_BROKER_PORT", 1883))
HIVEMQ_BROKER_USERNAME = os.environ.get("HIVEMQ_BROKER_USERNAME", "admin-user")
HIVEMQ_BROKER_PASSWORD = os.environ.get("HIVEMQ_BROKER_PASSWORD", "admin-password")
HIVEMQ_BROKER_TOPIC = os.environ.get("HIVEMQ_BROKER_TOPIC", "test")

# Connect to MongoDB
client = MongoClient(MONGO_URI)
db = client[MONGO_DATABASE]
collection = db[MONGO_COLLECTION]

mqttc = paho.Client(paho.CallbackAPIVersion.VERSION2)


def main():
    print("Connecting to client")
    # Create MQTT CLient and connect to broker
    mqttc.username_pw_set(HIVEMQ_BROKER_USERNAME, HIVEMQ_BROKER_PASSWORD)
    mqttc.connect(HIVEMQ_BROKER_HOSTNAME, 1883, 60)
    mqttc.loop_forever()


@mqttc.connect_fail_callback()
def on_connect_fail(client, userdata):
    print("Connection failed.")


@mqttc.connect_callback()
def on_connect(client, userdata, flags, rc, properties):
    print("Connection returned result: " + str(rc))
    mqttc.subscribe(HIVEMQ_BROKER_TOPIC, qos=1)


@mqttc.message_callback()
def on_message(client, userdata, message):
    print(
        f"Received message '{message.payload.decode()}' on topic '{message.topic}' with QoS {message.qos}"
    )
    document = {"payload": message.payload.decode()}
    collection.insert_one(document)


if __name__ == "__main__":
    main()

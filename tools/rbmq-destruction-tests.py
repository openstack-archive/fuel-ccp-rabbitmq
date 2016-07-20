import argparse
import sys
import time

import pika
import pykube

def get_client(kube_apiserver=None, key_file=None, cert_file=None, ca_cert=None):
    cluster = {"server": kube_apiserver}
    if ca_cert:
        cluster["certificate-authority"] = ca_cert

    user = {}
    if cert_file and key_file:
        user["client-certificate"] = cert_file
        user["client-key"] = key_file

    config = {
        "clusters": [
            {
                "name": "ccp",
                "cluster": cluster
            }
        ],
        "users": [
            {
                "name": "ccp",
                "user": user
            }
        ],
        "contexts": [
            {
                "name": "ccp",
                "context": {
                    "cluster": "ccp",
                    "user": "ccp"
                },
            }
        ],
        "current-context": "ccp"
    }
    return pykube.HTTPClient(pykube.KubeConfig(config))

def get_pods(api=None, namespace=None):
    return pykube.Pod.objects(api).filter(namespace=namespace).iterator()

def pick_and_delete(api, timeout, namespace=None, regexp=None):
    all_pods = get_pods(api, namespace=namespace)
    pick_list = [ name for name in all_pods if regexp in str(name) ]
    for pod in pick_list:
        pod.delete()
        print("Pod %s deleted" % pod)
        time.sleep(2)
        print("Waiting for cluster to rebuild. Timeout: %s sec" % timeout)
        wait_for_cluster_rebuild(api, timeout, namespace, regexp)

def wait_for_cluster_rebuild(api, timeout, namespace=None, regexp=None):

    rebuild_time = 0
    down_sec = 0
    for i in range(0, timeout):
        rebuild_time += 1
        all_pods = get_pods(api, namespace=namespace)
        pick_list = set([ name for name in all_pods if regexp in str(name) ])
        ready_list = set([ name for name in pick_list if name.ready ])
        if not ready_list:
            down_sec += 1
        if ready_list == pick_list:
            print("Cluster is ready")
            print("Cluster rebuild took %s seconds" % rebuild_time)
            print("Cluster was down for %s seconds" % down_sec)
            return
        else:
            time.sleep(1)
    print("Cluster is not ready")
    print("Reached wait timeout")
    sys.exit(1)

def rbmq_publish_msg():
    parameters = pika.URLParameters('amqp://rabbitmq:password@rabbitmq:5672')
    connection = pika.BlockingConnection(parameters=parameters)
    channel = connection.channel()
    channel.confirm_delivery()
    channel.queue_declare(queue='test', durable=True, arguments={'x-ha-policy': 'all'})
    message = "Hello World!"
    channel.basic_publish(exchange='',
                          routing_key='test',
                          body=message,
                          properties=pika.BasicProperties(delivery_mode=2))
    print("Publish '%s' message to RBMQ" % message)
    connection.close()

def rbmq_fetch_msg():
    parameters = pika.URLParameters('amqp://rabbitmq:password@rabbitmq:5672')
    connection = pika.BlockingConnection(parameters=parameters)
    channel = connection.channel()
    channel.queue_declare(queue='test', durable=True)

    for method_frame, properties, body in channel.consume(queue='test'):
        print("Recived '%s' message from RBMQ" % body)
        channel.basic_ack(method_frame.delivery_tag)
        break
    connection.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("kube_apiserver",
                        type=str,
                        default='http://localhost:8080',
                        nargs='?')
    parser.add_argument("namespace",
                        type=str,
                        default="ccp",
                        nargs='?')
    parser.add_argument("regexp", default='rabbitmq', nargs='?')
    parser.add_argument("timeout",
                        type=int,
                        default=100,
                        nargs='?')
    args = parser.parse_args()

    kube_apiserver = args.kube_apiserver
    namespace = args.namespace

    api = get_client(kube_apiserver=kube_apiserver)
    rbmq_publish_msg()
    pick_and_delete(api=api, namespace=namespace, regexp=args.regexp,
                    timeout=args.timeout)
    rbmq_fetch_msg()


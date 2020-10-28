# datashipper-turin

A collection of tools to collect and publish metrics on the 5G EVE platform.

Features:

- Install, configure and manage [Filebeat](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation.html)
- Scripts to collect infrastructure metrics (in [infrastructure](infrastructure))
- Scripts to collect common application metrics (in [application](application))

## Install

### Prerequisites

On the target host, create a new user with permission to use `sudo`.
The new user must also be able to SSH into the host machine with key-based access.

This is required by Filebeat to work correctly as a systemd unit service.
The installation procedure will also allow this user to execute the scripts contained in this repository with passwordless `sudo`.

### Filebeat

Filebeat is needed to push any kind of metrics to Kafka and it must be installed first.

Clone the repository on your local machine and edit [filebeat.yml](filebeat.yml). Set Kafka's host and port.

```shell script
output.kafka:
  # Change this with site's Kafka information
  hosts: [ "<host>:<port>" ]
  topic: "%{[fields][topic_id]}"
```

Install Filebeat as a systemd unit service with the provided Ansible playbook.

```shell script
ansible-playbook -i "<host-ip-address>," -u <user> --private-key <key-file> -K install_filebeat.yml
```

> *Note:*
>
> - do not forget to include the comma after `<host-ip-address>`
> - default user is `ubuntu`, override it with `-u` specifying the user you created in *Prerequisites*
> - You need to configure key-based SSH access to the remote host for this to work. Specify your key file with `--private-key`.
> - `-K` requests the `sudo` password before executing

### Infrastructure metrics collectors

See [infrastructure/README.md](infrastructure/README.md)

### Application metrics collectors

See [application/README.md](application/README.md)

## More information on Filebeat

[Filebeat](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation.html) monitors CSV files and pushes data to Kafka.
[filebeat.yml](filebeat.yml) is the main configuration file.
The CSV files to monitor are specified in external configuration files, loaded dynamically as they appear in the configured `path`.

```yaml
filebeat.config.inputs:
  enabled: true
  path: /opt/datashipper/configs/*.yml
  reload.enabled: true
  reload.period: 1s
```

This allows to support the metric collection from multiple experiments also running at the same time.

To test Filebeat on your local machine, comment section `filebeat.config.inputs` and de-comment section `filebeat.inputs` to provide some static input files. Then, run:

```shell script
filebeat -e
```

### Test with Kafka

Move to folder [kafka-docker](kafka-docker) and run

```shell script
export DOCKER_HOST_IP=<host-ip-address>
docker-compose up -d
```

> *Note:* Set `DOCKER_HOST_IP` if you want to reach Kafka from outside your machine.

Now you have a Kafka broker and a zookeeper instance on your local machine.
Set host and port in your `filebeat.yml` like this:

```
output.kafka:
  hosts: ["localhost:9092"]
```

Run filebeat as shown above. In the log you should see something like:

```
2020-08-18T15:23:56.040+0200    INFO    [publisher_pipeline_output]     pipeline/output.go:111      Connection to kafka(localhost:9092) established
```

Then, run one of the collectors and make it write data to the path you configured in `filebeat.yml`.
The filebeat will monitor the output file, read any new line and send it to Kafka in JSON format.

To read Kafka messages you need to install a Kafka client.
We use [kafkacat](https://github.com/edenhill/kafkacat).
If you are on Ubuntu, simply run:

```shell script
sudo apt install kafkacat

# List topics
kafkacat -b localhost:9092 -L

# Read messages from topics
kafkacat -q -b kafka-test.polito.it:9092 -C -t user_data_rate

# Pipe to jq for better output
kafkacat -q -b kafka-test.polito.it:9092 -C -t user_data_rate | jq
```

### As a Systemd service

If you want to run filebeat as a systemd service, override the default configuration file:

```shell script
sudo cp ./filebeat.yml /etc/filebeat/filebeat.yml
```

Then, set the absolute path for the files to monitor, for example:

```yaml
    paths:
        - /home/ubuntu/datashipper-turin/output/data-rate.csv
```

Start and optionally enable (start on boot) the service:

```shell script
sudo systemctl start filebeat.service
sudo systemctl enable filebeat.service
```

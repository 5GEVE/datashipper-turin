# Infrastructure metrics collectors

## Install

### Collectors

Install the collectors with the provided playbook.

```shell script
ansible-playbook -i "<host-ip-address>," -u <user> --private-key <key-file> -K install_infrastructure.yml
```

> *Note:*
>
> - do not forget to include the comma after `<host-ip-address>`
> - default user is `ubuntu`, override it with `-u` specifying the user you created in [*Prerequisites* section](../README.md)
> - You need to configure key-based SSH access to the remote host for this to work. Specify your key file with `--private-key`.
> - `-K` requests the `sudo` password before executing

### Register data shippers on the IWF Repository

The Runtime Configurator triggers the collection and publishing of metrics.
Information about the data shippers must be included in the [IWF Repository](https://github.com/5GEVE/iwf-repository).
Edit [post_ul_data_rate_shipper.sh](post_ul_data_rate_shipper.sh),
[post_dl_data_rate_shipper.sh](post_dl_data_rate_shipper.sh), and
[post_tcp_avg_rtt_shipper.sh](post_tcp_avg_rtt_shipper.sh) and change the information at the beginning of the files.

```shell script
IWFREPO_HOST=localhost
IWFREPO_PORT=8087
SITE_ID=1

dataShipperId=ITALY_TURIN.BANDWIDTH.data-rate
ipAddress=10.50.7.24
username=root
password=password
captureInterface=ens4
```

> *Note:*
>
> - The `SITE_ID` is the site you want to associate the data shipper to. You can get sites' IDs by issuing a GET request to the IWF Repository on `/sites` path.
> - The `captureInterface` is the network interface to capture traffic from. It should have visibility on the site's user data plane.

## More information on collectors

### [collect_data_rate.sh](collect_data_rate.sh)

Script to collect data rate.
Traffic can be filtered by host and port.
Run `./collect_data_rate.sh -h` for available options.

*Requirements:*

- Install Tshark: `sudo apt install tshark`
- Add your user to `wireshark` group: `gpasswd -a $USER wireshark`
- Install Basic Calculator and GNU Awk: `sudo apt install bc gawk`

### [collect_tcp_avg_rtt.sh](collect_tcp_avg_rtt.sh)

Script to collect the average ACK RTT of TCP connections.
Traffic can be filtered by host and port.
Run `./collect_tcp_avg_rtt.sh -h` for available options.

The script relies on `tcp.analysis.ack_rtt` field computed by Tshark.
Field `tcp.analysis.initial_rtt` could also be used, computing the RTT only on TCP handshake (usually producing fewer samples).

*Requirements:*

- Install Tshark: `sudo apt install tshark`
- Add your user to `wireshark` group: `gpasswd -a $USER wireshark`
- Install Basic Calculator and GNU Awk: `sudo apt install bc gawk`

### Testing collectors locally

To test the script, let's generate some traffic.
Open a terminal and run:

```shell script
nc -vvlnp 12345 >/dev/null
```

The above will listen for incoming traffic.
`12345` is the port number.

Open another terminal and run:

```shell script
dd if=/dev/zero bs=1M | nc -vvn 127.0.0.1 12345
```

The above will send traffic to the previously created endpoint.

Run the script to collect traffic and compute data rate:

```shell script
./collect_data_rate.sh -i lo -p 12345 -a 127.0.0.1 -t 3 -o output/data-rate.csv -v
```


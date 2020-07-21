# datashipper-turin

A collection of scripts to collect and publish infrastructure metrics on the 5G EVE platform.

## collect-data-rate.sh

Script to collect data rate for a use-case.
Traffic can be filtered by host and port.
Run `./collect-data-rate.sh -h` for available options.

*Requirements:*
- Install Tshark: `sudo apt install tshark`
- Add your user to `wireshark` group: `gpasswd -a $USER wireshark`
- Install Basic Calculator and GNU Awk: `sudo apt install bc gawk`

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
./collect-data-rate.sh -i lo -p 12345 -a 127.0.0.1 -d 3 -o output/data-rate.csv -v
```

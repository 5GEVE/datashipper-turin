# Application metrics collectors

## Install

### Collectors

Install the collectors with the provided playbook.
See [*Prerequisites* section](../README.md).

```shell script
ansible-playbook -i "<host-ip-address>," \
    -e 'ansible_ssh_user=<user>' \
    -e 'datashipper_password=<your-hashed-password>' \
    --private-key <key-file> \
    -K install_application.yml
```

> *Note:*
>
> - do not forget to include the comma after `<host-ip-address>`
> - Use `--private-key` to specify your SSH key file.
> - `-K` requests the `sudo` password before executing

### Use the TestCase Blueprint template

[tcb_template.yaml](tcb_template.yaml) provides a TCB example to be onboarded on the 5G EVE portal.
It shows the integration of the data shipper with topics generated by 5G EVE and parameters.

> Note: check IP addresses

To onboard the blueprint on the portal you need to convert it to JSON.
To convert from YAML to JSON you can use `yq` ([yq on GitHub](https://github.com/kislyuk/yq),
[docs](https://kislyuk.github.io/yq/)).

```shell script
yq . tcb_template.yaml > tcb_template.json
```

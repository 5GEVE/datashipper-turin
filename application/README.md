# Application metrics collectors

## Install

### Collectors

Install the collectors with the provided playbook.

> Note: You need to configure key-based SSH access to the remote host for this to work.

```shell script
ansible-playbook -i "<host-ip-address>," -u <user> -K install_application.yml
```

> *Note:*
>
> - do not forget to include the comma after `<host-ip-address>`
> - default user is `ubuntu`, override it with `-u`
> - request for `sudo` password is prompted by `-K`

### Use the TestCase Blueprint template
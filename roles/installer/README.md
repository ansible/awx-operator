AWX
=======

This role builds and maintains an Ansible Tower instance inside of Kubernetes.

Requirements
------------

TODO.

Role Variables
--------------

See `defaults/main.yml` for all the role variables that you can override.

TODO: add variable description table.

To customize the pg_dump command that will be executed during migration use the `pg_dump_suffix` variable. This variable will append your provided pg_dump parameters to the end of the 'standard' command. For example to exclude the data from 'main_jobevent' and 'main_job' to decrease the size of the backup use:

```
pg_dump_suffix: "--exclude-table-data 'main_jobevent*' --exclude-table-data 'main_job'"
```

Dependencies
------------

N/A

Example Playbook
----------------

    - hosts: localhost
      connection: local
      roles:
         - installer

License
-------

MIT / BSD

# Copyright (c) 2017 Ansible Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.errors import AnsibleFilterError

__ERROR_MSG = "Not a valid cpu value. Cannot process value"

class FilterModule(object):
    def filters(self):
        return {
            'cpu_string_to_decimal': self.cpu_string_to_decimal
        }
    def cpu_string_to_decimal(self, cpu_string):

        # verify if task_output is a dict
        if not isinstance(cpu_string, str):
            raise AnsibleFilterError(__ERROR_MSG)

        if cpu_string[-1] == 'm':
            cpu = int(cpu_string[:-1])//1000
        else:
         cpu = int(cpu_string)

        return cpu

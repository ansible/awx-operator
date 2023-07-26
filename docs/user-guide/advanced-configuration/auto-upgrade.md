#### Auto upgrade
With this parameter you can influence the behavior during an operator upgrade.  
If set to `true`, the operator will upgrade the specific instance directly.  
When the value is set to `false`, and we have a running deployment, the operator will not update the AWX instance.  
This can be useful when you have multiple AWX instances which you want to upgrade step by step instead of all at once.  


| Name         | Description                        | Default |
| -------------| ---------------------------------- | ------- |
| auto_upgrade | Automatic upgrade of AWX instances | true    |

Example configuration of `auto_upgrade` parameter

```yaml
  spec:
    auto_upgrade: true
```

##### Upgrade of instances without auto upgrade

There are two ways to upgrade instances which are marked with the 'auto_upgrade: false' flag.  

Changing flags:

- change the auto_upgrade flag on your AWX object to true  
- wait until the upgrade process of that instance is finished
- change the auto_upgrade flag on your AWX object back to false  

Delete the deployment:

- delete the deployment object of your AWX instance  
```
$ kubectl -n awx delete deployment <yourInstanceName> 
```
- wait until the instance gets redeployed  

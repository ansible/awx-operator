'''
After generating the CSV file, inject custom configuration such as
OLM parameters, relatedImages, etc.
'''

import yaml

csv_path = "../../../bundle/manifests/awx-operator.clusterserviceversion.yaml"
existing_csv = open(csv_path, 'r')
csv = yaml.safe_load(existing_csv)


raw_olm_params = open("olm-parameters.yaml")
olm_params = yaml.safe_load(raw_olm_params)

# Inject OLM parameters for Customer Resource Objects
csv['spec']['customresourcedefinitions']['owned'] = olm_params

csv['metadata']['annotations']['alm-examples'] = ''

file_content = yaml.safe_dump(csv, default_flow_style=False, explicit_start=True)

with open(csv_path, 'w') as f:
    f.write(file_content)

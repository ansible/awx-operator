# Changelog

This is a list of high-level changes for each release of `awx-operator`. A full list of commits can be found at `https://github.com/ansible/awx-operator/releases/tag/<version>`.

# 0.19.0 (Mar 23, 2022)

- Fix corrupted spec for the service with nodeport type (kurokobo) - dbaf64e
- Add ability to deploy with OLM & added logo (Christian Adams) - 86c31a4
- Fix backup & restore issues with special characters in the postgres password (kurokobo) - 589a375
- Use centos:stream8 container where applicable (Shane McDonald)- 12a58d7

# 0.14.0 (Oct 03, 2021)

- Starting with awx-operator 0.14.0, the project is now based on operator-sdk 1.x.
  - To avoid a headache, you probably want to delete your existing operator Deployment and follow the README.
- Starting with awx-operator 0.14.0, AWX can only be deployed in the namespace that the operator exists in. See [upgrade docs](./README.md#upgrading) for necessary cleanup actions. (Christian Adams) - 58c3ebf (breaking change)

# 0.10.0 (Jun 1, 2021)

- Make tower_ingress_type to respect ClusterIP definition (Marcelo Moreira de Mello) - e37c091 (breaking_change)
- Add ability to get/create/delete secrets for the awx service account (Christian M. Adams) - 61b3cb4
- Added ability to specify annotations to ServiceAccount (Marcelo Moreira de Mello) - 446ac0b
- Do not shadow other variables (Yanis Guenane) - 223fe98
- Do not prepend variables name with tower_ (Yanis Guenane) - 75458d0 (breaking_change)
- Fully remove finalizer (Christian M. Adams) - fd92050
- Use custom pg_dump format for faster restores (Christian M. Adams) - f16d9ac
- Allow user to specify empty string for storage class on PVC (Christian M. Adams) - 818b837
- Unset ownerRefs in the installer instead of the finalizer (Christian M. Adams) - c12a1f0
- Make awx-operator compatible with Ansible 2.12 (Alan Rominger) - 5216489
- Restore: set proper kind var after deploying AWX CR (Julen Landa Alustiza) - fc4687f
- Add support for custom service labels (Jeremy Kimber) - fd42802
- Rename product specific variable names (Christian M. Adams) - 5ae3636 (breaking_change)
- Add watcher for backup CR (Christian M. Adams) - fdcc745

# 0.9.0 (May 1, 2021)

- Update playbook to allow for deploying custom image version/tag (Shane McDonald) - 77e7039
- Mounts /var/lib/awx/projects on awx-web container (Marcelo Moreira de Mello) - f21ec4d
- Extra Settings: Allow one to pass extra API configuration settings. (Yanis Guenane) - 1d14ebc
- PostgreSQL: Properly handle variable name difference when using Red Hat containers (Yanis Guenane) - 2965a90
- Deployment type: Make more fields dynamic based on that field (Yanis Guenane) - 4706aa9
- Add templated EE volume mount var to operator config (Christian M. Adams) - e55d83f
- Add NodePort to tower_ingress_type enum (TheStally) - 96b878f
- Split container image and version in 2 variables (Marcelo Moreira de Mello) - bc34758 (breaking_change)
- Handles deleting and recreating statefulset and deployment when needed (Marcelo Moreira de Mello) - 597356f
- Add tower_ingress_type NodePort (stal) - 1b87616
- expose settings to use custom volumes and volume mounts (Gabe Muniz) - 8d65b84
- Inherit imagePullPolicy to redis container (Marcelo Moreira de Mello) - 83a85d1
- Add nodeSelector and tolerations for Postgres pod (Ernesto Pérez) - 151ff11
- Added support to override pg_sslmode (Marcelo Moreira de Mello) - 298d39c

# Changelog

This is a list of high-level changes for each release of `awx-operator`. A full list of commits can be found at `https://github.com/ansible/awx-operator/releases/tag/<version>`.

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

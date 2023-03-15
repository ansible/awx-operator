# Debugging Helm Chart Release issues

This doc is mainly focused on debugging release automation issues involving helm charts.


### Useful commands for debugging helm chart issues:

Check if helm charts are installed and delete if needed

```
$ helm list
$ helm uninstall awx-operator
```

Add awx-operator helm repo, update and list available charts

```
$ helm repo add awx-operator https://ansible.github.io/awx-operator/
$ helm repo update
$ helm search repo awx-operator -l
```

Install a specific awx-operator helm chart version in a specific namespace

```
helm install my-awx-operator awx-operator/awx-operator -n awx --create-namespace -f my-values.yml --version 1.3.0
```

### Running helm-release playbook

If the helm release automation fails, sometimes it may be necessary to re-run and debug the release playbook.  Here is how to run it:

```
ansible-playbook ansible/helm-release.yml -v  \
-e operator_image=quay.io/ansible/awx-operator  \
-e chart_owner=ansible  \
-e tag=1.3.0  \
-e gh_token=$GH_TOKEN  \
-e gh_user=rooftopcellist
```

If you need to replace an existing asset, you need to first delete the existing one.  This can be done with the GitHub API:

```
# Find the ASSET_ID by querying the API for that release
export RELEASE=1.3.0
curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GH_TOKEN"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/ansible/awx-operator/releases/$RELEASE/assets


# With the ASSET_ID from the previous step, you can now delete the existing release asset
export ASSET_ID=98285xxx
curl -L \
  -X DELETE \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GH_TOKEN"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/ansible/awx-operator/releases/assets/$ASSET_ID
```

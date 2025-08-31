# Testing Service Configurations

This document describes the comprehensive test suite for AWX Operator service configurations, covering the recent improvements to the service template.

## Test Coverage

The service configuration tests validate:

### 1. Service Types
- **ClusterIP** (default): Standard internal cluster access
- **NodePort**: External access via node ports with custom port configuration
- **LoadBalancer**: Cloud provider load balancer with HTTP/HTTPS protocols
- **Route Passthrough**: OpenShift route with TLS passthrough

### 2. Critical Bug Fixes
- **LoadBalancer Field Name**: Validates the critical fix from `loadbalancerip` → `loadBalancerIP`
- **YAML Indentation**: Ensures proper service labels and annotations formatting
- **Template Validation**: Tests variable validation for preventing misconfigurations

### 3. Configuration Options
- Custom service labels and annotations
- LoadBalancer IP assignment and class specification
- NodePort custom port assignment with range validation
- Route passthrough HTTPS port configuration

## Running Tests

### Method 1: Molecule Test Suite (Recommended for CI/CD)

Run the full Molecule test suite which includes service configuration tests:

```bash
# Run all tests including service configuration
molecule test

# Run only the verify phase (includes service tests)
molecule verify
```

### Method 2: Standalone Service Template Tests

Run the standalone test playbook for quick validation:

```bash
# Requires kubectl access to a Kubernetes cluster
ansible-playbook test_service_template.yml

# With specific Kubernetes context
KUBECONFIG=~/.kube/config ansible-playbook test_service_template.yml
```

### Method 3: Individual Test Components

Run specific test components from the Molecule tasks:

```bash
# Template unit tests (no cluster required)
ansible-playbook molecule/default/tasks/service_template_unit_test.yml

# Configuration integration tests (requires cluster)
ansible-playbook molecule/default/tasks/service_configuration_test.yml
```

## Test Scenarios

### ClusterIP Service Test
```yaml
spec:
  service_type: ClusterIP
  service_labels: |
    app: awx
    tier: web
  service_annotations: |
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

**Validates:**
- ✅ Service type is correctly set to ClusterIP
- ✅ HTTP port (80 → 8052) is configured
- ✅ Custom labels and annotations are applied
- ✅ Proper YAML indentation

### NodePort Service Test
```yaml
spec:
  service_type: NodePort
  nodeport_port: 30080
```

**Validates:**
- ✅ Service type is correctly set to NodePort  
- ✅ Custom NodePort is assigned (30080)
- ✅ Port range validation (30000-32767)
- ✅ HTTP port configuration

### LoadBalancer Service Test
```yaml
spec:
  service_type: LoadBalancer
  loadbalancer_port: 8080
  loadbalancer_protocol: http
  loadbalancer_ip: "192.168.1.100"
  loadbalancer_class: "nginx"
```

**Validates:**
- ✅ **Critical Fix**: `loadBalancerIP` field (not `loadbalancerip`)
- ✅ Custom port and protocol configuration
- ✅ LoadBalancer class specification
- ✅ IP address assignment
- ✅ Required field validation

### LoadBalancer HTTPS Test
```yaml
spec:
  service_type: LoadBalancer
  loadbalancer_port: 8443
  loadbalancer_protocol: https
```

**Validates:**
- ✅ HTTPS protocol port naming
- ✅ Secure port configuration
- ✅ Target port mapping (8443 → 8052)

### Route Passthrough Test
```yaml
spec:
  service_type: ClusterIP
  ingress_type: route
  route_tls_termination_mechanism: passthrough
```

**Validates:**
- ✅ Additional HTTPS port (443 → 8053) for passthrough
- ✅ Both HTTP and HTTPS ports available
- ✅ Correct target port for TLS passthrough

### Validation Error Tests

**Invalid NodePort Range:**
```yaml
spec:
  service_type: NodePort
  nodeport_port: 25000  # Below valid range
```

**Expected Result:** `❌ Template fails with validation error`

**Missing LoadBalancer Port:**
```yaml
spec:
  service_type: LoadBalancer
  # Missing loadbalancer_port
```

**Expected Result:** `❌ Template fails with validation error`

## Test Architecture

### Integration Tests (`service_configuration_test.yml`)
- Creates actual Kubernetes resources
- Validates service deployment in cluster
- Tests real-world scenarios with AWX CR objects
- Includes cleanup and error handling

### Unit Tests (`service_template_unit_test.yml`)
- Tests Jinja2 template rendering
- Validates YAML output structure
- Tests template validation logic
- Fast execution without cluster dependency

### Standalone Tests (`test_service_template.yml`)
- Comprehensive end-to-end testing
- Combines template and integration testing
- Easy to run for development validation
- Clear pass/fail reporting

## Expected Test Results

All tests should pass with these success messages:

```
✅ ClusterIP service test passed
✅ LoadBalancer service test passed - loadBalancerIP field correctly set
✅ NodePort service test passed
✅ NodePort validation test passed - invalid range caught
✅ LoadBalancer validation test passed - missing port caught
🎉 All service template tests passed!
```

## Troubleshooting Test Failures

### Common Issues

**Template Validation Failures:**
- Ensure variables are properly defined
- Check YAML syntax in test configurations
- Verify Jinja2 template syntax

**Kubernetes Resource Failures:**
- Ensure cluster connectivity
- Check namespace permissions
- Verify kubectl/kubeconfig setup

**LoadBalancer Field Issues:**
- Confirm `loadBalancerIP` field is correctly capitalized
- Validate LoadBalancer class support in cluster
- Check cloud provider LoadBalancer configuration

### Debug Commands

```bash
# Check rendered templates
cat /tmp/*service.yaml

# Verify Kubernetes resources
kubectl get svc -n awx-service-test

# Check service details
kubectl describe svc test-loadbalancer-service -n awx-service-test

# View test logs
molecule --debug verify
```

## Contributing

When adding new service configuration features:

1. **Add template tests** in `service_template_unit_test.yml`
2. **Add integration tests** in `service_configuration_test.yml` 
3. **Update standalone tests** in `test_service_template.yml`
4. **Document the feature** in this testing guide
5. **Verify all test scenarios** pass before submitting PR

This ensures comprehensive coverage and prevents regressions in service configuration functionality.
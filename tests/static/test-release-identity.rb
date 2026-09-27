#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

ROOT = File.expand_path("../..", __dir__)

def fail_test(message)
  warn "FAIL: #{message}"
  exit 1
end

def assert(condition, message)
  fail_test(message) unless condition
end

def environment(path)
  File.readlines(path, chomp: true).each_with_object({}) do |line, values|
    next if line.empty? || line.start_with?("#")

    key, value = line.split("=", 2)
    values[key] = value
  end
end

config = environment(File.join(ROOT, "config/platform.env.example"))
release = YAML.load_file(File.join(ROOT, "releases/v0.5.0-release-manifest.yaml")).fetch("release")

assert(release.fetch("version") == "v0.5.0", "release candidate version must be v0.5.0")
assert(release.dig("platform", "intended_tag") == "v0.5.0", "platform intended tag must be v0.5.0")
assert(!release.fetch("platform").key?("commit"), "release candidate must not embed a platform commit")
assert(!release.fetch("platform").key?("final_commit"), "release candidate must not embed a circular final commit")

assert(release.dig("gitops", "repository") == config.fetch("GITOPS_REPOSITORY_URL"), "GitOps repository changed")
assert(release.dig("gitops", "tag") == "v0.5.0", "GitOps tag must be v0.5.0")
assert(release.dig("gitops", "commit") == "16f648ab945fa6efdf5b291ac2ef54161e70e136", "GitOps commit changed")
assert(release.dig("gitops", "annotated_tag_object") == "09d0351f5cb2f0ef89279156af906628903e90d5", "GitOps annotated tag object changed")

assert(release.dig("service_a", "image").end_with?(config.fetch("SERVICE_A_IMAGE_DIGEST")), "Service A digest changed")
assert(release.dig("argocd", "version") == config.fetch("ARGOCD_VERSION"), "Argo CD version changed")
assert(release.dig("argocd", "manifest_sha256") == config.fetch("ARGOCD_INSTALL_MANIFEST_SHA256"), "Argo manifest checksum changed")
assert(release.dig("kind", "image") == config.fetch("KIND_NODE_IMAGE"), "kind node image changed")

assert(release.dig("trust_boundary", "repository_contract") == "SOURCE-CONFIRMED", "GP-2A repository evidence label changed")
assert(release.dig("trust_boundary", "static_policy") == "TEST-VERIFIED", "GP-2A static evidence label changed")
assert(release.dig("trust_boundary", "argocd_enforcement") == "RUNTIME-VERIFIED", "GP-2A runtime evidence changed")

assert(release.dig("workload_security", "repository_contract") == "SOURCE-CONFIRMED", "GP-3 repository evidence label changed")
assert(release.dig("workload_security", "static_policy") == "TEST-VERIFIED", "GP-3 static evidence label changed")
assert(release.dig("workload_security", "runtime_enforcement") == "RUNTIME-VERIFIED", "GP-3 runtime evidence changed")
assert(release.dig("workload_security", "pod_security_context") == {
  "run_as_non_root" => true,
  "run_as_user" => 10_001,
  "seccomp_profile" => "RuntimeDefault"
}, "GP-3 Pod security context changed")
assert(release.dig("workload_security", "service_account") == {
  "name" => "service-a",
  "namespace" => "dev",
  "automount_service_account_token" => false,
  "ownership" => "platform",
  "rbac_bindings" => []
}, "GP-3 ServiceAccount contract changed")
assert(release.dig("workload_security", "pod_security_admission") == {
  "namespace" => "dev",
  "level" => "restricted",
  "version" => "v1.36",
  "modes" => %w[enforce audit warn],
  "runtime_enforcement" => "RUNTIME-VERIFIED"
}, "GP-3 Pod Security Admission contract changed")

assert(release.dig("trust_boundary", "workload_project", "namespaced_resources") == [
  "apps/Deployment", "core/Service", "core/ConfigMap"
], "workload AppProject contract broadened")
assert(release.dig("trust_boundary", "workload_project", "cluster_resources") == [], "workload AppProject gained cluster authority")
assert(release.dig("workload_security", "identity_project", "namespaced_resources") == ["core/ServiceAccount"], "identity AppProject contract broadened")
assert(release.dig("workload_security", "identity_project", "cluster_resources") == [], "identity AppProject gained cluster authority")

assert(release.dig("resource_governance", "repository_contract") == "SOURCE-CONFIRMED", "GP-4 repository evidence label changed")
assert(release.dig("resource_governance", "static_policy") == "TEST-VERIFIED", "GP-4 static evidence label changed")
assert(release.dig("resource_governance", "runtime_enforcement") == "RUNTIME-VERIFIED", "GP-4 runtime evidence changed")
assert(release.dig("resource_governance", "governance_project") == {
  "name" => "golden-path-dev-governance",
  "namespaced_resources" => ["core/ResourceQuota", "core/LimitRange"],
  "cluster_resources" => []
}, "GP-4 governance AppProject contract changed")
assert(release.dig("resource_governance", "resource_quota") == {
  "name" => "dev-resource-budget",
  "hard" => {
    "requests.cpu" => "250m",
    "requests.memory" => "256Mi",
    "limits.cpu" => "500m",
    "limits.memory" => "512Mi",
    "pods" => "6",
    "services" => "5",
    "configmaps" => "10"
  }
}, "GP-4 ResourceQuota contract changed")
assert(release.dig("resource_governance", "limit_range") == {
  "name" => "dev-container-boundary",
  "type" => "Container",
  "maximum" => {"cpu" => "250m", "memory" => "256Mi"},
  "defaults" => "none"
}, "GP-4 LimitRange contract changed")

applications = release.fetch("applications")
assert(applications.keys.sort == %w[dev_resource_governance root service_a service_a_identity], "Application set changed")
assert(applications.dig("root", "target_revision") == "v0.5.0", "root Application must target GitOps v0.5.0")
%w[dev_resource_governance service_a service_a_identity].each do |application|
  assert(applications.dig(application, "target_revision") == "v0.4.0", "#{application} runtime revision changed")
end

assert(release.fetch("ci_contract") == {
  "version" => "GP-5",
  "repository_contract" => "SOURCE-CONFIRMED",
  "static_policy" => "TEST-VERIFIED",
  "gitops_entrypoint" => "scripts/validate.sh",
  "platform_entrypoint" => "make ci",
  "required_checks" => {
    "gitops" => "validate",
    "platform" => "static-validation"
  },
  "remote_gitops_identity" => {
    "verification" => "TEST-VERIFIED",
    "method" => "annotated-tag-object-and-peeled-commit",
    "repository" => "https://github.com/cbssmh/golden-path-gitops.git",
    "tag" => "v0.5.0",
    "annotated_tag_object" => "09d0351f5cb2f0ef89279156af906628903e90d5",
    "peeled_commit" => "16f648ab945fa6efdf5b291ac2ef54161e70e136"
  }
}, "GP-5 CI contract evidence changed")

puts "PASS: v0.5.0 release candidate records the exact finalized GitOps identity"
puts "PASS: platform release identity remains non-circular"
puts "PASS: GP-2A, GP-3, and GP-4 runtime evidence remains RUNTIME-VERIFIED"
puts "PASS: GP-5 CI contract is SOURCE-CONFIRMED and TEST-VERIFIED / STATIC"
puts "PASS: remote GitOps annotated-tag identity evidence is TEST-VERIFIED"

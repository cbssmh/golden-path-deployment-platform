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
release = YAML.load_file(File.join(ROOT, "releases/v0.3.0-release-manifest.yaml")).fetch("release")

assert(release.fetch("version") == "v0.3.0", "release candidate version must be v0.3.0")
assert(release.dig("platform", "intended_tag") == "v0.3.0", "platform intended tag must be v0.3.0")
assert(!release.fetch("platform").key?("commit"), "release candidate must not embed a platform commit")
assert(!release.fetch("platform").key?("final_commit"), "release candidate must not embed a circular final commit")

assert(release.dig("gitops", "repository") == config.fetch("GITOPS_REPOSITORY_URL"), "GitOps repository changed")
assert(release.dig("gitops", "tag") == "v0.3.0", "GitOps tag must be v0.3.0")
assert(release.dig("gitops", "commit") == "7ca762c380cecc47af922344abe268c84bb398e4", "GitOps commit changed")
assert(release.dig("gitops", "annotated_tag_object") == "232b0a8b8959c8447f5d0e809f40d350148fe198", "GitOps annotated tag object changed")

assert(release.dig("service_a", "image").end_with?(config.fetch("SERVICE_A_IMAGE_DIGEST")), "Service A digest changed")
assert(release.dig("argocd", "version") == config.fetch("ARGOCD_VERSION"), "Argo CD version changed")
assert(release.dig("argocd", "manifest_sha256") == config.fetch("ARGOCD_INSTALL_MANIFEST_SHA256"), "Argo manifest checksum changed")
assert(release.dig("kind", "image") == config.fetch("KIND_NODE_IMAGE"), "kind node image changed")

assert(release.dig("workload_security", "repository_contract") == "SOURCE-CONFIRMED", "GP-3 repository evidence label changed")
assert(release.dig("workload_security", "static_policy") == "TEST-VERIFIED", "GP-3 static evidence label changed")
assert(release.dig("workload_security", "runtime_enforcement") == "NOT RUNTIME-VERIFIED", "GP-3 runtime evidence must remain unverified")
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
  "runtime_enforcement" => "NOT RUNTIME-VERIFIED"
}, "GP-3 Pod Security Admission contract changed")

assert(release.dig("trust_boundary", "workload_project", "namespaced_resources") == [
  "apps/Deployment", "core/Service", "core/ConfigMap"
], "workload AppProject contract broadened")
assert(release.dig("trust_boundary", "workload_project", "cluster_resources") == [], "workload AppProject gained cluster authority")
assert(release.dig("workload_security", "identity_project", "namespaced_resources") == ["core/ServiceAccount"], "identity AppProject contract broadened")
assert(release.dig("workload_security", "identity_project", "cluster_resources") == [], "identity AppProject gained cluster authority")

applications = release.fetch("applications")
assert(applications.values.all? { |application| application.fetch("target_revision") == "v0.3.0" }, "all GP-3 Applications must target v0.3.0")

puts "PASS: v0.3.0 release candidate records the exact finalized GitOps identity"
puts "PASS: platform release identity remains non-circular"
puts "PASS: GP-3 workload security is SOURCE-CONFIRMED and TEST-VERIFIED / STATIC"
puts "PASS: GP-3 runtime enforcement remains NOT RUNTIME-VERIFIED"

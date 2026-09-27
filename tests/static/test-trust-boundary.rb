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

def rendered_document(path, substitutions)
  text = File.read(path)
  substitutions.each { |placeholder, value| text = text.gsub(placeholder, value) }
  docs = YAML.load_stream(text).compact
  assert(docs.length == 1, "#{path} must contain exactly one YAML document")
  docs.first
end

config = environment(File.join(ROOT, "config/platform.env.example"))
substitutions = {
  "__ARGOCD_NAMESPACE__" => config.fetch("ARGOCD_NAMESPACE"),
  "__GITOPS_REPOSITORY_URL__" => config.fetch("GITOPS_REPOSITORY_URL"),
  "__GITOPS_TARGET_REVISION__" => config.fetch("GITOPS_TARGET_REVISION"),
  "__GITOPS_ROOT_PATH__" => config.fetch("GITOPS_ROOT_PATH")
}

platform = rendered_document(File.join(ROOT, "bootstrap/argocd/platform-project.yaml"), substitutions)
platform_spec = platform.fetch("spec")
assert(platform.dig("metadata", "name") == "golden-path-platform", "unexpected platform project name")
assert(platform.dig("metadata", "namespace") == "argocd", "platform project must live in argocd")
assert(platform_spec.fetch("sourceRepos") == ["https://github.com/cbssmh/golden-path-gitops.git"], "platform source repository must be exact")
assert(platform_spec.fetch("destinations") == [{"server" => "https://kubernetes.default.svc", "namespace" => "argocd"}], "platform destination must be in-cluster argocd only")
namespace_kinds = platform_spec.fetch("namespaceResourceWhitelist").map { |item| [item.fetch("group"), item.fetch("kind")] }.sort
expected_namespace_kinds = [["argoproj.io", "Application"], ["argoproj.io", "AppProject"]].sort
assert(namespace_kinds == expected_namespace_kinds, "platform namespaced whitelist is broader than approved")
assert(platform_spec.fetch("clusterResourceWhitelist") == [{"group" => "", "kind" => "Namespace", "name" => "dev"}], "platform cluster whitelist must contain only Namespace/dev")

default_project = rendered_document(File.join(ROOT, "bootstrap/argocd/default-project.yaml"), substitutions)
default_spec = default_project.fetch("spec")
assert(default_project.dig("metadata", "name") == "default", "default lockdown must target the default project")
assert(default_spec.fetch("sourceRepos") == [], "default project still permits a source repository")
assert(default_spec.fetch("sourceNamespaces") == [], "default project still permits source namespaces")
assert(default_spec.fetch("destinations") == [], "default project still permits a destination")
assert(default_spec.fetch("clusterResourceWhitelist") == [], "default project still permits a cluster resource")
assert(default_spec.fetch("namespaceResourceBlacklist") == [{"group" => "*", "kind" => "*"}], "default project must deny all namespaced resources")

root_application = rendered_document(File.join(ROOT, "bootstrap/argocd/root-application.yaml"), substitutions)
assert(root_application.dig("spec", "project") == "golden-path-platform", "root Application must use golden-path-platform")
assert(root_application.dig("spec", "source", "repoURL") == config.fetch("GITOPS_REPOSITORY_URL"), "root source repository changed")
assert(root_application.dig("spec", "source", "targetRevision") == "v0.5.0", "root must target v0.5.0")
assert(root_application.dig("spec", "destination") == {"server" => "https://kubernetes.default.svc", "namespace" => "argocd"}, "root destination changed")
assert(root_application.dig("spec", "syncPolicy", "automated") == {"prune" => true, "selfHeal" => false}, "root prune/selfHeal policy changed")
assert(!root_application.dig("spec", "syncPolicy").key?("syncOptions"), "root must not use CreateNamespace")
assert(root_application.dig("spec", "project") != "default", "a current Application still uses the default project")

release_manifest = YAML.load_file(File.join(ROOT, "releases/v0.2.0-release-manifest.yaml")).fetch("release")
assert(release_manifest.fetch("version") == "v0.2.0", "release manifest version changed")
assert(release_manifest.dig("gitops", "repository") == config.fetch("GITOPS_REPOSITORY_URL"), "release GitOps repository changed")
assert(release_manifest.dig("gitops", "tag") == "v0.2.0", "release GitOps tag changed")
assert(release_manifest.dig("gitops", "commit") == "cbd5ad7de7d73b93859e019f5d2a34705917c477", "release GitOps commit changed")
assert(release_manifest.dig("service_a", "image").end_with?(config.fetch("SERVICE_A_IMAGE_DIGEST")), "release Service A digest changed")
assert(release_manifest.dig("argocd", "version") == config.fetch("ARGOCD_VERSION"), "release Argo CD version changed")
assert(release_manifest.dig("argocd", "manifest_sha256") == config.fetch("ARGOCD_INSTALL_MANIFEST_SHA256"), "release Argo manifest digest changed")
assert(release_manifest.dig("kind", "image") == config.fetch("KIND_NODE_IMAGE"), "release kind image changed")
assert(release_manifest.dig("trust_boundary", "repository_contract") == "SOURCE-CONFIRMED", "repository evidence label changed")
assert(release_manifest.dig("trust_boundary", "static_policy") == "TEST-VERIFIED", "static evidence label changed")
assert(release_manifest.dig("trust_boundary", "argocd_enforcement") == "NOT RUNTIME-VERIFIED", "runtime evidence label changed")
assert(!release_manifest.fetch("platform").key?("final_commit"), "release manifest must not embed a circular platform commit")

apply_script = File.read(File.join(ROOT, "bootstrap/argocd/apply-platform-projects.sh"))
platform_position = apply_script.index("platform-project.yaml")
guard_position = apply_script.index('default_applications="$(')
default_position = apply_script.index("default-project.yaml")
assert(
  platform_position && guard_position && default_position &&
    platform_position < guard_position && guard_position < default_position,
  "replacement project, default-project safety check, and lockdown are out of order"
)
assert(apply_script.include?('@.spec.project=="default"'), "default lockdown must guard against existing Applications that still use default")

bootstrap_script = File.read(File.join(ROOT, "scripts/bootstrap-platform.sh"))
install_position = bootstrap_script.index("bootstrap/argocd/install.sh")
projects_position = bootstrap_script.index("bootstrap/argocd/apply-platform-projects.sh")
root_position = bootstrap_script.index("bootstrap/argocd/apply-root-application.sh")
assert(
  install_position && projects_position && root_position &&
    install_position < projects_position && projects_position < root_position,
  "bootstrap must install Argo CD, apply project restrictions, then apply root"
)

puts "PASS: golden-path-platform permissions match the approved narrow contract"
puts "PASS: default AppProject has no source, destination, or workload deployment authority"
puts "PASS: root Application uses golden-path-platform and preserves prune=true/selfHeal=false"
puts "PASS: v0.2.0 release inputs record exact GitOps identity without a circular platform commit"
puts "PASS: replacement project is created before the default project is restricted"
puts "PASS: default lockdown refuses to strand an existing default-project Application"
puts "PASS: bootstrap order is Argo CD install, project lockdown sequence, then root Application"
puts "PASS: platform GP-2A trust-boundary policy is TEST-VERIFIED / STATIC"

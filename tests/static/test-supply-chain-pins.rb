# frozen_string_literal: true

require 'json'
require 'pathname'

root = Pathname.new(__dir__).join('../..').expand_path
workflow = root.join('.github/workflows/ci.yml').read
installer = root.join('scripts/install-ci-tools.sh').read
versions = root.join('ci/tool-versions.env').read
requirements = root.join('ci/requirements.txt').read
package_lock = JSON.parse(root.join('ci/package-lock.json').read)

failures = []
workflow.scan(/^\s*- uses:\s*([^\s#]+)/).flatten.each do |reference|
  next if reference.start_with?('./')
  next if reference.match?(%r{\A[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+@[0-9a-f]{40}\z})

  failures << "external Action is not pinned to a full commit SHA: #{reference}"
end

failures << 'workflow uses ubuntu-latest' if workflow.include?('ubuntu-latest')
failures << 'workflow contains a floating latest reference' if workflow.match?(%r{releases/latest|[:/@-]latest(?:\s|$)})
failures << 'mutable ShellCheck wrapper Action remains' if workflow.include?('ludeeus/action-shellcheck')
failures << 'pip does not require dependency hashes' unless workflow.include?('--require-hashes')
failures << 'npm does not use the committed lock' unless workflow.include?('npm ci --ignore-scripts --prefix ci')
failures << 'installer contains curl-to-tar execution' if installer.match?(/curl[^\n]*\|\s*tar/)
failures << 'installer does not fail on checksum mismatch' unless installer.include?('checksum mismatch')
unless system({ 'SC1_CHECKSUM_SELF_TEST' => '1' }, '/usr/bin/env', 'bash',
              root.join('scripts/install-ci-tools.sh').to_s,
              out: File::NULL, err: File::NULL)
  failures << 'checksum negative self-test failed'
end

requirements.each_line.reject { |line| line.strip.empty? || line.start_with?(' ') }.each do |line|
  failures << "Python dependency is not exactly pinned: #{line.strip}" unless line.strip.match?(/\A[A-Za-z0-9_-]+==[^\s]+ \\\z/)
end
failures << 'Python dependency hashes are incomplete' unless requirements.scan('--hash=sha256:').length == 3

markdownlint = package_lock.dig('packages', 'node_modules/markdownlint-cli')
unless markdownlint && markdownlint['version'] == '0.49.1' && markdownlint['integrity']&.start_with?('sha512-')
  failures << 'markdownlint-cli is not integrity-locked at 0.49.1'
end

%w[
  KUBECTL_VERSION=v1.36.1
  SHELLCHECK_VERSION=v0.11.0
  PYTHON_VERSION=3.12.12
  NODE_VERSION=22.23.3
  RUBY_VERSION=3.3.10
  YAMLLINT_VERSION=1.38.0
  MARKDOWNLINT_CLI_VERSION=0.49.1
].each do |pin|
  failures << "missing tool pin: #{pin}" unless versions.include?(pin)
end

abort("FAIL: #{failures.join('; ')}") unless failures.empty?

puts 'PASS: SC-1 Platform supply-chain pins are enforced.'

dep 'git.managed' do
  deprecated! "2013-12-12", :method_name => "'benhoskings:git.managed'", :callpoint => false, :instead => "the core 'git' dep"
  requires 'ppa'.with('ppa:git-core/ppa')
  installs 'git'
  provides 'git >= 1.7.4.1'
end

dep 'git.src', :version do
  deprecated! "2013-12-12", :method_name => "'benhoskings:git.src'", :callpoint => false, :instead => "the core 'git' dep"
  version.default!('1.7.9')
  source "http://git-core.googlecode.com/files/git-#{version}.tar.gz"
  met? { in_path? "git >= #{version}" }
end

dep 'web repo', :path do
  deprecated! "2013-12-12", :method_name => "'benhoskings:web repo'", :callpoint => false, :instead => "'common:web repo'"
  requires [
    'web repo exists'.with(path),
    'web repo hooks'.with(path),
    'web repo always receives'.with(path),
    'bundler.gem'
  ]
  met? {
    vanity_path = path.p.sub(/^#{Etc.getpwuid(Process.euid).dir.chomp('/')}/, '~')
    log "All done. The repo's URI: " + "#{shell('whoami')}@#{shell('hostname -f')}:#{vanity_path}".colorize('underline')
    true
  }
end

dep 'web repo always receives', :path do
  deprecated! "2013-12-12", :method_name => "'benhoskings:web repo always receives'", :callpoint => false, :instead => "'common:web repo always receives'"
  requires 'web repo exists'.with(path)
  met? { cd(path) { shell?("git config receive.denyCurrentBranch") == 'ignore' } }
  meet { cd(path) { shell("git config receive.denyCurrentBranch ignore") } }
end

dep 'web repo hooks', :path do
  deprecated! "2013-12-12", :method_name => "'benhoskings:web repo hooks'", :callpoint => false, :instead => "'common:web repo hooks'"
  requires 'web repo exists'.with(path)
  met? {
    %w[pre-receive post-receive].all? {|hook_name|
      (path / ".git/hooks/#{hook_name}").executable? &&
      Babushka::Renderable.new(path / ".git/hooks/#{hook_name}").from?(dependency.load_path.parent / "git/deploy-repo-#{hook_name}")
    }
  }
  meet {
    cd path, :create => true do
      %w[pre-receive post-receive].each {|hook_name|
        render_erb "git/deploy-repo-#{hook_name}", :to => ".git/hooks/#{hook_name}"
        shell "chmod +x .git/hooks/#{hook_name}"
      }
    end
  }
end

dep 'web repo exists', :path do
  deprecated! "2013-12-12", :method_name => "'benhoskings:web repo exists'", :callpoint => false, :instead => "'common:web repo exists'"
  requires 'git'
  path.ask("Where should the repo be created").default("~/current")
  met? { (path / '.git').dir? }
  meet {
    cd path, :create => true do
      shell "git init"
    end
  }
end

dep 'github token set' do
  deprecated! "2013-12-12", :method_name => "'benhoskings:github token set'", :callpoint => false, :instead => "'common:github token set'"
  met? { !shell('git config --global github.token').blank? }
  meet { shell("git config --global github.token '#{var(:github_token)}'")}
end

dep 'git fs' do
  deprecated! "2013-12-12", :method_name => "'benhoskings:git fs'", :callpoint => false, :instead => "'common:git fs'"
  def repo
    Babushka::GitRepo.new('/')
  end
  met? {
    repo.exists?
  }
  meet {
    log_shell "Creating repo", 'git init', :cd => '/'
    Babushka::Resource.get(
      'https://raw.github.com/benhoskings/git-root/master/.gitignore'
    ) {|path|
      path.copy('/.gitignore')
    }
    repo.repo_shell('git add .gitignore')
    repo.repo_shell('git commit -m "Initial commit."')
  }
end

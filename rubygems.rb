dep 'rubygems' do
  requires 'rubygems installed', 'github source', 'gemcutter source'
  setup {
    shell('ruby --version')['ruby 1.9'].nil? || definer.requires('fake json gem')
  }
end

dep 'fake json gem' do
  met? { Babushka::GemHelper.has? 'json' }
  meet {
    log "json is now included in ruby core, and when gems try to install the"
    log "gem, it fails to build. So, let's install a fake version of json-1.1.9."
    in_build_dir {
      log_block "Generating fake json-1.1.9 gem" do
        File.open 'fake_json.gemspec', 'w' do |f|
          f << %Q{
            spec = Gem::Specification.new do |s|
              s.name = "json"
              s.version = "1.1.9"
              s.summary = "this fakes json (which is now included in stdlib)"
              s.homepage = "http://gist.github.com/gists/58071"
              s.has_rdoc = false
              s.required_ruby_version = '>= 1.9.1'
            end
          }
        end
        shell "gem build fake_json.gemspec"
      end
      Babushka::GemHelper.install! 'json-1.1.9.gem', '--no-ri --no-rdoc'
    }
  }
end

meta :gem_source do
  accepts_list_for :uri
  template {
    requires 'rubygems installed'
    met? { uri.all? {|u| shell("gem sources")[u.to_s] } }
    meet { uri.each {|u| shell "gem sources -a #{u.to_s}", :sudo => !File.writable?(which('ruby')) } }
  }
end

gem_source 'gemcutter source' do
  uri 'http://gemcutter.org'
end
gem_source 'github source' do
  uri 'http://gems.github.com'
end

dep 'rubygems installed' do
  requires 'ruby', 'curl'
  merge :versions, :rubygems => '1.3.5'
  met? { cmds_in_path? 'gem', cmd_dir('ruby') }
  meet {
    in_build_dir {
      get_source("http://rubyforge.org/frs/download.php/60718/rubygems-#{var(:versions)[:rubygems]}.tgz") and

      in_dir "rubygems-#{var(:versions)[:rubygems]}" do
        shell "ruby setup.rb", :sudo => !File.writable?(which('ruby'))
      end
    }
  }
  after {
    in_dir cmd_dir('ruby') do
      if File.exists? 'gem1.8'
        shell "ln -sf gem1.8 gem", :sudo => !File.writable?(which('ruby'))
      end
    end
  }
end
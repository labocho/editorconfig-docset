require "shellwords"

def root
  File.expand_path(File.dirname(__FILE__))
end

def sha1
  `cd #{root.shellescape}/src && git log -n 1 --format=format:%H`.strip
end

namespace "repo" do
  task "clone" do
    unless Dir.exists?("src")
      sh "git clone https://github.com/editorconfig/editorconfig.github.com.git src"
    end
  end

  task "pull" => "clone" do
    sh "cd src && git pull"
  end

  task "clean" do
    rm_rf "src"
  end
end

namespace "html" do
  desc "Build HTML to src/_site"
  task "build" => "repo:pull" do
    revision_file = "src/_site/REVISION"
    next if File.exists?(revision_file) && File.read(revision_file) == sha1

    Dir.chdir("src") do
      sh "bundle exec jekyll build"
    end
    File.write(revision_file, sha1)
  end

  task "clean" do
    rm_rf "src/_site"
  end
end

namespace "docset" do
  task "build" => "html:build" do
    revision_file = "editorconfig.docset/Contents/Resources/Documents/REVISION"
    next if File.exists?(revision_file) && File.read(revision_file) == sha1

    ruby "scripts/generate_docsets.rb"
  end

  task "install" do
    source = "editorconfig.docset"
    dest = "#{ENV["HOME"]}/Library/Application Support/Dash/DocSets/editorconfig"
    rm_rf dest
    mkdir_p dest
    cp_r source, dest
  end

  task "clean" do
    rm_rf "editorconfig.docset"
  end
end

task "clean" => ["repo:clean", "html:clean", "docset:clean"]
task "default" => "docset:build"

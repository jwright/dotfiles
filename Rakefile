require 'fileutils'

if RUBY_VERSION < "1.9.0"
  require 'bundle_list'
  require 'dotfile_list'
else
  require_relative 'bundle_list'
  require_relative 'dotfile_list'
end

desc 'Setup/update dotfile symbolic links'
task :link do
  $dotfiles.each do |path|
    linked_file = File.join(ENV["HOME"], path)
    if File.symlink?(linked_file)
      File.unlink(linked_file)
    else
      FileUtils.rm_rf(linked_file)
    end
    File.symlink(File.join(File.dirname(__FILE__), path), linked_file)
  end
end

desc 'Update Vim bundles'
task :vim do
  # Install Vim Plug to manage bundles
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  # Grab newest version of all bundles
  bundles_dir = File.join(File.dirname(__FILE__), '.vim/bundle')

  if !File.directory?(bundles_dir)
    Dir.mkdir(bundles_dir, 0755)
  end

  FileUtils.cd(bundles_dir)
  Dir["*"].each {|d| FileUtils.rm_rf d }

  $git_bundles.each do |url|
    dir = url.split('/').last.sub(/\.git$/, '')
    puts "Unpacking #{url} into #{dir}"
    `git clone #{url} #{dir}`
    FileUtils.rm_rf(File.join(dir, ".git"))
  end

  # Grab newest version of all themes
  colors_dir = File.join(File.dirname(__FILE__), '.vim/colors')

  if !File.directory?(colors_dir)
    Dir.mkdir(colors_dir, 0755)
  end

  FileUtils.cd(colors_dir)
  Dir["*"].each {|d| FileUtils.rm_rf d }

  $vim_colors.each do |url|
    puts "Downloading #{url} into colors directory"
    `wget #{url}`
  end

  if File.directory?('Command-T')
    FileUtils.cd('Command-T')
    `bundle install && rake make`
  end
end

desc 'Link dotfiles and setup vim configuration and bundles'
task :default => [:link, :vim]

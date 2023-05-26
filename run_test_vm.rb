#!/usr/bin/env ruby

require 'tty-prompt'
require 'tty-file'
require 'shellwords'

class QemuCommand
  def execute
    raise NotImplementedError, "#{self.class} has not implemented the execute method"
  end
end

class SharedPrompt
  def self.prompt
    @prompt ||= TTY::Prompt.new
  end
end

class QemuSystemCommand < QemuCommand
  def initialize(selected_iso, selected_drive,vcpus,memory)
    @selected_iso = selected_iso
    @selected_drive = selected_drive
    @vcpus = vcpus
    @memory = memory
  end

  def execute
    command = "qemu-system-x86_64 -cdrom #{@selected_iso} -cpu host -enable-kvm -m #{@memory} -smp #{@vcpus} -drive file=#{@selected_drive},format=qcow2"
    puts "Executing command: #{command}"

    # Fork the process to execute the command
    pid = fork do
      exec(command)
    end

    # Wait for the child process to finish
    Process.wait(pid)
  end
end

class VirtInstallCommand < QemuCommand
  def initialize(selected_iso, selected_drive,vcpus,memory)
    @selected_iso = selected_iso
    @selected_drive = selected_drive
    @vcpus = vcpus
    @memory = memory
  end

  def execute
    vcpus = prompt.ask('Enter the number of vCPUs:')
    memory = prompt.ask('Enter the memory size (in MB):', convert: :int)

    command = "virt-install --cdrom #{@selected_iso} --disk #{@selected_drive} --cpu host --memory #{@memory} --vcpus #{@vcpus}"
    puts "Executing command: #{command}"

    # Fork the process to execute the command
    pid = fork do
      exec(command)
    end

    # Wait for the child process to finish
    Process.wait(pid)
  end
end

class QemuImgCommand < QemuCommand
  def initialize(drive_path, size)
    @drive_path = drive_path
    @size = size
  end

  def execute
    qemu_img_command = "qemu-img create -f qcow2 #{@drive_path} #{@size}G"
    puts "Executing command: #{qemu_img_command}"

    # Fork the process to execute the command
    pid = fork do
      exec(qemu_img_command)
    end

    # Wait for the child process to finish
    Process.wait(pid)
  end
end

HOME = ENV['HOME']

iso_folder = File.join(HOME, 'otherspace', 'iso', 'out')
drive_folder = File.join(HOME, 'otherspace', 'iso')

iso_files = Dir.glob(File.join(iso_folder, '*.iso')).sort
drive_files = Dir.glob(File.join(drive_folder, '*.qcow2')).sort

prompt = TTY::Prompt.new

create_new_disk_choice = 'Create new QEMU disk'

choices = iso_files.map.with_index do |iso_file, index|
  iso_name = File.basename(iso_file)
  drive_name = File.basename(drive_files[index]) if drive_files[index]
  "#{index + 1}) #{iso_name} with #{drive_name}"
end

selection = prompt.select('Available options:', [create_new_disk_choice] + choices.compact)

if selection == create_new_disk_choice
  drive_name = prompt.ask('Enter a name for the new QEMU disk (without extension):')
  drive_name += '.qcow2'
  drive_path = File.join(drive_folder, drive_name)

  size = prompt.ask('Enter the size of the new QEMU disk (in GB):', convert: :int)

  command = QemuImgCommand.new(drive_path, size)
  command.execute

  drive_files << drive_path # Add the newly created drive to the array

  selected_iso = Shellwords.escape(prompt.select('Select ISO file:', iso_files))
  selected_drive = Shellwords.escape(prompt.select('Select drive file:', drive_files))

  vcpus = SharedPrompt.prompt.ask('Enter the number of vCPUs:')
  memory = SharedPrompt.prompt.ask('Enter the memory size (in MB):', convert: :int)

  command = QemuSystemCommand.new(selected_iso, selected_drive, vcpus, memory)
  command.execute
else
  choice_index = selection.split(')')[0].to_i - 1

  selected_iso = Shellwords.escape(iso_files[choice_index])
  selected_drive = Shellwords.escape(drive_files[choice_index])

  vcpus = SharedPrompt.prompt.ask('Enter the number of vCPUs:')
  memory = SharedPrompt.prompt.ask('Enter the memory size (in MB):', convert: :int)

  command = QemuSystemCommand.new(selected_iso, selected_drive, vcpus, memory)
  command.execute
end

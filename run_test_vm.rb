#!/usr/bin/env ruby

require 'tty-prompt'
require 'shellwords'

HOME = ENV['HOME']

iso_folder = File.join(HOME, 'otherspace', 'iso', 'out')
drive_folder = File.join(HOME, 'otherspace', 'iso')

iso_files = Dir.glob(File.join(iso_folder, '*.iso')).sort
drive_files = Dir.glob(File.join(drive_folder, '*.qcow2')).sort

prompt = TTY::Prompt.new
choices = iso_files.map.with_index do |iso_file, index|
  iso_name = File.basename(iso_file)
  drive_name = File.basename(drive_files[index])
  "#{index + 1}) #{iso_name} with #{drive_name}"
end

choices << 'Create new QEMU disk'

selection = prompt.select('Available options:', choices)

if selection == 'Create new QEMU disk'
  drive_name = prompt.ask('Enter a name for the new QEMU disk (without extension):')
  drive_name += '.qcow2'
  drive_path = File.join(drive_folder, drive_name)

  size = prompt.ask('Enter the size of the new QEMU disk (in GB):', convert: :int)
  qemu_img_command = "qemu-img create -f qcow2 #{drive_path} #{size}G"
  puts "Executing command: #{qemu_img_command}"

  # Uncomment the following line to execute the qemu-img command
  system(qemu_img_command)
else
  choice_index = selection.split(')')[0].to_i - 1

  selected_iso = Shellwords.escape(iso_files[choice_index])
  selected_drive = Shellwords.escape(drive_files[choice_index])

  command = "qemu-system-x86_64 -cdrom #{selected_iso} -cpu host -enable-kvm -m 2048 -smp 2 -drive file=#{selected_drive},format=qcow2 -nographic"
  puts "Executing command: #{command}"

  # Uncomment the following line to execute the command
  system(command)
end

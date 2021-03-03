Dir.chdir(File.dirname(__FILE__)) do

  system('rm -fr html')
  system('rdoc --op html rdoc')
  require 'fileutils'
  include FileUtils
  FileUtils.mkdir_p('tocs')

  toc_lis_by_name = {}
  Dir.chdir('html/rdoc') do
    Dir.new('.').entries.each do |html_file_path|
      next if html_file_path.start_with?('.')
      toc_lis = []
      File.open(html_file_path, 'r') do |file|
        in_toc = false
        file.each_line do |line|
          unless in_toc
            if line.include?('<ul class="link-list" role="directory">')
              in_toc = true
              next
            end
          end
          if in_toc
            break if line.include?('</ul>')
            toc_lis.push(line.chomp)
          end
        end
      end
      key = html_file_path.sub('_rdoc.html', '')
      toc_lis_by_name[key] = toc_lis
    end
  end
  File.open('tocs/master_toc.rdoc', 'w') do |master_toc_file|
    master_toc_file.write("== Table of Contents\n\n")
    Dir.chdir('tocs') do
      toc_lis_by_name.each_pair do |name, lis|
        toc_file_name = name + '_toc.rdoc'
        File.open(toc_file_name, 'w') do |class_file|
          class_file.write("Tasks on this page:\n\n")
          lis.each_with_index do |li, i|
            _, temp = li.split('"', 2)
            link, temp = temp.split('">', 2)
            text = temp.sub('</a>', '')
            indentation = text.start_with?('Task') ? '  ' : ''
            toc_entry = "#{indentation}- {#{text}}[#{link}]\n"
            if i == 0
              text = text.split(' ')[1]
              link = "tasks/#{text.downcase}_rdoc.html"
              master_toc_file.write("=== {#{text}}[#{link}]\n")
              # master_toc_file.write("=== #{text}\n\n")
              next
            end
            master_link = "tasks/#{toc_file_name.sub('_toc.rdoc', '_rdoc.html')}#{link}"
            master_toc_entry = "#{indentation}- {#{text}}[#{master_link}]\n"
            master_toc_file.write(master_toc_entry)
            class_file.write(toc_entry)
          end
          master_toc_file.write("\n")
          class_file.write("\n")
        end
      end
    end
  end
  system('rm -fr html')

end

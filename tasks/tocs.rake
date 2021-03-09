require "tmpdir"

class TOCsGenerator
  include Rake::DSL

  def generate
    doc_tasks_dir = File.join(__dir__, "..", "doc", "rexml", "tasks")
    cd(doc_tasks_dir) do
      lis_by_name = extract_lis
      generate_files(lis_by_name)
    end
  end

  private
  def extract_lis
    lis_by_name = {}
    Dir.mktmpdir do |tmpdir|
      sh("rdoc", "--op", tmpdir, "--force-output", "rdoc")
      cd("#{tmpdir}/rdoc") do
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
          lis_by_name[key] = toc_lis
        end
      end
    end
    lis_by_name
  end

  def generate_files(lis_by_name)
    File.open('tocs/master_toc.rdoc', 'w') do |master_toc_file|
      master_toc_file.write("== Tasks\n\n")
      cd('tocs') do
        entries = Dir.entries('.')
        entries.delete_if {|entry| entry.start_with?('.') }
        entries.delete_if {|entry| entry == 'master_toc.rdoc' }
        lis_by_name.keys.sort.each do |name|
          lis = lis_by_name[name]
          toc_file_name = name + '_toc.rdoc'
          entries.delete(toc_file_name)
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
                link = "../../tasks/rdoc/#{text.downcase}_rdoc.html"
                master_toc_file.write("=== {#{text}}[#{link}]\n")
                next
              end
              master_link = "../../tasks/rdoc/#{toc_file_name.sub('_toc.rdoc', '_rdoc.html')}#{link}"
              master_toc_entry = "#{indentation}- {#{text}}[#{master_link}]\n"
              master_toc_file.write(master_toc_entry)
              class_file.write(toc_entry)
            end
            master_toc_file.write("\n")
            class_file.write("\n")
          end
        end
        unless entries.empty?
          message = "Some entries not updated: #{entries}"
          raise message
        end
      end
    end
  end
end

namespace :tocs do
  desc "Generate TOCs"
  task :generate do
    generator = TOCsGenerator.new
    generator.generate
  end
end

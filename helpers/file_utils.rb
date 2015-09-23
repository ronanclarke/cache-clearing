require 'fileutils'
module FileUtils

  def log_to_file(file_type, log_text, with_process=false)

    FileUtils.mkdir_p 'logs'

    if (with_process)
      file_name = "logs/results_#{file_type}_#{@process_index}.log"
    else
      file_name = "logs/results_#{file_type}.log"
    end

    open(file_name, 'a') do |f|
      f.puts "#{log_text}"
    end


  end

  def read_file_to_array(file_name, remove_newlines = false)

    ret = []
    return ret unless (File.exists? file_name)

    f = File.open(file_name)

    f.each_line do |line|

      line.strip!

      if (remove_newlines)
        ret << line.gsub(/\n/, "")
      else

        ret << line
      end
    end

    return ret

  end


end
require 'uri'

class FileImplant
    #
    # Consts
    #
    FOOTER_SPLITER_PRE = "\r\t_pre_\r\t"
    FOOTER_SPLITER_POST = "\r\t_post_\r\t"
    PARAMS_SPLITER = "&"
    PARAM_SPLITER = "="
    TAIL_SALT = "UUDDLRLRBA"

    #
    # Assemble
    #
    def assemble files=[], output
        # check
        raise "input file is not found." if files.size <= 0
        files.each{|file|
            raise "input #{file} is not a file." if !File.exist?(file) || !File.file?(file)
        }
        # assemble
        File.open(output, 'wb'){|out|
            files.each{|file|
                size = File.size(file).to_s
                filename = File.basename(file)
                params = {size: size, filename: filename}
                out.write File.binread(file)
                out.write get_footer(params)
            }
            out.write TAIL_SALT
        }
    end

    #
    # Disassemble
    #
    def disassemble input, output
        #check1: argument
        raise "input #{input} is not a file." if !File.exist?(input) || !File.file?(input)
        raise "input #{output} is not a directory." if !File.exist?(output) || !File.directory?(output)

        input_size = File.size(input)
        File.open(input, 'rb'){|binary|
            tail_length = TAIL_SALT.length
            index, length = -tail_length, tail_length
            #check2:tail salt
            binary.seek(index, IO::SEEK_END)
            tail = binary.read(length).unpack('A*').shift
            raise "tail is not salt, is it assembled file?" if tail != TAIL_SALT
            index -= 1

            while index > -input_size do
                #
                # seek footer
                #
                pre_index, post_index = nil, nil

                ## seek footer_post
                index, length = index, FOOTER_SPLITER_POST.length
                footer_post = nil
                while footer_post != FOOTER_SPLITER_POST && index >= -input_size do
                    index -= 1
                    binary.seek(index, IO::SEEK_END)
                    footer_post = binary.read(length).unpack('A*').shift
                end
                post_index = index + length

                ## seek footer_pre
                index, length = index, FOOTER_SPLITER_PRE.length
                footer_pre = nil
                while footer_post != FOOTER_SPLITER_PRE && index >= -input_size do
                    index -= 1
                    binary.seek(index, IO::SEEK_END)
                    footer_post = binary.read(length).unpack('A*').shift
                end
                pre_index = index

                ## read footer
                footer_len = post_index - pre_index
                binary.seek(pre_index, IO::SEEK_END)
                footer = binary.read(footer_len).unpack('A*').shift

                #
                # write file
                #
                p params = read_footer(footer)
                size = params[:size].to_i
                filename = params[:filename].to_s
                filepath = File.join(output, filename)
                file_index = index -= size
                File.open(filepath, 'wb'){|out|
                    binary.seek(file_index, IO::SEEK_END)
                    out.write(binary.read(size))
                }
                puts "#{filepath} is written, size is #{size} bytes."
                index = file_index
            end
        }
    end

    #####
    # Privates
    private

    def get_footer params
        param_str = params.keys.map{|key|
            "#{key.to_s}#{PARAM_SPLITER}#{URI.escape(params[key])}"
        }.join(PARAMS_SPLITER)
        "#{FOOTER_SPLITER_PRE}#{param_str}#{FOOTER_SPLITER_POST}"
    end

    def read_footer footer
        footer.slice!(0, FOOTER_SPLITER_PRE.size) if footer.start_with?(FOOTER_SPLITER_PRE)
        footer.slice!(-FOOTER_SPLITER_POST.size, FOOTER_SPLITER_POST.size) if footer.end_with?(FOOTER_SPLITER_POST)
        footer.strip.split(PARAMS_SPLITER).map{|param|
            k, v = param.split(PARAM_SPLITER)
            [k.to_sym, URI.unescape(v)]
        }.to_h
    end

end

if $0 == __FILE__ then
    m = FileImplant.new
    usage = [
        "usage1: #{File.basename(__FILE__)} -a INPUT_FILE1 [INPUT_FILE2 ...] OUTPUT_FILE",
        "usage2: #{File.basename(__FILE__)} -d INPUT_FILE OUTPUT_DIR",
    ].join("\n")
        
    cmd = ARGV.shift
    if(cmd =~ /-?[aA]/) then
        abort(usage) if ARGV.size <= 3
        output = ARGV.pop
        m.assemble(ARGV, output)
    elsif(cmd =~ /-?[dD]/) then
        abort(usage) if ARGV.size < 2
        m.disassemble(ARGV.shift, ARGV.shift)
    else
        abort usage
    end

end
 
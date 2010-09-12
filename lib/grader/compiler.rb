module Compiler
  class Cpp
    include ShellUtils
    
    def compile(src_file, output_file, options = {})
      verbose_system "g++ #{src_file} -o #{output_file} -O2 -s -lm -x c++"
    end
  end
  
  class Java
    def compile(src_file, output_file, options = {})
      verbose_system "javac #{src_file}"
    end
  end
end

#Grader.class_eval do
#  LANG_TO_COMPILER[Run::LANG_C_CPP] = Cpp
#  LANG_TO_COMPILER[Run::LANG_PAS] = Pascal
#end
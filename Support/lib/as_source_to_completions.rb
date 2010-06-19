#!/usr/bin/env ruby -wKU

require 'fileutils'
require ENV['TM_SUPPORT_PATH']+'/lib/textmate'

# Class to convert all the files in the current TM project to files that can be
# used by the the ActionScript 3 completion engine.
#
# This should essentially strip all comments and working code from the class
# leaving the method signatures, public vars, and metadata etc in place.
#
# Logic flow.
# 1. load class.
# 2. load includes.
# 3. strip comments.
# 4. strip internal classes.
# 5. strip any trailing imports.
# 6. gather package, imports, metadata, class, properties and methods.
# 7. format and output gathered file data.
class AsSourceToCompletions

  private

  def initialize
    @class = /^\s*(((dynamic|final)\s+)?(public)\s+((dynamic|final)\s+)?(class).*(?m:[^{]+))/
    @imports = /^\s*(import\s*[\w.*]+;?)/
    @methods = /^\s*(((override|public|protected|static)\s+)?(public|protected|static)\s+function\s+((get|set)\s+)?\b\w+\b\s*\(((?m:[^)]*))\)(\s*:\s*(\w+))?)/
    @internals = /(^\s*package\s+[\w.]+(?m:[^$].*))((^(internal\s+)?class\b))/
    @interface = /^\s*public\s+(interface)\s+(\w+)\b/
    @metadata = /^(\[\s*\b(Effect|Event|Style)\b.*\])\s*$/
    @package = /^\s*(package\s+[\w.]+)(?m:[^{]+)/
    @vars = /^\s*(\b(public|protected|static)\b\s+(\b(public|protected|static)\b\s+)?\b(var|const)\b\s+\b(\w+)\b\s*:\s*((\w+)|\*))/
  end

  public

  def process_project

    bp = "/Users/simon/Desktop/mx"
    pp = ENV['TM_PROJECT_DIRECTORY']

    file_count = 0
    start_time = Time.new.to_f

    TextMate.each_text_file do |file|

      if file =~ /\.as$/

        file_count += 1

        path = file.sub( pp, "" );
        fp = bp+path

        print "\nAdding: <a href=\"txmt://open/?url=file://#{file}\">#{path}</a> "

        r = process(file)

        if r == "ERROR" or r.nil?

          print "<b>Failed</b><br/>\n"

        else

          FileUtils.mkdir_p File.dirname(fp)

          out = File.new( fp, File::WRONLY|File::TRUNC|File::CREAT )
          out.print r
          out.close

          print "<a href=\"txmt://open/?url=file://#{fp}\">OK</a><br/>\n"

        end

      end

    end

    puts "<br/><h4>Complete</h4>"
    puts "<br/>processed: #{file_count} files"
    puts "<br/>in:  #{Time.new.to_f-start_time} seconds."
  end

  def process(uri)

    fo = File.open(uri,"r" )
    f = fo.read.strip
    fo.close

    doc = load_includes(f,uri)
    doc = strip_comments(doc)
    #doc = parse(doc)

    doc.scan(@interface)
    return strip_whitespace(doc) if $1 == "interface"

    doc = strip_internals(doc)

    p = package(doc,true)
    i = imports(doc,true)
    d = metadata(doc,true)
    c = class_def(doc,true)
    m = methods(doc,true)
    v = variables(doc,true)

    return "ERROR" if p.to_s == "" or c.to_s == ""

    result = p + " {\n" + i + "\n" + d + "\n" + c.chomp + " {\n" + v + m + "\n}}"
    result = strip_whitespace(result)
    result

  end

  def parse(doc)

    doc = strip_comments(doc)

    doc.scan(@interface)
    return doc unless $1.nil?

    doc = strip_internals(doc)

    doc

  end

  def imports(doc,pre_parsed=false)

    unless pre_parsed
      doc = parse(doc)
      return if doc.nil?
    end

    imps = doc.scan(@imports)
    imps.uniq!
    doc = imps.join("\n")
    doc

  end

  def metadata(doc,pre_parsed=false)

    unless pre_parsed
      doc = parse(doc)
      return if doc.nil?
    end

    m = []
    doc.scan(@metadata) do |l,e|
      m << l
    end

    doc = m.join("\n")
    doc

  end

  def class_def(doc,pre_parsed=false)

    unless pre_parsed
      doc = parse(doc)
      return if doc.nil?
    end

    m = []
    doc.scan(@class) do |l|
      m << $1
    end

    doc = m.join("\n")
    doc

  end

  def package(doc,pre_parsed=false)

    unless pre_parsed
      doc = parse(doc)
      return if doc.nil?
    end

    m = []
    doc.scan(@package) do |l|
      m << $1
    end

    doc = m.join("\n")
    doc

  end

  def methods(doc,pre_parsed=false)

    unless pre_parsed
      doc = parse(doc)
      return if doc.nil?
    end

    m = []
    doc.scan(@methods) do |l|
      #m << $&.to_s
      m << $1.gsub(/\s\s+|\n|\t/,'')
    end

    m.each_index { |i| m[i] = m[i]+"{}" }

    doc = m.join("\n")
    doc

  end

  def variables(doc,pre_parsed=false)

    unless pre_parsed
      doc = parse(doc)
      return if doc.nil?
    end

    m = []
    doc.scan(@vars) do |l|
      m << $1.to_s
    end

    doc = m.join(";\n") + ";\n"
    doc

  end

  private

  def strip_comments(doc)

    multiline_comments = /\/\*(?:.|([\r\n]))*?\*\//
    doc.gsub!(multiline_comments) do |s|
      if $1
        r = ""
        a = s.split("\n")
        r += "\n" * (a.length-1) if a.length > 1
        r
      end
    end

    single_line_comments = /\/\/.*$/
    return doc.gsub(single_line_comments,'')

  end

  def load_includes(doc,uri)

    doc_a = doc.split("\n")

    doc_a.each_index do |i|
      line = doc_a[i]
      if line =~ /^\s*include\s+"([\w.\/]+)"/

        include_path = File.dirname(uri)+"/#{$1}"

        if File.exists?(include_path)

          include_file = File.open(include_path,"r").read.strip
          doc_a[i] = include_file.to_s

        else

          puts "WARNING: #{include_path} 404."

        end

      end
    end

    doc = doc_a.join("\n")
    doc

  end

  def strip_internals(doc)

    doc.scan(@internals)
    unless $1.nil?
      doc = $1.sub( /\}((?m:[^}]+)\Z)/, "}\n")
    end

    doc
  end

  def strip_whitespace(doc)
    doc.gsub!( /^\s*$\n^\s*$\n/, '' )
    doc.gsub!("\n\n", "\n")
    doc
  end

end

if __FILE__ == $0
    
  require "test/unit"
                     
  class TestAsSourceToCompletions < Test::Unit::TestCase

    def test_interface
      
			doc = <<-EOF
package
{
	public interface Foo{}
}
			EOF

      p = AsSourceToCompletions.new

      assert_equal(doc, p.parse(doc))

    end

    def test_internal_class

      in_doc = <<-EOF
package test
{
import org.Bar;
public class Foo {
	public function Foo(){
		
	}
}
}
import org.FooFoo
class Hidden 
{
	
}
EOF

      out_doc = <<-EOF
package test
{
import org.Bar;
public class Foo {
	public function Foo(){
		
	}
}
}
EOF
      
      p = AsSourceToCompletions.new
      
      assert_equal(out_doc, p.parse(in_doc))
    end
    
    def test_imports

      doc = <<-EOF
package test
{
import org.Bar;
import org.Foo;
import org.Baz;
public class Foo {
	public function Foo(){

	}
}
}
EOF

			imp = <<-EOF
import org.Bar;
import org.Foo;
import org.Baz;
EOF

      p = AsSourceToCompletions.new

      assert_equal(imp.chomp, p.imports(doc))

    end

    def test_metadata

      doc = <<-EOF
package test
{
import org.Bar;
import org.Baz;
[Event(name="applicationComplete", type="mx.events.FlexEvent")]
[Style(name="verticalGap", type="Number", format="Length", inherit="no")]
public class Foo {
	public function Foo(){

	}
}
}
EOF

    meta = <<-EOF
[Event(name="applicationComplete", type="mx.events.FlexEvent")]
[Style(name="verticalGap", type="Number", format="Length", inherit="no")]
EOF

      p = AsSourceToCompletions.new

      assert_equal(meta.chomp, p.metadata(doc))

    end

    def test_class_extends

      doc = <<-EOF
package test
{
import org.Bar;
[Style(name="verticalGap", type="Number", format="Length", inherit="no")]
dynamic public class Foo extends Bar,
																 Baz
{
	public function Foo(){

	}
}
}
EOF

    cla = <<-EOF
dynamic public class Foo extends Bar,
																 Baz
EOF

      p = AsSourceToCompletions.new

      assert_equal(cla, p.class_def(doc))

    end

    def test_class_extends_implements

      doc = <<-EOF
package test
{
public final class Foo
						 implements IFoo
						 extends Bar,
										 Baz,
										 FooBar
{
	public function Foo(){

	}
}

class TestInternal
{
		
}
}
EOF

      cla = <<-EOF
public final class Foo
						 implements IFoo
						 extends Bar,
										 Baz,
										 FooBar
EOF

      p = AsSourceToCompletions.new

      assert_equal(cla, p.class_def(doc))

    end

    def test_package

      doc = <<-EOF
package org.foo.bar
{
	public interface Foo{}
}
			EOF

      p = AsSourceToCompletions.new

      assert_equal("package org.foo.bar", p.package(doc))

    end

    def test_methods

      doc = <<-EOF
package org.foo.bar
{
	public class Foo{
		
		public function Foo(){
			
		}
		
		public function set hello(value:String):void
		{
			//
		}
		
		public function get hello():String
		{
			
		}
		
		public function sayFoo():String
		{
			//
		}
		
		public function printBar(foo:String,
															bar:int,
															baz:*):void
		{
			
		}
		
		public static function sayBar():Array{}
		
	}
}
			EOF
			
			result = <<-EOF
public function Foo(){}
public function set hello(value:String):void{}
public function get hello():String{}
public function sayFoo():String{}
public function printBar(foo:String,bar:int,baz:*):void{}
public static function sayBar():Array{}
EOF

      p = AsSourceToCompletions.new

      assert_equal(result.chomp, p.methods(doc))

    end

  end

end

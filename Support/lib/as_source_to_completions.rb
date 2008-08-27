#!/usr/bin/env ruby -wKU

# Class to convert all the files in the current TM project to files that can be
# used by the the ActionScript 3 completion engine.
#
# This should essentially strip all comments and working code from the class
# leaving the method signatures, public vars, and metadata etc in place.

# Logic flow. 

# 1. load class.
# 2. load includes.
# 3. strip comments.
# 4. strip internal classes.
# 5. strip any trailing imports.
# 6. gather package, imports, metadata, class, and methods.

class AsSourceToCompletions

	private
	
	def initialize
		@class = /^\s*(((dynamic|final)\s+)?(public)\s+((dynamic|final)\s+)?(class).*(?m:[^{]+))/
		@imports = /^\s*import\s*[\w.*]+;?/
		@methods = /^\s*((override\s+)?(public|protected)\s+function\s+((get|set)\s+)?\b\w+\b\s*\(((?m:[^)]*))\)\s*:\s*(\w+))/		
		@internals = /(^\s*package\s+[\w.]+(?m:[^$].*))((^(internal\s+)?class\b))/
		@interface = /^\s*public\s+(interface)\s+(\w+)\b/
		@metadata = /^(\[\s*\b(Effect|Event|Style)\b.*\])\s*$/
		@package = /^\s*(package\s+[\w.]+)(?m:[^{]+)/
	end	
	
	public
	
	def parse(doc)
		
		doc = strip_comments(doc)
		
		# Interfaces need not be processed
		doc.scan(@interface)
		return doc unless $1.nil?
		
		doc.scan(@internals)
		unless $1.nil?
			doc = $1.sub( /\}((?m:[^}]+)\Z)/, "}\n")
		end
		
		doc
		
	end
	
	def imports(doc)
		
		d = parse(doc)
		return if d.nil?
		
		imps = d.scan(@imports)
		d = imps.join("\n")
		d
		
	end
	
	def metadata(doc)
		
		doc = parse(doc)
		return if doc.nil?
		
		m = []
		doc.scan(@metadata) do |l,e|
			m << l
		end
		
		doc = m.join("\n")
		doc

	end
	
	def class(doc)

		doc = parse(doc)
		return if doc.nil?
		
		m = []
		doc.scan(@class) do |l|
			m << $1
		end
			
		doc = m.join("\n")
		doc
		
	end
	
	def package(doc)

		doc = parse(doc)
		return if doc.nil?
		
		m = []
		doc.scan(@package) do |l|
			m << $1
		end
			
		doc = m.join("\n")
		doc
		
	end

	def methods(doc)

		doc = parse(doc)
		return if doc.nil?
		
		m = []
		doc.scan(@methods) do |l|
			#m << $&.to_s
			m << $1.gsub(/\n|\t/,'')
		end
			
		doc = m.join("\n")
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
		
		doc.each do |line|
			if line =~ /^\s*include\s+"([\w.\/]+)";$/
				include_path = File.dirname(uri)+"/#{$1}"
			end
		end
		
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

			assert_equal(cla, p.class(doc))

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

			assert_equal(cla, p.class(doc))

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
		
	}
}
			EOF
			
			result = <<-EOF
public function set hello(value:String):void
public function get hello():String
public function sayFoo():String
public function printBar(foo:String,bar:int,baz:*):void
EOF

			p = AsSourceToCompletions.new

			assert_equal(result.chomp, p.methods(doc))

		end
  end

end

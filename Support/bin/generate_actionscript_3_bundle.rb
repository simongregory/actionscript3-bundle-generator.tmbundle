#!/usr/bin/env ruby -wKU

require ENV['TM_SUPPORT_PATH']+'/lib/textmate'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/asdoc_class_parser'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/asdoc_framework_parser'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/list_to_regexp'

# =================================
# = Loading and Parsing of Asdocs =
# =================================

FLASH_PATH = '/Library/Application Support/Adobe/Flash CS3/en/Configuration/HelpPanel/Help/ActionScriptLangRefV3/all-classes.html'
FLEX_PATH = '/Applications/flex_sdk_3/docs/langref/all-classes.html' 

if !File.exist?(FLASH_PATH) or !File.exist?(FLEX_PATH)
    TextMate.exit_show_tool_tip( "Asdoc files were not found in their expected locations." )
end

log = true;

# Top Level.

tp = AsdocFrameworkParser.new
tp.logging_enabled = log
tp.package_filter = /^\.\//
tp.load_framework FLASH_PATH

tc = AsdocClassParser.new
tc.logging_enabled = log
tc.framework = tp.framework_name
tc.load_classes tp.class_path_list

# flash packages.

fp = AsdocFrameworkParser.new
fp.logging_enabled = log
fp.package_filter = /^flash\//
fp.load_framework FLASH_PATH

fc = AsdocClassParser.new
fc.logging_enabled = log
fc.framework = fp.framework_name
fc.load_classes fp.class_path_list

# fl packages.

flp = AsdocFrameworkParser.new
flp.logging_enabled = log
flp.package_filter = /^fl\//
flp.load_framework FLASH_PATH

flc = AsdocClassParser.new
flc.logging_enabled = log
flc.framework = flp.framework_name
flc.load_classes flp.class_path_list

# mx packages.

mp = AsdocFrameworkParser.new
mp.logging_enabled = log
mp.package_filter = /^mx\//
mp.load_framework FLEX_PATH

mc = AsdocClassParser.new
mc.logging_enabled = log
mc.framework = mp.framework_name
mc.load_classes mp.class_path_list

# collect docs info from flex docs.
dp = AsdocFrameworkParser.new
dp.logging_enabled = log
dp.load_framework FLEX_PATH

# =====================
# = Logging Utilities =
# =====================

log = false;

def print_to_file( path, content )
	if content		
		File.open(path, File::WRONLY|File::TRUNC|File::CREAT) do |file|
			file << content
		end
	end
end

if log

  path = '~/Desktop/as3_bundle_temp'
 
  unless File.exists?(path) 
  	Dir.mkdir(path)
  end

  print_to_file( path+"/constant_names.txt", flc.constant_names.join("\n") )
  print_to_file( path+"/method_names.txt", flc.method_names.join("\n") )
  print_to_file( path+"/property_names.txt", flc.property_names.join("\n") )

  print_to_file( path+"/constant_names_comp.txt", ListToRegexp.process_list(flc.constant_names) )
  print_to_file( path+"/method_names_comp.txt", ListToRegexp.process_list(flc.method_names) )
  print_to_file( path+"/property_names_comp.txt", ListToRegexp.process_list(flc.property_names) )

end

# =========================
# = Grammar Load and Save =
# =========================
 
def pattern_for(name, list)
  return unless list = ListToRegexp.process_list(list)
  {
    'name'  => name,
    'match' => "\\b#{ list }\\b"
  }
end

bundlePath = '/Users/simon/Library/Application Support/TextMate/Bundles/ActionScript 3.tmbundle'
grammarPath = bundlePath+'/Syntaxes/ActionScript 3.tmLanguage'

@grammar = OSX::PropertyList.load(File.read(grammarPath))

def add_framework(name,parser)

	patterns = []	

	patterns << pattern_for( "support.constant.#{name}.actionscript.3", parser.constant_names )
	patterns << pattern_for( "support.function.#{name}.actionscript.3", parser.method_names )
	patterns << pattern_for( "support.property.#{name}.actionscript.3", parser.property_names )

	@grammar['repository']['framework-'+name] = { 'patterns' => patterns }
	
end

def add_support_classes(name,parser)
  patterns = []
  patterns << pattern_for( "support.class.#{name}.actionscript.3", parser.class_names )
  @grammar['repository']['support-classes-'+name] = { 'patterns' => patterns }
end

add_support_classes("top-level",tc)
add_support_classes("flash",fc)
add_support_classes("fl",flc)
add_support_classes("mx",mc)

add_framework("top-level",tc)
add_framework("flash",fc)
add_framework("fl",flc)
add_framework("mx",mc)

File.open(grammarPath, "w") do |file|
  file << @grammar.to_plist
end

all_completions = tc.method_completions + fc.method_completions + flc.method_completions + mc.method_completions
all_completions = all_completions.uniq.sort

method_completions = File.open( bundlePath+"/Support/data/completions.txt", 
                                File::WRONLY|File::TRUNC|File::CREAT )
method_completions.puts all_completions

doc_extras = File.new( ENV['TM_BUNDLE_SUPPORT']+"/data/templates/additional_help.txt" )
doc_dictionary = File.new( bundlePath+"/Support/data/doc_dictionary.xml",
                           File::WRONLY|File::TRUNC|File::CREAT )

doc_dictionary.puts dp.asdoc_dictionary
# doc_dictionary.puts doc_extras.read

# `osascript -e 'tell app "TextMate" to reload bundles'`

print "Complete."

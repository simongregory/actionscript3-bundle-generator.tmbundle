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

# Top Level.

tp = AsdocFrameworkParser.new
tp.package_filter = /^\.\//
tp.load_framework FLASH_PATH

tc = AsdocClassParser.new
tc.framework = tp.framework_name
tc.load_classes tp.class_path_list.slice(0,5)

# flash packages.

fp = AsdocFrameworkParser.new
fp.package_filter = /^flash\//
fp.load_framework FLASH_PATH

fc = AsdocClassParser.new
fc.framework = fp.framework_name
fc.load_classes fp.class_path_list.slice(0,5)

# fl packages.

flp = AsdocFrameworkParser.new
flp.package_filter = /^fl\//
flp.load_framework FLASH_PATH

flc = AsdocClassParser.new
flc.framework = flp.framework_name
flc.load_classes flp.class_path_list.slice(0,5)

# mx packages.

mp = AsdocFrameworkParser.new
mp.package_filter = /^mx\//
mp.load_framework FLEX_PATH

mc = AsdocClassParser.new
mc.framework = mp.framework_name
mc.load_classes mp.class_path_list.slice(0,5)

# collect docs info from flex docs.
dp = AsdocFrameworkParser.new
dp.load_framework FLEX_PATH

# =======================================
# = Logging and File printing utilities =
# =======================================	

def print_to_file( path, content )
	if content		
		File.open(path, File::WRONLY|File::TRUNC|File::CREAT) do |file|
			file << content
		end
	end
end

path = '/Users/simon/Desktop/as3_bundle_temp'
 
unless File.exists?(path) 
	Dir.mkdir(path)
end

# print_to_file( path+"/constant_names.txt", flc.constant_names.join("\n") )
# print_to_file( path+"/method_names.txt", flc.method_names.join("\n") )
# print_to_file( path+"/property_names.txt", flc.property_names.join("\n") )
 
# print_to_file( path+"/constant_names_comp.txt", ListToRegexp.process_list(flc.constant_names) )
# print_to_file( path+"/method_names_comp.txt", ListToRegexp.process_list(flc.method_names) )
# print_to_file( path+"/property_names_comp.txt", ListToRegexp.process_list(flc.property_names) )

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

def add_repository_collection(name,parser)

	patterns = []	
	patterns << pattern_for( "support.class.#{name}.actionscript.3", parser.class_names )
	patterns << pattern_for( "support.constant.#{name}.actionscript.3", parser.constant_names )
	patterns << pattern_for( "support.function.#{name}.actionscript.3", parser.method_names )
	patterns << pattern_for( "support.property.#{name}.actionscript.3", parser.property_names )

	@grammar['repository']['framework-'+name] = { 'patterns' => patterns }
	
end

add_repository_collection("top-level",tc)
add_repository_collection("flash",fc)
add_repository_collection("fl",flc)
add_repository_collection("mx",mc)

File.open(grammarPath, "w") do |file|
  file << @grammar.to_plist
end

all_completions = tc.method_completions + fc.method_completions + flc.method_completions + mc.method_completions
all_completions = all_completions.uniq.sort

method_completions = File.open( bundlePath+"/Support/data/as3_completions_2.txt", File::WRONLY|File::TRUNC|File::CREAT )
method_completions.puts all_completions

doc_dictionary = File.new( bundlePath+"Support/data/doc_dictionary.xml", File::WRONLY|File::TRUNC|File::CREAT )
doc_dictionary.puts dp.asdoc_dictionary

`osascript -e'tell app "TextMate" to reload bundles'`

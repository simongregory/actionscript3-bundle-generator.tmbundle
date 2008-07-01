#!/usr/bin/env ruby -wKU

require ENV['TM_SUPPORT_PATH']+'/lib/textmate'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/asdoc_class_parser'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/asdoc_framework_parser'

# =================================
# = Loading and Parsing of Asdocs =
# =================================

HTML_PATH = ENV['TM_SELECTED_FILE']

TextMate.exit_show_tool_tip( "Please Select a File to Parse" ) if HTML_PATH == nil

fp = AsdocFrameworkParser.new
fp.package_filter = /^fl\//
fp.load_framework HTML_PATH

TextMate.exit_show_tool_tip( "No Class files found to parse." ) if fp.class_path_list.empty?

cp = AsdocClassParser.new
cp.framework = fp.framework_name
cp.load_classes fp.class_path_list

def print_to_file( path, content )
	if content		
		File.open(path, File::WRONLY|File::TRUNC|File::CREAT) do |file|
			file << content
		end
	end
end

path = '/Users/simon/Desktop/'
print_to_file( path+"constant_names.txt", cp.constant_names )
print_to_file( path+"method_names.txt", cp.method_names )
print_to_file( path+"property_names.txt", cp.property_names )

print "done"

# =========================
# = Grammar Load and Save =
# =========================

# grammarPath = '/Users/simon/Library/Application Support/TextMate/Bundles/ActionScript 3.tmbundle/Syntaxes/ActionScript 3.tmLanguage'
# grammar = OSX::PropertyList.load(File.read(grammarPath))
# 
# patterns = []
# 
# patterns << {
#   'name' => 'support.function.test-test-test.actionscript.3',
#   'match' => 'hello_world'
# }
# 
# grammar['repository']['a-test-by-simon'] = { 'patterns' => patterns }
# 
# File.open(grammarPath, 'w') do |file|
#   file << grammar.to_plist
# end
# 
# `osascript -e'tell app "TextMate" to reload bundles'`
#!/usr/bin/env ruby -wKU

require ENV['TM_SUPPORT_PATH']+'/lib/exit_codes'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/asdoc_class_parser'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/asdoc_framework_parser'

HTML_PATH = ENV['TM_SELECTED_FILE']

TextMate.exit_show_tool_tip( "Please Select a File to Parse" ) if HTML_PATH == nil

fp = AsdocFrameworkParser.new
fp.load_framework HTML_PATH

TextMate.exit_show_tool_tip( "No Class files found to parse." ) if fp.class_path_list.empty?

cp = AsdocClassParser.new
cp.framework = fp.framework_name
cp.load_classes fp.class_path_list

print cp.framework_language

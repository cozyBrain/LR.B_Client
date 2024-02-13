extends Node

@onready var hud_console = %"3d_hud_projector/console"
@onready var modules = %player_modules

func parse(input_data : String) -> Array: # return [ "command", {"option1":["arg1","arg2"]} ]
	# split input by space (" ")
	var tokens := input_data.split(" ", false)
	# extract command first
	var command : String = tokens[0]
	var options := {}
	# "-color white black -shape circle -init" --> options = {"-color":["white","black],"-shape":["circle"],"init":[]}
	# "cmd options_without_dash" -> {"_":["option_without_dash"]}
	var option_to_contain_args := "_" 
	options[option_to_contain_args] = []
	
	for i in range(1, tokens.size()):
		var token = tokens[i]
		if token.begins_with("-"):
			option_to_contain_args = token # update option_to_contain_args
			options[option_to_contain_args] = []
		else:
			options[option_to_contain_args].append(token)
	return [command, options]

func handle(content : Dictionary):
	var request = content["Request"]
	var data = content["Data"]
	match request:
		"print_line":
			print_line([data])
		"input":
			var parsed_input := parse(data)
			# extract command & options from the parsed_input
			var command: String = parsed_input[0]
			var options: Dictionary = parsed_input[1]
			print("parsed_input: ", command, "  ", options)
			var module = modules.get_node(command)
			if module == null:
				print_line(["Command or module \"", command, "\" doesn't exist."])
			else:
				module.handle(options)
			
		_: # match Request
			printerr("Invalid Request: ", request)

func print_line(texts : Array):
	var combined_text := ""
	for text in texts:
		combined_text += text
	hud_console.print_line(combined_text)

func print_invalid_arg_for_option(arg : String, option : String):
	print_line(["Invalid argument \"", arg, "\" for option \"", option, "\"."])
func print_invalid_option(option : String):
	print_line(["Invalid option \"", option, "\"."])

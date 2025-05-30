class_name OnlineLobbyMenu extends PanelContainer


# Menu for an online match lobby, which is shown before
# starting the match. Displays connected players.


signal start_pressed()
signal leave_pressed()


@export var _player_list: ItemList
@export var _match_config_label: RichTextLabel
@export var _start_button: Button


#########################
###       Public      ###
#########################

func set_start_button_visible(value: bool):
	_start_button.visible = value


# NOTE: skips presences without display names yet
func set_presences(presence_list: Array, host_user_id: String):
	_player_list.clear()

	for e in presence_list:
		var presence: NakamaRTAPI.UserPresence = e
		var user_id: String = presence.user_id
		var display_name: String = NakamaConnection.get_display_name_of_user(user_id)

		if display_name.is_empty():
			continue

		var user_is_host: bool = user_id == host_user_id

		var item_text: String = display_name

		if user_is_host:
			item_text += " %s" % tr("LOBBY_HOST_INDICATOR")

		_player_list.add_item(item_text)
		
		var new_item_index: int = _player_list.get_item_count() - 1
		_player_list.set_item_metadata(new_item_index, user_id)
		_player_list.set_item_selectable(new_item_index, false)


func display_match_config(match_config: MatchConfig):
	var match_config_string: String = match_config.get_display_string_rich()
	
	_match_config_label.clear()
	_match_config_label.append_text(match_config_string)


#########################
###     Callbacks     ###
#########################

func _on_leave_button_pressed():
	leave_pressed.emit()


func _on_start_button_pressed():
	start_pressed.emit()

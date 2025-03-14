extends Node

# UI Events
signal show_info(info: InfoResource)
signal game_over()

# Game Events
signal enemy_died()
signal encounter_finished()
signal load_encounter(encounter: EncounterResource)
signal start_encounter()

import Foundation

func displayConstant(_ symbol: String) -> String {
    let prefixes = [
        "TRAINER_CLASS_",
        "TRAINER_PIC_",
        "TRAINER_ENCOUNTER_MUSIC_",
        "AI_SCRIPT_",
        "OBJ_EVENT_GFX_",
        "MOVEMENT_TYPE_",
        "TRAINER_TYPE_",
        "BG_EVENT_PLAYER_FACING_",
        "SPECIES_",
        "ABILITY_",
        "TYPE_",
        "EGG_GROUP_",
        "ITEM_",
        "MOVE_",
        "NATURE_",
        "GROWTH_",
        "BODY_COLOR_",
        "EVO_",
        "VAR_",
        "FLAG_",
        "MAP_"
    ]
    let trimmed = prefixes.reduce(symbol) { value, prefix in
        value.hasPrefix(prefix) ? String(value.dropFirst(prefix.count)) : value
    }
    let words = trimmed.split(separator: "_").map { part in
        part.lowercased().capitalized
    }
    return words.isEmpty ? symbol : words.joined(separator: " ")
}

extends RefCounted
class_name PartyBuilder

const MAX_MEMBERS := 3

#暫存角色 (角色+職業)
var selections: Array[Dictionary] = []

#新增一個選擇
func add_selection(character: CharacterData, class_data: ClassData) -> bool:
	if selections.size() >= MAX_MEMBERS:
		return false
		
		#防止選到同一個角色兩次
	for s in selections:
		if s.character == character:
			return false
			
	selections.append({
		"character": character,
		"class": class_data
	})
	return true

#是否已選滿
func is_ready() -> bool:
	return selections.size() == MAX_MEMBERS
	
#建立正式Party (鎖定)
func build_party() -> Party:
	if not is_ready():
		push_error("PartyBuilder: 尚未選滿 3 人")
		return null
		
	var party = Party.new()
	for s in selections:
		var member = PartyMember.new(
			s.character,
			s.class
		)
		member.init_runtime_status()
		party.add_member(member)
	return party

#清空選擇 (重選用)
func clear():
	selections.clear()

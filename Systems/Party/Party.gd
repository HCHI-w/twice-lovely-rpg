extends RefCounted
class_name Party

const MAX_MEMBERS := 3

var members: Array[PartyMember] = []

#新增成員
func add_member(member: PartyMember) -> bool:
	if members.size() >= MAX_MEMBERS:
		return false
	members.append(member)
	return true
	
#是否已滿
func is_full() -> bool:
	return members.size() >= MAX_MEMBERS
	
#取得目前人數
func get_member_count() -> int:
	return members.size()
	
#取得所有成員
func get_members() -> Array[PartyMember]:
	return members
	
func has_class(class_id: String) -> bool:
	for m in members:
		if m.class_data.class_id == class_id:
			return true
	return false
	
#清空小隊 (之後重開冒險用)
func clear():
	members.clear()

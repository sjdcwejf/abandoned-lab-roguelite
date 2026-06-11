extends MarginContainer

@export var inventory : QuiverInventory


@onready var counters = {
	'Bomb': $VBoxContainer/Bombs/BombsCount,
	'Key': $VBoxContainer/Keys/KeysCount,
	'Coin': $VBoxContainer/Coins/CoinsCount,
}

func _ready():
	_connect_inventory()
	refresh()


func bind_inventory(new_inventory: QuiverInventory) -> void:
	_disconnect_inventory()
	inventory = new_inventory
	_connect_inventory()
	refresh()


func refresh() -> void:
	if inventory == null:
		return
	for item_name in counters:
		counters[item_name].text = str(inventory.get_item_amount(item_name))

func item_changed(item:QuiverItem):
	if counters.has(item.name):
		counters[item.name].text = str(inventory.get_item_amount(item))


func _connect_inventory() -> void:
	if inventory == null:
		return
	var changed_callable := Callable(self, "item_changed")
	if not inventory.item_changed.is_connected(changed_callable):
		inventory.item_changed.connect(changed_callable)


func _disconnect_inventory() -> void:
	if inventory == null:
		return
	var changed_callable := Callable(self, "item_changed")
	if inventory.item_changed.is_connected(changed_callable):
		inventory.item_changed.disconnect(changed_callable)

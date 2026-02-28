BEGIN TRANSACTION;

LET $shoppingLists = SELECT id, household, items FROM shopping_list;

FOR $list IN $shoppingLists {
  FOR $item IN $list.items {
    CREATE shopping_list_item CONTENT {
      item: $item.item,
      amount: $item.amount,
      unit: $item.unit,
      category: $item.category,
      recipe: $item.recipe,
      marked: $item.marked,
      shopping_list: $list.id,
      household: $list.household
    }
  }
};

REMOVE FIELD items ON shopping_list;
REMOVE FIELD items.*.item ON shopping_list;
REMOVE FIELD items.*.category ON shopping_list;
REMOVE FIELD items.*.amount ON shopping_list;
REMOVE FIELD items.*.unit ON shopping_list;
REMOVE FIELD items.*.recipe ON shopping_list;
REMOVE FIELD items.*.marked ON shopping_list;

UPDATE shopping_list SET items = NONE;

COMMIT TRANSACTION;
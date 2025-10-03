UPDATE shopping_list SET items = function(items) {
  return arguments[0].map(i => ({
      ...i,
      ingredient: undefined,
      item: i.ingredient || i.item
  }))
}
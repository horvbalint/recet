BEGIN TRANSACTION;

LET $recipes = SELECT image, id FROM recipe WHERE image IS NOT NONE;
FOR $recipe IN $recipes {
  fn::add_image_to_recipe($recipe.id, $recipe.image);
};

COMMIT;

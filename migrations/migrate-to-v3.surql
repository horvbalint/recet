BEGIN TRANSACTION;

LET $recipes = SELECT image, id FROM recipe WHERE image IS NOT NONE;
FOR $recipe IN $recipes {
	LET $file_handle = type::file("recipe_images", record::id($recipe.id));
	file::put($file_handle, $recipe.image);

	UPDATE ONLY $recipe.id SET image = $file_handle;
};

COMMIT;

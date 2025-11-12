BEGIN TRANSACTION;

LET $recipes = SELECT image, id FROM recipe WHERE image IS NOT NONE;
FOR $recipe IN $recipes {
	LET $file_handle = type::file("recipe_images", record::id($recipe.id));
	file::put($file_handle, $recipe.image);

	UPDATE ONLY $recipe.id SET image = $file_handle;
};

let $info = INFO FOR DB STRUCTURE;
FOR $table IN $info.tables {
	IF $table.name = 'member' {
			continue
	};
	
	UPDATE type::table($table.name) SET created_at = time::now() WHERE created_at = NONE;
};

COMMIT;

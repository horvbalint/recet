BEGIN TRANSACTION;

IF $pluginsBucketPath == NONE {
	throw "Please run `DEFINE PARAM $pluginsBucketPath VALUE 'file:/path/to/the/directory'` with the path to the directory where plugins will be stored.";
};

IF $recipeImagesBucketPath == NONE {
	throw "Please run `DEFINE PARAM $recipeImagesBucketPath VALUE 'file:/path/to/the/directory'` with the path to the directory where recipe images will be stored.";
};

DEFINE ANALYZER OVERWRITE hungarian_analyzer
  TOKENIZERS class
  FILTERS snowball(hungarian), lowercase, ascii;

DEFINE ANALYZER OVERWRITE english_analyzer
  TOKENIZERS class
  FILTERS snowball(english), lowercase, ascii;

// PLUGINS
DEFINE BUCKET OVERWRITE plugins BACKEND $pluginsBucketPath PERMISSIONS NONE;
DEFINE MODULE OVERWRITE mod::recet AS f"plugins:/recet.surli";

// TABLE: user
DEFINE TABLE OVERWRITE user SCHEMAFULL PERMISSIONS
	FOR select FULL
	FOR update WHERE id = $auth.id
	FOR create, delete NONE;

DEFINE FIELD OVERWRITE email ON user TYPE string ASSERT string::is_email($value) PERMISSIONS
	FOR select WHERE id = $auth.id || id IN ($auth.id -> member -> household <- member <- user);
DEFINE FIELD OVERWRITE username ON user TYPE string;
DEFINE FIELD OVERWRITE password ON user TYPE string PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_at ON user TYPE datetime DEFAULT time::now();
DEFINE FIELD OVERWRITE updated_at ON user TYPE datetime VALUE time::now() PERMISSIONS NONE;

DEFINE INDEX OVERWRITE email_unique ON user FIELDS email UNIQUE;
DEFINE INDEX OVERWRITE username_unique ON user FIELDS username UNIQUE;

// Define user authentication
DEFINE ACCESS OVERWRITE user ON DATABASE TYPE RECORD
	SIGNUP ( CREATE user SET email = $email, username = $username, password = crypto::argon2::generate($password) )
	SIGNIN ( SELECT * FROM ONLY user WHERE email = $email && crypto::argon2::compare(password, $password))
	DURATION FOR TOKEN 8h, FOR SESSION 12h
;

DEFINE FUNCTION OVERWRITE fn::can_read_household($household: record<household>) {
	RETURN fn::users_role_in_household($household) != NONE;
};

DEFINE FUNCTION OVERWRITE fn::can_write_household($household: record<household>) {
	RETURN fn::users_role_in_household($household) IN ["owner", "writer"];
};

DEFINE FUNCTION OVERWRITE fn::is_household_owner($household: record<household>) {
	RETURN fn::users_role_in_household($household) == "owner";
};

DEFINE FUNCTION OVERWRITE fn::users_role_in_household($household: record<household>) {
	RETURN SELECT VALUE role FROM ONLY member WHERE in = $auth.id && out = $household;
};

DEFINE FUNCTION OVERWRITE fn::define_household_table($name: string) {
	DEFINE TABLE OVERWRITE $name SCHEMAFULL PERMISSIONS
		for select WHERE fn::can_read_household(household)
		for create, delete, update WHERE fn::can_write_household(household);

	DEFINE FIELD OVERWRITE household ON $name TYPE record<household>;
	fn::define_meta_fields($name);
};

DEFINE FUNCTION OVERWRITE fn::define_meta_fields($table: string) {
	DEFINE FIELD OVERWRITE created_at ON $table TYPE datetime DEFAULT time::now();
	DEFINE FIELD OVERWRITE updated_at ON $table TYPE datetime VALUE time::now();
};

// TABLE: recipe
fn::define_household_table("recipe");
DEFINE FIELD OVERWRITE name ON recipe TYPE string;
DEFINE FIELD OVERWRITE ingredients ON recipe TYPE array<object> DEFAULT [];
DEFINE FIELD OVERWRITE ingredients.*.ingredient ON recipe TYPE record<ingredient> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE ingredients.*.amount ON recipe TYPE option<number>;
DEFINE FIELD OVERWRITE ingredients.*.unit ON recipe TYPE option<record<unit>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE ingredients.*.description ON recipe TYPE option<string>;
DEFINE FIELD OVERWRITE portions ON recipe TYPE option<number> ASSERT $value > 0; 
DEFINE FIELD OVERWRITE steps ON recipe TYPE array<string> DEFAULT [];
DEFINE FIELD OVERWRITE cooking_time_minutes ON recipe TYPE option<number> ASSERT $value >= 0;
DEFINE FIELD OVERWRITE author ON recipe TYPE record<user> VALUE author || $auth.id;
DEFINE FIELD OVERWRITE household ON recipe TYPE record<household>;
DEFINE FIELD OVERWRITE tags ON recipe TYPE array<record<recipe_tag>> DEFAULT [] ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE cuisine ON recipe TYPE option<record<cuisine>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE meal ON recipe TYPE array<record<meal>> DEFAULT [] ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE image_blur_hash ON recipe TYPE option<string> ASSERT image != NONE;
DEFINE FIELD OVERWRITE image ON recipe TYPE option<file>;

DEFINE INDEX OVERWRITE hungarian_search_name ON recipe FIELDS name FULLTEXT ANALYZER hungarian_analyzer;
DEFINE INDEX OVERWRITE english_search_name ON recipe FIELDS name FULLTEXT ANALYZER english_analyzer;

DEFINE EVENT OVERWRITE delete_unused_image ON recipe WHEN $event = "DELETE" THEN (
	IF ($before.image != NONE) {
		file::delete($before.image);
	}
);

// TABLE: meal
fn::define_household_table("meal");
DEFINE FIELD OVERWRITE name ON meal TYPE string;
DEFINE FIELD OVERWRITE color ON meal TYPE string;


// TABLE: cuisine
fn::define_household_table("cuisine");
DEFINE FIELD OVERWRITE name ON cuisine TYPE string;
DEFINE FIELD OVERWRITE color ON cuisine TYPE string;
DEFINE FIELD OVERWRITE flag ON cuisine TYPE option<string>;

// TABLE: recipe_tag
fn::define_household_table("recipe_tag");
DEFINE FIELD OVERWRITE name ON recipe_tag TYPE string;  
DEFINE FIELD OVERWRITE color ON recipe_tag TYPE string;
DEFINE FIELD OVERWRITE icon ON recipe_tag TYPE option<string>;

// TABLE: ingredient
fn::define_household_table("ingredient");
DEFINE FIELD OVERWRITE name ON ingredient TYPE string;
DEFINE FIELD OVERWRITE category ON ingredient TYPE option<record<ingredient_category>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE skip_from_shopping_list ON ingredient TYPE bool DEFAULT false;

// TABLE: ingredient_category
fn::define_household_table("ingredient_category");
DEFINE FIELD OVERWRITE name ON ingredient_category TYPE string;

DEFINE EVENT OVERWRITE add_to_shops ON ingredient_category WHEN $event = "CREATE" THEN (
	UPDATE shop SET categories = array::push(categories, $after.id) WHERE household = $after.household
);

DEFINE EVENT OVERWRITE remove_from_shops ON ingredient_category WHEN $event = "DELETE" THEN (
	UPDATE shop SET categories = array::remove(categories, array::find_index(categories, $before.id)) WHERE household = $before.household && $before.id IN categories
);

// TABLE: unit
fn::define_household_table("unit");
DEFINE FIELD OVERWRITE name ON unit TYPE string;

// TABLE: shop
fn::define_household_table("shop");
DEFINE FIELD OVERWRITE name ON shop TYPE string;
DEFINE FIELD OVERWRITE categories ON shop TYPE array<record<ingredient_category>> ASSERT $value.all(|$v| household = $v.household);

// TABLE: household
DEFINE TABLE OVERWRITE household SCHEMAFULL PERMISSIONS
	for create FULL
	for select WHERE fn::can_read_household(id)
	for delete, update WHERE fn::is_household_owner(id);
DEFINE FIELD OVERWRITE name ON household TYPE string;
DEFINE FIELD OVERWRITE language ON household TYPE 'en' | 'hu' DEFAULT 'en';
DEFINE FIELD OVERWRITE meal_rules ON household TYPE object DEFAULT {};
DEFINE FIELD OVERWRITE meal_rules.breakfast ON household TYPE array<record<meal_rule>> ASSERT $value.all(|$v| household = $v.household) DEFAULT [];
DEFINE FIELD OVERWRITE meal_rules.lunch ON household TYPE array<record<meal_rule>> ASSERT $value.all(|$v| household = $v.household) DEFAULT [];
DEFINE FIELD OVERWRITE meal_rules.dinner ON household TYPE array<record<meal_rule>> ASSERT $value.all(|$v| household = $v.household) DEFAULT [];
DEFINE FIELD OVERWRITE meal_rules.snack ON household TYPE array<record<meal_rule>> ASSERT $value.all(|$v| household = $v.household) DEFAULT [];
fn::define_meta_fields("household");

DEFINE EVENT OVERWRITE relate_owner ON household WHEN $event = "CREATE" THEN (
	RELATE ONLY $auth -> member -> $after SET role = "owner"
);

// TABLE: member
DEFINE TABLE OVERWRITE member SCHEMAFULL TYPE RELATION FROM user TO household PERMISSIONS
	FOR select WHERE fn::can_read_household(out)
	FOR create, update, delete WHERE fn::is_household_owner(out);
DEFINE FIELD OVERWRITE role ON member TYPE "owner" | "writer" | "guest";

DEFINE INDEX OVERWRITE member_unique ON member FIELDS in, out UNIQUE;

// TABLE: shopping_list
fn::define_household_table("shopping_list");
DEFINE FIELD OVERWRITE shop ON shopping_list TYPE option<record<shop>>;
DEFINE FIELD OVERWRITE name ON shopping_list TYPE string;
DEFINE FIELD OVERWRITE items ON shopping_list TYPE array<object> DEFAULT [];
DEFINE FIELD OVERWRITE items.*.item ON shopping_list TYPE string | record<ingredient> ASSERT !type::is_record($value) || household = $value.household;
DEFINE FIELD OVERWRITE items.*.category ON shopping_list TYPE option<record<ingredient_category>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE items.*.amount ON shopping_list TYPE option<number>;
DEFINE FIELD OVERWRITE items.*.unit ON shopping_list TYPE option<record<unit>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE items.*.recipe ON shopping_list TYPE option<record<recipe>> ASSERT household = $value.household;

// TABLE: meal_plan
fn::define_household_table("meal_plan");
DEFINE FIELD OVERWRITE date ON meal_plan TYPE datetime;
DEFINE FIELD OVERWRITE meals ON meal_plan TYPE object;
FOR $meal IN ["breakfast", "lunch", "dinner", "snack"] {
	DEFINE FIELD OVERWRITE "meals." + $meal ON meal_plan TYPE array<object> DEFAULT [];
	DEFINE FIELD OVERWRITE "meals." + $meal + ".*.recipe" ON meal_plan TYPE record<recipe> ASSERT household = $value.household;
	DEFINE FIELD OVERWRITE "meals." + $meal + ".*.servings" ON meal_plan TYPE option<number> ASSERT $value > 0;
	DEFINE FIELD OVERWRITE "meals." + $meal + ".*.rule" ON meal_plan TYPE option<record<meal_rule>> ASSERT household = $value.household;
};

fn::define_household_table("meal_rule");
DEFINE FIELD OVERWRITE name ON meal_rule TYPE string;
DEFINE FIELD OVERWRITE conditions ON meal_rule TYPE {
	operator: "and" | "or",
	categories: array<record<meal_category>>,
	tags: array<record<recipe_tag>>,
	cuisines: array<record<cuisine>>,
	rules: array<{
		operator: "and" | "or",
		categories: array<record<meal_category>>,
		tags: array<record<recipe_tag>>,
		cuisines: array<record<cuisine>>,
		rules: array<{
			operator: "and" | "or",
			categories: array<record<meal_category>>,
			tags: array<record<recipe_tag>>,
			cuisines: array<record<cuisine>>,
		}>
	}>
};

DEFINE BUCKET OVERWRITE recipe_images BACKEND $recipeImagesBucketPath PERMISSIONS WHERE
	IF $action = 'get' {
		LET $household = SELECT VALUE household FROM ONLY recipe WHERE image = $file;
		fn::can_read_household($household)
	}
	ELSE IF $action = 'put' {
		LET $household = SELECT VALUE household FROM ONLY type::record("recipe", file::key($file).slice(1..));
		fn::can_write_household($household)
	}
	ELSE {
		false
	};

DEFINE FUNCTION OVERWRITE fn::add_image_to_recipe($recipe_id: record<recipe>, $image: bytes) {
	LET $result = mod::recet::process_image($image);

	LET $file_handle = type::file("recipe_images", record::id($recipe_id));
	file::put($file_handle, $result.bytes);

	UPDATE ONLY $recipe_id MERGE {
		image: $file_handle,
		image_blur_hash: $result.blurhash
	};
};

DEFINE FUNCTION OVERWRITE fn::add_member_to_household($household: record<household>, $username: string, $role: "owner" | "writer" | "guest") {
	LET $user = (SELECT id FROM ONLY user WHERE username = $username);
	IF ($user == NONE) {
		THROW "User with the provided username does not exist.";
	};

	IF ((SELECT id FROM ONLY member WHERE in = $user.id && out = $household) != NONE) {
		THROW "User is already a member of the household.";
	};

	LET $temp = $user.id;
	RELATE ONLY $temp -> member -> $household SET role = $role;
};

DEFINE FUNCTION OVERWRITE fn::add_recipe_ingredients_to_shopping_list($recipe_id: record<recipe>, $ingredient_indexes: array<number>, $shopping_list_id: record<shopping_list>, $portionRatio: number) {
	LET $recipe = SELECT id, ingredients FROM ONLY $recipe_id FETCH ingredients.ingredient;
	LET $shopping_list = SELECT items FROM ONLY $shopping_list_id;
	
	IF ($recipe == NONE) {
		THROW "Recipe not found.";
	};
	
	IF ($shopping_list == NONE) {
		THROW "Shopping list not found.";
	};
	
	LET $items = function($recipe, $ingredient_indexes, $shopping_list.items, $portionRatio) {
    const [recipe, ingredientIndexes, listItems, portionRatio] = arguments;

		const ingredientsToAdd = ingredientIndexes.map(index => recipe.ingredients[index]).filter(ing => !ing.ingredient.skip_from_shopping_list);

    for(const ingredient of ingredientsToAdd) {
			const existing_item = listItems.find(item => typeof item.item === 'object' && item.item.id === ingredient.ingredient.id.id);

			if(existing_item && existing_item.unit?.id === ingredient.unit?.id) {
				existing_item.amount = (existing_item.amount || 0) + (ingredient.amount || 0) * portionRatio;
			}
			else {
				listItems.push({
					item: ingredient.ingredient.id,
					amount: ingredient.amount && ingredient.amount * portionRatio,
					unit: ingredient.unit,
					category: ingredient.ingredient.category,
					recipe: recipe.id
				});
			}
		}

    return listItems
	};
	
	UPDATE ONLY $shopping_list_id SET items = $items;
};

COMMIT;
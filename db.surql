BEGIN TRANSACTION;

-- To restrict signup to specific email addresses, set the following parameter:
-- DEFINE PARAM OVERWRITE $allowedSignupEmails VALUE NONE PERMISSIONS NONE; // to allow all email addresses
-- DEFINE PARAM OVERWRITE $allowedSignupEmails VALUE ['foo.bar.com'] PERMISSIONS NONE; // to allow specific email addresses
DEFINE PARAM OVERWRITE $allowedSignupEmails VALUE [] PERMISSIONS NONE; // to disallow all signups - default value

-- For AI integration set the following parameters:
-- DEFINE PARAM OVERWRITE $openAiBaseUrl VALUE 'open-ai-compatible-api-url' PERMISSIONS NONE;
-- DEFINE PARAM OVERWRITE $openAiModel VALUE 'name-of-the-model' PERMISSIONS NONE;
-- DEFINE PARAM OVERWRITE $openAiToken VALUE 'your-token' PERMISSIONS NONE;

-- The following parameters are required:
-- DEFINE PARAM OVERWRITE $pluginsBucketPath VALUE 'file:/path/to/the/directory' PERMISSIONS NONE;
-- DEFINE PARAM OVERWRITE $recipeImagesBucketPath VALUE 'file:/path/to/the/directory' PERMISSIONS NONE;

IF $pluginsBucketPath == NONE {
	throw "Please run `DEFINE PARAM OVERWRITE $pluginsBucketPath VALUE 'file:/path/to/the/directory' PERMISSIONS NONE;` with the path to the directory where plugins will be stored.";
};

IF $recipeImagesBucketPath == NONE {
	throw "Please run `DEFINE PARAM OVERWRITE $recipeImagesBucketPath VALUE 'file:/path/to/the/directory' PERMISSIONS NONE;` with the path to the directory where recipe images will be stored.";
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

DEFINE ACCESS OVERWRITE desktop_user ON DATABASE TYPE RECORD
	SIGNUP
		IF $allowedSignupEmails != NONE && !$allowedSignupEmails.includes($email) {
			THROW "The admin did not allow this email address for signup."
		}
		ELSE {
			CREATE user SET email = $email, username = $username, password = crypto::argon2::generate($password)
		}
	SIGNIN
		SELECT id FROM ONLY user WHERE email = $email && crypto::argon2::compare(password, $password)
	WITH REFRESH
	DURATION
		FOR TOKEN 15m,
		FOR SESSION 1h
;

DEFINE ACCESS OVERWRITE mobile_user ON DATABASE TYPE RECORD
	SIGNUP
		IF $allowedSignupEmails != NONE && !$allowedSignupEmails.includes($email) {
			THROW "The admin did not allow this email address for signup."
		}
		ELSE {
			CREATE user SET email = $email, username = $username, password = crypto::argon2::generate($password)
		}
	SIGNIN
		SELECT id FROM ONLY user WHERE email = $email && crypto::argon2::compare(password, $password)
	WITH REFRESH
	DURATION
		FOR TOKEN 15m,
		FOR SESSION 1h
;

DEFINE ACCESS OVERWRITE recipe_guest ON DATABASE TYPE RECORD
	SIGNIN (SELECT * FROM ONLY recipe WHERE id = type::record('recipe', $recipe_id) && public = true)
	DURATION
		FOR TOKEN 5m,
		FOR SESSION 5m
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
	RETURN SELECT VALUE role FROM ONLY member WHERE in = $auth && out = $household;
};

DEFINE FUNCTION OVERWRITE fn::has_guest_access($id: record) {
	RETURN $access = 'recipe_guest'&& (
		$auth == $id ||
		$auth.author = $id ||
		$auth.tags.includes($id) ||
		$auth.cuisine = $id ||
		$auth.meal.includes($id) ||
		$auth.ingredients.any(|$i| {
			RETURN $i.ingredient = $id || $i.unit = $id;
		})
	)	
};

DEFINE FUNCTION OVERWRITE fn::define_household_table($name: string) {
	DEFINE TABLE OVERWRITE $name SCHEMAFULL PERMISSIONS
		for select WHERE fn::can_read_household(household) || fn::has_guest_access(id)
		for create, delete, update WHERE fn::can_write_household(household);

	DEFINE FIELD OVERWRITE household ON $name TYPE record<household>;
	fn::define_meta_fields($name);
};

DEFINE FUNCTION OVERWRITE fn::define_meta_fields($table: string) {
	DEFINE FIELD OVERWRITE created_at ON $table TYPE datetime DEFAULT time::now();
	DEFINE FIELD OVERWRITE updated_at ON $table TYPE datetime VALUE time::now();
};

// TABLE: user
DEFINE TABLE OVERWRITE user SCHEMAFULL PERMISSIONS
	FOR select WHERE id = $auth || id IN ($auth -> member -> household <- member <- user) || fn::has_guest_access(id)
	FOR update WHERE id = $auth
	FOR create, delete NONE;

DEFINE FIELD OVERWRITE email ON user TYPE string ASSERT string::is_email($value) PERMISSIONS
	FOR select WHERE id = $auth || id IN ($auth -> member -> household <- member <- user);
DEFINE FIELD OVERWRITE username ON user TYPE string;
DEFINE FIELD OVERWRITE password ON user TYPE string PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_at ON user TYPE datetime DEFAULT time::now();
DEFINE FIELD OVERWRITE updated_at ON user TYPE datetime VALUE time::now() PERMISSIONS NONE;

DEFINE INDEX OVERWRITE email_unique ON user FIELDS email UNIQUE;
DEFINE INDEX OVERWRITE username_unique ON user FIELDS username UNIQUE;

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
DEFINE FIELD OVERWRITE author ON recipe TYPE record<user> VALUE author || $auth;
DEFINE FIELD OVERWRITE household ON recipe TYPE record<household>;
DEFINE FIELD OVERWRITE tags ON recipe TYPE array<record<recipe_tag>> DEFAULT [] ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE cuisine ON recipe TYPE option<record<cuisine>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE meal ON recipe TYPE array<record<meal>> DEFAULT [] ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE image_blur_hash ON recipe TYPE option<string> ASSERT image != NONE;
DEFINE FIELD OVERWRITE image ON recipe TYPE option<file>;
DEFINE FIELD OVERWRITE public ON recipe TYPE bool DEFAULT false;

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

DEFINE INDEX OVERWRITE hungarian_search_name ON meal FIELDS name FULLTEXT ANALYZER hungarian_analyzer;
DEFINE INDEX OVERWRITE english_search_name ON meal FIELDS name FULLTEXT ANALYZER english_analyzer;


// TABLE: cuisine
fn::define_household_table("cuisine");
DEFINE FIELD OVERWRITE name ON cuisine TYPE string;
DEFINE FIELD OVERWRITE color ON cuisine TYPE string;
DEFINE FIELD OVERWRITE flag ON cuisine TYPE option<string>;

DEFINE INDEX OVERWRITE hungarian_search_name ON cuisine FIELDS name FULLTEXT ANALYZER hungarian_analyzer;
DEFINE INDEX OVERWRITE english_search_name ON cuisine FIELDS name FULLTEXT ANALYZER english_analyzer;

// TABLE: recipe_tag
fn::define_household_table("recipe_tag");
DEFINE FIELD OVERWRITE name ON recipe_tag TYPE string;  
DEFINE FIELD OVERWRITE color ON recipe_tag TYPE string;
DEFINE FIELD OVERWRITE icon ON recipe_tag TYPE option<string>;

DEFINE INDEX OVERWRITE hungarian_search_name ON recipe_tag FIELDS name FULLTEXT ANALYZER hungarian_analyzer;
DEFINE INDEX OVERWRITE english_search_name ON recipe_tag FIELDS name FULLTEXT ANALYZER english_analyzer;

// TABLE: ingredient
fn::define_household_table("ingredient");
DEFINE FIELD OVERWRITE name ON ingredient TYPE string;
DEFINE FIELD OVERWRITE category ON ingredient TYPE option<record<ingredient_category>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE skip_from_shopping_list ON ingredient TYPE bool DEFAULT false;

DEFINE INDEX OVERWRITE hungarian_search_name ON ingredient FIELDS name FULLTEXT ANALYZER hungarian_analyzer;
DEFINE INDEX OVERWRITE english_search_name ON ingredient FIELDS name FULLTEXT ANALYZER english_analyzer;

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

DEFINE INDEX OVERWRITE hungarian_search_name ON unit FIELDS name FULLTEXT ANALYZER hungarian_analyzer;
DEFINE INDEX OVERWRITE english_search_name ON unit FIELDS name FULLTEXT ANALYZER english_analyzer;

// TABLE: shop
fn::define_household_table("shop");
DEFINE FIELD OVERWRITE name ON shop TYPE string;
DEFINE FIELD OVERWRITE categories ON shop TYPE array<record<ingredient_category>> ASSERT $value.all(|$v| household = $v.household);

// TABLE: household
DEFINE TABLE OVERWRITE household SCHEMAFULL PERMISSIONS
	for create WHERE $access = 'mobile_user' || $access = 'desktop_user'
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
	FOR select WHERE in = $auth || (!$parent && fn::is_household_owner(out))
	FOR create, update, delete WHERE fn::is_household_owner(out);
DEFINE FIELD OVERWRITE role ON member TYPE "owner" | "writer" | "guest";

DEFINE INDEX OVERWRITE member_unique ON member FIELDS in, out UNIQUE;

// TABLE: invitation
DEFINE TABLE OVERWRITE invitation SCHEMAFULL PERMISSIONS
	FOR select, create, delete WHERE fn::is_household_owner(household)
	FOR update NONE;
DEFINE FIELD OVERWRITE token ON invitation TYPE uuid DEFAULT rand::uuid();
DEFINE FIELD OVERWRITE household ON invitation TYPE record<household>;
DEFINE FIELD OVERWRITE role ON invitation TYPE "owner" | "writer" | "guest";
fn::define_meta_fields("invitation");

DEFINE INDEX OVERWRITE token_unique ON invitation FIELDS token UNIQUE;

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
DEFINE FIELD OVERWRITE items.*.marked ON shopping_list TYPE option<bool>;

// TABLE: meal_plan
fn::define_household_table("meal_plan");
DEFINE FIELD OVERWRITE household ON meal_rule TYPE record<household>;
DEFINE FIELD OVERWRITE date ON meal_plan TYPE datetime;
DEFINE FIELD OVERWRITE meals ON meal_plan TYPE object;
FOR $meal IN ["breakfast", "lunch", "dinner", "snack"] {
	DEFINE FIELD OVERWRITE "meals." + $meal ON meal_plan TYPE array<object> DEFAULT [];
	DEFINE FIELD OVERWRITE "meals." + $meal + ".*.recipe" ON meal_plan TYPE record<recipe> ASSERT household = $value.household;
	DEFINE FIELD OVERWRITE "meals." + $meal + ".*.servings" ON meal_plan TYPE number DEFAULT 1 ASSERT $value > 0;
	DEFINE FIELD OVERWRITE "meals." + $meal + ".*.state" ON meal_plan TYPE 'todo' | 'prepared' | 'done' | 'served' DEFAULT 'todo';
};

DEFINE INDEX OVERWRITE date_unique ON meal_plan FIELDS household, date UNIQUE;

fn::define_household_table("meal_rule");
DEFINE FIELD OVERWRITE name ON meal_rule TYPE string;
DEFINE FIELD OVERWRITE include_operator ON meal_rule TYPE "and" | "or";
DEFINE FIELD OVERWRITE include ON meal_rule TYPE object;
DEFINE FIELD OVERWRITE include.meals ON meal_rule TYPE object;
DEFINE FIELD OVERWRITE include.meals.operator ON meal_rule TYPE "and" | "or";
DEFINE FIELD OVERWRITE include.meals.items ON meal_rule TYPE array<record<meal>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE include.tags ON meal_rule TYPE object;
DEFINE FIELD OVERWRITE include.tags.operator ON meal_rule TYPE "and" | "or";
DEFINE FIELD OVERWRITE include.tags.items ON meal_rule TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE include.cuisines ON meal_rule TYPE object;
DEFINE FIELD OVERWRITE include.cuisines.items ON meal_rule TYPE array<record<cuisine>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE include.ingredients ON meal_rule TYPE object;
DEFINE FIELD OVERWRITE include.ingredients.operator ON meal_rule TYPE "and" | "or";
DEFINE FIELD OVERWRITE include.ingredients.items ON meal_rule TYPE array<record<ingredient>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE exclude ON meal_rule TYPE object;
DEFINE FIELD OVERWRITE exclude.meals ON meal_rule TYPE array<record<meal>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE exclude.tags ON meal_rule TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE exclude.cuisines ON meal_rule TYPE array<record<cuisine>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE exclude.ingredients ON meal_rule TYPE array<record<ingredient>> ASSERT $value.all(|$v| household = $v.household);

DEFINE BUCKET OVERWRITE recipe_images BACKEND $recipeImagesBucketPath PERMISSIONS WHERE
	IF $action = 'get' {
		LET $recipe = SELECT household, id FROM ONLY recipe WHERE image = $file;
		fn::can_read_household($recipe.household) || fn::has_guest_access($recipe.id)
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


DEFINE API OVERWRITE "/invitation/accept" FOR post
	MIDDLEWARE
		api::timeout(1s)
	THEN {
		IF $access != 'mobile_user' && $access != 'desktop_user' {
			RETURN { status: 403, body: { error: "Forbidden" } };
		};

		LET $body_token = <uuid> $request.body.token;
		LET $invitation = SELECT * FROM ONLY invitation WHERE token = $body_token LIMIT 1;

		IF $invitation == NONE {
			RETURN { status: 400, body: { error: "Invalid or expired invitation token." } };
		};

		LET $existing = SELECT id FROM ONLY member WHERE in = $auth.id AND out = $invitation.household;
		IF $existing != NONE {
			DELETE $invitation.id;
			RETURN { status: 400, body: { error: "You are already a member of this household." } };
		};

		RELATE ONLY ($auth.id) -> member -> ($invitation.household) SET role = $invitation.role;
		DELETE $invitation.id;

		LET $household = SELECT id, name, language FROM ONLY $invitation.household;
		RETURN { status: 200, body: $household };
	};

DEFINE API OVERWRITE "/recipe/scrape/:type" FOR get
	THEN {
		IF $access != 'mobile_user' && $access != 'desktop_user' {
			RETURN { status: 403, body: { error: "Forbidden" } };
		};

		LET $type = $request.params.type;
		LET $source = $request.query.source;

		LET $result = mod::recet::scrape_for_recipe($type, $source);
		RETURN { status: 200, body: $result };
	};


COMMIT;
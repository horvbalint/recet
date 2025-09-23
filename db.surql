BEGIN TRANSACTION;

// TABLE: user
DEFINE TABLE OVERWRITE user SCHEMAFULL PERMISSIONS
	FOR select FULL
	FOR update WHERE id = $auth.id
	FOR create, delete NONE;

DEFINE FIELD OVERWRITE email ON user TYPE string ASSERT string::is::email($value) PERMISSIONS
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


// TABLE: recipe
DEFINE TABLE OVERWRITE recipe SCHEMAFULL PERMISSIONS
	for select WHERE fn::can_read_household(household)
	for create, delete, update WHERE fn::can_write_household(household);

DEFINE FIELD OVERWRITE name ON recipe TYPE string;
DEFINE FIELD OVERWRITE ingredients ON recipe TYPE array<object> DEFAULT [];
DEFINE FIELD OVERWRITE ingredients.*.ingredient ON recipe TYPE record<ingredient> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE ingredients.*.amount ON recipe TYPE option<number>;
DEFINE FIELD OVERWRITE ingredients.*.unit ON recipe TYPE option<record<unit>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE ingredients.*.description ON recipe TYPE option<string>;
DEFINE FIELD OVERWRITE steps ON recipe TYPE array<string> DEFAULT [];
DEFINE FIELD OVERWRITE author ON recipe TYPE record<user>;
DEFINE FIELD OVERWRITE household ON recipe TYPE record<household>;
DEFINE FIELD OVERWRITE tags ON recipe TYPE array<record<recipe_tag>> DEFAULT [] ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE cuisine ON recipe TYPE option<record<cuisine>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE meal ON recipe TYPE array<record<meal>> DEFAULT [] ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE created_at ON recipe TYPE datetime DEFAULT time::now();
DEFINE FIELD OVERWRITE updated_at ON recipe TYPE datetime VALUE time::now();

// TABLE: meal
DEFINE TABLE OVERWRITE meal SCHEMAFULL PERMISSIONS 
	for select WHERE fn::can_read_household(household)
	for create, delete, update WHERE fn::can_write_household(household);
	
DEFINE FIELD OVERWRITE name ON meal TYPE string;
DEFINE FIELD OVERWRITE color ON meal TYPE string;
DEFINE FIELD OVERWRITE household ON meal TYPE record<household>;


// TABLE: cuisine
DEFINE TABLE OVERWRITE cuisine SCHEMAFULL PERMISSIONS 
	for select WHERE fn::can_read_household(household)
	for create, delete, update WHERE fn::can_write_household(household);
	
DEFINE FIELD OVERWRITE name ON cuisine TYPE string;
DEFINE FIELD OVERWRITE color ON cuisine TYPE string;
DEFINE FIELD OVERWRITE flag ON cuisine TYPE option<string>;
DEFINE FIELD OVERWRITE household ON cuisine TYPE record<household>;

// TABLE: recipe_tag
DEFINE TABLE OVERWRITE recipe_tag SCHEMAFULL PERMISSIONS 
	for select WHERE fn::can_read_household(household)
	for create, delete, update WHERE fn::can_write_household(household);
	
DEFINE FIELD OVERWRITE name ON recipe_tag TYPE string;  
DEFINE FIELD OVERWRITE color ON recipe_tag TYPE string;
DEFINE FIELD OVERWRITE icon ON recipe_tag TYPE string;
DEFINE FIELD OVERWRITE household ON recipe_tag TYPE record<household>;

// TABLE: ingredient
DEFINE TABLE OVERWRITE ingredient SCHEMAFULL PERMISSIONS 
	for select WHERE fn::can_read_household(household)
	for create, delete, update WHERE fn::can_write_household(household);
	
DEFINE FIELD OVERWRITE name ON ingredient TYPE string;
DEFINE FIELD OVERWRITE category ON ingredient TYPE option<record<ingredient_category>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE skip_from_shopping_list ON ingredient TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE household ON ingredient TYPE record<household>;

// TABLE: ingredient_category
DEFINE TABLE OVERWRITE ingredient_category SCHEMAFULL PERMISSIONS 
	for select WHERE fn::can_read_household(household)
	for create, delete, update WHERE fn::can_write_household(household);
	
DEFINE FIELD OVERWRITE name ON ingredient_category TYPE string;
DEFINE FIELD OVERWRITE household ON ingredient_category TYPE record<household>;

DEFINE EVENT OVERWRITE add_to_shops ON ingredient_category WHEN $event = "CREATE" THEN (
	UPDATE shop SET categories = array::push(categories, $after.id) WHERE household = $after.household
);

DEFINE EVENT OVERWRITE remove_from_shops ON ingredient_category WHEN $event = "DELETE" THEN (
	UPDATE shop SET categories = array::remove(categories, array::find_index(categories, $before.id)) WHERE household = $before.household && $before.id IN categories
);

// TABLE: unit
DEFINE TABLE OVERWRITE unit SCHEMAFULL PERMISSIONS 
	for select WHERE fn::can_read_household(household)
	for create, delete, update WHERE fn::can_write_household(household);
	
DEFINE FIELD OVERWRITE name ON unit TYPE string;
DEFINE FIELD OVERWRITE household ON unit TYPE record<household>;

// TABLE: shop
DEFINE TABLE OVERWRITE shop SCHEMAFULL PERMISSIONS 
	for select WHERE fn::can_read_household(household)
	for create, delete, update WHERE fn::can_write_household(household);
	
DEFINE FIELD OVERWRITE name ON shop TYPE string;
DEFINE FIELD OVERWRITE household ON shop TYPE record<household>;
DEFINE FIELD OVERWRITE categories ON shop TYPE array<record<ingredient_category>> ASSERT $value.all(|$v| household = $v.household);

// TABLE: household
DEFINE TABLE OVERWRITE household SCHEMAFULL PERMISSIONS
	for create FULL
	for select WHERE fn::can_read_household(id)
	for delete, update WHERE fn::is_household_owner(id);
DEFINE FIELD OVERWRITE name ON household TYPE string;
DEFINE FIELD OVERWRITE created_at ON household TYPE datetime DEFAULT time::now();
DEFINE FIELD OVERWRITE updated_at ON household TYPE datetime VALUE time::now();

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
DEFINE TABLE OVERWRITE shopping_list SCHEMAFULL PERMISSIONS 
	for select WHERE fn::can_read_household(household)
	for create, delete, update WHERE fn::can_write_household(household);
	
DEFINE FIELD OVERWRITE household ON shopping_list TYPE record<household>;
DEFINE FIELD OVERWRITE shop ON shopping_list TYPE option<record<shop>>;
DEFINE FIELD OVERWRITE name ON shopping_list TYPE string;
DEFINE FIELD OVERWRITE items ON shopping_list TYPE array<object> DEFAULT [];
DEFINE FIELD OVERWRITE items.*.ingredient ON shopping_list TYPE record<ingredient> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE items.*.category ON shopping_list TYPE option<record<ingredient_category>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE items.*.amount ON shopping_list TYPE option<number>;
DEFINE FIELD OVERWRITE items.*.unit ON shopping_list TYPE option<record<unit>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE items.*.recipe ON shopping_list TYPE option<record<recipe>> ASSERT household = $value.household;
DEFINE FIELD OVERWRITE items.*.checked ON shopping_list TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE updated_at ON shopping_list TYPE datetime VALUE time::now();

// TABLE: weekly_plan
DEFINE TABLE OVERWRITE weekly_plan SCHEMAFULL PERMISSIONS 
	for select WHERE fn::can_read_household(household)
	for create, delete, update WHERE fn::can_write_household(household);
	
DEFINE FIELD OVERWRITE name ON weekly_plan TYPE string;
DEFINE FIELD OVERWRITE household ON weekly_plan TYPE record<household>;

DEFINE FIELD OVERWRITE monday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE monday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE monday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE monday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE monday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE monday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE monday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE monday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE monday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE monday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE monday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE monday.other.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE monday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);

DEFINE FIELD OVERWRITE tuesday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE tuesday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE tuesday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE tuesday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE tuesday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE tuesday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE tuesday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE tuesday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE tuesday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE tuesday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE tuesday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE tuesday.other.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE tuesday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);

DEFINE FIELD OVERWRITE wednesday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE wednesday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE wednesday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE wednesday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE wednesday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE wednesday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE wednesday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE wednesday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE wednesday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE wednesday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE wednesday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE wednesday.other.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE wednesday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);

DEFINE FIELD OVERWRITE thursday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE thursday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE thursday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE thursday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE thursday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE thursday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE thursday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE thursday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE thursday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE thursday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE thursday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE thursday.other.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE thursday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);

DEFINE FIELD OVERWRITE friday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE friday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE friday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE friday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE friday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE friday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE friday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE friday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE friday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE friday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE friday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE friday.other.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE friday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);

DEFINE FIELD OVERWRITE saturday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE saturday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE saturday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE saturday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE saturday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE saturday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE saturday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE saturday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE saturday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE saturday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE saturday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE saturday.other.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE saturday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);

DEFINE FIELD OVERWRITE sunday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE sunday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE sunday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE sunday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE sunday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE sunday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE sunday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE sunday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE sunday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE sunday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE sunday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE sunday.other.recipes ON weekly_plan TYPE array<record<recipe>> ASSERT $value.all(|$v| household = $v.household);
DEFINE FIELD OVERWRITE sunday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> ASSERT $value.all(|$v| household = $v.household);

DEFINE FUNCTION OVERWRITE fn::add_member_to_household($household: record<household>, $username: string, $role: "owner" | "writer" | "guest") {
	LET $user = (SELECT id FROM ONLY user WHERE username = $username);
	IF ($user == NONE) {
		THROW "User with the provided username does not exist.";
	};

	IF ((SELECT id FROM ONLY member WHERE in = $user.id && out = $household) != NONE) {
		THROW "User is already a member of the household.";
	};

	RELATE ONLY ($user.id) -> member -> $household SET role = $role;
};

DEFINE FUNCTION OVERWRITE fn::add_recipe_ingredients_to_shopping_list($recipe_id: record<recipe>, $ingredient_indexes: array<number>, $shopping_list_id: record<shopping_list>) {
	LET $recipe = SELECT id, ingredients FROM ONLY $recipe_id FETCH ingredients.ingredient;
	LET $shopping_list = SELECT items FROM ONLY $shopping_list_id;
	
	IF ($recipe == NONE) {
		THROW "Recipe not found.";
	};
	
	IF ($shopping_list == NONE) {
		THROW "Shopping list not found.";
	};
	
	LET $items = function($recipe, $ingredient_indexes, $shopping_list.items) {
    const [recipe, ingredientIndexes, listItems] = arguments;

		const ingredientsToAdd = ingredientIndexes.map(index => recipe.ingredients[index]).filter(ing => !ing.ingredient.skip_from_shopping_list);

    for(const ingredient of ingredientsToAdd) {
			const existing_item = listItems.find(item => item.ingredient.id === ingredient.ingredient.id.id);

			if(existing_item?.unit.id === ingredient.unit?.id) {
				existing_item.amount = (existing_item.amount || 0) + (ingredient.amount || 0);
				existing_item.checked = false;
			}
			else {
				listItems.push({
					ingredient: ingredient.ingredient.id,
					amount: ingredient.amount,
					unit: ingredient.unit,
					category: ingredient.ingredient.category,
					checked: false,
					recipe: recipe.id
				});
			}
		}

    return listItems
	};
	
	UPDATE ONLY $shopping_list_id SET items = $items;
};

COMMIT;